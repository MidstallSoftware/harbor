import 'dart:async';

import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborHandle', () {
    test('load and get value', () async {
      final h = HarborHandle<int>();
      expect(h.isLoaded, isFalse);

      h.load(42);
      expect(h.isLoaded, isTrue);
      expect(await h.value, equals(42));
    });

    test('pre-loaded via HarborHandle.of', () async {
      final h = HarborHandle.of('hello');
      expect(h.isLoaded, isTrue);
      expect(await h.value, equals('hello'));
    });

    test('get suspends until load', () async {
      final h = HarborHandle<int>();

      // Schedule the load to happen later
      Future<void>.delayed(Duration.zero, () => h.load(99));

      final result = await h.value;
      expect(result, equals(99));
    });

    test('multiple awaits get the same value', () async {
      final h = HarborHandle<int>();
      h.load(7);

      expect(await h.value, equals(7));
      expect(await h.value, equals(7));
    });

    test('double load throws', () {
      final h = HarborHandle<int>();
      h.load(1);
      expect(() => h.load(2), throwsStateError);
    });
  });
}
