import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborI2cController', () {
    test('creates with correct ports', () {
      final i2c = HarborI2cController(baseAddress: 0x10003000);
      expect(i2c.bus, isNotNull);
      expect(i2c.interrupt.width, equals(1));
    });

    test('DT node is correct', () {
      final i2c = HarborI2cController(baseAddress: 0x10003000);
      final dt = i2c.dtNode;
      expect(dt.compatible.first, equals('harbor,i2c'));
      expect(dt.reg.start, equals(0x10003000));
    });

    test('supports TileLink', () {
      final i2c = HarborI2cController(
        baseAddress: 0x10003000,
        protocol: BusProtocol.tilelink,
      );
      expect(i2c.bus.protocol, equals(BusProtocol.tilelink));
    });
  });
}
