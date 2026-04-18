import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborSpiFlashConfig', () {
    test('W25Q128 preset', () {
      const config = HarborSpiFlashConfig.w25q128();
      expect(config.size, equals(16 * 1024 * 1024));
      expect(config.mode, equals(HarborSpiFlashMode.quad));
      expect(config.readCommand, equals(0x6B));
      expect(config.dummyCycles, equals(8));
    });

    test('IS25LP128 preset', () {
      const config = HarborSpiFlashConfig.is25lp128();
      expect(config.size, equals(16 * 1024 * 1024));
      expect(config.mode, equals(HarborSpiFlashMode.quad));
    });

    test('S25FL256 4-byte addressing', () {
      const config = HarborSpiFlashConfig.s25fl256();
      expect(config.addressBytes, equals(4));
      expect(config.size, equals(32 * 1024 * 1024));
    });

    test('toPrettyString', () {
      const config = HarborSpiFlashConfig.w25q128();
      final pretty = config.toPrettyString();
      expect(pretty, contains('16 MB'));
      expect(pretty, contains('quad'));
    });
  });

  group('HarborSpiFlashController', () {
    test('creates with QSPI config', () {
      final flash = HarborSpiFlashController(
        config: const HarborSpiFlashConfig.w25q128(),
        baseAddress: 0x20000000,
      );
      expect(flash.bus, isNotNull);
    });

    test('standard SPI has MOSI/MISO', () {
      final flash = HarborSpiFlashController(
        config: const HarborSpiFlashConfig(
          size: 1024 * 1024,
          mode: HarborSpiFlashMode.standard,
        ),
        baseAddress: 0x20000000,
      );
      expect(flash.tryOutput('spi_mosi'), isNotNull);
    });

    test('DT compatible is jedec,spi-nor', () {
      final flash = HarborSpiFlashController(
        config: const HarborSpiFlashConfig.w25q128(),
        baseAddress: 0x20000000,
      );
      expect(flash.dtNode.compatible.first, equals('jedec,spi-nor'));
    });
  });
}
