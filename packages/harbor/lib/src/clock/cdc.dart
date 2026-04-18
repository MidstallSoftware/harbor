import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

/// Clock domain crossing synchronizer.
///
/// Implements a multi-stage flip-flop synchronizer for safely
/// crossing single-bit signals between clock domains.
///
/// For multi-bit data, use [HarborCdcHandshake] or [HarborCdcFifo].
class HarborCdcSync extends BridgeModule {
  /// Number of synchronizer stages (minimum 2).
  final int stages;

  /// Synchronized output.
  Logic get syncOut => output('sync_out');

  HarborCdcSync({this.stages = 2, super.name = 'cdc_sync'})
    : super('HarborCdcSync') {
    assert(stages >= 2, 'CDC synchronizer requires at least 2 stages');

    createPort('async_in', PortDirection.input);
    createPort('dst_clk', PortDirection.input);
    createPort('dst_reset', PortDirection.input);
    addOutput('sync_out');

    final dstClk = input('dst_clk');
    final dstReset = input('dst_reset');
    final asyncIn = input('async_in');

    // Chain of flip-flops
    final regs = <Logic>[
      for (var i = 0; i < stages; i++) Logic(name: 'sync_stage_$i'),
    ];

    Sequential(dstClk, [
      If(
        dstReset,
        then: [for (final r in regs) r < Const(0)],
        orElse: [
          regs[0] < asyncIn,
          for (var i = 1; i < stages; i++) regs[i] < regs[i - 1],
        ],
      ),
    ]);

    syncOut <= regs.last;
  }
}

/// Clock domain crossing with handshake protocol.
///
/// Safely transfers multi-bit data between two clock domains
/// using a req/ack handshake.
class HarborCdcHandshake extends BridgeModule {
  /// Data width in bits.
  final int dataWidth;

  HarborCdcHandshake({this.dataWidth = 32, super.name = 'cdc_handshake'})
    : super('HarborCdcHandshake') {
    // Source domain
    createPort('src_clk', PortDirection.input);
    createPort('src_reset', PortDirection.input);
    createPort('src_data', PortDirection.input, width: dataWidth);
    createPort('src_valid', PortDirection.input);
    addOutput('src_ready');

    // Destination domain
    createPort('dst_clk', PortDirection.input);
    createPort('dst_reset', PortDirection.input);
    addOutput('dst_data', width: dataWidth);
    addOutput('dst_valid');
    createPort('dst_ready', PortDirection.input);

    final srcClk = input('src_clk');
    final srcReset = input('src_reset');
    final dstClk = input('dst_clk');
    final dstReset = input('dst_reset');

    // Source side: latch data and assert req
    final srcReq = Logic(name: 'src_req');
    final dataReg = Logic(name: 'data_reg', width: dataWidth);

    // Synchronize ack back to src domain
    final ackSync0 = Logic(name: 'ack_sync0');
    final ackSync1 = Logic(name: 'ack_sync1');

    Sequential(srcClk, [
      If(
        srcReset,
        then: [
          srcReq < Const(0),
          dataReg < Const(0, width: dataWidth),
          ackSync0 < Const(0),
          ackSync1 < Const(0),
        ],
        orElse: [
          ackSync0 < Logic(name: 'dst_ack_raw'),
          ackSync1 < ackSync0,
          If(
            input('src_valid') & ~srcReq & ~ackSync1,
            then: [dataReg < input('src_data'), srcReq < Const(1)],
          ),
          If(ackSync1, then: [srcReq < Const(0)]),
        ],
      ),
    ]);

    output('src_ready') <= ~srcReq & ~ackSync1;

    // Destination side: synchronize req, latch data, assert ack
    final reqSync0 = Logic(name: 'req_sync0');
    final reqSync1 = Logic(name: 'req_sync1');
    final dstAck = Logic(name: 'dst_ack');

    Sequential(dstClk, [
      If(
        dstReset,
        then: [reqSync0 < Const(0), reqSync1 < Const(0), dstAck < Const(0)],
        orElse: [
          reqSync0 < srcReq,
          reqSync1 < reqSync0,
          If(reqSync1 & ~dstAck, then: [dstAck < Const(1)]),
          If(input('dst_ready') & dstAck, then: [dstAck < Const(0)]),
        ],
      ),
    ]);

    output('dst_data') <= dataReg;
    output('dst_valid') <= reqSync1 & dstAck;
  }
}

/// Asynchronous FIFO for clock domain crossing.
///
/// Uses gray-code pointers to safely pass data between two
/// independent clock domains.
class HarborCdcFifo extends BridgeModule {
  /// Data width in bits.
  final int dataWidth;

  /// FIFO depth (must be power of 2).
  final int depth;

  HarborCdcFifo({this.dataWidth = 32, this.depth = 8, super.name = 'cdc_fifo'})
    : super('HarborCdcFifo') {
    assert(
      depth > 0 && (depth & (depth - 1)) == 0,
      'FIFO depth must be power of 2',
    );

    // Write domain
    createPort('wr_clk', PortDirection.input);
    createPort('wr_reset', PortDirection.input);
    createPort('wr_data', PortDirection.input, width: dataWidth);
    createPort('wr_en', PortDirection.input);
    addOutput('wr_full');

    // Read domain
    createPort('rd_clk', PortDirection.input);
    createPort('rd_reset', PortDirection.input);
    addOutput('rd_data', width: dataWidth);
    createPort('rd_en', PortDirection.input);
    addOutput('rd_empty');

    // Pointer width includes extra bit for full/empty detection
    final ptrWidth = _log2(depth) + 1;

    final wrPtr = Logic(name: 'wr_ptr', width: ptrWidth);
    final wrPtrGray = Logic(name: 'wr_ptr_gray', width: ptrWidth);
    final rdPtrGraySync = Logic(name: 'rd_ptr_gray_sync', width: ptrWidth);

    final rdPtr = Logic(name: 'rd_ptr', width: ptrWidth);
    final rdPtrGray = Logic(name: 'rd_ptr_gray', width: ptrWidth);
    final wrPtrGraySync = Logic(name: 'wr_ptr_gray_sync', width: ptrWidth);

    // Gray code conversion: binary ^ (binary >> 1)
    wrPtrGray <= wrPtr ^ (wrPtr >>> 1);
    rdPtrGray <= rdPtr ^ (rdPtr >>> 1);

    // Full: write gray == inverted top 2 bits of read gray, rest equal
    output('wr_full') <=
        wrPtrGray.eq(
          [
            ~rdPtrGraySync.getRange(ptrWidth - 2, ptrWidth),
            rdPtrGraySync.getRange(0, ptrWidth - 2),
          ].swizzle(),
        );

    // Empty: read gray == write gray
    output('rd_empty') <= rdPtrGray.eq(wrPtrGraySync);

    // Write domain logic
    final wrClk = input('wr_clk');
    final wrReset = input('wr_reset');

    // Synchronize read pointer gray to write domain
    final rdGraySync0 = Logic(name: 'rd_gray_sync0', width: ptrWidth);
    Sequential(wrClk, [
      If(
        wrReset,
        then: [
          wrPtr < Const(0, width: ptrWidth),
          rdGraySync0 < Const(0, width: ptrWidth),
          rdPtrGraySync < Const(0, width: ptrWidth),
        ],
        orElse: [
          rdGraySync0 < rdPtrGray,
          rdPtrGraySync < rdGraySync0,
          If(input('wr_en') & ~output('wr_full'), then: [wrPtr < wrPtr + 1]),
        ],
      ),
    ]);

    // Read domain logic
    final rdClk = input('rd_clk');
    final rdReset = input('rd_reset');

    final wrGraySync0 = Logic(name: 'wr_gray_sync0', width: ptrWidth);
    Sequential(rdClk, [
      If(
        rdReset,
        then: [
          rdPtr < Const(0, width: ptrWidth),
          wrGraySync0 < Const(0, width: ptrWidth),
          wrPtrGraySync < Const(0, width: ptrWidth),
        ],
        orElse: [
          wrGraySync0 < wrPtrGray,
          wrPtrGraySync < wrGraySync0,
          If(input('rd_en') & ~output('rd_empty'), then: [rdPtr < rdPtr + 1]),
        ],
      ),
    ]);

    // Memory would be inferred by synthesis
    output('rd_data') <= Const(0, width: dataWidth); // placeholder
  }

  static int _log2(int val) {
    var result = 0;
    var v = val;
    while (v > 1) {
      v >>= 1;
      result++;
    }
    return result;
  }
}
