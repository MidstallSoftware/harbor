import '../../encoding/riscv_formats.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../operation.dart';
import '../resource.dart';

const _fp64 = RiscVFloatRegFile(64);
const _int = RiscVIntRegFile(32);

/// D extension - Double-precision floating-point.
///
/// Requires F extension. Operations use f0-f31 with 64-bit width.
const rvD = RiscVExtension(
  name: 'D',
  key: 'D',
  misaBit: 3,
  operations: [
    // Load/Store
    RiscVOperation(
      mnemonic: 'fld',
      opcode: 0x07,
      funct3: 0x3,
      format: iType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_fp64, rd),
        MemoryResource.load(),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVMemLoad(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          RiscVMemSize.dword,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'fsd',
      opcode: 0x27,
      funct3: 0x3,
      format: sType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_fp64, rs2),
        MemoryResource.store(),
        FpuResource(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVMemStore(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rs2,
          RiscVMemSize.dword,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    // Arithmetic
    RiscVOperation(
      mnemonic: 'fadd.d',
      opcode: 0x53,
      funct7: 0x01,
      format: rType,
      resources: [
        RfResource(_fp64, rs1),
        RfResource(_fp64, rs2),
        RfResource(_fp64, rd),
        FpuResource(),
      ],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    RiscVOperation(
      mnemonic: 'fsub.d',
      opcode: 0x53,
      funct7: 0x05,
      format: rType,
      resources: [
        RfResource(_fp64, rs1),
        RfResource(_fp64, rs2),
        RfResource(_fp64, rd),
        FpuResource(),
      ],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    RiscVOperation(
      mnemonic: 'fmul.d',
      opcode: 0x53,
      funct7: 0x09,
      format: rType,
      resources: [
        RfResource(_fp64, rs1),
        RfResource(_fp64, rs2),
        RfResource(_fp64, rd),
        FpuResource(),
      ],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    RiscVOperation(
      mnemonic: 'fdiv.d',
      opcode: 0x53,
      funct7: 0x0D,
      format: rType,
      resources: [
        RfResource(_fp64, rs1),
        RfResource(_fp64, rs2),
        RfResource(_fp64, rd),
        FpuResource(),
      ],
      executionMode: RiscVExecutionMode.microcoded,
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    RiscVOperation(
      mnemonic: 'fsqrt.d',
      opcode: 0x53,
      funct7: 0x2D,
      format: rType,
      resources: [RfResource(_fp64, rs1), RfResource(_fp64, rd), FpuResource()],
      executionMode: RiscVExecutionMode.microcoded,
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    // Conversion single↔double
    RiscVOperation(
      mnemonic: 'fcvt.s.d',
      opcode: 0x53,
      funct7: 0x20,
      format: rType,
      resources: [RfResource(_fp64, rs1), RfResource(_fp64, rd), FpuResource()],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    RiscVOperation(
      mnemonic: 'fcvt.d.s',
      opcode: 0x53,
      funct7: 0x21,
      format: rType,
      resources: [RfResource(_fp64, rs1), RfResource(_fp64, rd), FpuResource()],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    // Compare
    RiscVOperation(
      mnemonic: 'feq.d',
      opcode: 0x53,
      funct7: 0x51,
      funct3: 0x2,
      format: rType,
      resources: [
        RfResource(_fp64, rs1),
        RfResource(_fp64, rs2),
        RfResource(_int, rd),
        FpuResource(),
      ],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    RiscVOperation(
      mnemonic: 'flt.d',
      opcode: 0x53,
      funct7: 0x51,
      funct3: 0x1,
      format: rType,
      resources: [
        RfResource(_fp64, rs1),
        RfResource(_fp64, rs2),
        RfResource(_int, rd),
        FpuResource(),
      ],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
    RiscVOperation(
      mnemonic: 'fle.d',
      opcode: 0x53,
      funct7: 0x51,
      funct3: 0x0,
      format: rType,
      resources: [
        RfResource(_fp64, rs1),
        RfResource(_fp64, rs2),
        RfResource(_int, rd),
        FpuResource(),
      ],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4)],
    ),
  ],
);
