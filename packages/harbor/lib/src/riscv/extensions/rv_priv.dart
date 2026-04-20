import '../../encoding/riscv_formats.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../operation.dart';

final rvPriv = RiscVExtension(
  name: 'Priv',
  key: null,
  misaBit: null,
  operations: [
    RiscVOperation(
      mnemonic: 'sret',
      opcode: RiscvOpcode.system,
      funct7: 0x08,
      format: rType,
      privilegeLevel: 1,
      microcode: [RiscVReturnOp(1)],
    ),
    RiscVOperation(
      mnemonic: 'mret',
      opcode: RiscvOpcode.system,
      funct7: 0x18,
      format: rType,
      privilegeLevel: 3,
      microcode: [RiscVReturnOp(3)],
    ),
    RiscVOperation(
      mnemonic: 'wfi',
      opcode: RiscvOpcode.system,
      funct7: 0x08,
      funct3: 0,
      format: rType,
      microcode: [RiscVWaitForInterrupt()],
    ),
  ],
);
