import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborDatabase', () {
    test('HarborValueElement get/set', () {
      const key = HarborDatabaseKey<int>('xlen');
      final db = HarborDatabase()..set(key, HarborValueElement(32));

      final element = db.get(key) as HarborValueElement<int>;
      expect(element.value, equals(32));

      element.value = 64;
      expect(element.value, equals(64));
    });

    test('HarborBlockingElement suspends until set', () async {
      const key = HarborDatabaseKey<int>('width');
      final blocking = HarborBlockingElement<int>();
      final db = HarborDatabase()..set(key, blocking);

      expect(blocking.isSet, isFalse);

      blocking.set(128);
      expect(blocking.isSet, isTrue);

      final val = await db.get(key).value;
      expect(val, equals(128));
    });

    test('HarborLambdaElement computes lazily and caches', () {
      var callCount = 0;
      const key = HarborDatabaseKey<String>('computed');
      final db = HarborDatabase()
        ..set(
          key,
          HarborLambdaElement(() {
            callCount++;
            return 'result';
          }),
        );

      expect(callCount, equals(0));

      final v1 = db.get(key).value as String;
      expect(v1, equals('result'));
      expect(callCount, equals(1));

      final v2 = db.get(key).value as String;
      expect(v2, equals('result'));
      expect(callCount, equals(1)); // cached
    });

    test('get throws on missing key', () {
      final db = HarborDatabase();
      expect(
        () => db.get(const HarborDatabaseKey<int>('missing')),
        throwsStateError,
      );
    });

    test('tryGet returns null on missing key', () {
      final db = HarborDatabase();
      expect(db.tryGet(const HarborDatabaseKey<int>('missing')), isNull);
    });

    test('has returns correct values', () {
      const key = HarborDatabaseKey<int>('x');
      final db = HarborDatabase();

      expect(db.has(key), isFalse);
      db.set(key, HarborValueElement(1));
      expect(db.has(key), isTrue);
    });

    test('unresolvedBlockingKeys reports unset blocking elements', () {
      const k1 = HarborDatabaseKey<int>('resolved');
      const k2 = HarborDatabaseKey<int>('unresolved');

      final db = HarborDatabase()
        ..set(k1, HarborBlockingElement<int>()..set(42))
        ..set(k2, HarborBlockingElement<int>());

      final unresolved = db.unresolvedBlockingKeys;
      expect(unresolved, hasLength(1));
      expect(unresolved.first, equals(k2));
    });

    test('HarborDatabaseKey equality', () {
      const a = HarborDatabaseKey<int>('x');
      const b = HarborDatabaseKey<int>('x');
      const c = HarborDatabaseKey<int>('y');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
