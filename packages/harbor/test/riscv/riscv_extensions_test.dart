import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('RV32I extension', () {
    test('has correct operation count', () {
      // lui, auipc, jal, jalr, 6 branches, 5 loads, 3 stores,
      // 6 alu-imm, 3 shifts, 10 alu-reg, fence, ecall, ebreak
      expect(rv32i.operations.length, greaterThanOrEqualTo(35));
    });
  });

  group('RVA23 profile', () {
    test('rva23u64 has all required base extensions', () {
      final extNames = rva23u64.extensions.map((e) => e.name).toList();
      // Must include base + standard extensions
      expect(extNames, contains(rv32i.name));
      expect(extNames, contains(rv64i.name));
      expect(extNames, contains(rvM.name));
      expect(extNames, contains(rvA.name));
      expect(extNames, contains(rvF.name));
      expect(extNames, contains(rvD.name));
      expect(extNames, contains(rvC.name));
      expect(extNames, contains(rvV.name));
      expect(extNames, contains(rvB.name));
    });

    test('rva23u64 has user mode', () {
      expect(rva23u64.hasUser, isTrue);
    });

    test('rva23s64 extends rva23u64 with supervisor', () {
      expect(rva23s64.hasSupervisor, isTrue);
      expect(rva23s64.hasUser, isTrue);
      // Must include hypervisor
      final extNames = rva23s64.extensions.map((e) => e.name).toList();
      expect(extNames, contains(rvH.name));
    });

    test('rva23s64 has paging modes', () {
      expect(rva23s64.pagingModes, contains(RiscVPagingMode.sv39));
      expect(rva23s64.pagingModes, contains(RiscVPagingMode.sv48));
      expect(rva23s64.pagingModes, contains(RiscVPagingMode.sv57));
    });

    test('rva23s64 has more extensions than rva23u64', () {
      expect(
        rva23s64.extensions.length,
        greaterThan(rva23u64.extensions.length),
      );
    });
  });
}
