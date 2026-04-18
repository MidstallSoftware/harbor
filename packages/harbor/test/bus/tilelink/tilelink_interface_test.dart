import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('TileLinkConfig', () {
    test('valid config passes', () {
      const config = TileLinkConfig(addressWidth: 32, dataWidth: 32);
      expect(config.validate(), isEmpty);
    });

    test('non-power-of-2 data width fails', () {
      const config = TileLinkConfig(addressWidth: 32, dataWidth: 24);
      expect(config.validate(), isNotEmpty);
    });

    test('mask width is bytes', () {
      const config = TileLinkConfig(addressWidth: 32, dataWidth: 64);
      expect(config.maskWidth, equals(8));
    });
  });

  group('TileLinkInterface', () {
    test('creates Channel A and D signals (UL)', () {
      const config = TileLinkConfig(addressWidth: 32, dataWidth: 32);
      final intf = TileLinkInterface(config);

      // Channel A
      expect(intf.aValid.width, equals(1));
      expect(intf.aReady.width, equals(1));
      expect(intf.aOpcode.width, equals(3));
      expect(intf.aAddress.width, equals(32));
      expect(intf.aData.width, equals(32));
      expect(intf.aMask.width, equals(4));

      // Channel D
      expect(intf.dValid.width, equals(1));
      expect(intf.dReady.width, equals(1));
      expect(intf.dOpcode.width, equals(3));
      expect(intf.dData.width, equals(32));
    });

    test('coherency channels absent without withBCE', () {
      const config = TileLinkConfig(addressWidth: 32, dataWidth: 32);
      final intf = TileLinkInterface(config);

      expect(intf.bValid, isNull);
      expect(intf.cValid, isNull);
      expect(intf.eValid, isNull);
    });

    test('coherency channels present with withBCE', () {
      const config = TileLinkConfig(
        addressWidth: 32,
        dataWidth: 32,
        withBCE: true,
      );
      final intf = TileLinkInterface(config);

      expect(intf.bValid, isNotNull);
      expect(intf.bAddress, isNotNull);
      expect(intf.bAddress!.width, equals(32));

      expect(intf.cValid, isNotNull);
      expect(intf.cAddress, isNotNull);

      expect(intf.eValid, isNotNull);
      expect(intf.eSink, isNotNull);
    });

    test('clone produces identical interface', () {
      const config = TileLinkConfig(
        addressWidth: 64,
        dataWidth: 64,
        sourceWidth: 4,
        withBCE: true,
      );
      final original = TileLinkInterface(config);
      final cloned = original.clone();

      expect(cloned.config.addressWidth, equals(64));
      expect(cloned.config.dataWidth, equals(64));
      expect(cloned.config.sourceWidth, equals(4));
      expect(cloned.config.withBCE, isTrue);
      expect(cloned.bValid, isNotNull);
    });

    test('invalid config throws', () {
      const config = TileLinkConfig(addressWidth: 0, dataWidth: 32);
      expect(() => TileLinkInterface(config), throwsArgumentError);
    });
  });

  group('TileLink opcodes', () {
    test('A opcodes have correct values', () {
      expect(TileLinkAOpcode.get.value, equals(4));
      expect(TileLinkAOpcode.putFullData.value, equals(0));
      expect(TileLinkAOpcode.putPartialData.value, equals(1));
    });

    test('D opcodes have correct values', () {
      expect(TileLinkDOpcode.accessAck.value, equals(0));
      expect(TileLinkDOpcode.accessAckData.value, equals(1));
      expect(TileLinkDOpcode.grant.value, equals(4));
    });
  });
}
