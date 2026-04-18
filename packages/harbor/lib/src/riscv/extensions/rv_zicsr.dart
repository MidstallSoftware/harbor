import '../../encoding/riscv_formats.dart';
import '../extension.dart';
import '../micro_op.dart';
import '../operation.dart';
import '../resource.dart';

const _int = RiscVIntRegFile(32);

RiscVOperation _csr(String mnemonic, int funct3, {bool isImm = false}) =>
    RiscVOperation(
      mnemonic: mnemonic,
      opcode: RiscvOpcode.system,
      funct3: funct3,
      format: iType,
      resources: [
        if (!isImm) RfResource(_int, rs1),
        RfResource(_int, rd),
        CsrResource(),
      ],
      microcode: [
        if (!isImm) RiscVReadRegister(RiscVMicroOpField.rs1),
        RiscVReadCsr(RiscVMicroOpField.imm),
        RiscVWriteCsr(
          RiscVMicroOpField.imm,
          isImm ? RiscVMicroOpSource.imm : RiscVMicroOpSource.rs1,
        ),
        RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.rd),
        RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
      ],
    );

/// Zicsr - CSR instructions.
final rvZicsr = RiscVExtension(
  name: 'Zicsr',
  key: null,
  misaBit: null,
  operations: [
    _csr('csrrw', CsrFunct3.csrrw),
    _csr('csrrs', CsrFunct3.csrrs),
    _csr('csrrc', CsrFunct3.csrrc),
    _csr('csrrwi', CsrFunct3.csrrwi, isImm: true),
    _csr('csrrsi', CsrFunct3.csrrsi, isImm: true),
    _csr('csrrci', CsrFunct3.csrrci, isImm: true),
  ],
);
