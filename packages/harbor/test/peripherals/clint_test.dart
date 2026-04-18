import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborClint', () {
    test('creates with default hart count', () {
      final clint = HarborClint(baseAddress: 0x02000000);
      expect(clint.timerInterrupt, hasLength(1));
      expect(clint.softwareInterrupt, hasLength(1));
    });

    test('creates with multiple harts', () {
      final clint = HarborClint(baseAddress: 0x02000000, hartCount: 4);
      expect(clint.timerInterrupt, hasLength(4));
      expect(clint.softwareInterrupt, hasLength(4));
    });

    test('has bus interface', () {
      final clint = HarborClint(baseAddress: 0x02000000);
      expect(clint.bus, isNotNull);
    });

    test('DT node is correct', () {
      final clint = HarborClint(baseAddress: 0x02000000);
      final dt = clint.dtNode;
      expect(dt.compatible.first, equals('riscv,clint0'));
      expect(dt.reg.start, equals(0x02000000));
      expect(dt.reg.size, equals(0x10000));
    });
  });
}
