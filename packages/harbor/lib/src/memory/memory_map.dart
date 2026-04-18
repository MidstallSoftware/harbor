import '../bus/bus.dart';
import '../util/pretty_string.dart';

/// Memory region attributes.
class HarborMemoryRegion with HarborPrettyString {
  /// Region name.
  final String name;

  /// Address range.
  final BusAddressRange range;

  /// Whether this region is main memory (cacheable).
  final bool isMain;

  /// Whether code can be executed from this region.
  final bool isExecutable;

  /// Whether this region is readable.
  final bool isReadable;

  /// Whether this region is writable.
  final bool isWritable;

  /// Whether this region supports atomic operations.
  final bool isAtomic;

  /// Whether accesses to this region are cacheable.
  final bool isCacheable;

  /// Whether accesses must be naturally aligned.
  final bool requiresAlignment;

  const HarborMemoryRegion({
    required this.name,
    required this.range,
    this.isMain = true,
    this.isExecutable = true,
    this.isReadable = true,
    this.isWritable = true,
    this.isAtomic = true,
    this.isCacheable = true,
    this.requiresAlignment = false,
  });

  /// IO region (non-cacheable, non-main).
  const HarborMemoryRegion.io({
    required this.name,
    required this.range,
    this.isExecutable = false,
    this.isReadable = true,
    this.isWritable = true,
  }) : isMain = false,
       isAtomic = false,
       isCacheable = false,
       requiresAlignment = false;

  /// ROM region (read-only, executable).
  const HarborMemoryRegion.rom({required this.name, required this.range})
    : isMain = true,
      isExecutable = true,
      isReadable = true,
      isWritable = false,
      isAtomic = false,
      isCacheable = true,
      requiresAlignment = false;

  /// Whether [addr] falls within this region.
  bool contains(int addr) => range.contains(addr);

  @override
  String toString() => 'HarborMemoryRegion($name, $range)';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final c = options.childPrefix;
    final buf = StringBuffer('${p}HarborMemoryRegion(\n');
    buf.writeln('${c}name: $name,');
    buf.writeln(
      '${c}range: 0x${range.start.toRadixString(16)}'
      ' - 0x${range.end.toRadixString(16)}'
      ' (${range.size ~/ 1024} KB),',
    );
    final flags = <String>[
      if (isMain) 'main',
      if (isExecutable) 'exec',
      if (isReadable) 'read',
      if (isWritable) 'write',
      if (isAtomic) 'atomic',
      if (isCacheable) 'cacheable',
    ];
    buf.writeln('${c}flags: ${flags.join(", ")},');
    buf.write('$p)');
    return buf.toString();
  }
}

/// A complete memory map for a SoC.
///
/// Defines all memory regions with their attributes. Used by the
/// MMU, PMP, and cache subsystems.
class HarborMemoryMap with HarborPrettyString {
  /// All memory regions, ordered by start address.
  final List<HarborMemoryRegion> regions;

  const HarborMemoryMap(this.regions);

  /// Finds the region containing [addr].
  HarborMemoryRegion? findRegion(int addr) {
    for (final region in regions) {
      if (region.contains(addr)) return region;
    }
    return null;
  }

  /// All main memory regions.
  List<HarborMemoryRegion> get mainRegions =>
      regions.where((r) => r.isMain).toList();

  /// All IO regions.
  List<HarborMemoryRegion> get ioRegions =>
      regions.where((r) => !r.isMain).toList();

  /// Validates the memory map for overlaps.
  List<String> validate() {
    final errors = <String>[];
    for (var i = 0; i < regions.length; i++) {
      for (var j = i + 1; j < regions.length; j++) {
        final a = regions[i].range;
        final b = regions[j].range;
        if (a.start < b.end && b.start < a.end) {
          errors.add(
            'Overlap: ${regions[i].name} ($a) and '
            '${regions[j].name} ($b)',
          );
        }
      }
    }
    return errors;
  }

  @override
  String toString() => 'HarborMemoryMap(${regions.length} regions)';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final buf = StringBuffer('${p}HarborMemoryMap(\n');
    for (final region in regions) {
      buf.writeln(region.toPrettyString(options.nested()));
    }
    buf.write('$p)');
    return buf.toString();
  }
}
