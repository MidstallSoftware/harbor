import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborPowerDomain', () {
    test('basic properties', () {
      const domain = HarborPowerDomain(name: 'cpu', index: 0);
      expect(domain.canPowerOff, isTrue);
      expect(domain.canRetain, isTrue);
    });
  });

  group('HarborPmuConfig', () {
    test('toPrettyString', () {
      const config = HarborPmuConfig(
        domains: [
          HarborPowerDomain(name: 'cpu', index: 0),
          HarborPowerDomain(name: 'gpu', index: 1, canPowerOff: false),
        ],
        supportsDvfs: true,
      );
      final pretty = config.toPrettyString();
      expect(pretty, contains('domains: 2'));
      expect(pretty, contains('DVFS'));
      expect(pretty, contains('cpu'));
      expect(pretty, contains('gpu'));
    });
  });

  group('HarborPowerManagementUnit', () {
    test('creates with domains', () {
      final pmu = HarborPowerManagementUnit(
        config: const HarborPmuConfig(
          domains: [
            HarborPowerDomain(name: 'cpu', index: 0),
            HarborPowerDomain(name: 'io', index: 1),
          ],
        ),
        baseAddress: 0x10006000,
      );
      expect(pmu.bus, isNotNull);
      expect(pmu.domainPower, hasLength(2));
    });

    test('DT node', () {
      final pmu = HarborPowerManagementUnit(
        config: const HarborPmuConfig(
          domains: [HarborPowerDomain(name: 'cpu', index: 0)],
        ),
        baseAddress: 0x10006000,
      );
      final dt = pmu.dtNode;
      expect(dt.compatible.first, equals('harbor,pmu'));
      expect(dt.properties['num-domains'], equals(1));
    });
  });
}
