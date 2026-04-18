import '../../encoding/riscv_formats.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../mxlen.dart';
import '../operation.dart';
import '../resource.dart';

const _int = RiscVIntRegFile(32);

RiscVOperation _atomic(
  String mnemonic,
  int funct7,
  RiscVAtomicFunct afunct,
  RiscVMemSize size, {
  Set<RiscVMxlen>? xlen,
}) => RiscVOperation(
  mnemonic: mnemonic,
  opcode: RiscvOpcode.amo,
  funct3: size == RiscVMemSize.word ? 0x2 : 0x3,
  funct7: funct7,
  format: rType,
  xlenConstraint: xlen,
  executionMode: RiscVExecutionMode.microcoded,
  resources: [
    RfResource(_int, rs1),
    RfResource(_int, rs2),
    RfResource(_int, rd),
    MemoryResource.load(),
    MemoryResource.store(),
  ],
  microcode: [
    RiscVReadRegister(RiscVMicroOpField.rs1),
    RiscVReadRegister(RiscVMicroOpField.rs2),
    RiscVAtomicMemory(
      afunct,
      RiscVMicroOpField.rs1,
      RiscVMicroOpField.rs2,
      RiscVMicroOpField.rd,
      size,
    ),
    RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
  ],
);

/// RV32A + RV64A - Atomic extension.
final rvA = RiscVExtension(
  name: 'A',
  key: 'A',
  misaBit: 0,
  operations: [
    // LR/SC word
    RiscVOperation(
      mnemonic: 'lr.w',
      opcode: RiscvOpcode.amo,
      funct3: 0x2,
      funct7: 0x10,
      format: rType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_int, rd),
        MemoryResource.load(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVLoadReserved(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          RiscVMemSize.word,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'sc.w',
      opcode: RiscvOpcode.amo,
      funct3: 0x2,
      funct7: 0x18,
      format: rType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_int, rs2),
        RfResource(_int, rd),
        MemoryResource.store(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVStoreConditional(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rs2,
          RiscVMicroOpField.rd,
          RiscVMemSize.word,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    // AMO word
    _atomic('amoswap.w', 0x08, RiscVAtomicFunct.swap, RiscVMemSize.word),
    _atomic('amoadd.w', 0x00, RiscVAtomicFunct.add, RiscVMemSize.word),
    _atomic('amoxor.w', 0x20, RiscVAtomicFunct.xor_, RiscVMemSize.word),
    _atomic('amoand.w', 0x60, RiscVAtomicFunct.and_, RiscVMemSize.word),
    _atomic('amoor.w', 0x40, RiscVAtomicFunct.or_, RiscVMemSize.word),
    _atomic('amomin.w', 0x80, RiscVAtomicFunct.min, RiscVMemSize.word),
    _atomic('amomax.w', 0xA0, RiscVAtomicFunct.max, RiscVMemSize.word),
    _atomic('amominu.w', 0xC0, RiscVAtomicFunct.minu, RiscVMemSize.word),
    _atomic('amomaxu.w', 0xE0, RiscVAtomicFunct.maxu, RiscVMemSize.word),
    // LR/SC double (RV64)
    RiscVOperation(
      mnemonic: 'lr.d',
      opcode: RiscvOpcode.amo,
      funct3: 0x3,
      funct7: 0x10,
      format: rType,
      xlenConstraint: {RiscVMxlen.rv64, RiscVMxlen.rv128},
      resources: [
        RfResource(_int, rs1),
        RfResource(_int, rd),
        MemoryResource.load(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVLoadReserved(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          RiscVMemSize.dword,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    RiscVOperation(
      mnemonic: 'sc.d',
      opcode: RiscvOpcode.amo,
      funct3: 0x3,
      funct7: 0x18,
      format: rType,
      xlenConstraint: {RiscVMxlen.rv64, RiscVMxlen.rv128},
      resources: [
        RfResource(_int, rs1),
        RfResource(_int, rs2),
        RfResource(_int, rd),
        MemoryResource.store(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVStoreConditional(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rs2,
          RiscVMicroOpField.rd,
          RiscVMemSize.dword,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    ),
    // AMO double (RV64)
    _atomic(
      'amoswap.d',
      0x08,
      RiscVAtomicFunct.swap,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amoadd.d',
      0x00,
      RiscVAtomicFunct.add,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amoxor.d',
      0x20,
      RiscVAtomicFunct.xor_,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amoand.d',
      0x60,
      RiscVAtomicFunct.and_,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amoor.d',
      0x40,
      RiscVAtomicFunct.or_,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amomin.d',
      0x80,
      RiscVAtomicFunct.min,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amomax.d',
      0xA0,
      RiscVAtomicFunct.max,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amominu.d',
      0xC0,
      RiscVAtomicFunct.minu,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
    _atomic(
      'amomaxu.d',
      0xE0,
      RiscVAtomicFunct.maxu,
      RiscVMemSize.dword,
      xlen: {RiscVMxlen.rv64, RiscVMxlen.rv128},
    ),
  ],
);
