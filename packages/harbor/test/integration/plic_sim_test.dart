import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('PLIC sim', () {
    test('write source priority and read back', () async {
      final plic = HarborPlic(baseAddress: 0x9000, sources: 4, contexts: 1);
      for (var i = 0; i < 4; i++) {
        plic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(plic);
      await tb.init();

      // Source 1 priority at byte addr 4 (source*4)
      await tb.write(4, 5);
      final val = await tb.read(4);
      expect(val, equals(5));

      await Simulator.endSimulation();
    });

    test('no interrupt when all sources low', () async {
      final plic = HarborPlic(baseAddress: 0x9000, sources: 4, contexts: 1);
      for (var i = 0; i < 4; i++) {
        plic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(plic);
      await tb.init();

      await tb.waitCycles(5);
      expect(plic.externalInterrupt[0].value.toInt(), equals(0));

      await Simulator.endSimulation();
    });

    test('write enable register and read back', () async {
      final plic = HarborPlic(baseAddress: 0x9000, sources: 4, contexts: 1);
      for (var i = 0; i < 4; i++) {
        plic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(plic);
      await tb.init();

      // Enable register for context 0 at byte addr 0x2000
      // Enable sources 0 and 2 (bits 0 and 2)
      await tb.write(0x2000, 0x05);
      final val = await tb.read(0x2000);
      expect(val & 0x0F, equals(0x05));

      await Simulator.endSimulation();
    });

    test('write threshold and read back', () async {
      final plic = HarborPlic(baseAddress: 0x9000, sources: 4, contexts: 1);
      for (var i = 0; i < 4; i++) {
        plic.port('src_irq_$i').getsLogic(Const(0));
      }

      final tb = PeripheralTestBench(plic);
      await tb.init();

      // Threshold for context 0 at byte addr 0x200000
      await tb.write(0x200000, 3);
      final val = await tb.read(0x200000);
      expect(val, equals(3));

      await Simulator.endSimulation();
    });
  });
}
