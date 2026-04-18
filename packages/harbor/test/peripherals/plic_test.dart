import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborPlic', () {
    test('creates with defaults', () {
      final plic = HarborPlic(baseAddress: 0x0C000000);
      expect(plic.externalInterrupt, hasLength(1));
      expect(plic.sourceInterrupt, hasLength(32));
    });

    test('creates with custom params', () {
      final plic = HarborPlic(
        baseAddress: 0x0C000000,
        sources: 64,
        contexts: 4,
        priorityBits: 4,
      );
      expect(plic.externalInterrupt, hasLength(4));
      expect(plic.sourceInterrupt, hasLength(64));
    });

    test('has bus interface', () {
      final plic = HarborPlic(baseAddress: 0x0C000000);
      expect(plic.bus, isNotNull);
    });

    test('DT node is correct', () {
      final plic = HarborPlic(baseAddress: 0x0C000000, sources: 32);
      final dt = plic.dtNode;
      expect(dt.compatible.first, equals('sifive,plic-1.0.0'));
      expect(dt.interruptController, isTrue);
      expect(dt.properties['riscv,ndev'], equals(32));
    });
  });
}
