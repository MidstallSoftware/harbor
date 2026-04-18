import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborBusFabric', () {
    test('creates with masters and slaves', () {
      final fabric = HarborBusFabric(
        topology: HarborFabricTopology.sharedBus,
        masters: [const HarborFabricMasterPort(name: 'cpu')],
        slaves: [
          const HarborFabricSlavePort(
            name: 'sram',
            addressRange: BusAddressRange(0x00000000, 0x10000),
          ),
          const HarborFabricSlavePort(
            name: 'uart',
            addressRange: BusAddressRange(0x10000000, 0x1000),
          ),
        ],
      );
      expect(fabric.masterPorts, hasLength(1));
      expect(fabric.slavePorts, hasLength(2));
    });

    test('address map matches slave config', () {
      final fabric = HarborBusFabric(
        topology: HarborFabricTopology.crossbar,
        masters: [const HarborFabricMasterPort(name: 'cpu')],
        slaves: [
          const HarborFabricSlavePort(
            name: 'mem',
            addressRange: BusAddressRange(0x80000000, 0x40000000),
          ),
          const HarborFabricSlavePort(
            name: 'io',
            addressRange: BusAddressRange(0x10000000, 0x10000000),
          ),
        ],
      );
      final map = fabric.addressMap;
      expect(map, hasLength(2));
      expect(map[0].range.start, equals(0x80000000));
      expect(map[0].range.size, equals(0x40000000));
      expect(map[1].range.start, equals(0x10000000));
    });

    test('multi-master fabric', () {
      final fabric = HarborBusFabric(
        topology: HarborFabricTopology.crossbar,
        masters: [
          const HarborFabricMasterPort(name: 'cpu_i', priority: 0),
          const HarborFabricMasterPort(name: 'cpu_d', priority: 0),
          const HarborFabricMasterPort(name: 'dma', priority: 1),
        ],
        slaves: [
          const HarborFabricSlavePort(
            name: 'ddr',
            addressRange: BusAddressRange(0x80000000, 0x40000000),
          ),
        ],
      );
      expect(fabric.masterPorts, hasLength(3));
      expect(fabric.slavePorts, hasLength(1));
    });

    test('topology enum values', () {
      expect(HarborFabricTopology.values, hasLength(3));
      expect(HarborFabricTopology.sharedBus.name, 'sharedBus');
      expect(HarborFabricTopology.crossbar.name, 'crossbar');
      expect(HarborFabricTopology.partialCrossbar.name, 'partialCrossbar');
    });
  });
}
