import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborDmaChannelConfig', () {
    test('defaults', () {
      const config = HarborDmaChannelConfig();
      expect(config.maxBurstLength, equals(16));
      expect(config.scatterGather, isFalse);
    });

    test('toPrettyString', () {
      const config = HarborDmaChannelConfig(scatterGather: true);
      expect(config.toPrettyString(), contains('scatter-gather'));
    });
  });

  group('HarborDmaController', () {
    test('creates with default channels', () {
      final dma = HarborDmaController(baseAddress: 0x30000000);
      expect(dma.bus, isNotNull);
      expect(dma.interrupt.width, equals(1));
      expect(dma.channels, equals(4));
    });

    test('creates with custom channel count', () {
      final dma = HarborDmaController(baseAddress: 0x30000000, channels: 8);
      expect(dma.channels, equals(8));
    });

    test('DT node', () {
      final dma = HarborDmaController(baseAddress: 0x30000000, channels: 2);
      final dt = dma.dtNode;
      expect(dt.compatible.first, equals('harbor,dma'));
      expect(dt.properties['dma-channels'], equals(2));
    });

    test('supports TileLink', () {
      final dma = HarborDmaController(
        baseAddress: 0x30000000,
        protocol: BusProtocol.tilelink,
      );
      expect(dma.bus.protocol, equals(BusProtocol.tilelink));
    });
  });
}
