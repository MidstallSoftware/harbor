import '../encoding/bit_struct.dart';
import 'micro_op.dart';
import 'mxlen.dart';
import 'resource.dart';

/// How an instruction should be executed.
enum RiscVExecutionMode {
  /// Implemented directly in hardware (combinational/pipelined).
  hardcoded,

  /// Executed via a microcode sequencer stepping through [RiscVMicroOp]s.
  microcoded,

  /// Both: a hard-coded fast path exists alongside a microcode
  /// fallback. The CPU chooses which to use.
  parallel,
}

/// A single RISC-V instruction definition.
///
/// Declarative and const - describes everything the framework
/// needs to know about an instruction: its encoding, what
/// resources it uses, how it executes, and which XLEN values
/// it's valid for.
///
/// ```dart
/// const add = RiscVOperation(
///   mnemonic: 'add',
///   opcode: 0x33,
///   funct3: 0x0,
///   funct7: 0x00,
///   format: rType,
///   resources: [
///     RfResource(intReg32, rs1),
///     RfResource(intReg32, rs2),
///     RfResource(intReg32, rd),
///   ],
///   microcode: [
///     RiscVReadRegister(RiscVMicroOpField.rs1),
///     RiscVReadRegister(RiscVMicroOpField.rs2),
///     RiscVAlu(RiscVAluFunct.add, RiscVMicroOpField.rs1, RiscVMicroOpField.rs2),
///     RiscVWriteRegister(RiscVMicroOpField.rd, RiscVMicroOpSource.alu),
///     RiscVUpdatePc(RiscVMicroOpField.pc, offset: 4),
///   ],
/// );
/// ```
class RiscVOperation {
  /// Human-readable mnemonic (e.g., `'add'`, `'lw'`, `'beq'`).
  final String mnemonic;

  /// Major opcode (bits 6:0).
  final int opcode;

  /// funct3 field (bits 14:12), if used.
  final int? funct3;

  /// funct7 field (bits 31:25), if used.
  final int? funct7;

  /// funct2 field, if used (e.g., some FP instructions).
  final int? funct2;

  /// Instruction format (HarborBitStruct for field extraction).
  final HarborBitStruct format;

  /// Resources this instruction uses (registers, memory, CSR, etc.).
  final List<Resource> resources;

  /// Micro-operation sequence for execution.
  final List<RiscVMicroOp> microcode;

  /// How this instruction should be executed.
  final RiscVExecutionMode executionMode;

  /// Which XLEN values this instruction is valid for.
  ///
  /// `null` means valid for all XLEN values.
  /// `{RiscVMxlen.rv64, RiscVMxlen.rv128}` means only 64/128-bit.
  final Set<RiscVMxlen>? xlenConstraint;

  /// Minimum privilege level required (0=U, 1=S, 3=M).
  /// `null` means any privilege level.
  final int? privilegeLevel;

  const RiscVOperation({
    required this.mnemonic,
    required this.opcode,
    this.funct3,
    this.funct7,
    this.funct2,
    required this.format,
    this.resources = const [],
    this.microcode = const [],
    this.executionMode = RiscVExecutionMode.microcoded,
    this.xlenConstraint,
    this.privilegeLevel,
  });

  /// Whether this instruction is valid for the given [mxlen].
  bool isValidFor(RiscVMxlen mxlen) =>
      xlenConstraint == null || xlenConstraint!.contains(mxlen);

  /// Whether this operation matches the given opcode/funct fields.
  bool matches(int opcode, int? funct3, int? funct7) {
    if (this.opcode != opcode) return false;
    if (this.funct3 != null && this.funct3 != funct3) return false;
    if (this.funct7 != null && this.funct7 != funct7) return false;
    return true;
  }

  @override
  String toString() => 'RiscVOperation($mnemonic)';
}
