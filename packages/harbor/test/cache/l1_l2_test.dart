import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborL1ICache', () {
    test('creates with default config', () {
      final cache = HarborL1ICache(
        config: const HarborCacheConfig(size: 32 * 1024, ways: 4),
      );
      expect(cache.reqAddr.width, equals(32));
      expect(cache.reqValid.width, equals(1));
      expect(cache.respData.width, equals(64 * 8)); // 64B line
      expect(cache.respValid.width, equals(1));
      expect(cache.miss.width, equals(1));
    });

    test('refill interface widths match config', () {
      final cache = HarborL1ICache(
        config: const HarborCacheConfig(size: 16 * 1024, ways: 2, lineSize: 32),
      );
      expect(cache.refillData.width, equals(32 * 8)); // 32B line
      expect(cache.refillAddr.width, equals(32));
    });
  });

  group('HarborL1DCache', () {
    test('creates with store buffer', () {
      final cache = HarborL1DCache(
        config: const HarborCacheConfig(size: 32 * 1024, ways: 4),
        hasStoreBuffer: true,
        storeBufferDepth: 8,
      );
      expect(cache.hasStoreBuffer, isTrue);
      expect(cache.storeBufferDepth, equals(8));
    });

    test('has snoop interface', () {
      final cache = HarborL1DCache(
        config: const HarborCacheConfig(size: 32 * 1024, ways: 4),
      );
      expect(cache.output('snoop_hit').width, equals(1));
      expect(cache.output('snoop_data').width, equals(64 * 8));
    });

    test('has writeback interface', () {
      final cache = HarborL1DCache(
        config: const HarborCacheConfig(size: 32 * 1024, ways: 4),
      );
      expect(cache.output('writeback_addr').width, equals(32));
      expect(cache.output('writeback_valid').width, equals(1));
    });
  });

  group('HarborL2Cache', () {
    test('creates with 2 requestors', () {
      final cache = HarborL2Cache(
        config: const HarborCacheConfig(size: 256 * 1024, ways: 8),
        numRequestors: 2,
      );
      expect(cache.numRequestors, equals(2));
      expect(cache.output('resp0_valid').width, equals(1));
      expect(cache.output('resp1_valid').width, equals(1));
    });

    test('snoop outputs per requestor', () {
      final cache = HarborL2Cache(
        config: const HarborCacheConfig(size: 256 * 1024, ways: 8),
        numRequestors: 3,
      );
      expect(cache.output('snoop0_addr').width, equals(32));
      expect(cache.output('snoop1_addr').width, equals(32));
      expect(cache.output('snoop2_addr').width, equals(32));
    });

    test('performance counter outputs', () {
      final cache = HarborL2Cache(
        config: const HarborCacheConfig(size: 256 * 1024, ways: 8),
      );
      expect(cache.output('perf_hits').width, equals(32));
      expect(cache.output('perf_misses').width, equals(32));
      expect(cache.output('perf_evictions').width, equals(32));
    });

    test('coherency protocol', () {
      final cache = HarborL2Cache(
        config: const HarborCacheConfig(size: 256 * 1024, ways: 8),
        coherencyProtocol: HarborCoherencyProtocol.moesi,
      );
      expect(cache.coherencyProtocol, equals(HarborCoherencyProtocol.moesi));
    });
  });
}
