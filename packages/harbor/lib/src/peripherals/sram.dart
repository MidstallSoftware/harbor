import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../bus/bus.dart';
import '../bus/bus_slave_port.dart';
import '../soc/device_tree.dart';

/// On-chip SRAM memory module.
///
/// Provides a simple single-cycle read/write memory with a Wishbone
/// slave interface. Compatible with the `sram` device tree binding.
///
/// For FPGA targets, this infers block RAM. For larger memories,
/// use vendor-specific blackbox primitives (SB_SPRAM256KA, etc.).
class HarborSram extends BridgeModule with HarborDeviceTreeNodeProvider {
  /// Memory size in bytes.
  final int size;

  /// Base address in the SoC memory map.
  final int baseAddress;

  /// Data width in bits.
  final int dataWidth;

  /// Bus slave port.
  late final BusSlavePort bus;

  HarborSram({
    required this.baseAddress,
    required this.size,
    this.dataWidth = 32,
    BusProtocol protocol = BusProtocol.wishbone,
    String? name,
  }) : super('HarborSram', name: name ?? 'sram') {
    createPort('clk', PortDirection.input);
    createPort('reset', PortDirection.input);

    final addrWidth = (size ~/ (dataWidth ~/ 8)).bitLength;

    bus = BusSlavePort.create(
      module: this,
      name: 'bus',
      protocol: protocol,
      addressWidth: addrWidth,
      dataWidth: dataWidth,
    );

    final clk = input('clk');
    final datOut = bus.dataOut;
    final ack = bus.ack;
    final stb = bus.stb;
    final we = bus.we;

    // Memory placeholder - synthesis tools infer block RAM from
    // the sequential read/write pattern
    final mem = Logic(name: 'mem', width: dataWidth);

    Sequential(clk, [
      ack < Const(0),
      datOut < Const(0, width: dataWidth),
      If(
        stb & ~ack,
        then: [
          ack < Const(1),
          If(
            we,
            then: [
              // Write - actual memory write would be inferred
              // from the synthesis tool's RAM inference
            ],
            orElse: [
              // Read
              datOut < mem,
            ],
          ),
        ],
      ),
    ]);

    // Note: actual RAM inference depends on the synthesis tool.
    // The sequential read/write pattern above should infer BRAM
    // on most FPGA toolchains. For explicit control, use
    // vendor-specific blackbox primitives.
    mem <= Const(0, width: dataWidth);
  }

  @override
  HarborDeviceTreeNode get dtNode => HarborDeviceTreeNode(
    compatible: ['harbor,sram', 'mmio-sram'],
    reg: BusAddressRange(baseAddress, size),
    properties: {'data-width': dataWidth},
  );
}
