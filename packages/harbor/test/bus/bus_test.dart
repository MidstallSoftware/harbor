import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('BusAddressRange', () {
    test('contains', () {
      const range = BusAddressRange(0x1000, 0x100);
      expect(range.contains(0x1000), isTrue);
      expect(range.contains(0x1050), isTrue);
      expect(range.contains(0x10FF), isTrue);
      expect(range.contains(0x1100), isFalse);
      expect(range.contains(0x0FFF), isFalse);
    });

    test('end', () {
      const range = BusAddressRange(0x1000, 0x100);
      expect(range.end, equals(0x1100));
    });

    test('shift', () {
      const range = BusAddressRange(0x1000, 0x100);
      final shifted = range.shift(offset: 0x2000);
      expect(shifted.start, equals(0x3000));
      expect(shifted.size, equals(0x100));
    });

    test('equality', () {
      const a = BusAddressRange(0x1000, 0x100);
      const b = BusAddressRange(0x1000, 0x100);
      const c = BusAddressRange(0x2000, 0x100);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('HarborAddressMapping', () {
    test('hit', () {
      const mapping = HarborAddressMapping(
        range: BusAddressRange(0x1000, 0x100),
        slaveIndex: 0,
      );
      expect(mapping.hit(0x1050), isTrue);
      expect(mapping.hit(0x2000), isFalse);
    });
  });

  group('validateAddressMappings', () {
    test('no overlap passes', () {
      final mappings = [
        const HarborAddressMapping(
          range: BusAddressRange(0x0000, 0x1000),
          slaveIndex: 0,
        ),
        const HarborAddressMapping(
          range: BusAddressRange(0x1000, 0x1000),
          slaveIndex: 1,
        ),
      ];
      expect(validateAddressMappings(mappings), isEmpty);
    });

    test('overlap detected', () {
      final mappings = [
        const HarborAddressMapping(
          range: BusAddressRange(0x0000, 0x2000),
          slaveIndex: 0,
        ),
        const HarborAddressMapping(
          range: BusAddressRange(0x1000, 0x1000),
          slaveIndex: 1,
        ),
      ];
      expect(validateAddressMappings(mappings), isNotEmpty);
    });
  });
}
