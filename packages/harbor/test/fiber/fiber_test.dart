import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborFiber', () {
    test('phases execute in order', () async {
      final log = <String>[];
      final fiber = HarborFiber()
        ..build(() async => log.add('build'))
        ..setup(() async => log.add('setup'))
        ..check(() async => log.add('check'))
        ..patch(() async => log.add('patch'));

      await fiber.run();

      expect(log, equals(['setup', 'build', 'patch', 'check']));
    });

    test('tasks within a phase run concurrently', () async {
      final handle = HarborHandle<int>();
      final results = <int>[];
      final fiber = HarborFiber();

      // Task 1: awaits a handle loaded by task 2
      fiber.build(() async {
        final val = await handle.value;
        results.add(val * 2);
      });

      // Task 2: loads the handle
      fiber.build(() async {
        handle.load(21);
      });

      await fiber.run();
      expect(results, equals([42]));
    });

    test('empty phases are skipped', () async {
      final log = <String>[];
      final fiber = HarborFiber()
        ..setup(() async => log.add('setup'))
        ..check(() async => log.add('check'));

      await fiber.run();
      expect(log, equals(['setup', 'check']));
    });

    test('failure wraps in HarborFiberElaborationException', () async {
      final fiber = HarborFiber()..build(() async => throw Exception('boom'));

      expect(
        () => fiber.run(),
        throwsA(
          isA<HarborFiberElaborationException>().having(
            (e) => e.phase,
            'phase',
            HarborFiberPhase.build,
          ),
        ),
      );
    });
  });
}
