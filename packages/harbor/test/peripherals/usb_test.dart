import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborUsbConfig', () {
    test('isSuperSpeed', () {
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.full).isSuperSpeed,
        isFalse,
      );
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.high).isSuperSpeed,
        isFalse,
      );
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.super_).isSuperSpeed,
        isTrue,
      );
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.superPlus).isSuperSpeed,
        isTrue,
      );
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.superPlus2x2).isSuperSpeed,
        isTrue,
      );
    });

    test('isHighSpeed', () {
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.full).isHighSpeed,
        isFalse,
      );
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.high).isHighSpeed,
        isTrue,
      );
      expect(
        HarborUsbConfig(maxSpeed: HarborUsbSpeed.super_).isHighSpeed,
        isTrue,
      );
    });

    test('toPrettyString', () {
      const config = HarborUsbConfig(
        maxSpeed: HarborUsbSpeed.high,
        role: HarborUsbRole.otg,
      );
      expect(config.toPrettyString(), contains('high'));
      expect(config.toPrettyString(), contains('otg'));
    });
  });

  group('HarborUsbController', () {
    test('creates USB 2.0 device', () {
      final usb = HarborUsbController(
        config: const HarborUsbConfig(
          maxSpeed: HarborUsbSpeed.full,
          role: HarborUsbRole.device,
        ),
        baseAddress: 0x50000000,
      );
      expect(usb.bus, isNotNull);
      expect(usb.interrupt.width, equals(1));
    });

    test('USB 3.0 has SuperSpeed pins', () {
      final usb = HarborUsbController(
        config: const HarborUsbConfig(
          maxSpeed: HarborUsbSpeed.super_,
          role: HarborUsbRole.host,
        ),
        baseAddress: 0x50000000,
      );
      // Should have SS TX/RX pins
      expect(usb.tryOutput('ss_tx_p'), isNotNull);
      expect(usb.tryOutput('ss_tx_n'), isNotNull);
    });

    test('USB 2.0 has no SuperSpeed pins', () {
      final usb = HarborUsbController(
        config: const HarborUsbConfig(maxSpeed: HarborUsbSpeed.high),
        baseAddress: 0x50000000,
      );
      expect(usb.tryOutput('ss_tx_p'), isNull);
    });

    test('DT node uses standard speed strings', () {
      final usb = HarborUsbController(
        config: const HarborUsbConfig(
          maxSpeed: HarborUsbSpeed.super_,
          role: HarborUsbRole.otg,
        ),
        baseAddress: 0x50000000,
      );
      final dt = usb.dtNode;
      expect(dt.properties['maximum-speed'], equals('super-speed'));
      expect(dt.properties['dr_mode'], equals('otg'));
    });
  });
}
