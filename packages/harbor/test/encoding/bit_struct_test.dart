import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

void main() {
  group('HarborBitRange', () {
    test('width', () {
      expect(const HarborBitRange(0, 6).width, equals(7));
      expect(const HarborBitRange(7, 11).width, equals(5));
      expect(const HarborBitRange.single(5).width, equals(1));
    });

    test('encode/decode', () {
      const range = HarborBitRange(7, 11);
      expect(range.decode(0x00000F80), equals(0x1F));
      expect(range.encode(5), equals(5 << 7));
    });

    test('mask', () {
      expect(const HarborBitRange(0, 6).mask, equals(0x7F));
      expect(const HarborBitRange(0, 31).mask, equals(0xFFFFFFFF));
    });
  });

  group('HarborBitStruct', () {
    test('encode/decode R-type instruction', () {
      // ADD x1, x2, x3 = 0x003100B3
      // funct7=0x00, rs2=3, rs1=2, funct3=0, rd=1, opcode=0x33
      final encoded = rType.encode({
        'opcode': 0x33,
        'rd': 1,
        'funct3': 0,
        'rs1': 2,
        'rs2': 3,
        'funct7': 0,
      });

      expect(encoded, equals(0x003100B3));

      final decoded = rType.decode(encoded);
      expect(decoded['opcode'], equals(0x33));
      expect(decoded['rd'], equals(1));
      expect(decoded['rs1'], equals(2));
      expect(decoded['rs2'], equals(3));
      expect(decoded['funct3'], equals(0));
      expect(decoded['funct7'], equals(0));
    });

    test('width', () {
      expect(rType.width, equals(32));
      expect(iType.width, equals(32));
    });

    test('getField / setField', () {
      const value = 0x003100B3; // ADD x1, x2, x3
      expect(rType.getField(value, 'opcode'), equals(0x33));
      expect(rType.getField(value, 'rd'), equals(1));

      final modified = rType.setField(value, 'rd', 5);
      expect(rType.getField(modified, 'rd'), equals(5));
      expect(rType.getField(modified, 'opcode'), equals(0x33)); // unchanged
    });

    test('field access throws on unknown field', () {
      expect(() => rType.getField(0, 'bogus'), throwsArgumentError);
    });

    test('operator []', () {
      expect(rType['opcode'], equals(const HarborBitRange(0, 6)));
      expect(rType['nonexistent'], isNull);
    });

    test('toPrettyString', () {
      final pretty = rType.toPrettyString();
      expect(pretty, contains('HarborBitStruct('));
      expect(pretty, contains('opcode:'));
      expect(pretty, contains('rd:'));
      expect(pretty, contains('7 bits'));
    });
  });

  group('HarborBitStructView (hardware)', () {
    test('creates Logic slices for fields', () {
      final signal = Logic(name: 'instruction', width: 32);
      final view = rType.view(signal);

      expect(view['opcode'].width, equals(7));
      expect(view['rd'].width, equals(5));
      expect(view['funct3'].width, equals(3));
      expect(view['rs1'].width, equals(5));
      expect(view['rs2'].width, equals(5));
      expect(view['funct7'].width, equals(7));
    });

    test('caches slices', () {
      final signal = Logic(name: 'instr', width: 32);
      final view = rType.view(signal);

      expect(identical(view['rd'], view['rd']), isTrue);
    });

    test('has() checks field existence', () {
      final signal = Logic(name: 'instr', width: 32);
      final view = rType.view(signal);

      expect(view.has('opcode'), isTrue);
      expect(view.has('bogus'), isFalse);
    });

    test('all returns map of all slices', () {
      final signal = Logic(name: 'instr', width: 32);
      final view = rType.view(signal);
      final all = view.all;

      expect(all, hasLength(6));
      expect(
        all.keys,
        containsAll(['opcode', 'rd', 'funct3', 'rs1', 'rs2', 'funct7']),
      );
    });

    test('throws on signal too narrow', () {
      final signal = Logic(name: 'narrow', width: 16);
      expect(() => rType.view(signal), throwsArgumentError);
    });

    test('throws on unknown field access', () {
      final signal = Logic(name: 'instr', width: 32);
      final view = rType.view(signal);
      expect(() => view['nonexistent'], throwsArgumentError);
    });
  });

  group('RISC-V instruction formats', () {
    test('I-type decode', () {
      // ADDI x1, x2, 42
      final encoded = iType.encode({
        'opcode': RiscvOpcode.opImm,
        'rd': 1,
        'funct3': AluImmFunct3.addi,
        'rs1': 2,
        'imm': 42,
      });

      final decoded = iType.decode(encoded);
      expect(decoded['opcode'], equals(RiscvOpcode.opImm));
      expect(decoded['rd'], equals(1));
      expect(decoded['rs1'], equals(2));
      expect(decoded['imm'], equals(42));
    });

    test('U-type decode', () {
      // LUI x5, 0x12345
      final encoded = uType.encode({
        'opcode': RiscvOpcode.lui,
        'rd': 5,
        'imm': 0x12345,
      });

      final decoded = uType.decode(encoded);
      expect(decoded['opcode'], equals(RiscvOpcode.lui));
      expect(decoded['rd'], equals(5));
      expect(decoded['imm'], equals(0x12345));
    });

    test('S-type immediate reconstruction', () {
      final fields = {'immLo': 0x08, 'immHi': 0x01};
      expect(sTypeImm(fields), equals(0x28));
    });

    test('opcode constants match spec', () {
      expect(RiscvOpcode.lui, equals(0x37));
      expect(RiscvOpcode.auipc, equals(0x17));
      expect(RiscvOpcode.jal, equals(0x6F));
      expect(RiscvOpcode.jalr, equals(0x67));
      expect(RiscvOpcode.branch, equals(0x63));
      expect(RiscvOpcode.load, equals(0x03));
      expect(RiscvOpcode.store, equals(0x23));
      expect(RiscvOpcode.op, equals(0x33));
      expect(RiscvOpcode.opImm, equals(0x13));
      expect(RiscvOpcode.system, equals(0x73));
    });
  });
}
