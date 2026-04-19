import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('Temperature sensor sim', () {
    test('write CTRL enable+continuous and read back', () async {
      final temp = HarborTemperatureSensor(baseAddress: 0x13000);
      temp.port('temp_raw_in').getsLogic(Const(0, width: 12));
      temp.port('temp_valid_in').getsLogic(Const(0));

      final tb = PeripheralTestBench(temp);
      await tb.init();

      // CTRL word addr 0: bit 0=enable, bit 1=continuous
      await tb.write(0, 0x03);
      final val = await tb.read(0);
      expect(val & 0x03, equals(0x03));

      await Simulator.endSimulation();
    });

    test('write ALARM_HI and read back', () async {
      final temp = HarborTemperatureSensor(baseAddress: 0x13000);
      temp.port('temp_raw_in').getsLogic(Const(0, width: 12));
      temp.port('temp_valid_in').getsLogic(Const(0));

      final tb = PeripheralTestBench(temp);
      await tb.init();

      // ALARM_HI word addr 4 (0x10 >> 2)
      await tb.write(4, 95000);
      final val = await tb.read(4);
      expect(val, equals(95000));

      await Simulator.endSimulation();
    });

    test('write ALARM_LO and read back', () async {
      final temp = HarborTemperatureSensor(baseAddress: 0x13000);
      temp.port('temp_raw_in').getsLogic(Const(0, width: 12));
      temp.port('temp_valid_in').getsLogic(Const(0));

      final tb = PeripheralTestBench(temp);
      await tb.init();

      // ALARM_LO word addr 5 (0x14 >> 2)
      await tb.write(5, 10000);
      final val = await tb.read(5);
      expect(val, equals(10000));

      await Simulator.endSimulation();
    });

    test('write INT_ENABLE and read back', () async {
      final temp = HarborTemperatureSensor(baseAddress: 0x13000);
      temp.port('temp_raw_in').getsLogic(Const(0, width: 12));
      temp.port('temp_valid_in').getsLogic(Const(0));

      final tb = PeripheralTestBench(temp);
      await tb.init();

      // INT_ENABLE word addr 7 (0x1C >> 2)
      await tb.write(7, 0x07);
      final val = await tb.read(7);
      expect(val & 0x07, equals(0x07));

      await Simulator.endSimulation();
    });

    test('read STATUS register', () async {
      final temp = HarborTemperatureSensor(baseAddress: 0x13000);
      temp.port('temp_raw_in').getsLogic(Const(0, width: 12));
      temp.port('temp_valid_in').getsLogic(Const(0));

      final tb = PeripheralTestBench(temp);
      await tb.init();

      // STATUS word addr 1 (0x04 >> 2)
      final val = await tb.read(1);
      // After reset: data_valid=0, over_temp=0
      expect(val & 0x03, equals(0));

      await Simulator.endSimulation();
    });
  });
}
