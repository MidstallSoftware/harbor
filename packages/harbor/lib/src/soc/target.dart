import '../pdk/pdk_provider.dart';

/// Build target describing whether the SoC targets an FPGA or ASIC,
/// and which vendor/PDK to use.
///
/// The target controls what synthesis and place-and-route scripts
/// are generated when calling [HarborSoC.generateAll].
sealed class HarborDeviceTarget {
  /// Human-readable name for this target.
  String get name;

  const HarborDeviceTarget();
}

/// FPGA target with vendor-specific toolchain configuration.
///
/// ```dart
/// final target = HarborFpgaTarget.ice40(
///   device: 'up5k',
///   package: 'sg48',
///   frequency: 48000000,
///   pinMap: {'uart_tx': 'P1', 'uart_rx': 'P2'},
/// );
/// ```
class HarborFpgaTarget extends HarborDeviceTarget {
  @override
  final String name;

  /// FPGA vendor.
  final HarborFpgaVendor vendor;

  /// Device part number (e.g., `'up5k'`, `'lfe5u-45f'`, `'xc7s50'`).
  final String device;

  /// Package (e.g., `'sg48'`, `'CABGA381'`, `'ftgb196'`).
  final String package;

  /// Target clock frequency in Hz.
  final int frequency;

  /// Pin constraints: signal name → pin identifier.
  final Map<String, String> pinMap;

  /// Additional constraints passed to the toolchain.
  final Map<String, String> extraConstraints;

  /// Whether this FPGA supports eFuse OTP storage.
  ///
  /// ECP5 and Spartan 7 have eFuse support for user data and
  /// security keys. iCE40 does not.
  bool get hasEfuse => switch (vendor) {
    HarborFpgaVendor.ice40 => false,
    HarborFpgaVendor.ecp5 => true,
    HarborFpgaVendor.vivado => true,
    HarborFpgaVendor.openXc7 => true,
  };

  /// Whether this FPGA has a built-in temperature sensor primitive.
  ///
  /// ECP5 has DTR, Xilinx 7-series has XADC. iCE40 does not.
  bool get hasTemperatureSensor => switch (vendor) {
    HarborFpgaVendor.ice40 => false,
    HarborFpgaVendor.ecp5 => true,
    HarborFpgaVendor.vivado => true,
    HarborFpgaVendor.openXc7 => true,
  };

  /// File extension for the constraint file (e.g., `'pcf'`, `'lpf'`, `'xdc'`).
  String get constraintExtension => switch (vendor) {
    HarborFpgaVendor.ice40 => 'pcf',
    HarborFpgaVendor.ecp5 => 'lpf',
    HarborFpgaVendor.vivado => 'xdc',
    HarborFpgaVendor.openXc7 => 'xdc',
  };

  const HarborFpgaTarget({
    required this.name,
    required this.vendor,
    required this.device,
    required this.package,
    this.frequency = 0,
    this.pinMap = const {},
    this.extraConstraints = const {},
  });

  /// iCE40 UP5K target using Yosys + nextpnr-ice40.
  const HarborFpgaTarget.ice40({
    required this.device,
    required this.package,
    this.frequency = 0,
    this.pinMap = const {},
    this.extraConstraints = const {},
  }) : name = 'ice40-$device',
       vendor = HarborFpgaVendor.ice40;

  /// Lattice ECP5 target using Yosys + nextpnr-ecp5.
  const HarborFpgaTarget.ecp5({
    required this.device,
    required this.package,
    this.frequency = 0,
    this.pinMap = const {},
    this.extraConstraints = const {},
  }) : name = 'ecp5-$device',
       vendor = HarborFpgaVendor.ecp5;

  /// Xilinx Spartan 7 target using Vivado or openXC7.
  const HarborFpgaTarget.spartan7({
    required this.device,
    required this.package,
    this.frequency = 0,
    this.pinMap = const {},
    this.extraConstraints = const {},
    bool useOpenXc7 = false,
  }) : name = 'spartan7-$device',
       vendor = useOpenXc7 ? HarborFpgaVendor.openXc7 : HarborFpgaVendor.vivado;

  /// Generates a pin constraint file in the vendor's format.
  ///
  /// - iCE40: `.pcf` (Physical Constraints File)
  /// - ECP5: `.lpf` (Lattice Preference File)
  /// - Xilinx: `.xdc` (Xilinx Design Constraints)
  String generateConstraints() {
    switch (vendor) {
      case HarborFpgaVendor.ice40:
        return _generatePcf();
      case HarborFpgaVendor.ecp5:
        return _generateLpf();
      case HarborFpgaVendor.vivado:
      case HarborFpgaVendor.openXc7:
        return _generateXdc();
    }
  }

  String _generatePcf() {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated PCF for $name');
    for (final entry in pinMap.entries) {
      buf.writeln('set_io ${entry.key} ${entry.value}');
    }
    if (frequency > 0) {
      final clkPin = pinMap['clk'];
      if (clkPin != null) {
        buf.writeln('set_frequency clk ${frequency / 1e6}');
      }
    }
    return buf.toString();
  }

  String _generateLpf() {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated LPF for $name');
    for (final entry in pinMap.entries) {
      buf.writeln('LOCATE COMP "${entry.key}" SITE "${entry.value}";');
      buf.writeln('IOBUF PORT "${entry.key}" IO_TYPE=LVCMOS33;');
    }
    if (frequency > 0) {
      buf.writeln(
        'FREQUENCY PORT "clk" ${(frequency / 1e6).toStringAsFixed(1)} MHz;',
      );
    }
    return buf.toString();
  }

  String _generateXdc() {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated XDC for $name');
    for (final entry in pinMap.entries) {
      buf.writeln(
        'set_property -dict {PACKAGE_PIN ${entry.value} IOSTANDARD LVCMOS33} '
        '[get_ports {${entry.key}}]',
      );
    }
    if (frequency > 0) {
      final periodNs = 1e9 / frequency;
      buf.writeln(
        'create_clock -period ${periodNs.toStringAsFixed(3)} '
        '[get_ports {clk}]',
      );
    }
    return buf.toString();
  }
}

/// ASIC tapeout target with PDK configuration.
///
/// ```dart
/// final target = HarborAsicTarget(
///   provider: Sky130Provider(pdkRoot: '/path/to/sky130A'),
///   topCell: 'MySoC',
///   frequency: 50000000,
/// );
/// ```
class HarborAsicTarget extends HarborDeviceTarget {
  @override
  String get name => '${provider.name}-${provider.node}';

  /// The PDK provider supplying cell libraries, analog blocks, etc.
  final PdkProvider provider;

  /// Top-level cell name for synthesis.
  final String topCell;

  /// Target clock frequency in Hz.
  final int frequency;

  /// Utilization target for placement (0.0 to 1.0).
  final double utilization;

  const HarborAsicTarget({
    required this.provider,
    required this.topCell,
    this.frequency = 0,
    this.utilization = 0.5,
  });

  /// Generates an SDC timing constraints file.
  String generateSdc() {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated SDC for $name');
    if (frequency > 0) {
      final periodNs = 1e9 / frequency;
      buf.writeln(
        'create_clock -name clk -period ${periodNs.toStringAsFixed(3)} '
        '[get_ports {clk}]',
      );
    }
    buf.writeln('set_input_delay 0 -clock clk [all_inputs]');
    buf.writeln('set_output_delay 0 -clock clk [all_outputs]');
    return buf.toString();
  }

  /// Generates a Yosys synthesis TCL script.
  String generateYosysTcl() {
    final lib = provider.standardCellLibrary;
    final buf = StringBuffer();
    buf.writeln('# Auto-generated Yosys synthesis for $topCell');
    buf.writeln('# PDK: ${provider.name}');
    buf.writeln();
    buf.writeln('yosys read_verilog -sv \$SV_FILE');
    buf.writeln('yosys hierarchy -top $topCell');
    buf.writeln('yosys synth -top $topCell -flatten');
    buf.writeln('yosys dfflibmap -liberty ${lib.libertyPath}');
    buf.writeln('yosys abc -liberty ${lib.libertyPath}');
    buf.writeln(
      'yosys hilomap -hicell ${lib.tieHighCell} Z '
      '-locell ${lib.tieLowCell} ZN',
    );
    buf.writeln('yosys opt_clean -purge');
    buf.writeln('yosys write_verilog -noattr ${topCell}_synth.v');
    buf.writeln('yosys stat -liberty ${lib.libertyPath}');
    return buf.toString();
  }

  /// Generates an OpenROAD place-and-route TCL script.
  String generateOpenroadTcl() {
    final lib = provider.standardCellLibrary;
    final buf = StringBuffer();
    buf.writeln('# Auto-generated OpenROAD P&R for $topCell');
    buf.writeln('# PDK: ${provider.name}');
    buf.writeln();

    // Read inputs
    buf.writeln('read_liberty ${lib.libertyPath}');
    if (lib.techLefPath != null) {
      buf.writeln('read_lef ${lib.techLefPath}');
    }
    buf.writeln('read_lef ${lib.lefPath}');
    buf.writeln('read_verilog ${topCell}_synth.v');
    buf.writeln('link_design $topCell');
    buf.writeln('read_sdc ${topCell}.sdc');
    buf.writeln();

    // Floorplan
    buf.writeln('initialize_floorplan \\');
    buf.writeln('    -utilization $utilization \\');
    buf.writeln('    -core_space 2 \\');
    buf.writeln('    -site ${lib.siteName}');
    buf.writeln();

    // Power
    buf.writeln('add_global_connection -net VDD -pin_pattern VDD -power');
    buf.writeln('add_global_connection -net VSS -pin_pattern VSS -ground');
    buf.writeln('global_connect');
    buf.writeln();

    // Placement
    buf.writeln('global_placement -density $utilization');
    buf.writeln('detailed_placement');
    buf.writeln();

    // CTS
    if (lib.clockBufferCells.isNotEmpty) {
      buf.writeln('estimate_parasitics -placement');
      buf.writeln(
        'clock_tree_synthesis -buf_list '
        '{${lib.clockBufferCells.join(" ")}}',
      );
      buf.writeln('detailed_placement');
      buf.writeln();
    }

    // Routing
    buf.writeln('global_route -allow_congestion');
    buf.writeln('detailed_route');
    buf.writeln();

    // Fill
    if (lib.fillCells.isNotEmpty) {
      buf.writeln('filler_placement ${lib.fillCells.join(" ")}');
      buf.writeln();
    }

    // Reports & outputs
    buf.writeln('report_checks -path_delay min_max > timing.rpt');
    buf.writeln('report_design_area > area.rpt');
    buf.writeln('report_power > power.rpt');
    buf.writeln('write_def ${topCell}_final.def');
    buf.writeln('write_verilog ${topCell}_final.v');

    return buf.toString();
  }
}

/// Supported FPGA vendors / toolchains.
enum HarborFpgaVendor {
  /// Lattice iCE40 - Yosys + nextpnr-ice40
  ice40,

  /// Lattice ECP5 - Yosys + nextpnr-ecp5
  ecp5,

  /// Xilinx Vivado (proprietary)
  vivado,

  /// Xilinx openXC7 (open-source)
  openXc7,
}
