import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../bus/bus.dart';
import '../bus/bus_slave_port.dart';
import '../soc/device_tree.dart';

/// On-chip SRAM memory module.
///
/// Provides single-cycle read/write memory with a bus slave interface.
/// Uses a register array that synthesis tools infer as block RAM
/// on FPGAs.
///
/// For larger memories or explicit BRAM control, use vendor-specific
/// blackbox primitives (Ice40SbSpram256ka, XilinxRamb36e1, etc.).
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

    final bytesPerWord = dataWidth ~/ 8;
    final numWords = size ~/ bytesPerWord;
    final addrWidth = numWords.bitLength;
    // Number of address bits used for byte offset within a word
    // e.g., 4 bytes -> 2 bits, 8 bytes -> 3 bits
    final byteOffsetBits = bytesPerWord > 1 ? (bytesPerWord - 1).bitLength : 0;
    final totalAddrWidth = addrWidth + byteOffsetBits;

    bus = BusSlavePort.create(
      module: this,
      name: 'bus',
      protocol: protocol,
      addressWidth: totalAddrWidth,
      dataWidth: dataWidth,
    );

    final clk = input('clk');
    final datOut = bus.dataOut;
    final ack = bus.ack;
    final stb = bus.stb;
    final we = bus.we;
    final addr = bus.addr;
    final datIn = bus.dataIn;

    // Word address (strip byte offset bits)
    final wordAddr = byteOffsetBits > 0
        ? addr.getRange(byteOffsetBits, byteOffsetBits + addrWidth)
        : addr.getRange(0, addrWidth);

    // Memory array - synthesis tools infer block RAM from this pattern:
    // synchronous read + synchronous write on the same clock edge
    final mem = <Logic>[
      for (var i = 0; i < numWords; i++)
        Logic(name: 'mem_$i', width: dataWidth),
    ];

    // Read data mux
    Logic readData = Const(0, width: dataWidth);
    for (var i = 0; i < numWords; i++) {
      readData = mux(
        wordAddr.eq(Const(i, width: wordAddr.width)),
        mem[i],
        readData,
      );
    }

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
              // Write: store data to the addressed word
              for (var i = 0; i < numWords; i++)
                If(
                  wordAddr.eq(Const(i, width: wordAddr.width)),
                  then: [mem[i] < datIn],
                ),
            ],
            orElse: [
              // Read: output data from the addressed word
              datOut < readData,
            ],
          ),
        ],
      ),
    ]);
  }

  @override
  HarborDeviceTreeNode get dtNode => HarborDeviceTreeNode(
    compatible: ['harbor,sram', 'mmio-sram'],
    reg: BusAddressRange(baseAddress, size),
    properties: {'data-width': dataWidth},
  );
}
