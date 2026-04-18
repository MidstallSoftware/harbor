import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborSpiController', () {
    test('creates with defaults', () {
      final spi = HarborSpiController(baseAddress: 0x10002000);
      expect(spi.bus, isNotNull);
      expect(spi.interrupt.width, equals(1));
    });

    test('creates with multiple chip selects', () {
      final spi = HarborSpiController(baseAddress: 0x10002000, csCount: 4);
      final dt = spi.dtNode;
      expect(dt.properties['num-cs'], equals(4));
    });

    test('DT node is correct', () {
      final spi = HarborSpiController(baseAddress: 0x10002000);
      final dt = spi.dtNode;
      expect(dt.compatible.first, equals('harbor,spi'));
      expect(dt.reg.start, equals(0x10002000));
    });

    test('supports both bus protocols', () {
      final wb = HarborSpiController(
        baseAddress: 0x1000,
        protocol: BusProtocol.wishbone,
      );
      final tl = HarborSpiController(
        baseAddress: 0x1000,
        protocol: BusProtocol.tilelink,
      );
      expect(wb.bus.protocol, equals(BusProtocol.wishbone));
      expect(tl.bus.protocol, equals(BusProtocol.tilelink));
    });
  });
}
