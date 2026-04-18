import '../../encoding/riscv_compressed.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../operation.dart';
import '../resource.dart';

const _int = RiscVIntRegFile(32);

/// C extension - Compressed instructions.
///
/// Compressed instructions are 16-bit encodings that expand to
/// their 32-bit equivalents. The operations here describe the
/// compressed forms; the CPU's fetch stage detects and expands them.
const rvC = RiscVExtension(
  name: 'C',
  key: 'C',
  misaBit: 2,
  operations: [
    // Quadrant 0
    RiscVOperation(
      mnemonic: 'c.addi4spn',
      opcode: CompressedOp.c0,
      funct3: C0Funct3.cAddi4spn,
      format: ciwType,
      resources: [RfResource(_int, rd)],
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2)],
    ),
    RiscVOperation(
      mnemonic: 'c.lw',
      opcode: CompressedOp.c0,
      funct3: C0Funct3.cLw,
      format: clType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_int, rd),
        MemoryResource.load(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVMemLoad(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          RiscVMemSize.word,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.sw',
      opcode: CompressedOp.c0,
      funct3: C0Funct3.cSw,
      format: csType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_int, rs2),
        MemoryResource.store(),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVMemStore(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rs2,
          RiscVMemSize.word,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),

    // Quadrant 1
    RiscVOperation(
      mnemonic: 'c.nop',
      opcode: CompressedOp.c1,
      funct3: C1Funct3.cNop,
      format: ciType,
      microcode: [RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2)],
    ),
    RiscVOperation(
      mnemonic: 'c.addi',
      opcode: CompressedOp.c1,
      funct3: C1Funct3.cAddi,
      format: ciType,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVAlu(
          RiscVAluFunct.add,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.imm,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.li',
      opcode: CompressedOp.c1,
      funct3: C1Funct3.cLi,
      format: ciType,
      resources: [RfResource(_int, rd)],
      microcode: [
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.imm),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.lui',
      opcode: CompressedOp.c1,
      funct3: C1Funct3.cLui,
      format: ciType,
      resources: [RfResource(_int, rd)],
      microcode: [
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.imm),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.j',
      opcode: CompressedOp.c1,
      funct3: C1Funct3.cJ,
      format: cjType,
      resources: [PcResource()],
      microcode: [
        RiscVUpdatePc(RiscVMicroOpField.pc, offsetField: RiscVMicroOpField.imm),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.beqz',
      opcode: CompressedOp.c1,
      funct3: C1Funct3.cBeqz,
      format: cbType,
      resources: [RfResource(_int, rs1), PcResource()],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVBranch(
          RiscVBranchCondition.eq,
          RiscVMicroOpSource.rs1,
          offsetField: RiscVMicroOpField.imm,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.bnez',
      opcode: CompressedOp.c1,
      funct3: C1Funct3.cBnez,
      format: cbType,
      resources: [RfResource(_int, rs1), PcResource()],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVBranch(
          RiscVBranchCondition.ne,
          RiscVMicroOpSource.rs1,
          offsetField: RiscVMicroOpField.imm,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),

    // Quadrant 2
    RiscVOperation(
      mnemonic: 'c.slli',
      opcode: CompressedOp.c2,
      funct3: C2Funct3.cSlli,
      format: ciType,
      resources: [RfResource(_int, rs1), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVAlu(
          RiscVAluFunct.sll,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.imm,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.lwsp',
      opcode: CompressedOp.c2,
      funct3: C2Funct3.cLwsp,
      format: ciType,
      resources: [RfResource(_int, rd), MemoryResource.load()],
      microcode: [
        RiscVMemLoad(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rd,
          RiscVMemSize.word,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.swsp',
      opcode: CompressedOp.c2,
      funct3: C2Funct3.cSwsp,
      format: cssType,
      resources: [RfResource(_int, rs2), MemoryResource.store()],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVMemStore(
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rs2,
          RiscVMemSize.word,
        ),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.mv',
      opcode: CompressedOp.c2,
      funct3: C2Funct3.cMv,
      format: crType,
      resources: [RfResource(_int, rs2), RfResource(_int, rd)],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rs2),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
    RiscVOperation(
      mnemonic: 'c.add',
      opcode: CompressedOp.c2,
      funct3: C2Funct3.cMv,
      format: crType,
      resources: [
        RfResource(_int, rs1),
        RfResource(_int, rs2),
        RfResource(_int, rd),
      ],
      microcode: [
        RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadRegister(RiscVMicroOpField.rs2),
        RiscVAlu(
          RiscVAluFunct.add,
          RiscVMicroOpField.rs1,
          RiscVMicroOpField.rs2,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 2),
      ],
    ),
  ],
);
