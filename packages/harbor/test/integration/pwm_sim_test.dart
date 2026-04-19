import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('PWM sim', () {
    test('write global enable and read back', () async {
      final pwm = HarborPwmTimer(baseAddress: 0x7000);
      final tb = PeripheralTestBench(pwm);
      await tb.init();

      // GLOBAL_CTRL word addr 0, bit 0 = global enable
      await tb.write(0, 0x01);
      final val = await tb.read(0);
      expect(val & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });

    test('read INT_STATUS register', () async {
      final pwm = HarborPwmTimer(baseAddress: 0x7000);
      final tb = PeripheralTestBench(pwm);
      await tb.init();

      // INT_STATUS word addr 1
      final val = await tb.read(1);
      // After reset, no interrupts pending
      expect(val, equals(0));

      await Simulator.endSimulation();
    });
  });
}
