import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

// Use RiscVInstructionDecoder directly as a standalone module for testing.
// Inject into its input and read from its outputs.

void main() {
  group('RiscVInstructionDecoder', () {
    late RiscVIsaConfig isa;

    setUp(() {
      isa = RiscVIsaConfig(mxlen: RiscVMxlen.rv32, extensions: [rv32i, rvM]);
    });

    test('creates with correct output widths', () {
      final mod = RiscVInstructionDecoder(
        isa,
        instructionInput: Logic(width: 32),
      );
      expect(mod.opcodeField.width, equals(7));
      expect(mod.rdField.width, equals(5));
      expect(mod.funct3Field.width, equals(3));
      expect(mod.rs1Field.width, equals(5));
      expect(mod.rs2Field.width, equals(5));
      expect(mod.funct7Field.width, equals(7));
      expect(mod.immediateField.width, equals(32));
    });

    test('builds without errors', () async {
      final mod = RiscVInstructionDecoder(
        isa,
        instructionInput: Logic(width: 32),
      );
      await mod.build();
    });

    test('decodes ADD instruction', () async {
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(isa, instructionInput: instrIn);
      await mod.build();

      instrIn.put(0x003100B3); // ADD x1, x2, x3

      expect(mod.output('opcode').value.toInt(), equals(0x33));
      expect(mod.output('rd').value.toInt(), equals(1));
      expect(mod.output('funct3').value.toInt(), equals(0));
      expect(mod.output('rs1').value.toInt(), equals(2));
      expect(mod.output('rs2').value.toInt(), equals(3));
      expect(mod.output('funct7').value.toInt(), equals(0));
      expect(mod.output('illegal').value.toInt(), equals(0));
    });

    test('decodes SUB instruction', () async {
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(isa, instructionInput: instrIn);
      await mod.build();

      final sub = rType.encode({
        'opcode': 0x33,
        'rd': 5,
        'funct3': 0,
        'rs1': 6,
        'rs2': 7,
        'funct7': 0x20,
      });
      instrIn.put(sub);

      expect(mod.output('opcode').value.toInt(), equals(0x33));
      expect(mod.output('rd').value.toInt(), equals(5));
      expect(mod.output('funct7').value.toInt(), equals(0x20));
      expect(mod.output('illegal').value.toInt(), equals(0));
    });

    test('flags illegal instruction', () async {
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(isa, instructionInput: instrIn);
      await mod.build();

      instrIn.put(0x0000007B); // opcode 0x7B not in rv32i/M
      expect(mod.output('illegal').value.toInt(), equals(1));
    });

    test('detects compressed instruction', () async {
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(isa, instructionInput: instrIn);
      await mod.build();

      instrIn.put(0x00000001); // bits [1:0] = 01 -> compressed
      expect(mod.output('is_compressed').value.toInt(), equals(1));

      instrIn.put(0x00000033); // bits [1:0] = 11 -> not compressed
      expect(mod.output('is_compressed').value.toInt(), equals(0));
    });

    test('operation index differs for ADD vs SUB', () async {
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(isa, instructionInput: instrIn);
      await mod.build();

      instrIn.put(0x003100B3); // ADD
      final addIndex = mod.output('op_index').value.toInt();

      final sub = rType.encode({
        'opcode': 0x33,
        'rd': 1,
        'funct3': 0,
        'rs1': 2,
        'rs2': 3,
        'funct7': 0x20,
      });
      instrIn.put(sub); // SUB
      final subIndex = mod.output('op_index').value.toInt();

      expect(addIndex, isNot(equals(subIndex)));
    });

    test('MUL is flagged as microcoded', () async {
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(isa, instructionInput: instrIn);
      await mod.build();

      final mul = rType.encode({
        'opcode': 0x33,
        'rd': 1,
        'funct3': 0,
        'rs1': 2,
        'rs2': 3,
        'funct7': 0x01,
      });
      instrIn.put(mul);

      expect(mod.output('illegal').value.toInt(), equals(0));
      expect(mod.output('is_microcoded').value.toInt(), equals(1));
    });

    test('execution mode overrides work', () async {
      final overriddenIsa = RiscVIsaConfig(
        mxlen: RiscVMxlen.rv32,
        extensions: [rv32i, rvM],
        executionOverrides: {'mul': RiscVExecutionMode.hardcoded},
      );

      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(
        overriddenIsa,
        instructionInput: instrIn,
      );
      await mod.build();

      final mul = rType.encode({
        'opcode': 0x33,
        'rd': 1,
        'funct3': 0,
        'rs1': 2,
        'rs2': 3,
        'funct7': 0x01,
      });
      instrIn.put(mul);

      expect(mod.output('is_hardcoded').value.toInt(), equals(1));
      expect(mod.output('is_microcoded').value.toInt(), equals(0));
    });

    test('ADDI immediate extraction', () async {
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(isa, instructionInput: instrIn);
      await mod.build();

      final addi = iType.encode({
        'opcode': 0x13,
        'rd': 1,
        'funct3': 0,
        'rs1': 2,
        'imm': 42,
      });
      instrIn.put(addi);

      expect(mod.output('illegal').value.toInt(), equals(0));
      expect(mod.output('immediate').value.toInt(), equals(42));
    });

    test('empty ISA decoder flags everything illegal', () async {
      final emptyIsa = RiscVIsaConfig(mxlen: RiscVMxlen.rv32, extensions: []);
      final instrIn = Logic(name: 'instr_in', width: 32);
      final mod = RiscVInstructionDecoder(emptyIsa, instructionInput: instrIn);
      await mod.build();

      instrIn.put(0x003100B3);
      expect(mod.output('illegal').value.toInt(), equals(1));
    });
  });
}
