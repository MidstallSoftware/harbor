import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('RiscvOpcode', () {
    test('has expected constant values', () {
      expect(RiscvOpcode.lui, equals(0x37));
      expect(RiscvOpcode.auipc, equals(0x17));
      expect(RiscvOpcode.jal, equals(0x6F));
      expect(RiscvOpcode.jalr, equals(0x67));
      expect(RiscvOpcode.branch, equals(0x63));
      expect(RiscvOpcode.load, equals(0x03));
      expect(RiscvOpcode.store, equals(0x23));
      expect(RiscvOpcode.opImm, equals(0x13));
      expect(RiscvOpcode.op, equals(0x33));
      expect(RiscvOpcode.opImm32, equals(0x1B));
      expect(RiscvOpcode.op32, equals(0x3B));
      expect(RiscvOpcode.fence, equals(0x0F));
      expect(RiscvOpcode.system, equals(0x73));
      expect(RiscvOpcode.amo, equals(0x2F));
    });
  });

  group('BranchFunct3', () {
    test('eq', () {
      expect(BranchFunct3.beq, equals(0));
    });

    test('ne', () {
      expect(BranchFunct3.bne, equals(1));
    });

    test('lt', () {
      expect(BranchFunct3.blt, equals(4));
    });

    test('ge', () {
      expect(BranchFunct3.bge, equals(5));
    });
  });

  group('MachineCsr', () {
    test('mstatus', () {
      expect(MachineCsr.mstatus, equals(0x300));
    });

    test('misa', () {
      expect(MachineCsr.misa, equals(0x301));
    });

    test('mie', () {
      expect(MachineCsr.mie, equals(0x304));
    });

    test('mtvec', () {
      expect(MachineCsr.mtvec, equals(0x305));
    });
  });

  group('SupervisorCsr', () {
    test('sstatus', () {
      expect(SupervisorCsr.sstatus, equals(0x100));
    });

    test('sie', () {
      expect(SupervisorCsr.sie, equals(0x104));
    });

    test('stvec', () {
      expect(SupervisorCsr.stvec, equals(0x105));
    });
  });

  group('Instruction format BitStructs', () {
    test('rType has expected field names', () {
      expect(rType['opcode'], isNotNull);
      expect(rType['rd'], isNotNull);
      expect(rType['funct3'], isNotNull);
      expect(rType['rs1'], isNotNull);
      expect(rType['rs2'], isNotNull);
      expect(rType['funct7'], isNotNull);
    });

    test('iType has expected field names', () {
      expect(iType['opcode'], isNotNull);
      expect(iType['rd'], isNotNull);
      expect(iType['funct3'], isNotNull);
      expect(iType['rs1'], isNotNull);
      expect(iType['imm'], isNotNull);
    });

    test('sType has expected field names', () {
      expect(sType['opcode'], isNotNull);
      expect(sType['immLo'], isNotNull);
      expect(sType['funct3'], isNotNull);
      expect(sType['rs1'], isNotNull);
      expect(sType['rs2'], isNotNull);
      expect(sType['immHi'], isNotNull);
    });

    test('bType has expected field names', () {
      expect(bType['opcode'], isNotNull);
      expect(bType['immLo'], isNotNull);
      expect(bType['funct3'], isNotNull);
      expect(bType['rs1'], isNotNull);
      expect(bType['rs2'], isNotNull);
      expect(bType['immHi'], isNotNull);
    });

    test('uType has expected field names', () {
      expect(uType['opcode'], isNotNull);
      expect(uType['rd'], isNotNull);
      expect(uType['imm'], isNotNull);
    });

    test('jType has expected field names', () {
      expect(jType['opcode'], isNotNull);
      expect(jType['rd'], isNotNull);
      expect(jType['imm'], isNotNull);
    });
  });
}
