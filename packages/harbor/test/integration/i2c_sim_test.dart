import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('I2C sim', () {
    test('write prescaler and read back', () async {
      final i2c = HarborI2cController(baseAddress: 0x6000);
      i2c.port('scl_in').getsLogic(Const(1));
      i2c.port('sda_in').getsLogic(Const(1));

      final tb = PeripheralTestBench(i2c);
      await tb.init();

      // PRESCALE word addr 4
      await tb.write(4, 200);
      final val = await tb.read(4);
      expect(val, equals(200));

      await Simulator.endSimulation();
    });

    test('write CTRL enable and read back', () async {
      final i2c = HarborI2cController(baseAddress: 0x6000);
      i2c.port('scl_in').getsLogic(Const(1));
      i2c.port('sda_in').getsLogic(Const(1));

      final tb = PeripheralTestBench(i2c);
      await tb.init();

      // CTRL word addr 0: bit 0 = enable
      await tb.write(0, 0x01);
      final val = await tb.read(0);
      expect(val & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });

    test('read STATUS register', () async {
      final i2c = HarborI2cController(baseAddress: 0x6000);
      i2c.port('scl_in').getsLogic(Const(1));
      i2c.port('sda_in').getsLogic(Const(1));

      final tb = PeripheralTestBench(i2c);
      await tb.init();

      // STATUS word addr 1 (0x04 >> 2)
      final val = await tb.read(1);
      // After reset: busy=0, ack=0, arb_lost=0, rx_ready=0
      expect(val & 0x01, equals(0));

      await Simulator.endSimulation();
    });

    test('write slave address and read back', () async {
      final i2c = HarborI2cController(baseAddress: 0x6000);
      i2c.port('scl_in').getsLogic(Const(1));
      i2c.port('sda_in').getsLogic(Const(1));

      final tb = PeripheralTestBench(i2c);
      await tb.init();

      // ADDR word addr 3 (0x0C >> 2)
      await tb.write(3, 0x50);
      final val = await tb.read(3);
      expect(val & 0x7F, equals(0x50));

      await Simulator.endSimulation();
    });
  });
}
