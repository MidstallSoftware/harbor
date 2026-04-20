import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('RiscVCopyField', () {
    test('stores src and dest fields', () {
      const op = RiscVCopyField(RiscVMicroOpField.imm, RiscVMicroOpField.rd);
      expect(op.src, equals(RiscVMicroOpField.imm));
      expect(op.dest, equals(RiscVMicroOpField.rd));
    });

    test('is a RiscVMicroOp', () {
      const op = RiscVCopyField(RiscVMicroOpField.rs1, RiscVMicroOpField.rs2);
      expect(op, isA<RiscVMicroOp>());
    });

    test('is const-constructible', () {
      const a = RiscVCopyField(RiscVMicroOpField.imm, RiscVMicroOpField.rd);
      const b = RiscVCopyField(RiscVMicroOpField.imm, RiscVMicroOpField.rd);
      expect(identical(a, b), isTrue);
    });
  });

  group('RiscVSetField', () {
    test('stores src and dest', () {
      const op = RiscVSetField(RiscVMicroOpSource.alu, RiscVMicroOpField.rs2);
      expect(op.src, equals(RiscVMicroOpSource.alu));
      expect(op.dest, equals(RiscVMicroOpField.rs2));
    });

    test('is a RiscVMicroOp', () {
      const op = RiscVSetField(RiscVMicroOpSource.imm, RiscVMicroOpField.rd);
      expect(op, isA<RiscVMicroOp>());
    });

    test('is const-constructible', () {
      const a = RiscVSetField(RiscVMicroOpSource.alu, RiscVMicroOpField.rs2);
      const b = RiscVSetField(RiscVMicroOpSource.alu, RiscVMicroOpField.rs2);
      expect(identical(a, b), isTrue);
    });
  });
}
