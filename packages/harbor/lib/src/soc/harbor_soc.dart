import 'dart:io';

import 'package:rohd_bridge/rohd_bridge.dart';

import '../bus/bus.dart';
import '../bus/wishbone/wishbone_interface.dart';
import '../pdk/klayout.dart';
import 'device_tree.dart';
import 'graph.dart';
import 'target.dart';

/// A composable SoC built on rohd_bridge.
///
/// Provides a declarative API for assembling a RISC-V SoC: add
/// peripherals and bus masters, and [HarborSoC] auto-wires them
/// through a bus decoder. For custom topology, drop down to
/// rohd_bridge's [addSubModule], [connectInterfaces], and
/// [connectPorts] directly.
///
/// ```dart
/// final soc = HarborSoC(
///   name: 'MySoC',
///   compatible: 'midstall,creek-v1',
///   busConfig: WishboneConfig(addressWidth: 32, dataWidth: 32),
/// );
///
/// // Declarative - auto-wired by address
/// soc.addPeripheral(HarborClint(baseAddress: 0x02000000));
/// soc.addPeripheral(HarborPlic(baseAddress: 0x0C000000));
/// soc.addPeripheral(HarborUart(baseAddress: 0x10000000));
///
/// // Expose UART pins at SoC level
/// soc.exposePin(uart, 'tx');
/// soc.exposePin(uart, 'rx');
///
/// // Add a bus master (CPU)
/// soc.addMaster(myRiverCore);
///
/// // Build the bus fabric (decoder + wiring)
/// soc.buildFabric();
///
/// // Generate outputs
/// await soc.buildAndGenerateRTL();
/// File('soc.dts').writeAsStringSync(soc.generateDts());
/// File('soc.dot').writeAsStringSync(soc.generateDot());
/// ```
class HarborSoC extends BridgeModule {
  /// Root `compatible` string for the device tree.
  final String compatible;

  /// Bus configuration for the fabric.
  final WishboneConfig busConfig;

  /// CPU information for the device tree.
  final List<HarborDeviceTreeCpu> cpus;

  /// Build target (FPGA or ASIC). Controls what scripts are generated.
  final HarborDeviceTarget? target;

  final List<_PeripheralEntry> _peripherals = [];
  final List<_MasterEntry> _masters = [];

  /// Creates a new SoC.
  HarborSoC({
    required String name,
    required this.compatible,
    required this.busConfig,
    this.cpus = const [],
    this.target,
  }) : super(name, name: name) {
    createPort('clk', PortDirection.input);
    createPort('reset', PortDirection.input);
  }

  /// All registered peripherals.
  List<BridgeModule> get peripherals =>
      _peripherals.map((e) => e.module).toList();

  /// All registered bus masters.
  List<BridgeModule> get masters => _masters.map((e) => e.module).toList();

  /// Adds a peripheral to the SoC.
  ///
  /// The peripheral must implement [HarborDeviceTreeNodeProvider] so
  /// the address mapping can be derived from its [HarborDeviceTreeNode.reg].
  ///
  /// Clock and reset are auto-wired. The bus interface is connected
  /// when [buildFabric] is called.
  T addPeripheral<T extends BridgeModule>(T peripheral) {
    if (peripheral is! HarborDeviceTreeNodeProvider) {
      throw ArgumentError(
        'Peripheral ${peripheral.name} must implement '
        'HarborDeviceTreeNodeProvider.',
      );
    }

    addSubModule(peripheral);

    final dt = (peripheral as HarborDeviceTreeNodeProvider).dtNode;
    _peripherals.add(
      _PeripheralEntry(module: peripheral, addressRange: dt.reg),
    );

    // Auto-wire clock and reset
    connectPorts(port('clk'), peripheral.port('clk'));
    connectPorts(port('reset'), peripheral.port('reset'));

    return peripheral;
  }

  /// Adds a bus master (e.g., CPU core) to the SoC.
  ///
  /// [busInterfaceName] is the name of the master's Wishbone provider
  /// interface (default `'dataBus'`).
  ///
  /// Clock and reset are auto-wired.
  T addMaster<T extends BridgeModule>(
    T master, {
    String busInterfaceName = 'dataBus',
  }) {
    addSubModule(master);
    _masters.add(
      _MasterEntry(module: master, busInterfaceName: busInterfaceName),
    );

    connectPorts(port('clk'), master.port('clk'));
    connectPorts(port('reset'), master.port('reset'));

    return master;
  }

  /// Pulls a peripheral's port up to the SoC level as an external pin.
  ///
  /// Useful for UART TX/RX, GPIO, SPI, etc.
  PortReference exposePin(
    BridgeModule peripheral,
    String portName, {
    String? externalName,
  }) {
    return pullUpPort(
      peripheral.port(portName),
      newPortName: externalName ?? '${peripheral.name}_$portName',
    );
  }

  /// Builds the bus fabric connecting masters to peripherals.
  ///
  /// For each master, creates address-decode logic that routes
  /// transactions to the correct peripheral based on
  /// [HarborDeviceTreeNode.reg] address ranges.
  ///
  /// Must be called after all [addPeripheral] and [addMaster]
  /// calls, before [build].
  void buildFabric() {
    if (_peripherals.isEmpty || _masters.isEmpty) return;

    // Validate no address overlaps
    final mappings = _peripherals.indexed
        .map(
          (e) =>
              HarborAddressMapping(range: e.$2.addressRange, slaveIndex: e.$1),
        )
        .toList();

    final errors = validateAddressMappings(mappings);
    if (errors.isNotEmpty) {
      throw StateError(
        'Address mapping errors in $name:\n${errors.join("\n")}',
      );
    }

    // For each master, connect its bus to all peripherals via
    // rohd_bridge's connectInterfaces
    for (final masterEntry in _masters) {
      final masterIntf = masterEntry.module.interface(
        masterEntry.busInterfaceName,
      );

      // Connect master bus to each peripheral's bus
      // The address decoding is handled by the peripherals themselves
      // when they check their address range against the incoming address.
      // We use pullUpInterface to expose each peripheral's bus at
      // this SoC level and connect them.
      for (final periEntry in _peripherals) {
        connectInterfaces(masterIntf, periEntry.module.interface('bus'));
      }
    }
  }

  /// Generates a Linux/U-Boot compatible `.dts` file.
  String generateDts() {
    return HarborDeviceTreeGenerator(
      model: name,
      compatible: compatible,
      cpus: cpus,
      peripherals: _peripherals
          .map((e) => e.module)
          .whereType<HarborDeviceTreeNodeProvider>()
          .toList(),
    ).generate();
  }

  /// Generates a Mermaid flowchart of this SoC's topology.
  String generateMermaid() {
    return HarborSoCGraphGenerator(
      name: name,
      cpus: cpus,
      peripherals: _peripherals
          .map((e) => e.module)
          .whereType<HarborDeviceTreeNodeProvider>()
          .toList(),
    ).mermaid();
  }

  /// Generates a Graphviz DOT graph of this SoC's topology.
  String generateDot() {
    return HarborSoCGraphGenerator(
      name: name,
      cpus: cpus,
      peripherals: _peripherals
          .map((e) => e.module)
          .whereType<HarborDeviceTreeNodeProvider>()
          .toList(),
    ).dot();
  }

  /// Builds RTL and writes all generated outputs to [outputPath].
  ///
  /// Generates:
  /// - `rtl/` - SystemVerilog files + filelist.f (via rohd_bridge)
  /// - `<name>.dts` - device tree source
  /// - `<name>.dot` - Graphviz topology graph
  /// - `<name>.mermaid.md` - Mermaid topology graph
  /// - Target-specific files:
  ///   - FPGA: constraint file (`.pcf`/`.lpf`/`.xdc`)
  ///   - ASIC: SDC timing constraints
  Future<void> generateAll(Directory directory) async {
    directory.createSync(recursive: true);
    final path = directory.path;

    // RTL generation via rohd_bridge
    await buildAndGenerateRTL(outputPath: path);

    // Device tree
    File('$path/$name.dts').writeAsStringSync(generateDts());

    // Graphs
    File('$path/$name.dot').writeAsStringSync(generateDot());
    File(
      '$path/$name.mermaid.md',
    ).writeAsStringSync('```mermaid\n${generateMermaid()}\n```\n');

    // Target-specific outputs
    final t = target;
    if (t != null) {
      switch (t) {
        case HarborFpgaTarget():
          File(
            '$path/$name.${t.constraintExtension}',
          ).writeAsStringSync(t.generateConstraints());
          File('$path/synth.tcl').writeAsStringSync(t.generateYosysTcl(name));
          File('$path/Makefile').writeAsStringSync(t.generateMakefile(name));
        case HarborAsicTarget():
          File('$path/$name.sdc').writeAsStringSync(t.generateSdc());
          File('$path/synth.tcl').writeAsStringSync(t.generateYosysTcl());
          File('$path/pnr.tcl').writeAsStringSync(t.generateOpenroadTcl());

          // Hierarchical macro scripts
          if (t.isHierarchical) {
            final macroDir = Directory('$path/macros');
            macroDir.createSync(recursive: true);
            for (final macro in t.macros) {
              File(
                '$path/macros/${macro.moduleName}_synth.tcl',
              ).writeAsStringSync(t.generateMacroYosysTcl(macro));
              File(
                '$path/macros/${macro.moduleName}_pnr.tcl',
              ).writeAsStringSync(t.generateMacroOpenroadTcl(macro));
            }
          }

          // KLayout scripts
          final klayout = HarborKlayoutScripts(
            pdkName: t.provider.name,
            topCell: t.topCell,
            drc: t.klayoutDrc,
            lvsNetlistPath: '${t.topCell}_final.v',
          );

          final klayoutDir = Directory('$path/klayout');
          klayoutDir.createSync(recursive: true);

          // DEF to GDS conversion
          final lib = t.provider.standardCellLibrary;
          File('$path/klayout/def2gds.py').writeAsStringSync(
            klayout.generateDefToGds(
              defPath: '${t.topCell}_final.def',
              techLefPath: lib.techLefPath ?? lib.lefPath,
              outputGdsPath: '${t.topCell}.gds',
            ),
          );

          // GDS merge (if analog blocks present)
          if (t.analogGdsPaths.isNotEmpty) {
            File('$path/klayout/gds_merge.py').writeAsStringSync(
              klayout.generateGdsMerge(
                digitalGdsPath: '${t.topCell}.gds',
                analogGdsPaths: t.analogGdsPaths,
                outputGdsPath: '${t.topCell}_merged.gds',
              ),
            );
          }

          // DRC
          File(
            '$path/klayout/drc.py',
          ).writeAsStringSync(klayout.generateDrc(gdsPath: '${t.topCell}.gds'));

          // LVS
          File(
            '$path/klayout/lvs.py',
          ).writeAsStringSync(klayout.generateLvs(gdsPath: '${t.topCell}.gds'));
      }
    }
  }
}

class _PeripheralEntry {
  final BridgeModule module;
  final BusAddressRange addressRange;

  const _PeripheralEntry({required this.module, required this.addressRange});
}

class _MasterEntry {
  final BridgeModule module;
  final String busInterfaceName;

  const _MasterEntry({required this.module, required this.busInterfaceName});
}
