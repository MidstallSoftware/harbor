/// Resources that RISC-V instructions use.
///
/// Each [RiscVOperation] declares its resources so the framework can
/// derive hazard detection, pipeline scheduling, and register
/// file port requirements.

/// A register file specification.
///
/// Defines the properties of a logical register file (integer,
/// float, vector).
abstract class RiscVRegfileSpec {
  /// Number of architectural registers.
  int get archSize;

  /// Width of each register in bits (may depend on XLEN/VLEN).
  int get width;

  /// Whether register 0 is hardwired to zero.
  bool get x0AlwaysZero;

  /// Human-readable name.
  String get name;

  const RiscVRegfileSpec();
}

/// The standard RISC-V integer register file (x0-x31).
class RiscVIntRegFile extends RiscVRegfileSpec {
  @override
  final int width;

  @override
  int get archSize => 32;

  @override
  bool get x0AlwaysZero => true;

  @override
  String get name => 'INT';

  const RiscVIntRegFile(this.width);
}

/// The RISC-V floating-point register file (f0-f31).
class RiscVFloatRegFile extends RiscVRegfileSpec {
  @override
  final int width; // 32 for F, 64 for D

  @override
  int get archSize => 32;

  @override
  bool get x0AlwaysZero => false;

  @override
  String get name => 'FP';

  const RiscVFloatRegFile(this.width);
}

/// The RISC-V vector register file (v0-v31).
class RiscVVectorRegFile extends RiscVRegfileSpec {
  @override
  final int width; // VLEN

  @override
  int get archSize => 32;

  @override
  bool get x0AlwaysZero => false;

  @override
  String get name => 'VEC';

  const RiscVVectorRegFile(this.width);
}

/// Base class for register file access types.
sealed class RiscVRfAccess {
  const RiscVRfAccess();
}

/// A register read access.
class RfRead extends RiscVRfAccess {
  final String name;
  const RfRead(this.name);

  @override
  String toString() => name;
}

/// A register write access.
class RfWrite extends RiscVRfAccess {
  final String name;
  const RfWrite(this.name);

  @override
  String toString() => name;
}

/// Standard register read ports.
const rs1 = RfRead('RS1');
const rs2 = RfRead('RS2');
const rs3 = RfRead('RS3');

/// Standard register write port.
const rd = RfWrite('RD');

/// A resource that an instruction uses.
///
/// Resources are declared per-[RiscVOperation] and used by the framework
/// for hazard detection and pipeline scheduling.
sealed class Resource {
  const Resource();
}

/// Register file resource: an instruction reads or writes a register.
class RfResource extends Resource {
  /// Which register file.
  final RiscVRegfileSpec regfile;

  /// Which access (RS1, RS2, RD, etc.).
  final RiscVRfAccess access;

  const RfResource(this.regfile, this.access);

  @override
  String toString() => 'Rf(${regfile.name}, $access)';
}

/// Memory resource: the instruction performs a load or store.
class MemoryResource extends Resource {
  /// Whether this is a load (true) or store (false).
  final bool isLoad;

  const MemoryResource({required this.isLoad});
  const MemoryResource.load() : isLoad = true;
  const MemoryResource.store() : isLoad = false;

  @override
  String toString() => isLoad ? 'LQ' : 'SQ';
}

/// CSR resource: the instruction reads or writes a CSR.
class CsrResource extends Resource {
  const CsrResource();

  @override
  String toString() => 'CSR';
}

/// PC resource: the instruction reads the program counter.
class PcResource extends Resource {
  const PcResource();

  @override
  String toString() => 'PC_READ';
}

/// FPU resource: the instruction uses the floating-point unit.
class FpuResource extends Resource {
  const FpuResource();

  @override
  String toString() => 'FPU';
}

/// Vector resource: the instruction uses the vector unit.
class VectorResource extends Resource {
  const VectorResource();

  @override
  String toString() => 'VEC';
}
