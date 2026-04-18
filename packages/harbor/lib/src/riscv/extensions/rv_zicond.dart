import '../../encoding/riscv_formats.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../operation.dart';
import '../resource.dart';

const _int = RiscVIntRegFile(32);

/// Zicond - Conditional zero instructions.
final rvZicond = RiscVExtension(
  name: 'Zicond',
  key: null,
  misaBit: null,
  operations: [
    RiscVOperation(
      mnemonic: 'czero.eqz',
      opcode: RiscvOpcode.op,
      funct3: 0x5,
      funct7: 0x07,
      format: rType,
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
    ),
    RiscVOperation(
      mnemonic: 'czero.nez',
      opcode: RiscvOpcode.op,
      funct3: 0x7,
      funct7: 0x07,
      format: rType,
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
    ),
  ],
);
