import '../riscv/mxlen.dart';
import '../riscv/paging.dart';
import '../util/pretty_string.dart';

/// TLB (Translation Lookaside Buffer) level configuration.
class HarborTlbLevel with HarborPrettyString {
  /// Level index (0 = fastest/smallest).
  final int level;

  /// Number of entries.
  final int entries;

  /// Number of ways (associativity). 0 = fully associative.
  final int ways;

  const HarborTlbLevel({
    required this.level,
    required this.entries,
    this.ways = 0,
  });

  /// Whether this is fully associative.
  bool get isFullyAssociative => ways == 0;

  @override
  String toString() =>
      'HarborTlbLevel($level, $entries entries'
      '${ways > 0 ? ", $ways-way" : ", fully-assoc"})';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final c = options.childPrefix;
    final buf = StringBuffer('${p}HarborTlbLevel(\n');
    buf.writeln('${c}level: $level,');
    buf.writeln('${c}entries: $entries,');
    buf.writeln(
      '${c}associativity: ${isFullyAssociative ? "fully" : "$ways-way"},',
    );
    buf.write('$p)');
    return buf.toString();
  }
}

/// PMP (Physical Memory Protection) configuration.
class HarborPmpConfig with HarborPrettyString {
  /// Number of PMP entries (0, 16, or 64).
  final int entries;

  /// PMP granularity in bytes (minimum 4).
  final int granularity;

  /// Whether TOR (Top of Range) matching is supported.
  final bool withTor;

  /// Whether NAPOT (Naturally Aligned Power-of-Two) matching is supported.
  final bool withNapot;

  const HarborPmpConfig({
    this.entries = 16,
    this.granularity = 4,
    this.withTor = true,
    this.withNapot = true,
  });

  /// No PMP.
  static const none = HarborPmpConfig(entries: 0);

  @override
  String toString() =>
      'HarborPmpConfig($entries entries, ${granularity}B gran)';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final c = options.childPrefix;
    final buf = StringBuffer('${p}HarborPmpConfig(\n');
    buf.writeln('${c}entries: $entries,');
    buf.writeln('${c}granularity: $granularity bytes,');
    if (withTor) buf.writeln('${c}TOR matching,');
    if (withNapot) buf.writeln('${c}NAPOT matching,');
    buf.write('$p)');
    return buf.toString();
  }
}

/// Physical Memory Attribute type.
///
/// Defines the memory type for a physical address region,
/// controlling cacheability and ordering behavior.
enum HarborPmaMemoryType {
  /// Regular cacheable memory (DRAM, SRAM).
  ///
  /// Supports speculative access, caching, and merging of stores.
  memory,

  /// I/O device registers (uncacheable, strongly ordered).
  ///
  /// No speculative access, no caching, no store merging.
  /// Accesses must be exactly as programmed (width, count).
  io,

  /// Empty/vacant region (access causes access fault).
  empty,
}

/// Physical Memory Attribute ordering model.
enum HarborPmaOrdering {
  /// No ordering constraints (for cacheable memory).
  relaxed,

  /// Channel ordering only (for well-behaved devices).
  channel,

  /// Strongly ordered (for legacy MMIO devices).
  ///
  /// All accesses are serialized and performed in program order.
  strong,
}

/// Configures Physical Memory Attributes (PMA) for an address region.
///
/// PMAs are properties of the physical memory system, not of the
/// virtual address space. They describe how the hardware must
/// handle accesses to different physical address regions.
///
/// Unlike PMP (which is per-hart and software-configured), PMAs
/// are typically fixed by the platform/SoC design.
class HarborPmaRegion with HarborPrettyString {
  /// Start address of the region (inclusive).
  final int start;

  /// Size of the region in bytes.
  final int size;

  /// Memory type (cacheable memory vs I/O).
  final HarborPmaMemoryType memoryType;

  /// Ordering model.
  final HarborPmaOrdering ordering;

  /// Whether instruction fetch is allowed.
  final bool executable;

  /// Whether reads are allowed.
  final bool readable;

  /// Whether writes are allowed.
  final bool writable;

  /// Whether atomic operations (LR/SC/AMO) are supported.
  final bool atomicSupport;

  /// Whether misaligned accesses are supported in hardware.
  final bool misalignedSupport;

  /// Supported access widths in bytes (e.g., 1, 2, 4, 8).
  final List<int> accessWidths;

  /// Whether this region is idempotent (reads return same value,
  /// writes can be repeated without side effects).
  final bool idempotent;

  const HarborPmaRegion({
    required this.start,
    required this.size,
    this.memoryType = HarborPmaMemoryType.memory,
    this.ordering = HarborPmaOrdering.relaxed,
    this.executable = true,
    this.readable = true,
    this.writable = true,
    this.atomicSupport = true,
    this.misalignedSupport = true,
    this.accessWidths = const [1, 2, 4, 8],
    this.idempotent = true,
  });

  /// Convenience constructor for a main memory region (DRAM/SRAM).
  const HarborPmaRegion.memory({required this.start, required this.size})
    : memoryType = HarborPmaMemoryType.memory,
      ordering = HarborPmaOrdering.relaxed,
      executable = true,
      readable = true,
      writable = true,
      atomicSupport = true,
      misalignedSupport = true,
      accessWidths = const [1, 2, 4, 8],
      idempotent = true;

  /// Convenience constructor for an I/O device region.
  const HarborPmaRegion.io({
    required this.start,
    required this.size,
    this.writable = true,
    this.accessWidths = const [4],
  }) : memoryType = HarborPmaMemoryType.io,
       ordering = HarborPmaOrdering.strong,
       executable = false,
       readable = true,
       atomicSupport = false,
       misalignedSupport = false,
       idempotent = false;

  /// End address (exclusive).
  int get end => start + size;

  /// Whether [addr] falls within this region.
  bool contains(int addr) => addr >= start && addr < end;

  @override
  String toString() =>
      'HarborPmaRegion(0x${start.toRadixString(16)}, '
      '${size ~/ 1024}K, ${memoryType.name})';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final c = options.childPrefix;
    final buf = StringBuffer('${p}HarborPmaRegion(\n');
    buf.writeln(
      '${c}range: 0x${start.toRadixString(16)} - '
      '0x${end.toRadixString(16)},',
    );
    buf.writeln('${c}type: ${memoryType.name},');
    buf.writeln('${c}ordering: ${ordering.name},');
    final perms = <String>[
      if (readable) 'R',
      if (writable) 'W',
      if (executable) 'X',
      if (atomicSupport) 'A',
    ];
    buf.writeln('${c}perms: ${perms.join("")},');
    buf.writeln('${c}widths: ${accessWidths.join(", ")} bytes,');
    if (idempotent) buf.writeln('${c}idempotent,');
    if (misalignedSupport) buf.writeln('${c}misaligned OK,');
    buf.write('$p)');
    return buf.toString();
  }
}

/// PMA configuration for the entire physical address space.
///
/// Defines the set of PMA regions. Addresses not covered by any
/// region are treated as [HarborPmaMemoryType.empty] (access fault).
class HarborPmaConfig with HarborPrettyString {
  /// PMA regions, ordered by start address.
  final List<HarborPmaRegion> regions;

  const HarborPmaConfig({this.regions = const []});

  /// Look up the PMA region for a physical address.
  /// Returns null if the address is in an empty/vacant region.
  HarborPmaRegion? lookup(int addr) {
    for (final r in regions) {
      if (r.contains(addr)) return r;
    }
    return null;
  }

  /// Validate that no regions overlap. Returns error messages.
  List<String> validate() {
    final errors = <String>[];
    for (var i = 0; i < regions.length; i++) {
      for (var j = i + 1; j < regions.length; j++) {
        final a = regions[i];
        final b = regions[j];
        if (a.start < b.end && b.start < a.end) {
          errors.add('PMA overlap: $a and $b');
        }
      }
    }
    return errors;
  }

  @override
  String toString() => 'HarborPmaConfig(${regions.length} regions)';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final buf = StringBuffer('${p}HarborPmaConfig(\n');
    for (final r in regions) {
      buf.writeln(r.toPrettyString(options.nested()));
    }
    buf.write('$p)');
    return buf.toString();
  }
}

/// MMU port timing configuration.
///
/// Controls at which pipeline stages TLB reads, hits, and responses
/// occur. This lets the CPU implementation tune the MMU to its
/// pipeline depth.
class HarborMmuPortTiming {
  /// Stage at which TLB is read.
  final int readAt;

  /// Stage at which TLB hit is determined.
  final int hitsAt;

  /// Stage at which control decisions are made.
  final int ctrlAt;

  /// Stage at which the response is available.
  final int rspAt;

  const HarborMmuPortTiming({
    this.readAt = 0,
    this.hitsAt = 0,
    this.ctrlAt = 1,
    this.rspAt = 1,
  });
}

/// Complete MMU configuration.
///
/// Combines paging mode support, TLB levels, PMP, and feature
/// flags into a single configuration object.
///
/// ```dart
/// final mmu = HarborMmuConfig(
///   mxlen: RiscVMxlen.rv64,
///   pagingModes: [RiscVPagingMode.bare, RiscVPagingMode.sv39, RiscVPagingMode.sv48],
///   tlbLevels: [
///     HarborTlbLevel(level: 0, entries: 32, ways: 4),
///     HarborTlbLevel(level: 1, entries: 16, ways: 2),
///   ],
///   pmp: HarborPmpConfig(entries: 16),
///   hasSupervisorUserMemory: true,
///   hasMakeExecutableReadable: true,
/// );
/// ```
class HarborMmuConfig with HarborPrettyString {
  /// Base integer width.
  final RiscVMxlen mxlen;

  /// Supported paging modes.
  final List<RiscVPagingMode> pagingModes;

  /// TLB levels (from fastest/smallest to slowest/largest).
  final List<HarborTlbLevel> tlbLevels;

  /// PMP configuration.
  final HarborPmpConfig pmp;

  /// Fetch port timing.
  final HarborMmuPortTiming fetchTiming;

  /// Load/store port timing.
  final HarborMmuPortTiming lsuTiming;

  /// Whether the SUM (Supervisor User Memory) bit is supported.
  ///
  /// When set, supervisor mode can access user-mode pages.
  final bool hasSupervisorUserMemory;

  /// Whether the MXR (Make eXecutable Readable) bit is supported.
  ///
  /// When set, loads from executable pages are permitted.
  final bool hasMakeExecutableReadable;

  /// Whether hardware A/D (Accessed/Dirty) bit updates are supported.
  ///
  /// When false, A/D bit updates cause page faults for software handling.
  final bool hasHardwareAdBits;

  /// Whether NAPOT translation contiguity is supported (Svnapot).
  final bool hasNapotContiguity;

  /// Whether page-based memory types are supported (Svpbmt).
  final bool hasPageBasedMemoryTypes;

  /// Physical Memory Attributes configuration.
  final HarborPmaConfig pma;

  const HarborMmuConfig({
    required this.mxlen,
    this.pagingModes = const [RiscVPagingMode.bare],
    this.tlbLevels = const [],
    this.pmp = HarborPmpConfig.none,
    this.pma = const HarborPmaConfig(),
    this.fetchTiming = const HarborMmuPortTiming(),
    this.lsuTiming = const HarborMmuPortTiming(),
    this.hasSupervisorUserMemory = false,
    this.hasMakeExecutableReadable = false,
    this.hasHardwareAdBits = false,
    this.hasNapotContiguity = false,
    this.hasPageBasedMemoryTypes = false,
  });

  /// Whether paging is enabled (any mode beyond bare).
  bool get hasPaging => pagingModes.any((m) => m != RiscVPagingMode.bare);

  /// Maximum supported page table depth.
  int get maxPageTableLevels {
    var max = 0;
    for (final mode in pagingModes) {
      if (mode.levels > max) max = mode.levels;
    }
    return max;
  }

  /// Physical address width based on mxlen and paging.
  int get physicalAddressWidth => mxlen.size;

  /// Virtual address width (from the largest paging mode).
  int get virtualAddressWidth {
    var max = mxlen.size;
    for (final mode in pagingModes) {
      if (mode.virtualBits > 0 && mode.virtualBits < max) {
        max = mode.virtualBits;
      }
    }
    return max;
  }

  @override
  String toString() =>
      'HarborMmuConfig(${mxlen}, paging: ${pagingModes.map((m) => m.name).join("/")})';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final c = options.childPrefix;
    final buf = StringBuffer('${p}HarborMmuConfig(\n');
    buf.writeln('${c}mxlen: $mxlen,');
    buf.writeln('${c}paging: ${pagingModes.map((m) => m.name).join(", ")},');
    if (tlbLevels.isNotEmpty) {
      buf.writeln('${c}TLB:');
      for (final level in tlbLevels) {
        buf.writeln(level.toPrettyString(options.nested()));
      }
    }
    if (pmp.entries > 0) {
      buf.writeln('${c}PMP:');
      buf.writeln(pmp.toPrettyString(options.nested()));
    }
    if (pma.regions.isNotEmpty) {
      buf.writeln('${c}PMA:');
      buf.writeln(pma.toPrettyString(options.nested()));
    }
    final features = <String>[
      if (hasSupervisorUserMemory) 'SUM',
      if (hasMakeExecutableReadable) 'MXR',
      if (hasHardwareAdBits) 'Svadu',
      if (hasNapotContiguity) 'Svnapot',
      if (hasPageBasedMemoryTypes) 'Svpbmt',
    ];
    if (features.isNotEmpty) {
      buf.writeln('${c}features: ${features.join(", ")},');
    }
    buf.write('$p)');
    return buf.toString();
  }
}
