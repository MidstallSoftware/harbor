import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../bus/bus.dart';
import '../bus/bus_slave_port.dart';
import '../soc/device_tree.dart';

/// 16550-compatible UART peripheral.
///
/// Works with Linux `ns16550a` driver and U-Boot `ns16550` driver.
///
/// Register map (standard 16550):
/// - 0x0: RBR (read) / THR (write) / DLL (DLAB=1)
/// - 0x1: IER (DLAB=0) / DLM (DLAB=1)
/// - 0x2: IIR (read) / FCR (write)
/// - 0x3: LCR (bit 7 = DLAB)
/// - 0x4: MCR
/// - 0x5: LSR (read-only)
/// - 0x6: MSR (read-only)
/// - 0x7: SCR
///
/// Address space: 8 bytes (mapped to 0x1000 page for SoC).
class HarborUart extends BridgeModule with HarborDeviceTreeNodeProvider {
  final int baseAddress;
  final int clockFrequency;

  /// TX serial output.
  Logic get tx => output('tx');

  /// Interrupt output.
  Logic get interrupt => output('interrupt');

  /// Bus slave port.
  late final BusSlavePort bus;

  HarborUart({
    required this.baseAddress,
    this.clockFrequency = 0,
    int? busAddressWidth,
    int? busDataWidth,
    BusProtocol protocol = BusProtocol.wishbone,
    String? name,
  }) : super('HarborUart', name: name ?? 'uart') {
    createPort('clk', PortDirection.input);
    createPort('reset', PortDirection.input);
    createPort('rx', PortDirection.input);
    addOutput('tx');
    addOutput('interrupt');

    bus = BusSlavePort.create(
      module: this,
      name: 'bus',
      protocol: protocol,
      addressWidth: busAddressWidth ?? 3,
      dataWidth: busDataWidth ?? 8,
    );

    final clk = input('clk');
    final reset = input('reset');
    // Use only the lower 3 bits of address and 8 bits of data
    final addr = bus.addr.getRange(0, 3);
    final datIn = bus.dataIn.getRange(0, 8);
    final datOut8 = Logic(name: 'uart_dat_out', width: 8);
    bus.dataOut <= datOut8.zeroExtend(bus.dataOut.width);
    final ack = bus.ack;
    final stb = bus.stb;
    final we = bus.we;

    // Registers
    final dll = Logic(name: 'dll', width: 8);
    final dlm = Logic(name: 'dlm', width: 8);
    final ier = Logic(name: 'ier', width: 8);
    final fcr = Logic(name: 'fcr', width: 8);
    final lcr = Logic(name: 'lcr', width: 8);
    final mcr = Logic(name: 'mcr', width: 8);
    final scr = Logic(name: 'scr', width: 8);

    // TX state (single-byte holding register, no FIFO for simplicity)
    final txBusy = Logic(name: 'tx_busy');
    final txShift = Logic(name: 'tx_shift', width: 10);
    final txCount = Logic(name: 'tx_count', width: 4);
    final txHolding = Logic(name: 'tx_holding', width: 8);
    final txHoldingFull = Logic(name: 'tx_holding_full');

    // RX state (single-byte holding register)
    final rxData = Logic(name: 'rx_data', width: 8);
    final rxReady = Logic(name: 'rx_ready');

    // Baud rate
    final baudCount = Logic(name: 'baud_count', width: 16);
    final baudTick = Logic(name: 'baud_tick');
    final divisor = [dlm, dll].swizzle();
    baudTick <=
        baudCount.eq(Const(0, width: 16)) & divisor.neq(Const(0, width: 16));

    // LSR
    final lsr = Logic(name: 'lsr', width: 8);
    lsr <=
        rxReady.zeroExtend(8) | // bit 0: data ready
            ((~txHoldingFull).zeroExtend(8) <<
                Const(5, width: 8)) | // bit 5: THRE
            (((~txHoldingFull) & (~txBusy)).zeroExtend(8) <<
                Const(6, width: 8)); // bit 6: TEMT

    // IIR
    final irqRx = rxReady & ier[0];
    final irqTx = (~txHoldingFull) & ier[1];
    final computedIir = Logic(name: 'computed_iir', width: 8);
    Combinational([
      computedIir < (fcr.getRange(6, 8).zeroExtend(8) << Const(6, width: 8)),
      If(
        irqRx,
        then: [computedIir < (computedIir | Const(0x04, width: 8))],
        orElse: [
          If(
            irqTx,
            then: [computedIir < (computedIir | Const(0x02, width: 8))],
            orElse: [computedIir < (computedIir | Const(0x01, width: 8))],
          ),
        ],
      ),
    ]);

    interrupt <= irqRx | irqTx;

    final dlab = lcr[7];

    Sequential(clk, [
      If(
        reset,
        then: [
          dll < Const(1, width: 8),
          dlm < Const(0, width: 8),
          ier < Const(0, width: 8),
          fcr < Const(0, width: 8),
          lcr < Const(0x03, width: 8), // 8N1
          mcr < Const(0, width: 8),
          scr < Const(0, width: 8),
          txBusy < Const(0),
          txShift < Const(0x3FF, width: 10),
          txCount < Const(0, width: 4),
          txHolding < Const(0, width: 8),
          txHoldingFull < Const(0),
          rxData < Const(0, width: 8),
          rxReady < Const(0),
          baudCount < Const(0, width: 16),
          ack < Const(0),
          datOut8 < Const(0, width: 8),
        ],
        orElse: [
          // Baud counter
          If(
            baudCount.eq(Const(0, width: 16)),
            then: [baudCount < (divisor - Const(1, width: 16))],
            orElse: [baudCount < (baudCount - Const(1, width: 16))],
          ),

          // TX engine
          If(
            txBusy & baudTick,
            then: [
              txShift < (txShift >> Const(1, width: 10)),
              txCount < (txCount + Const(1, width: 4)),
              If(
                txCount.eq(Const(9, width: 4)),
                then: [txBusy < Const(0), txCount < Const(0, width: 4)],
              ),
            ],
          ),

          // Load from holding register when TX idle
          If(
            ~txBusy & txHoldingFull,
            then: [
              txShift <
                  [Const(1, width: 1), txHolding, Const(0, width: 1)].swizzle(),
              txBusy < Const(1),
              txCount < Const(0, width: 4),
              txHoldingFull < Const(0),
            ],
          ),

          // Bus access
          ack < Const(0),
          datOut8 < Const(0, width: 8),

          If(
            stb & ~ack,
            then: [
              ack < Const(1),

              Case(addr, [
                // 0x0: RBR/THR/DLL
                CaseItem(Const(0, width: 3), [
                  If(
                    dlab,
                    then: [
                      If(we, then: [dll < datIn], orElse: [datOut8 < dll]),
                    ],
                    orElse: [
                      If(
                        we,
                        then: [txHolding < datIn, txHoldingFull < Const(1)],
                        orElse: [datOut8 < rxData, rxReady < Const(0)],
                      ),
                    ],
                  ),
                ]),
                // 0x1: IER/DLM
                CaseItem(Const(1, width: 3), [
                  If(
                    dlab,
                    then: [
                      If(we, then: [dlm < datIn], orElse: [datOut8 < dlm]),
                    ],
                    orElse: [
                      If(we, then: [ier < datIn], orElse: [datOut8 < ier]),
                    ],
                  ),
                ]),
                // 0x2: IIR/FCR
                CaseItem(Const(2, width: 3), [
                  If(we, then: [fcr < datIn], orElse: [datOut8 < computedIir]),
                ]),
                // 0x3: LCR
                CaseItem(Const(3, width: 3), [
                  If(we, then: [lcr < datIn], orElse: [datOut8 < lcr]),
                ]),
                // 0x4: MCR
                CaseItem(Const(4, width: 3), [
                  If(we, then: [mcr < datIn], orElse: [datOut8 < mcr]),
                ]),
                // 0x5: LSR (read-only)
                CaseItem(Const(5, width: 3), [datOut8 < lsr]),
                // 0x6: MSR (read-only stub)
                CaseItem(Const(6, width: 3), [datOut8 < Const(0, width: 8)]),
                // 0x7: SCR
                CaseItem(Const(7, width: 3), [
                  If(we, then: [scr < datIn], orElse: [datOut8 < scr]),
                ]),
              ]),
            ],
          ),
        ],
      ),
    ]);

    // TX output: LSB of shift register when busy, else idle high
    Combinational([
      If(txBusy, then: [tx < txShift[0]], orElse: [tx < Const(1)]),
    ]);
  }

  @override
  HarborDeviceTreeNode get dtNode => HarborDeviceTreeNode(
    compatible: ['ns16550a'],
    reg: BusAddressRange(baseAddress, 0x1000),
    properties: {
      'reg-shift': 0,
      'reg-io-width': 1,
      if (clockFrequency > 0) 'clock-frequency': clockFrequency,
    },
  );
}
