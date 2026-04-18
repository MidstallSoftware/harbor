import 'dart:typed_data';

import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborElfSegment', () {
    test('flags', () {
      final seg = HarborElfSegment(
        virtualAddress: 0x80000000,
        physicalAddress: 0x80000000,
        data: Uint8List(0),
        memorySize: 0,
        flags: 5, // PF_R | PF_X
      );
      expect(seg.isReadable, isTrue);
      expect(seg.isExecutable, isTrue);
      expect(seg.isWritable, isFalse);
    });

    test('fileSize', () {
      final seg = HarborElfSegment(
        virtualAddress: 0,
        physicalAddress: 0,
        data: Uint8List.fromList([1, 2, 3, 4]),
        memorySize: 8,
        flags: 7,
      );
      expect(seg.fileSize, equals(4));
      expect(seg.memorySize, equals(8));
    });

    test('toString', () {
      final seg = HarborElfSegment(
        virtualAddress: 0x80000000,
        physicalAddress: 0x80000000,
        data: Uint8List(16),
        memorySize: 16,
        flags: 5,
      );
      expect(seg.toString(), contains('0x80000000'));
      expect(seg.toString(), contains('R-X'));
    });
  });

  group('HarborElfLoader', () {
    // We can't easily test with real ELF files in unit tests,
    // but we can test the helper methods and edge cases.

    test('toWords converts bytes to words', () {
      // Create a minimal mock-like HarborElfLoader
      final loader = HarborElfLoader(
        entryPoint: 0x80000000,
        is64Bit: false,
        isLittleEndian: true,
        machine: 243, // RISC-V
        segments: [
          HarborElfSegment(
            virtualAddress: 0x80000000,
            physicalAddress: 0x80000000,
            data: Uint8List.fromList([
              0x33, 0x00, 0x00, 0x00, // word 0
              0x13, 0x00, 0x00, 0x00, // word 1
            ]),
            memorySize: 8,
            flags: 5,
          ),
        ],
      );

      expect(loader.isRiscV, isTrue);
      expect(loader.entryPoint, equals(0x80000000));
      expect(loader.minAddress, equals(0x80000000));
      expect(loader.maxAddress, equals(0x80000008));
      expect(loader.totalSize, equals(8));

      final words = loader.toWords();
      expect(words, hasLength(2));
      expect(words[0], equals(0x00000033));
      expect(words[1], equals(0x00000013));
    });

    test('toBytes flattens segments', () {
      final loader = HarborElfLoader(
        entryPoint: 0x1000,
        is64Bit: false,
        isLittleEndian: true,
        machine: 243,
        segments: [
          HarborElfSegment(
            virtualAddress: 0x1000,
            physicalAddress: 0x1000,
            data: Uint8List.fromList([0xAA, 0xBB, 0xCC, 0xDD]),
            memorySize: 4,
            flags: 5,
          ),
        ],
      );

      final bytes = loader.toBytes();
      expect(bytes, hasLength(4));
      expect(bytes[0], equals(0xAA));
      expect(bytes[3], equals(0xDD));
    });

    test('toBytes with custom base address', () {
      final loader = HarborElfLoader(
        entryPoint: 0x2000,
        is64Bit: false,
        isLittleEndian: true,
        machine: 243,
        segments: [
          HarborElfSegment(
            virtualAddress: 0x2000,
            physicalAddress: 0x2000,
            data: Uint8List.fromList([0x11, 0x22]),
            memorySize: 2,
            flags: 5,
          ),
        ],
      );

      final bytes = loader.toBytes(baseAddress: 0x2000);
      expect(bytes, hasLength(2));
      expect(bytes[0], equals(0x11));
    });

    test('multiple segments', () {
      final loader = HarborElfLoader(
        entryPoint: 0x1000,
        is64Bit: true,
        isLittleEndian: true,
        machine: 243,
        segments: [
          HarborElfSegment(
            virtualAddress: 0x1000,
            physicalAddress: 0x1000,
            data: Uint8List.fromList([0xAA, 0xBB]),
            memorySize: 2,
            flags: 5, // R-X
          ),
          HarborElfSegment(
            virtualAddress: 0x2000,
            physicalAddress: 0x2000,
            data: Uint8List.fromList([0xCC, 0xDD]),
            memorySize: 2,
            flags: 6, // RW-
          ),
        ],
      );

      expect(loader.is64Bit, isTrue);
      expect(loader.segments, hasLength(2));
      expect(loader.minAddress, equals(0x1000));
      expect(loader.maxAddress, equals(0x2002));
    });

    test('invalid ELF magic throws', () {
      expect(
        () => HarborElfLoader.fromBytes(Uint8List.fromList([0, 0, 0, 0])),
        throwsFormatException,
      );
    });
  });
}
