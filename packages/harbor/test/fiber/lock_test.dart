import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborLock', () {
    test('unretained lock completes immediately', () async {
      final lock = HarborLock();
      expect(lock.isLocked, isFalse);
      await lock.wait; // should not hang
    });

    test('retain and release', () async {
      final lock = HarborLock()..retain();
      expect(lock.isLocked, isTrue);

      lock.release();
      expect(lock.isLocked, isFalse);
      await lock.wait;
    });

    test('multiple retains require multiple releases', () async {
      final lock = HarborLock()
        ..retain()
        ..retain()
        ..retain();
      expect(lock.isLocked, isTrue);

      lock.release();
      expect(lock.isLocked, isTrue);
      lock.release();
      expect(lock.isLocked, isTrue);
      lock.release();
      expect(lock.isLocked, isFalse);

      await lock.wait;
    });

    test('release without retain throws', () {
      final lock = HarborLock();
      expect(() => lock.release(), throwsStateError);
    });

    test('wait suspends until released', () async {
      final lock = HarborLock()..retain();
      final log = <String>[];

      final waiter = lock.wait.then((_) => log.add('unlocked'));

      log.add('before_release');
      lock.release();

      await waiter;
      expect(log, equals(['before_release', 'unlocked']));
    });
  });
}
