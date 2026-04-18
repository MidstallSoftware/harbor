import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborEthernetConfig', () {
    test('defaults to gigabit RGMII', () {
      const config = HarborEthernetConfig();
      expect(config.maxSpeed, equals(HarborEthernetSpeed.speed1000));
      expect(config.phyInterface, equals(HarborEthernetPhyInterface.rgmii));
    });

    test('toPrettyString', () {
      const config = HarborEthernetConfig(checksumOffload: true);
      final pretty = config.toPrettyString();
      expect(pretty, contains('1000 Mbps'));
      expect(pretty, contains('rgmii'));
      expect(pretty, contains('checksum offload'));
    });
  });

  group('HarborEthernetMac', () {
    test('creates gigabit controller', () {
      final eth = HarborEthernetMac(
        config: const HarborEthernetConfig(),
        baseAddress: 0x40000000,
      );
      expect(eth.bus, isNotNull);
      expect(eth.interrupt.width, equals(1));
    });

    test('100M has narrower data bus', () {
      final eth100 = HarborEthernetMac(
        config: const HarborEthernetConfig(
          maxSpeed: HarborEthernetSpeed.speed100,
        ),
        baseAddress: 0x40000000,
      );
      // 10/100 uses 4-bit data, gigabit uses 8-bit
      expect(eth100.output('txd').width, equals(4));

      final eth1000 = HarborEthernetMac(
        config: const HarborEthernetConfig(
          maxSpeed: HarborEthernetSpeed.speed1000,
        ),
        baseAddress: 0x40000000,
      );
      expect(eth1000.output('txd').width, equals(8));
    });

    test('DT node', () {
      final eth = HarborEthernetMac(
        config: const HarborEthernetConfig(
          phyInterface: HarborEthernetPhyInterface.rmii,
          maxSpeed: HarborEthernetSpeed.speed100,
        ),
        baseAddress: 0x40000000,
      );
      final dt = eth.dtNode;
      expect(dt.compatible.first, equals('harbor,ethernet'));
      expect(dt.properties['phy-mode'], equals('rmii'));
      expect(dt.properties['max-speed'], equals(100));
    });
  });
}
