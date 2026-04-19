import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborSram', () {
    test('creates with size and baseAddress', () {
      final sram = HarborSram(baseAddress: 0x80000000, size: 4096);
      expect(sram.size, equals(4096));
      expect(sram.baseAddress, equals(0x80000000));
    });

    test('has bus', () {
      final sram = HarborSram(baseAddress: 0x80000000, size: 4096);
      expect(sram.bus, isNotNull);
    });

    test('DT node compatible', () {
      final sram = HarborSram(baseAddress: 0x80000000, size: 4096);
      final dt = sram.dtNode;
      expect(dt.compatible, equals(['harbor,sram', 'mmio-sram']));
    });

    test('DT reg.size matches input size', () {
      final sram = HarborSram(baseAddress: 0x80000000, size: 8192);
      final dt = sram.dtNode;
      expect(dt.reg.size, equals(8192));
      expect(dt.reg.start, equals(0x80000000));
    });

    test('data width 32 (default)', () {
      final sram = HarborSram(baseAddress: 0x80000000, size: 4096);
      expect(sram.dataWidth, equals(32));
    });

    test('data width 64', () {
      final sram = HarborSram(
        baseAddress: 0x80000000,
        size: 4096,
        dataWidth: 64,
      );
      expect(sram.dataWidth, equals(64));
    });
  });
}
