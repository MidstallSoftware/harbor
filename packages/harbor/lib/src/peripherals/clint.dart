import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../bus/bus.dart';
import '../bus/bus_slave_port.dart';
import '../soc/device_tree.dart';

/// RISC-V Core Local Interruptor (CLINT), SiFive-compatible.
///
/// Provides per-hart timer and software interrupt functionality.
/// Compatible with Linux `riscv,clint0` driver.
///
/// Register map (per SiFive CLINT spec):
/// - `msip[hart]`:     0x0000 + hart*4  (4 bytes, software interrupt pending)
/// - `mtimecmp[hart]`: 0x4000 + hart*8  (8 bytes, timer compare)
/// - `mtime`:          0xBFF8           (8 bytes, machine timer)
///
/// Address space: 64 KB (0x10000).
class HarborClint extends BridgeModule with HarborDeviceTreeNodeProvider {
  /// Number of harts this CLINT serves.
  final int hartCount;

  /// Base address in the SoC memory map.
  final int baseAddress;

  /// Timer interrupt output per hart.
  late final List<Logic> timerInterrupt;

  /// Software interrupt output per hart.
  late final List<Logic> softwareInterrupt;

  /// Bus slave port.
  late final BusSlavePort bus;

  HarborClint({
    required this.baseAddress,
    this.hartCount = 1,
    BusProtocol protocol = BusProtocol.wishbone,
    String? name,
  }) : super('HarborClint', name: name ?? 'clint') {
    createPort('clk', PortDirection.input);
    createPort('reset', PortDirection.input);

    bus = BusSlavePort.create(
      module: this,
      name: 'bus',
      protocol: protocol,
      addressWidth: 16,
      dataWidth: 32,
    );

    final clk = input('clk');
    final reset = input('reset');
    final addr = bus.addr;
    final datIn = bus.dataIn;
    final datOut = bus.dataOut;
    final ack = bus.ack;
    final stb = bus.stb;
    final we = bus.we;

    timerInterrupt = List.generate(hartCount, (i) => addOutput('timer_irq_$i'));
    softwareInterrupt = List.generate(hartCount, (i) => addOutput('sw_irq_$i'));

    final mtime = Logic(name: 'mtime', width: 64);
    final mtimecmp = List.generate(
      hartCount,
      (i) => Logic(name: 'mtimecmp_$i', width: 64),
    );
    final msip = List.generate(hartCount, (i) => Logic(name: 'msip_$i'));

    for (var i = 0; i < hartCount; i++) {
      timerInterrupt[i] <= mtime.gte(mtimecmp[i]);
      softwareInterrupt[i] <= msip[i];
    }

    Sequential(clk, [
      If(
        reset,
        then: [
          mtime < Const(0, width: 64),
          for (var i = 0; i < hartCount; i++) ...[
            mtimecmp[i] < Const(0, width: 64),
            msip[i] < Const(0),
          ],
          ack < Const(0),
          datOut < Const(0, width: 32),
        ],
        orElse: [
          mtime < mtime + Const(1, width: 64),
          ack < Const(0),
          datOut < Const(0, width: 32),

          If(
            stb & ~ack,
            then: [
              ack < Const(1),

              for (var i = 0; i < hartCount; i++) ...[
                If(
                  addr.eq(Const(i * 4, width: 16)),
                  then: [
                    If(
                      we,
                      then: [msip[i] < datIn[0]],
                      orElse: [datOut < msip[i].zeroExtend(32)],
                    ),
                  ],
                ),
              ],

              for (var i = 0; i < hartCount; i++) ...[
                If(
                  addr.eq(Const(0x4000 + i * 8, width: 16)),
                  then: [
                    If(
                      we,
                      then: [
                        mtimecmp[i] <
                            mtimecmp[i] &
                                    (Const(0xFFFFFFFF00000000, width: 64)) |
                                (datIn.zeroExtend(64)),
                      ],
                      orElse: [datOut < mtimecmp[i].getRange(0, 32)],
                    ),
                  ],
                ),
                If(
                  addr.eq(Const(0x4000 + i * 8 + 4, width: 16)),
                  then: [
                    If(
                      we,
                      then: [
                        mtimecmp[i] <
                            mtimecmp[i] &
                                    (Const(0x00000000FFFFFFFF, width: 64)) |
                                (datIn.zeroExtend(64) << Const(32, width: 64)),
                      ],
                      orElse: [datOut < mtimecmp[i].getRange(32, 64)],
                    ),
                  ],
                ),
              ],

              If(
                addr.eq(Const(0xBFF8, width: 16)),
                then: [datOut < mtime.getRange(0, 32)],
              ),
              If(
                addr.eq(Const(0xBFFC, width: 16)),
                then: [datOut < mtime.getRange(32, 64)],
              ),
            ],
          ),
        ],
      ),
    ]);
  }

  @override
  HarborDeviceTreeNode get dtNode => HarborDeviceTreeNode(
    compatible: ['riscv,clint0'],
    reg: BusAddressRange(baseAddress, 0x10000),
    properties: {'reg-names': 'control'},
  );
}
