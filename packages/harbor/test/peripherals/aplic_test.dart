import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborAplic', () {
    test('creates with defaults', () {
      final aplic = HarborAplic(baseAddress: 0x0D000000);
      expect(aplic.externalInterrupt, hasLength(1));
      expect(aplic.sourceInterrupt, hasLength(32));
    });

    test('creates with multiple harts', () {
      final aplic = HarborAplic(baseAddress: 0x0D000000, sources: 64, harts: 4);
      expect(aplic.externalInterrupt, hasLength(4));
      expect(aplic.sourceInterrupt, hasLength(64));
    });

    test('has bus interface', () {
      final aplic = HarborAplic(baseAddress: 0x0D000000);
      expect(aplic.bus, isNotNull);
    });

    test('DT node is correct', () {
      final aplic = HarborAplic(baseAddress: 0x0D000000, sources: 128);
      final dt = aplic.dtNode;
      expect(dt.compatible.first, equals('riscv,aplic'));
      expect(dt.interruptController, isTrue);
      expect(dt.interruptCells, equals(2));
    });
  });
}
