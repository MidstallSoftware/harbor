import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('Display sim', () {
    test('write H_ACTIVE = 640 and read back', () async {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.vga,
          timing: HarborDisplayTiming.vga640x480(),
        ),
        baseAddress: 0xC000,
      );
      display.port('pixel_clk').getsLogic(Const(0));
      display.port('fb_data').getsLogic(Const(0, width: 32));
      display.port('fb_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(display);
      await tb.init();

      // H_ACTIVE word addr 4
      await tb.write(4, 640);
      final val = await tb.read(4);
      expect(val, equals(640));

      await Simulator.endSimulation();
    });

    test('write V_ACTIVE = 480 and read back', () async {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.vga,
          timing: HarborDisplayTiming.vga640x480(),
        ),
        baseAddress: 0xC000,
      );
      display.port('pixel_clk').getsLogic(Const(0));
      display.port('fb_data').getsLogic(Const(0, width: 32));
      display.port('fb_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(display);
      await tb.init();

      // V_ACTIVE word addr 6
      await tb.write(6, 480);
      final val = await tb.read(6);
      expect(val, equals(480));

      await Simulator.endSimulation();
    });

    test('write CTRL enable and read back', () async {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.vga,
          timing: HarborDisplayTiming.vga640x480(),
        ),
        baseAddress: 0xC000,
      );
      display.port('pixel_clk').getsLogic(Const(0));
      display.port('fb_data').getsLogic(Const(0, width: 32));
      display.port('fb_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(display);
      await tb.init();

      // CTRL word addr 0, bit 0 = enable
      await tb.write(0, 0x01);
      final val = await tb.read(0);
      expect(val & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });

    test('write FB_BASE and read back', () async {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.vga,
          timing: HarborDisplayTiming.vga640x480(),
        ),
        baseAddress: 0xC000,
      );
      display.port('pixel_clk').getsLogic(Const(0));
      display.port('fb_data').getsLogic(Const(0, width: 32));
      display.port('fb_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(display);
      await tb.init();

      // FB_BASE word addr 2 (0x08 >> 2)
      await tb.write(2, 0x40000000);
      final val = await tb.read(2);
      expect(val, equals(0x40000000));

      await Simulator.endSimulation();
    });

    test('write FB_STRIDE and read back', () async {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.vga,
          timing: HarborDisplayTiming.vga640x480(),
        ),
        baseAddress: 0xC000,
      );
      display.port('pixel_clk').getsLogic(Const(0));
      display.port('fb_data').getsLogic(Const(0, width: 32));
      display.port('fb_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(display);
      await tb.init();

      // FB_STRIDE word addr 3 (0x0C >> 2)
      await tb.write(3, 2560);
      final val = await tb.read(3);
      expect(val, equals(2560));

      await Simulator.endSimulation();
    });

    test('write INT_ENABLE and read back', () async {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.vga,
          timing: HarborDisplayTiming.vga640x480(),
        ),
        baseAddress: 0xC000,
      );
      display.port('pixel_clk').getsLogic(Const(0));
      display.port('fb_data').getsLogic(Const(0, width: 32));
      display.port('fb_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(display);
      await tb.init();

      // INT_ENABLE word addr 9 (0x24 >> 2)
      await tb.write(9, 0x03);
      final val = await tb.read(9);
      expect(val & 0x0F, equals(0x03));

      await Simulator.endSimulation();
    });
  });
}
