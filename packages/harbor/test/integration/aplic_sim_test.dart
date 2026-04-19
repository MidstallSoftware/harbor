import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('APLIC sim', () {
    test('write sourcecfg for source 0 and read back', () async {
      final aplic = HarborAplic(baseAddress: 0x11000, sources: 4, harts: 1);
      for (var i = 0; i < 4; i++) {
        aplic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(aplic);
      await tb.init();

      // sourcecfg[0] at byte addr 0x0004
      await tb.write(0x0004, 0x01);
      final val = await tb.read(0x0004);
      expect(val, equals(0x01));

      await Simulator.endSimulation();
    });

    test('write domaincfg and read back', () async {
      final aplic = HarborAplic(baseAddress: 0x11000, sources: 4, harts: 1);
      for (var i = 0; i < 4; i++) {
        aplic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(aplic);
      await tb.init();

      // domaincfg at byte addr 0x0000
      await tb.write(0x0000, 0x80000004);
      final val = await tb.read(0x0000);
      expect(val, equals(0x80000004));

      await Simulator.endSimulation();
    });

    test('no interrupt when sources low', () async {
      final aplic = HarborAplic(baseAddress: 0x11000, sources: 4, harts: 1);
      for (var i = 0; i < 4; i++) {
        aplic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(aplic);
      await tb.init();

      await tb.waitCycles(5);
      expect(aplic.externalInterrupt[0].value.toInt(), equals(0));

      await Simulator.endSimulation();
    });

    test('write IDC threshold for hart 0 and read back', () async {
      final aplic = HarborAplic(baseAddress: 0x11000, sources: 4, harts: 1);
      for (var i = 0; i < 4; i++) {
        aplic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(aplic);
      await tb.init();

      // IDC ithreshold for hart 0 at byte addr 0x4000 + 0*32 + 8 = 0x4008
      await tb.write(0x4008, 0x05);
      final val = await tb.read(0x4008);
      expect(val, equals(0x05));

      await Simulator.endSimulation();
    });
  });
}
