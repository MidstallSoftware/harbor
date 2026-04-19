import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('CLINT sim', () {
    test('write msip and read back', () async {
      final clint = HarborClint(baseAddress: 0x8000);
      final tb = PeripheralTestBench(clint);
      await tb.init();

      // msip[0] at byte addr 0, bit 0
      await tb.write(0, 0x01);
      final val = await tb.read(0);
      expect(val & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });

    test('clear msip', () async {
      final clint = HarborClint(baseAddress: 0x8000);
      final tb = PeripheralTestBench(clint);
      await tb.init();

      // Set msip
      await tb.write(0, 0x01);
      var val = await tb.read(0);
      expect(val & 0x01, equals(0x01));

      // Clear msip
      await tb.write(0, 0x00);
      val = await tb.read(0);
      expect(val & 0x01, equals(0x00));

      await Simulator.endSimulation();
    });

    test('mtime increments over clock cycles', () async {
      final clint = HarborClint(baseAddress: 0x8000);
      final tb = PeripheralTestBench(clint);
      await tb.init();

      // Read mtime_lo at byte addr 0xBFF8
      final first = await tb.read(0xBFF8);
      await tb.waitCycles(10);
      final second = await tb.read(0xBFF8);
      // mtime increments every clock cycle, so second > first
      expect(second, greaterThan(first));

      await Simulator.endSimulation();
    });
  });
}
