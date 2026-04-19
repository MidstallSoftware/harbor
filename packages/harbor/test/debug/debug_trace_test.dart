import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborDebugModule', () {
    test('creates with defaults (numHarts=1)', () {
      final dm = HarborDebugModule(baseAddress: 0x00000000);
      expect(dm, isNotNull);
      expect(dm.numHarts, equals(1));
    });

    test('multi-hart (numHarts=4) has hart3 ports', () {
      final dm = HarborDebugModule(baseAddress: 0x00000000, numHarts: 4);
      expect(dm.output('hart3_halt_req').width, equals(1));
      expect(dm.output('hart3_resume_req').width, equals(1));
    });

    test('DT node contains riscv,debug-013', () {
      final dm = HarborDebugModule(baseAddress: 0x00000000);
      expect(dm.dtNode.compatible, contains('riscv,debug-013'));
    });

    test('ndmreset output', () {
      final dm = HarborDebugModule(baseAddress: 0x00000000);
      expect(dm.output('ndmreset').width, equals(1));
    });

    test('DMI interface (dmi_addr width=7, dmi_data_in width=32)', () {
      final dm = HarborDebugModule(baseAddress: 0x00000000);
      expect(dm.input('dmi_addr').width, equals(7));
      expect(dm.input('dmi_data_in').width, equals(32));
    });
  });

  group('HarborTraceEncoder', () {
    test('creates with defaults (bufferSize=4096, syncInterval=256)', () {
      final trace = HarborTraceEncoder(baseAddress: 0x00000000);
      expect(trace, isNotNull);
      expect(trace.bufferSize, equals(4096));
      expect(trace.syncInterval, equals(256));
    });

    test('DT node', () {
      final trace = HarborTraceEncoder(baseAddress: 0x00000000);
      expect(trace.dtNode.compatible, contains('riscv,trace'));
    });

    test(
      'trace outputs (trace_data width=32, trace_valid, trace_sync, overflow)',
      () {
        final trace = HarborTraceEncoder(baseAddress: 0x00000000);
        expect(trace.output('trace_data').width, equals(32));
        expect(trace.output('trace_valid').width, equals(1));
        expect(trace.output('trace_sync').width, equals(1));
        expect(trace.output('overflow').width, equals(1));
      },
    );
  });

  group('JtagTapController', () {
    test('creates without error', () {
      final tap = JtagTapController(irWidth: 5, idcode: 0x10001FFF);
      expect(tap, isNotNull);
    });

    test('has state/instruction/inShiftDr outputs', () {
      final tap = JtagTapController(irWidth: 5);
      expect(tap.state.width, equals(4));
      expect(tap.instruction.width, equals(5));
      expect(tap.inShiftDr.width, equals(1));
    });
  });

  group('JtagDtm', () {
    test('creates without error', () {
      final dtm = JtagDtm();
      expect(dtm, isNotNull);
    });

    test('has DMI outputs', () {
      final dtm = JtagDtm();
      expect(dtm.dmiReqValid.width, equals(1));
      expect(dtm.dmiReqAddr.width, equals(7));
      expect(dtm.dmiReqData.width, equals(32));
      expect(dtm.dmiReqOp.width, equals(2));
      expect(dtm.dmiRspReady.width, equals(1));
    });
  });
}
