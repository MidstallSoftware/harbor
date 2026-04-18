import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborSdioConfig', () {
    test('SD preset', () {
      const config = HarborSdioConfig.sd();
      expect(config.maxBusWidth, equals(HarborSdioBusWidth.four));
      expect(config.maxSpeed, equals(HarborSdioSpeed.highSpeed));
      expect(config.supportsIo, isFalse);
      expect(config.maxIoFunctions, equals(0));
    });

    test('WiFi preset', () {
      const config = HarborSdioConfig.wifi();
      expect(config.supportsIo, isTrue);
      expect(config.maxIoFunctions, equals(2));
    });

    test('UHS preset', () {
      const config = HarborSdioConfig.uhs();
      expect(config.maxSpeed, equals(HarborSdioSpeed.sdr104));
      expect(config.supports1v8, isTrue);
      expect(config.maxIoFunctions, equals(7));
    });

    test('eMMC preset', () {
      const config = HarborSdioConfig.emmc();
      expect(config.maxBusWidth, equals(HarborSdioBusWidth.eight));
      expect(config.supportsEmmc, isTrue);
      expect(config.maxIoFunctions, equals(0));
    });

    test('toPrettyString', () {
      const config = HarborSdioConfig.wifi();
      final pretty = config.toPrettyString();
      expect(pretty, contains('4-bit'));
      expect(pretty, contains('SDIO I/O'));
    });
  });

  group('HarborSdioController', () {
    test('creates with SD config', () {
      final sdio = HarborSdioController(baseAddress: 0x60000000);
      expect(sdio.bus, isNotNull);
      expect(sdio.interrupt.width, equals(1));
    });

    test('DT compatible for SD vs eMMC', () {
      final sd = HarborSdioController(baseAddress: 0x60000000);
      expect(sd.dtNode.compatible.first, equals('harbor,sdhci'));

      final emmc = HarborSdioController(
        baseAddress: 0x60000000,
        config: const HarborSdioConfig.emmc(),
      );
      expect(emmc.dtNode.compatible.first, equals('harbor,sdhci-emmc'));
    });

    test('bus width in DT', () {
      final sd = HarborSdioController(
        baseAddress: 0x60000000,
        config: const HarborSdioConfig(maxBusWidth: HarborSdioBusWidth.eight),
      );
      expect(sd.dtNode.properties['bus-width'], equals(8));
    });
  });
}
