import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborUart', () {
    test('creates with defaults', () {
      final uart = HarborUart(baseAddress: 0x10000000);
      expect(uart.tx.width, equals(1));
      expect(uart.interrupt.width, equals(1));
    });

    test('has bus interface', () {
      final uart = HarborUart(baseAddress: 0x10000000);
      expect(uart.bus, isNotNull);
    });

    test('clock frequency in DT properties', () {
      final uart = HarborUart(
        baseAddress: 0x10000000,
        clockFrequency: 48000000,
      );
      expect(uart.dtNode.properties['clock-frequency'], equals(48000000));
    });

    test('no clock frequency when zero', () {
      final uart = HarborUart(baseAddress: 0x10000000);
      expect(uart.dtNode.properties.containsKey('clock-frequency'), isFalse);
    });

    test('DT node is correct', () {
      final uart = HarborUart(baseAddress: 0x10000000);
      final dt = uart.dtNode;
      expect(dt.compatible.first, equals('ns16550a'));
      expect(dt.reg.start, equals(0x10000000));
      expect(dt.reg.size, equals(0x1000));
    });
  });
}
