import 'dart:io';
import 'dart:typed_data';

/// A minimal ELF file parser for loading firmware into HarborMaskRom
/// or simulation memory.
///
/// Supports ELF32 and ELF64, little-endian and big-endian.
/// Only loads PT_LOAD segments (code and data).
///
/// ```dart
/// final elf = HarborElfLoader.fromFile(File('firmware.elf'));
/// print('Entry: 0x${elf.entryPoint.toRadixString(16)}');
/// print('Segments: ${elf.segments.length}');
///
/// // Get flat binary for a specific address range
/// final bytes = elf.toBytes(baseAddress: 0x80000000);
///
/// // Get word list for HarborMaskRom
/// final words = elf.toWords(baseAddress: 0x00000000);
/// ```
class HarborElfLoader {
  /// ELF entry point address.
  final int entryPoint;

  /// Whether this is a 64-bit ELF.
  final bool is64Bit;

  /// Whether this is little-endian.
  final bool isLittleEndian;

  /// Machine type (EM_RISCV = 243).
  final int machine;

  /// Loadable segments.
  final List<HarborElfSegment> segments;

  const HarborElfLoader({
    required this.entryPoint,
    required this.is64Bit,
    required this.isLittleEndian,
    required this.machine,
    required this.segments,
  });

  /// Parses an ELF file.
  factory HarborElfLoader.fromFile(File file) {
    final bytes = file.readAsBytesSync();
    return HarborElfLoader.fromBytes(bytes);
  }

  /// Parses ELF from raw bytes.
  factory HarborElfLoader.fromBytes(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);

    // Verify ELF magic
    if (bytes[0] != 0x7F ||
        bytes[1] != 0x45 ||
        bytes[2] != 0x4C ||
        bytes[3] != 0x46) {
      throw FormatException('Not an ELF file');
    }

    final is64 = bytes[4] == 2;
    final isLE = bytes[5] == 1;
    final endian = isLE ? Endian.little : Endian.big;

    final machine = data.getUint16(18, endian);

    int entryPoint;
    int phOff;
    int phEntSize;
    int phNum;

    if (is64) {
      entryPoint = data.getUint64(24, endian);
      phOff = data.getUint64(32, endian);
      phEntSize = data.getUint16(54, endian);
      phNum = data.getUint16(56, endian);
    } else {
      entryPoint = data.getUint32(24, endian);
      phOff = data.getUint32(28, endian);
      phEntSize = data.getUint16(42, endian);
      phNum = data.getUint16(44, endian);
    }

    final segments = <HarborElfSegment>[];
    for (var i = 0; i < phNum; i++) {
      final off = phOff + i * phEntSize;

      int pType, pOffset, pVaddr, pPaddr, pFilesz, pMemsz, pFlags;

      if (is64) {
        pType = data.getUint32(off, endian);
        pFlags = data.getUint32(off + 4, endian);
        pOffset = data.getUint64(off + 8, endian);
        pVaddr = data.getUint64(off + 16, endian);
        pPaddr = data.getUint64(off + 24, endian);
        pFilesz = data.getUint64(off + 32, endian);
        pMemsz = data.getUint64(off + 40, endian);
      } else {
        pType = data.getUint32(off, endian);
        pOffset = data.getUint32(off + 4, endian);
        pVaddr = data.getUint32(off + 8, endian);
        pPaddr = data.getUint32(off + 12, endian);
        pFilesz = data.getUint32(off + 16, endian);
        pMemsz = data.getUint32(off + 20, endian);
        pFlags = data.getUint32(off + 24, endian);
      }

      // PT_LOAD = 1
      if (pType == 1 && pFilesz > 0) {
        segments.add(
          HarborElfSegment(
            virtualAddress: pVaddr,
            physicalAddress: pPaddr,
            data: Uint8List.fromList(bytes.sublist(pOffset, pOffset + pFilesz)),
            memorySize: pMemsz,
            flags: pFlags,
          ),
        );
      }
    }

    return HarborElfLoader(
      entryPoint: entryPoint,
      is64Bit: is64,
      isLittleEndian: isLE,
      machine: machine,
      segments: segments,
    );
  }

  /// Whether this is a RISC-V ELF (EM_RISCV = 243).
  bool get isRiscV => machine == 243;

  /// Minimum physical address across all segments.
  int get minAddress =>
      segments.map((s) => s.physicalAddress).reduce((a, b) => a < b ? a : b);

  /// Maximum physical address + size across all segments.
  int get maxAddress => segments
      .map((s) => s.physicalAddress + s.memorySize)
      .reduce((a, b) => a > b ? a : b);

  /// Total size needed from min to max address.
  int get totalSize => maxAddress - minAddress;

  /// Converts loaded segments to a flat byte array.
  ///
  /// If [baseAddress] is specified, addresses are relative to it.
  /// Gaps between segments are filled with zeros.
  Uint8List toBytes({int? baseAddress}) {
    final base = baseAddress ?? minAddress;
    final size = maxAddress - base;
    final result = Uint8List(size);

    for (final seg in segments) {
      final offset = seg.physicalAddress - base;
      if (offset >= 0 && offset < size) {
        result.setRange(
          offset,
          (offset + seg.data.length).clamp(0, size),
          seg.data,
        );
      }
    }

    return result;
  }

  /// Converts loaded segments to a list of data words.
  ///
  /// Suitable for [HarborMaskRom.initialData].
  List<int> toWords({int? baseAddress, int wordSize = 4}) {
    final bytes = toBytes(baseAddress: baseAddress);
    final words = <int>[];

    for (var i = 0; i < bytes.length; i += wordSize) {
      var word = 0;
      for (var b = 0; b < wordSize && (i + b) < bytes.length; b++) {
        word |= bytes[i + b] << (b * 8);
      }
      words.add(word);
    }

    return words;
  }
}

/// A loadable segment from an ELF file.
class HarborElfSegment {
  /// Virtual address (used by the program).
  final int virtualAddress;

  /// Physical address (where to load in memory).
  final int physicalAddress;

  /// Segment data from the file.
  final Uint8List data;

  /// Total memory size (may be larger than data for BSS).
  final int memorySize;

  /// Segment flags (PF_X=1, PF_W=2, PF_R=4).
  final int flags;

  const HarborElfSegment({
    required this.virtualAddress,
    required this.physicalAddress,
    required this.data,
    required this.memorySize,
    required this.flags,
  });

  /// File size (data bytes).
  int get fileSize => data.length;

  /// Whether this segment is executable.
  bool get isExecutable => (flags & 1) != 0;

  /// Whether this segment is writable.
  bool get isWritable => (flags & 2) != 0;

  /// Whether this segment is readable.
  bool get isReadable => (flags & 4) != 0;

  @override
  String toString() =>
      'HarborElfSegment(paddr=0x${physicalAddress.toRadixString(16)}, '
      '${data.length} bytes, '
      '${isReadable ? "R" : "-"}${isWritable ? "W" : "-"}${isExecutable ? "X" : "-"})';
}
