import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('rvZicsr extension', () {
    test('has correct name', () {
      expect(rvZicsr.name, equals('Zicsr'));
    });

    test('has no misa key or bit', () {
      expect(rvZicsr.key, isNull);
      expect(rvZicsr.misaBit, isNull);
    });

    test('has 6 operations', () {
      expect(rvZicsr.operations, hasLength(6));
    });

    test('all operations use system opcode', () {
      for (final op in rvZicsr.operations) {
        expect(
          op.opcode,
          equals(RiscvOpcode.system),
          reason: '${op.mnemonic} should use system opcode',
        );
      }
    });

    test('all operations use iType format', () {
      for (final op in rvZicsr.operations) {
        expect(
          op.format,
          equals(iType),
          reason: '${op.mnemonic} should be iType',
        );
      }
    });

    test('csrrw has correct funct3', () {
      final csrrw = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrw',
      );
      expect(csrrw.funct3, equals(CsrFunct3.csrrw));
    });

    test('csrrs has correct funct3', () {
      final csrrs = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrs',
      );
      expect(csrrs.funct3, equals(CsrFunct3.csrrs));
    });

    test('csrrc has correct funct3', () {
      final csrrc = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrc',
      );
      expect(csrrc.funct3, equals(CsrFunct3.csrrc));
    });

    test('csrrwi has correct funct3', () {
      final csrrwi = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrwi',
      );
      expect(csrrwi.funct3, equals(CsrFunct3.csrrwi));
    });

    test('csrrsi has correct funct3', () {
      final csrrsi = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrsi',
      );
      expect(csrrsi.funct3, equals(CsrFunct3.csrrsi));
    });

    test('csrrci has correct funct3', () {
      final csrrci = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrci',
      );
      expect(csrrci.funct3, equals(CsrFunct3.csrrci));
    });
  });

  group('rvZicsr microcode sequences', () {
    test('csrrw starts with RiscVReadRegister for rs1', () {
      final csrrw = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrw',
      );
      expect(csrrw.microcode.first, isA<RiscVReadRegister>());
    });

    test('csrrwi does not start with RiscVReadRegister', () {
      final csrrwi = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrwi',
      );
      expect(csrrwi.microcode.first, isNot(isA<RiscVReadRegister>()));
    });

    test('csrrw has CopyField, ReadCsr, WriteCsr, WriteRegister, UpdatePc', () {
      final csrrw = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrw',
      );
      final types = csrrw.microcode.map((m) => m.runtimeType).toList();
      expect(types, contains(RiscVCopyField));
      expect(types, contains(RiscVReadCsr));
      expect(types, contains(RiscVWriteCsr));
      expect(types, contains(RiscVWriteRegister));
      expect(types, contains(RiscVUpdatePc));
    });

    test('csrrs uses OR ALU op for set semantics', () {
      final csrrs = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrs',
      );
      final aluOps = csrrs.microcode.whereType<RiscVAlu>().toList();
      expect(aluOps, hasLength(1));
      expect(aluOps.first.funct, equals(RiscVAluFunct.or_));
    });

    test('csrrc uses AND then XOR ALU ops for clear semantics', () {
      final csrrc = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrc',
      );
      final aluOps = csrrc.microcode.whereType<RiscVAlu>().toList();
      expect(aluOps, hasLength(2));
      expect(aluOps[0].funct, equals(RiscVAluFunct.and_));
      expect(aluOps[1].funct, equals(RiscVAluFunct.xor_));
    });

    test('csrrc uses SetField between the two ALU ops', () {
      final csrrc = rvZicsr.operations.firstWhere(
        (op) => op.mnemonic == 'csrrc',
      );
      final setFields = csrrc.microcode.whereType<RiscVSetField>().toList();
      expect(setFields, hasLength(1));
      expect(setFields.first.src, equals(RiscVMicroOpSource.alu));
      expect(setFields.first.dest, equals(RiscVMicroOpField.rs2));
    });

    test('all operations end with UpdatePc offset 4', () {
      for (final op in rvZicsr.operations) {
        final last = op.microcode.last;
        expect(
          last,
          isA<RiscVUpdatePc>(),
          reason: '${op.mnemonic} should end with UpdatePc',
        );
        expect((last as RiscVUpdatePc).offset, equals(4));
      }
    });

    test('all operations have CsrResource', () {
      for (final op in rvZicsr.operations) {
        expect(
          op.resources.whereType<CsrResource>(),
          isNotEmpty,
          reason: '${op.mnemonic} should have CsrResource',
        );
      }
    });
  });
}
