import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborGpio', () {
    test('creates with default pin count', () {
      final gpio = HarborGpio(baseAddress: 0x10001000);
      expect(gpio.bus, isNotNull);
      expect(gpio.gpioOut.width, equals(32));
      expect(gpio.gpioDir.width, equals(32));
      expect(gpio.interrupt.width, equals(1));
    });

    test('creates with custom pin count', () {
      final gpio = HarborGpio(baseAddress: 0x10001000, pinCount: 16);
      expect(gpio.gpioOut.width, equals(16));
      expect(gpio.gpioDir.width, equals(16));
    });

    test('DT node is correct', () {
      final gpio = HarborGpio(baseAddress: 0x10001000, pinCount: 8);
      final dt = gpio.dtNode;
      expect(dt.compatible.first, equals('harbor,gpio'));
      expect(dt.reg.start, equals(0x10001000));
      expect(dt.properties['ngpios'], equals(8));
      expect(dt.properties['gpio-controller'], equals(true));
    });

    test('supports TileLink protocol', () {
      final gpio = HarborGpio(
        baseAddress: 0x10001000,
        protocol: BusProtocol.tilelink,
      );
      expect(gpio.bus.protocol, equals(BusProtocol.tilelink));
    });
  });
}
