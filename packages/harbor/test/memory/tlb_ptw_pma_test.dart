import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborTlb', () {
    test('creates instruction TLB', () {
      final tlb = HarborTlb(entries: 32, isInstruction: true);
      expect(tlb.entries, equals(32));
      expect(tlb.isInstruction, isTrue);
      expect(tlb.name, equals('itlb'));
    });

    test('creates data TLB', () {
      final tlb = HarborTlb(entries: 64, isInstruction: false);
      expect(tlb.entries, equals(64));
      expect(tlb.isInstruction, isFalse);
      expect(tlb.name, equals('dtlb'));
    });

    test('two-stage translation ports', () {
      final tlb = HarborTlb(entries: 32, twoStage: true);
      expect(tlb.twoStage, isTrue);
      expect(tlb.input('hfence_gvma').width, equals(1));
      expect(tlb.input('hgatp_mode').width, equals(4));
    });

    test('paging mode support', () {
      final tlb = HarborTlb(
        entries: 32,
        pagingModes: [
          RiscVPagingMode.sv39,
          RiscVPagingMode.sv48,
          RiscVPagingMode.sv57,
        ],
      );
      expect(tlb.pagingModes, hasLength(3));
    });

    test('lookup interface widths', () {
      final tlb = HarborTlb(entries: 16);
      expect(tlb.output('lookup_ppn').width, equals(44));
      expect(tlb.output('lookup_hit').width, equals(1));
      expect(tlb.output('lookup_fault').width, equals(1));
      expect(tlb.output('lookup_perms').width, equals(7));
      expect(tlb.output('lookup_page_level').width, equals(3));
    });
  });

  group('HarborPageTableWalker', () {
    test('creates with default config', () {
      final ptw = HarborPageTableWalker();
      expect(ptw.hardwareAdUpdate, isTrue);
      expect(ptw.twoStage, isFalse);
    });

    test('two-stage translation', () {
      final ptw = HarborPageTableWalker(twoStage: true);
      expect(ptw.twoStage, isTrue);
      expect(ptw.input('hgatp').width, equals(64));
      expect(ptw.input('vsatp').width, equals(64));
      expect(ptw.input('v_mode').width, equals(1));
    });

    test('outputs for TLB write-back', () {
      final ptw = HarborPageTableWalker();
      expect(ptw.output('tlb_write_valid').width, equals(1));
      expect(ptw.output('tlb_write_vpn').width, equals(44));
      expect(ptw.output('tlb_write_ppn').width, equals(44));
      expect(ptw.output('tlb_write_perms').width, equals(7));
      expect(ptw.output('tlb_write_level').width, equals(3));
    });

    test('fault outputs', () {
      final ptw = HarborPageTableWalker();
      expect(ptw.output('fault_valid').width, equals(1));
      expect(ptw.output('fault_cause').width, equals(4));
      expect(ptw.output('fault_addr').width, equals(64));
    });

    test('hardware A/D bit update', () {
      final ptw = HarborPageTableWalker(hardwareAdUpdate: true);
      expect(ptw.output('mem_write').width, equals(1));
      expect(ptw.output('mem_wdata').width, equals(64));
    });
  });

  group('HarborPmaRegion', () {
    test('memory region defaults', () {
      const r = HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000);
      expect(r.memoryType, equals(HarborPmaMemoryType.memory));
      expect(r.ordering, equals(HarborPmaOrdering.relaxed));
      expect(r.executable, isTrue);
      expect(r.readable, isTrue);
      expect(r.writable, isTrue);
      expect(r.atomicSupport, isTrue);
      expect(r.idempotent, isTrue);
    });

    test('IO region defaults', () {
      const r = HarborPmaRegion.io(start: 0x10000000, size: 0x1000);
      expect(r.memoryType, equals(HarborPmaMemoryType.io));
      expect(r.ordering, equals(HarborPmaOrdering.strong));
      expect(r.executable, isFalse);
      expect(r.atomicSupport, isFalse);
      expect(r.idempotent, isFalse);
      expect(r.accessWidths, equals([4]));
    });

    test('contains', () {
      const r = HarborPmaRegion.memory(start: 0x1000, size: 0x1000);
      expect(r.contains(0x1000), isTrue);
      expect(r.contains(0x1FFF), isTrue);
      expect(r.contains(0x2000), isFalse);
      expect(r.contains(0x0FFF), isFalse);
    });

    test('toPrettyString', () {
      const r = HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000);
      final pretty = r.toPrettyString();
      expect(pretty, contains('memory'));
      expect(pretty, contains('RWXA'));
    });
  });

  group('HarborPmaConfig', () {
    test('lookup finds correct region', () {
      const config = HarborPmaConfig(
        regions: [
          HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000),
          HarborPmaRegion.io(start: 0x10000000, size: 0x10000000),
        ],
      );

      final mem = config.lookup(0x80000000);
      expect(mem, isNotNull);
      expect(mem!.memoryType, equals(HarborPmaMemoryType.memory));

      final io = config.lookup(0x10000000);
      expect(io, isNotNull);
      expect(io!.memoryType, equals(HarborPmaMemoryType.io));

      expect(config.lookup(0x00000000), isNull);
    });

    test('validates no overlaps', () {
      const good = HarborPmaConfig(
        regions: [
          HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000),
          HarborPmaRegion.io(start: 0x10000000, size: 0x10000000),
        ],
      );
      expect(good.validate(), isEmpty);
    });

    test('detects overlaps', () {
      const bad = HarborPmaConfig(
        regions: [
          HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000),
          HarborPmaRegion.memory(start: 0x90000000, size: 0x40000000),
        ],
      );
      expect(bad.validate(), isNotEmpty);
    });
  });

  group('HarborPmaChecker', () {
    test('creates with regions', () {
      final checker = HarborPmaChecker(
        config: const HarborPmaConfig(
          regions: [
            HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000),
            HarborPmaRegion.io(start: 0x10000000, size: 0x10000000),
          ],
        ),
      );
      expect(checker.output('mem_type').width, equals(2));
      expect(checker.output('ordering').width, equals(2));
      expect(checker.output('cacheable').width, equals(1));
      expect(checker.output('fault').width, equals(1));
    });
  });

  group('HarborMmuConfig with PMA', () {
    test('pma field accessible', () {
      final mmu = HarborMmuConfig(
        mxlen: RiscVMxlen.rv64,
        pagingModes: [RiscVPagingMode.sv39],
        pma: const HarborPmaConfig(
          regions: [
            HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000),
          ],
        ),
      );
      expect(mmu.pma.regions, hasLength(1));
      expect(
        mmu.pma.regions.first.memoryType,
        equals(HarborPmaMemoryType.memory),
      );
    });

    test('toPrettyString includes PMA', () {
      final mmu = HarborMmuConfig(
        mxlen: RiscVMxlen.rv64,
        pma: const HarborPmaConfig(
          regions: [
            HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000),
          ],
        ),
      );
      final pretty = mmu.toPrettyString();
      expect(pretty, contains('PMA'));
    });
  });
}
