import '../../encoding/riscv_formats.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../mxlen.dart';
import '../operation.dart';
import '../resource.dart';

const _int = RiscVIntRegFile(32);
const _rv64 = {RiscVMxlen.rv64, RiscVMxlen.rv128};

// ── Zba: Address generation ──

RiscVOperation _zbaReg(
  String m,
  int f3,
  int f7,
  RiscVAluFunct f, {
  Set<RiscVMxlen>? xlen,
  int op = RiscvOpcode.op,
}) => RiscVOperation(
  mnemonic: m,
  opcode: op,
  funct3: f3,
  funct7: f7,
  format: rType,
  xlenConstraint: xlen,
  resources: [
    RfResource(_int, rs1),
    RfResource(_int, rs2),
    RfResource(_int, rd),
  ],
  microcode: [
    RiscVReadRegister(RiscVMicroOpField.rs1),
    RiscVReadRegister(RiscVMicroOpField.rs2),
    RiscVAlu(f, RiscVMicroOpField.rs1, RiscVMicroOpField.rs2),
    RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
    RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
  ],
);

/// Zba - Address generation instructions.
final rvZba = RiscVExtension(
  name: 'Zba',
  key: null,
  misaBit: null,
  operations: [
    _zbaReg('sh1add', 0x2, 0x10, RiscVAluFunct.add),
    _zbaReg('sh2add', 0x4, 0x10, RiscVAluFunct.add),
    _zbaReg('sh3add', 0x6, 0x10, RiscVAluFunct.add),
    _zbaReg(
      'add.uw',
      0x0,
      0x04,
      RiscVAluFunct.add,
      xlen: _rv64,
      op: RiscvOpcode.op32,
    ),
    _zbaReg(
      'sh1add.uw',
      0x2,
      0x10,
      RiscVAluFunct.add,
      xlen: _rv64,
      op: RiscvOpcode.op32,
    ),
    _zbaReg(
      'sh2add.uw',
      0x4,
      0x10,
      RiscVAluFunct.add,
      xlen: _rv64,
      op: RiscvOpcode.op32,
    ),
    _zbaReg(
      'sh3add.uw',
      0x6,
      0x10,
      RiscVAluFunct.add,
      xlen: _rv64,
      op: RiscvOpcode.op32,
    ),
    RiscVOperation(
      mnemonic: 'slli.uw',
      opcode: RiscvOpcode.opImm32,
      funct3: 0x1,
      funct7: 0x04,
      format: iType,
      xlenConstraint: _rv64,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVAlu(
          RiscVAluFunct.sll,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.imm,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
  ],
);

// ── Zbb: Basic bit manipulation ──

RiscVOperation _zbbReg(
  String m,
  int f3,
  int f7, {
  Set<RiscVMxlen>? xlen,
  int op = RiscvOpcode.op,
}) => RiscVOperation(
  mnemonic: m,
  opcode: op,
  funct3: f3,
  funct7: f7,
  format: rType,
  xlenConstraint: xlen,
  resources: [
    RfResource(_int, rs1),
    RfResource(_int, rs2),
    RfResource(_int, rd),
  ],
  microcode: [
    RiscVReadRegister(RiscVMicroOpField.rs1),
    RiscVReadRegister(RiscVMicroOpField.rs2),
    RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
    RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
  ],
);

RiscVOperation _zbbUnary(String m, int f3, int f7, {Set<RiscVMxlen>? xlen}) =>
    RiscVOperation(
      mnemonic: m,
      opcode: RiscvOpcode.op,
      funct3: f3,
      funct7: f7,
      format: rType,
      xlenConstraint: xlen,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    );

/// Zbb - Basic bit manipulation instructions.
final rvZbb = RiscVExtension(
  name: 'Zbb',
  key: null,
  misaBit: null,
  operations: [
    // Logical with negate
    _zbbReg('andn', 0x7, 0x20),
    _zbbReg('orn', 0x6, 0x20),
    _zbbReg('xnor', 0x4, 0x20),

    // Count leading/trailing zeros, popcount
    _zbbUnary('clz', 0x1, 0x30),
    _zbbUnary('ctz', 0x1, 0x30), // rs2=0x01
    _zbbUnary('cpop', 0x1, 0x30), // rs2=0x02
    _zbbUnary('clzw', 0x1, 0x30, xlen: _rv64),
    _zbbUnary('ctzw', 0x1, 0x30, xlen: _rv64),
    _zbbUnary('cpopw', 0x1, 0x30, xlen: _rv64),

    // Min/max
    _zbbReg('max', 0x6, 0x05),
    _zbbReg('maxu', 0x7, 0x05),
    _zbbReg('min', 0x4, 0x05),
    _zbbReg('minu', 0x5, 0x05),

    // Sign/zero extend
    _zbbUnary('sext.b', 0x1, 0x30), // rs2=0x04
    _zbbUnary('sext.h', 0x1, 0x30), // rs2=0x05
    _zbbUnary('zext.h', 0x4, 0x04),

    // Rotate
    _zbbReg('rol', 0x1, 0x30),
    _zbbReg('ror', 0x5, 0x30),
    RiscVOperation(
      mnemonic: 'rori',
      opcode: RiscvOpcode.opImm,
      funct3: 0x5,
      funct7: 0x30,
      format: iType,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    _zbbReg('rolw', 0x1, 0x30, xlen: _rv64, op: RiscvOpcode.op32),
    _zbbReg('rorw', 0x5, 0x30, xlen: _rv64, op: RiscvOpcode.op32),
    RiscVOperation(
      mnemonic: 'roriw',
      opcode: RiscvOpcode.opImm32,
      funct3: 0x5,
      funct7: 0x30,
      format: iType,
      xlenConstraint: _rv64,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),

    // Byte reverse
    _zbbUnary('rev8', 0x5, 0x34),

    // Or-combine
    _zbbUnary('orc.b', 0x5, 0x14),
  ],
);

// ── Zbc: Carry-less multiplication ──

/// Zbc - Carry-less multiplication instructions.
final rvZbc = RiscVExtension(
  name: 'Zbc',
  key: null,
  misaBit: null,
  operations: [
    _zbbReg('clmul', 0x1, 0x05),
    _zbbReg('clmulh', 0x3, 0x05),
    _zbbReg('clmulr', 0x2, 0x05),
  ],
);

// ── Zbs: Single-bit operations ──

/// Zbs - Single-bit instructions.
final rvZbs = RiscVExtension(
  name: 'Zbs',
  key: null,
  misaBit: null,
  operations: [
    _zbbReg('bclr', 0x1, 0x24),
    _zbbReg('bext', 0x5, 0x24),
    _zbbReg('binv', 0x1, 0x34),
    _zbbReg('bset', 0x1, 0x14),
    RiscVOperation(
      mnemonic: 'bclri',
      opcode: RiscvOpcode.opImm,
      funct3: 0x1,
      funct7: 0x24,
      format: iType,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'bexti',
      opcode: RiscvOpcode.opImm,
      funct3: 0x5,
      funct7: 0x24,
      format: iType,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'binvi',
      opcode: RiscvOpcode.opImm,
      funct3: 0x1,
      funct7: 0x34,
      format: iType,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'bseti',
      opcode: RiscvOpcode.opImm,
      funct3: 0x1,
      funct7: 0x14,
      format: iType,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
  ],
);

/// Combined B extension - includes Zba + Zbb + Zbc + Zbs.
///
/// For convenience, provides all B sub-extensions as a single extension.
final rvB = RiscVExtension(
  name: 'B',
  key: 'B',
  misaBit: 1,
  operations: [
    ...rvZba.operations,
    ...rvZbb.operations,
    ...rvZbc.operations,
    ...rvZbs.operations,
  ],
);
