import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('WishboneConfig', () {
    test('valid config passes validation', () {
      const config = WishboneConfig(addressWidth: 32, dataWidth: 32);
      expect(config.validate(), isEmpty);
    });

    test('invalid data width fails', () {
      const config = WishboneConfig(addressWidth: 32, dataWidth: 24);
      expect(config.validate(), isNotEmpty);
    });

    test('BTE without CTI fails', () {
      const config = WishboneConfig(
        addressWidth: 32,
        dataWidth: 32,
        useBte: true,
      );
      expect(config.validate(), isNotEmpty);
    });

    test('effective sel width defaults to bytes', () {
      const config = WishboneConfig(addressWidth: 32, dataWidth: 32);
      expect(config.effectiveSelWidth, equals(4));
    });
  });

  group('WishboneInterface', () {
    test('creates core signals', () {
      const config = WishboneConfig(addressWidth: 16, dataWidth: 8);
      final intf = WishboneInterface(config);

      expect(intf.cyc.width, equals(1));
      expect(intf.stb.width, equals(1));
      expect(intf.we.width, equals(1));
      expect(intf.ack.width, equals(1));
      expect(intf.adr.width, equals(16));
      expect(intf.datMosi.width, equals(8));
      expect(intf.datMiso.width, equals(8));
    });

    test('optional signals absent when not configured', () {
      const config = WishboneConfig(addressWidth: 32, dataWidth: 32);
      final intf = WishboneInterface(config);

      expect(intf.err, isNull);
      expect(intf.rty, isNull);
      expect(intf.cti, isNull);
      expect(intf.bte, isNull);
    });

    test('optional signals present when configured', () {
      const config = WishboneConfig(
        addressWidth: 32,
        dataWidth: 32,
        useErr: true,
        useRty: true,
        useCti: true,
        useBte: true,
      );
      final intf = WishboneInterface(config);

      expect(intf.err, isNotNull);
      expect(intf.rty, isNotNull);
      expect(intf.cti, isNotNull);
      expect(intf.cti!.width, equals(3));
      expect(intf.bte, isNotNull);
      expect(intf.bte!.width, equals(2));
    });

    test('clone produces identical interface', () {
      const config = WishboneConfig(
        addressWidth: 32,
        dataWidth: 64,
        useErr: true,
      );
      final original = WishboneInterface(config);
      final cloned = original.clone();

      expect(cloned.config.addressWidth, equals(32));
      expect(cloned.config.dataWidth, equals(64));
      expect(cloned.config.useErr, isTrue);
      expect(cloned.err, isNotNull);
    });

    test('invalid config throws', () {
      const config = WishboneConfig(addressWidth: 0, dataWidth: 32);
      expect(() => WishboneInterface(config), throwsArgumentError);
    });
  });
}
