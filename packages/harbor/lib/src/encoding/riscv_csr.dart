/// Standard RISC-V Control and Status Register (CSR) addresses.
///
/// Per the RISC-V Privileged Architecture specification.

/// Machine-level CSRs.
abstract final class MachineCsr {
  // Machine information
  static const mvendorid = 0xF11;
  static const marchid = 0xF12;
  static const mimpid = 0xF13;
  static const mhartid = 0xF14;
  static const mconfigptr = 0xF15;

  // Machine trap setup
  static const mstatus = 0x300;
  static const misa = 0x301;
  static const medeleg = 0x302;
  static const mideleg = 0x303;
  static const mie = 0x304;
  static const mtvec = 0x305;
  static const mcounteren = 0x306;
  static const mstatush = 0x310; // RV32 only

  // Machine trap handling
  static const mscratch = 0x340;
  static const mepc = 0x341;
  static const mcause = 0x342;
  static const mtval = 0x343;
  static const mip = 0x344;
  static const mtinst = 0x34A;
  static const mtval2 = 0x34B;

  // Machine configuration
  static const menvcfg = 0x30A;
  static const menvcfgh = 0x31A; // RV32 only
  static const mseccfg = 0x747;
  static const mseccfgh = 0x757; // RV32 only

  // Machine counters/timers
  static const mcycle = 0xB00;
  static const minstret = 0xB02;
  static const mcycleh = 0xB80; // RV32 only
  static const minstreth = 0xB82; // RV32 only

  // Machine counter setup
  static const mcountinhibit = 0x320;

  // PMP
  static const pmpcfg0 = 0x3A0;
  static const pmpcfg1 = 0x3A1; // RV32 only
  static const pmpcfg2 = 0x3A2;
  static const pmpcfg3 = 0x3A3; // RV32 only
  static const pmpaddr0 = 0x3B0;
  // ... through pmpaddr63 = 0x3EF
}

/// Supervisor-level CSRs.
abstract final class SupervisorCsr {
  // Supervisor trap setup
  static const sstatus = 0x100;
  static const sie = 0x104;
  static const stvec = 0x105;
  static const scounteren = 0x106;

  // Supervisor configuration
  static const senvcfg = 0x10A;

  // Supervisor trap handling
  static const sscratch = 0x140;
  static const sepc = 0x141;
  static const scause = 0x142;
  static const stval = 0x143;
  static const sip = 0x144;

  // Supervisor address translation
  static const satp = 0x180;
}

/// User-level CSRs.
abstract final class UserCsr {
  // User counters/timers (read-only shadows)
  static const cycle = 0xC00;
  static const time = 0xC01;
  static const instret = 0xC02;
  static const cycleh = 0xC80; // RV32 only
  static const timeh = 0xC81; // RV32 only
  static const instreth = 0xC82; // RV32 only
}

/// mstatus / sstatus field bit positions.
abstract final class StatusFields {
  static const sieBit = 1;
  static const mieBit = 3;
  static const spieBit = 5;
  static const ubeBit = 6;
  static const mpieBit = 7;
  static const sppBit = 8;
  static const mppShift = 11;
  static const mppMask = 0x3;
  static const fsBit = 13;
  static const xsBit = 15;
  static const mprvBit = 17;
  static const sumBit = 18;
  static const mxrBit = 19;
  static const tvmBit = 20;
  static const twBit = 21;
  static const tsrBit = 22;
  static const sdBit = 63; // RV64, bit 31 on RV32
}

/// misa extension bit positions (A=0, B=1, ..., Z=25).
abstract final class MisaExtension {
  static const a = 0; // Atomic
  static const b = 1; // Bit manipulation
  static const c = 2; // Compressed
  static const d = 3; // Double-precision float
  static const e = 4; // RV32E base
  static const f = 5; // Single-precision float
  static const h = 7; // Hypervisor
  static const i = 8; // Integer base
  static const m = 12; // Multiply/Divide
  static const s = 18; // Supervisor mode
  static const u = 20; // User mode
  static const v = 21; // Vector
}

/// Privilege mode encoding (used in mstatus.MPP, etc.).
abstract final class PrivilegeMode {
  static const user = 0x0;
  static const supervisor = 0x1;
  static const hypervisorReserved = 0x2;
  static const machine = 0x3;
}

/// satp / hgatp mode field values.
abstract final class SatpMode {
  static const bare = 0;
  static const sv32 = 1; // RV32 only
  static const sv39 = 8; // RV64
  static const sv48 = 9; // RV64
  static const sv57 = 10; // RV64
}
