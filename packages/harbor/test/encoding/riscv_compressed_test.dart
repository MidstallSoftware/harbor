import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

void main() {
  group('Compressed instruction detection', () {
    test('isCompressedInstruction detects compressed', () {
      expect(isCompressedInstruction(0x0000), isTrue); // C0
      expect(isCompressedInstruction(0x0001), isTrue); // C1
      expect(isCompressedInstruction(0x0002), isTrue); // C2
    });

    test('isCompressedInstruction rejects 32-bit', () {
      // Bits [1:0] == 0b11 means 32-bit instruction
      expect(isCompressedInstruction(0x0003), isFalse);
      expect(isCompressedInstruction(0x0033), isFalse); // ADD opcode
    });
  });

  group('Compressed register mapping', () {
    test('maps 3-bit to full register', () {
      expect(compressedRegFull(0), equals(8)); // x8/s0
      expect(compressedRegFull(1), equals(9)); // x9/s1
      expect(compressedRegFull(2), equals(10)); // x10/a0
      expect(compressedRegFull(7), equals(15)); // x15/a5
    });
  });

  group('CR-type format', () {
    test('struct has correct widths', () {
      expect(crType.width, equals(16));
      expect(crType['op']!.width, equals(2));
      expect(crType['rs2']!.width, equals(5));
      expect(crType['rd_rs1']!.width, equals(5));
      expect(crType['funct4']!.width, equals(4));
    });

    test('encode/decode round-trips', () {
      final encoded = crType.encode({
        'op': CompressedOp.c2,
        'rs2': 5,
        'rd_rs1': 10,
        'funct4': 0x8,
      });
      final decoded = crType.decode(encoded);
      expect(decoded['op'], equals(CompressedOp.c2));
      expect(decoded['rs2'], equals(5));
      expect(decoded['rd_rs1'], equals(10));
      expect(decoded['funct4'], equals(0x8));
    });
  });

  group('CI-type format', () {
    test('struct has correct widths', () {
      expect(ciType.width, equals(16));
      expect(ciType['imm_lo']!.width, equals(5));
      expect(ciType['imm_hi']!.width, equals(1));
      expect(ciType['rd_rs1']!.width, equals(5));
      expect(ciType['funct3']!.width, equals(3));
    });

    test('immediate reconstruction', () {
      final fields = {'imm_hi': 1, 'imm_lo': 0x1F};
      expect(ciTypeImm(fields), equals(0x3F));

      final fields2 = {'imm_hi': 0, 'imm_lo': 5};
      expect(ciTypeImm(fields2), equals(5));
    });
  });

  group('CA-type format', () {
    test('struct has correct widths', () {
      expect(caType.width, equals(16));
      expect(caType['rs2_prime']!.width, equals(3));
      expect(caType['funct2']!.width, equals(2));
      expect(caType['rd_rs1_prime']!.width, equals(3));
      expect(caType['funct6']!.width, equals(6));
    });
  });

  group('CB-type format', () {
    test('struct has correct widths', () {
      expect(cbType.width, equals(16));
      expect(cbType['offset_lo']!.width, equals(5));
      expect(cbType['rs1_prime']!.width, equals(3));
      expect(cbType['offset_hi']!.width, equals(3));
    });
  });

  group('CJ-type format', () {
    test('struct has correct widths', () {
      expect(cjType.width, equals(16));
      expect(cjType['jump_target']!.width, equals(11));
      expect(cjType['funct3']!.width, equals(3));
    });
  });

  group('Hardware view with compressed', () {
    test('creates 16-bit Logic slices', () {
      final signal = Logic(name: 'cinstr', width: 16);
      final view = crType.view(signal);

      expect(view['op'].width, equals(2));
      expect(view['rs2'].width, equals(5));
      expect(view['rd_rs1'].width, equals(5));
      expect(view['funct4'].width, equals(4));
    });
  });

  group('CompressedOp constants', () {
    test('match spec', () {
      expect(CompressedOp.c0, equals(0));
      expect(CompressedOp.c1, equals(1));
      expect(CompressedOp.c2, equals(2));
      expect(CompressedOp.notCompressed, equals(3));
    });
  });

  group('Compressed funct3 constants', () {
    test('C0 funct3 values', () {
      expect(C0Funct3.cAddi4spn, equals(0));
      expect(C0Funct3.cLw, equals(2));
      expect(C0Funct3.cSw, equals(6));
    });

    test('C1 funct3 values', () {
      expect(C1Funct3.cAddi, equals(0));
      expect(C1Funct3.cLi, equals(2));
      expect(C1Funct3.cJ, equals(5));
      expect(C1Funct3.cBeqz, equals(6));
      expect(C1Funct3.cBnez, equals(7));
    });

    test('C2 funct3 values', () {
      expect(C2Funct3.cSlli, equals(0));
      expect(C2Funct3.cLwsp, equals(2));
      expect(C2Funct3.cSwsp, equals(6));
    });
  });
}
