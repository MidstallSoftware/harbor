import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborCdcSync', () {
    test('creates with default 2 stages', () {
      final sync = HarborCdcSync();
      expect(sync.stages, equals(2));
      expect(sync.syncOut.width, equals(1));
    });

    test('creates with custom stages', () {
      final sync = HarborCdcSync(stages: 3);
      expect(sync.stages, equals(3));
    });

    test('rejects less than 2 stages', () {
      expect(() => HarborCdcSync(stages: 1), throwsA(isA<AssertionError>()));
    });
  });

  group('HarborCdcHandshake', () {
    test('creates with default data width', () {
      final hs = HarborCdcHandshake();
      expect(hs.dataWidth, equals(32));
      expect(hs.output('src_ready').width, equals(1));
      expect(hs.output('dst_data').width, equals(32));
      expect(hs.output('dst_valid').width, equals(1));
    });

    test('creates with custom width', () {
      final hs = HarborCdcHandshake(dataWidth: 64);
      expect(hs.dataWidth, equals(64));
      expect(hs.output('dst_data').width, equals(64));
    });
  });

  group('HarborCdcFifo', () {
    test('creates with default config', () {
      final fifo = HarborCdcFifo();
      expect(fifo.dataWidth, equals(32));
      expect(fifo.depth, equals(8));
      expect(fifo.output('wr_full').width, equals(1));
      expect(fifo.output('rd_empty').width, equals(1));
      expect(fifo.output('rd_data').width, equals(32));
    });

    test('custom depth and width', () {
      final fifo = HarborCdcFifo(dataWidth: 64, depth: 16);
      expect(fifo.dataWidth, equals(64));
      expect(fifo.depth, equals(16));
    });

    test('rejects non-power-of-2 depth', () {
      expect(() => HarborCdcFifo(depth: 7), throwsA(isA<AssertionError>()));
    });
  });

  group('HarborClockGate', () {
    test('creates with correct ports', () {
      final gate = HarborClockGate();
      expect(gate.gatedClk.width, equals(1));
      expect(gate.input('enable').width, equals(1));
      expect(gate.input('test_enable').width, equals(1));
    });
  });
}
