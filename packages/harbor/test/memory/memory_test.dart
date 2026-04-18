import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborMemoryPortInterface', () {
    test('creates with correct widths', () {
      final port = HarborMemoryPortInterface(dataWidth: 32, addrWidth: 32);
      expect(port.en.width, equals(1));
      expect(port.addr.width, equals(32));
      expect(port.we.width, equals(1));
      expect(port.wdata.width, equals(32));
      expect(port.rdata.width, equals(32));
      expect(port.done.width, equals(1));
      expect(port.valid.width, equals(1));
    });

    test('clone preserves config', () {
      final port = HarborMemoryPortInterface(dataWidth: 64, addrWidth: 48);
      final cloned = port.clone();
      expect(cloned.dataWidth, equals(64));
      expect(cloned.addrWidth, equals(48));
    });
  });

  group('HarborMemoryRegion', () {
    test('main memory region', () {
      const region = HarborMemoryRegion(
        name: 'dram',
        range: BusAddressRange(0x80000000, 0x80000000),
      );
      expect(region.isMain, isTrue);
      expect(region.isExecutable, isTrue);
      expect(region.isCacheable, isTrue);
      expect(region.contains(0x80000000), isTrue);
      expect(region.contains(0x70000000), isFalse);
    });

    test('IO region', () {
      const region = HarborMemoryRegion.io(
        name: 'uart',
        range: BusAddressRange(0x10000000, 0x1000),
      );
      expect(region.isMain, isFalse);
      expect(region.isCacheable, isFalse);
      expect(region.isExecutable, isFalse);
    });

    test('ROM region', () {
      const region = HarborMemoryRegion.rom(
        name: 'boot',
        range: BusAddressRange(0x00000000, 0x10000),
      );
      expect(region.isWritable, isFalse);
      expect(region.isExecutable, isTrue);
      expect(region.isCacheable, isTrue);
    });

    test('toPrettyString', () {
      const region = HarborMemoryRegion(
        name: 'dram',
        range: BusAddressRange(0x80000000, 0x40000000),
      );
      final pretty = region.toPrettyString();
      expect(pretty, contains('dram'));
      expect(pretty, contains('main'));
      expect(pretty, contains('cacheable'));
    });
  });

  group('HarborMemoryMap', () {
    test('findRegion', () {
      const map = HarborMemoryMap([
        HarborMemoryRegion(
          name: 'rom',
          range: BusAddressRange(0x00000000, 0x10000),
        ),
        HarborMemoryRegion.io(
          name: 'uart',
          range: BusAddressRange(0x10000000, 0x1000),
        ),
        HarborMemoryRegion(
          name: 'dram',
          range: BusAddressRange(0x80000000, 0x80000000),
        ),
      ]);

      expect(map.findRegion(0x00000100)?.name, equals('rom'));
      expect(map.findRegion(0x10000000)?.name, equals('uart'));
      expect(map.findRegion(0x80000000)?.name, equals('dram'));
      expect(map.findRegion(0x50000000), isNull);
    });

    test('validates overlaps', () {
      const map = HarborMemoryMap([
        HarborMemoryRegion(name: 'a', range: BusAddressRange(0x0, 0x2000)),
        HarborMemoryRegion(name: 'b', range: BusAddressRange(0x1000, 0x2000)),
      ]);
      expect(map.validate(), isNotEmpty);
    });

    test('no overlaps passes', () {
      const map = HarborMemoryMap([
        HarborMemoryRegion(name: 'a', range: BusAddressRange(0x0, 0x1000)),
        HarborMemoryRegion(name: 'b', range: BusAddressRange(0x1000, 0x1000)),
      ]);
      expect(map.validate(), isEmpty);
    });

    test('mainRegions and ioRegions', () {
      const map = HarborMemoryMap([
        HarborMemoryRegion(
          name: 'dram',
          range: BusAddressRange(0x80000000, 0x1000),
        ),
        HarborMemoryRegion.io(
          name: 'uart',
          range: BusAddressRange(0x10000000, 0x100),
        ),
      ]);
      expect(map.mainRegions, hasLength(1));
      expect(map.ioRegions, hasLength(1));
    });
  });

  group('HarborTlbLevel', () {
    test('fully associative', () {
      const tlb = HarborTlbLevel(level: 0, entries: 32);
      expect(tlb.isFullyAssociative, isTrue);
    });

    test('set-associative', () {
      const tlb = HarborTlbLevel(level: 0, entries: 64, ways: 4);
      expect(tlb.isFullyAssociative, isFalse);
    });
  });

  group('HarborPmpConfig', () {
    test('default', () {
      const pmp = HarborPmpConfig();
      expect(pmp.entries, equals(16));
      expect(pmp.granularity, equals(4));
      expect(pmp.withTor, isTrue);
      expect(pmp.withNapot, isTrue);
    });

    test('none', () {
      expect(HarborPmpConfig.none.entries, equals(0));
    });
  });

  group('HarborMmuConfig', () {
    test('basic config', () {
      final mmu = HarborMmuConfig(
        mxlen: RiscVMxlen.rv64,
        pagingModes: [
          RiscVPagingMode.bare,
          RiscVPagingMode.sv39,
          RiscVPagingMode.sv48,
        ],
        tlbLevels: [
          const HarborTlbLevel(level: 0, entries: 32, ways: 4),
          const HarborTlbLevel(level: 1, entries: 16, ways: 2),
        ],
        pmp: const HarborPmpConfig(entries: 16),
        hasSupervisorUserMemory: true,
        hasMakeExecutableReadable: true,
      );

      expect(mmu.hasPaging, isTrue);
      expect(mmu.maxPageTableLevels, equals(4)); // sv48
      expect(mmu.tlbLevels, hasLength(2));
      expect(mmu.pmp.entries, equals(16));
    });

    test('bare-only has no paging', () {
      final mmu = HarborMmuConfig(
        mxlen: RiscVMxlen.rv32,
        pagingModes: [RiscVPagingMode.bare],
      );
      expect(mmu.hasPaging, isFalse);
    });

    test('toPrettyString', () {
      final mmu = HarborMmuConfig(
        mxlen: RiscVMxlen.rv64,
        pagingModes: [RiscVPagingMode.sv39],
        tlbLevels: [const HarborTlbLevel(level: 0, entries: 32)],
        pmp: const HarborPmpConfig(entries: 16),
        hasSupervisorUserMemory: true,
      );
      final pretty = mmu.toPrettyString();
      expect(pretty, contains('sv39'));
      expect(pretty, contains('TLB'));
      expect(pretty, contains('PMP'));
      expect(pretty, contains('SUM'));
    });
  });
}
