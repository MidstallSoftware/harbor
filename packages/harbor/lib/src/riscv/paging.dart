import 'mxlen.dart';

/// RISC-V virtual memory paging modes.
///
/// Each mode specifies the page table structure and which
/// XLEN values support it.
enum RiscVPagingMode {
  /// No virtual memory translation.
  bare(
    id: 0,
    levels: 0,
    vpnBits: 0,
    pteBytes: 0,
    ppnBits: [],
    supportedMxlens: [RiscVMxlen.rv32, RiscVMxlen.rv64, RiscVMxlen.rv128],
  ),

  /// Sv32: 2-level, 32-bit virtual addresses (RV32 only).
  sv32(
    id: 1,
    levels: 2,
    vpnBits: 10,
    pteBytes: 4,
    ppnBits: [10, 12],
    supportedMxlens: [RiscVMxlen.rv32],
  ),

  /// Sv39: 3-level, 39-bit virtual addresses (RV64/RV128).
  sv39(
    id: 8,
    levels: 3,
    vpnBits: 9,
    pteBytes: 8,
    ppnBits: [9, 9, 26],
    supportedMxlens: [RiscVMxlen.rv64, RiscVMxlen.rv128],
  ),

  /// Sv48: 4-level, 48-bit virtual addresses (RV64/RV128).
  sv48(
    id: 9,
    levels: 4,
    vpnBits: 9,
    pteBytes: 8,
    ppnBits: [9, 9, 9, 17],
    supportedMxlens: [RiscVMxlen.rv64, RiscVMxlen.rv128],
  ),

  /// Sv57: 5-level, 57-bit virtual addresses (RV64/RV128).
  sv57(
    id: 10,
    levels: 5,
    vpnBits: 9,
    pteBytes: 8,
    ppnBits: [9, 9, 9, 9, 8],
    supportedMxlens: [RiscVMxlen.rv64, RiscVMxlen.rv128],
  );

  /// satp MODE field value.
  final int id;

  /// Number of page table levels.
  final int levels;

  /// Bits per VPN segment.
  final int vpnBits;

  /// Page table entry size in bytes.
  final int pteBytes;

  /// PPN field widths per level.
  final List<int> ppnBits;

  /// Which XLEN values support this mode.
  final List<RiscVMxlen> supportedMxlens;

  const RiscVPagingMode({
    required this.id,
    required this.levels,
    required this.vpnBits,
    required this.pteBytes,
    required this.ppnBits,
    required this.supportedMxlens,
  });

  /// Whether this paging mode is supported on [mxlen].
  bool isSupported(RiscVMxlen mxlen) => supportedMxlens.contains(mxlen);

  /// Page size in bytes (always 4 KiB for RISC-V).
  int get pageSize => 4096;

  /// Total virtual address bits.
  int get virtualBits => this == bare ? 0 : 12 + levels * vpnBits;

  /// Returns all paging modes supported by [mxlen].
  static List<RiscVPagingMode> supportedBy(RiscVMxlen mxlen) =>
      values.where((m) => m.isSupported(mxlen)).toList();
}
