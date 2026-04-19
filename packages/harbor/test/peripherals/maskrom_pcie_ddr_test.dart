import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborMaskRom', () {
    test('creates with baseAddress', () {
      final rom = HarborMaskRom(
        baseAddress: 0x00000000,
        initialData: [0x00000297, 0x02028593],
      );
      expect(rom, isNotNull);
      expect(rom.baseAddress, equals(0x00000000));
    });

    test('DT node compatible contains harbor,maskrom', () {
      final rom = HarborMaskRom(
        baseAddress: 0x00000000,
        initialData: [0x00000297],
      );
      expect(rom.dtNode.compatible, contains('harbor,maskrom'));
    });
  });

  group('HarborPcieController', () {
    test('creates with defaults', () {
      final pcie = HarborPcieController(
        config: HarborPcieConfig(),
        baseAddress: 0x30000000,
        ecamBase: 0x40000000,
      );
      expect(pcie, isNotNull);
    });

    test('DT node compatible', () {
      final pcie = HarborPcieController(
        config: HarborPcieConfig(),
        baseAddress: 0x30000000,
        ecamBase: 0x40000000,
      );
      expect(pcie.dtNode.compatible, contains('harbor,pcie-host'));
    });

    test('role rootComplex', () {
      final pcie = HarborPcieController(
        config: HarborPcieConfig(role: HarborPcieRole.rootComplex),
        baseAddress: 0x30000000,
        ecamBase: 0x40000000,
      );
      expect(pcie.config.role, equals(HarborPcieRole.rootComplex));
      expect(pcie.dtNode.compatible, contains('harbor,pcie-host'));
    });

    test('role endpoint', () {
      final pcie = HarborPcieController(
        config: HarborPcieConfig(role: HarborPcieRole.endpoint),
        baseAddress: 0x30000000,
        ecamBase: 0x40000000,
      );
      expect(pcie.config.role, equals(HarborPcieRole.endpoint));
      expect(pcie.dtNode.compatible, contains('harbor,pcie-ep'));
    });

    test('maxGen', () {
      final pcie = HarborPcieController(
        config: HarborPcieConfig(maxGen: HarborPcieGen.gen5),
        baseAddress: 0x30000000,
        ecamBase: 0x40000000,
      );
      expect(pcie.config.maxGen, equals(HarborPcieGen.gen5));
    });

    test('maxLanes', () {
      final pcie = HarborPcieController(
        config: HarborPcieConfig(maxLanes: HarborPcieLanes.x16),
        baseAddress: 0x30000000,
        ecamBase: 0x40000000,
      );
      expect(pcie.config.maxLanes, equals(HarborPcieLanes.x16));
    });
  });

  group('HarborDdrController', () {
    test('creates with OrangeCrab config', () {
      final ddr = HarborDdrController(
        config: HarborDdrConfig.orangeCrab(),
        baseAddress: 0x80000000,
      );
      expect(ddr, isNotNull);
      expect(ddr.config.type, equals(HarborDdrType.ddr3));
    });

    test('creates with SDR config (isSdr=true, isDdr=false)', () {
      final ddr = HarborDdrController(
        config: HarborDdrConfig.sdr(),
        baseAddress: 0x80000000,
      );
      expect(ddr.config.isSdr, isTrue);
      expect(ddr.config.isDdr, isFalse);
    });

    test('DT node', () {
      final ddr = HarborDdrController(
        config: HarborDdrConfig.orangeCrab(),
        baseAddress: 0x80000000,
      );
      expect(ddr.dtNode.compatible, contains('harbor,sdram-controller'));
    });

    test('SDR has no DDR-specific ports', () {
      final ddr = HarborDdrController(
        config: HarborDdrConfig.sdr(),
        baseAddress: 0x80000000,
      );
      expect(ddr.config.isSdr, isTrue);
      // SDR config does not create DDR-specific ports (sdram_dqs, sdram_odt, sdram_reset_n)
      expect(() => ddr.input('sdram_dqs'), throwsA(isA<Exception>()));
    });
  });

  group('HarborDdrConfig', () {
    test('dataRate SDR is 1x frequency', () {
      const config = HarborDdrConfig.sdr(frequency: 133000000);
      expect(config.dataRate, equals(133000000));
    });

    test('dataRate DDR is 2x frequency', () {
      const config = HarborDdrConfig.orangeCrab();
      expect(config.dataRate, equals(400000000 * 2));
    });

    test('bandwidthMBs', () {
      const config = HarborDdrConfig.orangeCrab();
      // dataRate * dataWidth / 8 / 1e6 = 800000000 * 16 / 8 / 1e6 = 1600.0
      expect(config.bandwidthMBs, equals(1600.0));
    });

    test('frequencyMhz', () {
      const config = HarborDdrConfig.orangeCrab();
      expect(config.frequencyMhz, equals(400.0));
    });
  });
}
