import '../../encoding/riscv_formats.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../operation.dart';
import '../resource.dart';

const _fp32 = RiscVFloatRegFile(32);
const _int = RiscVIntRegFile(32);

const rvF = RiscVExtension(
  name: 'F',
  key: 'F',
  misaBit: 5,
  operations: [
    RiscVOperation(
      mnemonic: 'flw',
      opcode: 0x07,
      funct3: 0x2,
      format: iType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_fp32, rd),
        MemoryResource.load(),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVMemLoad(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          RiscVMemSize.word,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fsw',
      opcode: 0x27,
      funct3: 0x2,
      format: sType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_fp32, rs2),
        MemoryResource.store(),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVMemStore(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rs2,
          RiscVMemSize.word,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fadd.s',
      opcode: 0x53,
      funct7: 0x00,
      format: rType,
      resources: [
        RfResource(_fp32, rs1),
        RfResource(_fp32, rs2),
        RfResource(_fp32, rd),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVFpuOp(
          RiscVFpuFunct.fadd,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          b: RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fsub.s',
      opcode: 0x53,
      funct7: 0x04,
      format: rType,
      resources: [
        RfResource(_fp32, rs1),
        RfResource(_fp32, rs2),
        RfResource(_fp32, rd),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVFpuOp(
          RiscVFpuFunct.fsub,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          b: RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fmul.s',
      opcode: 0x53,
      funct7: 0x08,
      format: rType,
      resources: [
        RfResource(_fp32, rs1),
        RfResource(_fp32, rs2),
        RfResource(_fp32, rd),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVFpuOp(
          RiscVFpuFunct.fmul,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          b: RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fdiv.s',
      opcode: 0x53,
      funct7: 0x0C,
      format: rType,
      resources: [
        RfResource(_fp32, rs1),
        RfResource(_fp32, rs2),
        RfResource(_fp32, rd),
        FpuResource(),
      ],
      executionMode: RiscVExecutionMode.microcoded,
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVFpuOp(
          RiscVFpuFunct.fdiv,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          b: RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fsqrt.s',
      opcode: 0x53,
      funct7: 0x2C,
      format: rType,
      resources: [RfResource(_fp32, rs1), RfResource(_fp32, rd), FpuResource()],
      executionMode: RiscVExecutionMode.microcoded,
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVFpuOp(
          RiscVFpuFunct.fsqrt,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fcvt.w.s',
      opcode: 0x53,
      funct7: 0x60,
      format: rType,
      resources: [RfResource(_fp32, rs1), RfResource(_int, rd), FpuResource()],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVFpuOp(
          RiscVFpuFunct.fcvtWS,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fcvt.s.w',
      opcode: 0x53,
      funct7: 0x68,
      format: rType,
      resources: [RfResource(_int, rs1), RfResource(_fp32, rd), FpuResource()],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVFpuOp(
          RiscVFpuFunct.fcvtSW,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'feq.s',
      opcode: 0x53,
      funct7: 0x50,
      funct3: 0x2,
      format: rType,
      resources: [
        RfResource(_fp32, rs1),
        RfResource(_fp32, rs2),
        RfResource(_int, rd),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVFpuOp(
          RiscVFpuFunct.feq,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          b: RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'flt.s',
      opcode: 0x53,
      funct7: 0x50,
      funct3: 0x1,
      format: rType,
      resources: [
        RfResource(_fp32, rs1),
        RfResource(_fp32, rs2),
        RfResource(_int, rd),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVFpuOp(
          RiscVFpuFunct.flt,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          b: RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fle.s',
      opcode: 0x53,
      funct7: 0x50,
      funct3: 0x0,
      format: rType,
      resources: [
        RfResource(_fp32, rs1),
        RfResource(_fp32, rs2),
        RfResource(_int, rd),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVFpuOp(
          RiscVFpuFunct.fle,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          b: RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
  ],
);
