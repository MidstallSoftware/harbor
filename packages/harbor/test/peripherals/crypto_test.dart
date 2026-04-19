import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborCryptoOp', () {
    test('has all 7 enum values', () {
      expect(HarborCryptoOp.values, hasLength(7));
      expect(HarborCryptoOp.values, contains(HarborCryptoOp.aesEncrypt));
      expect(HarborCryptoOp.values, contains(HarborCryptoOp.aesDecrypt));
      expect(HarborCryptoOp.values, contains(HarborCryptoOp.sha256));
      expect(HarborCryptoOp.values, contains(HarborCryptoOp.sha512));
      expect(HarborCryptoOp.values, contains(HarborCryptoOp.clmul));
      expect(HarborCryptoOp.values, contains(HarborCryptoOp.bitManip));
      expect(HarborCryptoOp.values, contains(HarborCryptoOp.crossbar));
    });
  });

  group('HarborCryptoSubOp', () {
    test('has all 4 enum values', () {
      expect(HarborCryptoSubOp.values, hasLength(4));
      expect(HarborCryptoSubOp.values, contains(HarborCryptoSubOp.variant0));
      expect(HarborCryptoSubOp.values, contains(HarborCryptoSubOp.variant1));
      expect(HarborCryptoSubOp.values, contains(HarborCryptoSubOp.variant2));
      expect(HarborCryptoSubOp.values, contains(HarborCryptoSubOp.variant3));
    });
  });

  group('HarborCryptoUnit', () {
    test('creates with all default operations', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.operations, hasLength(7));
      expect(crypto.operations, containsAll(HarborCryptoOp.values));
    });

    test('has result output (width 64)', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.output('result').width, equals(64));
    });

    test('has result_valid output', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.output('result_valid').width, equals(1));
    });

    test('has busy output', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.output('busy').width, equals(1));
    });

    test('has sub_op input (width 2)', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.input('sub_op').width, equals(2));
    });

    test('has rs1 input (width 64)', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.input('rs1').width, equals(64));
    });

    test('has rs2 input (width 64)', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.input('rs2').width, equals(64));
    });
  });
}
