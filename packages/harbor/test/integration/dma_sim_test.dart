import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('DMA sim', () {
    test('write CTRL enable and read back', () async {
      final dma = HarborDmaController(baseAddress: 0xD000);
      dma.port('dma_rdata').getsLogic(Const(0, width: 32));
      dma.port('dma_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(dma);
      await tb.init();

      // Global CTRL word addr 0, bit 0 = global enable
      await tb.write(0, 0x01);
      final val = await tb.read(0);
      expect(val & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });

    test('write and read INT_ENABLE register', () async {
      final dma = HarborDmaController(baseAddress: 0xD000);
      dma.port('dma_rdata').getsLogic(Const(0, width: 32));
      dma.port('dma_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(dma);
      await tb.init();

      // INT_ENABLE at word addr 2
      await tb.write(2, 0x0F);
      final val = await tb.read(2);
      expect(val & 0x0F, equals(0x0F));

      await Simulator.endSimulation();
    });

    test('read STATUS register for channel 0', () async {
      final dma = HarborDmaController(baseAddress: 0xD000);
      dma.port('dma_rdata').getsLogic(Const(0, width: 32));
      dma.port('dma_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(dma);
      await tb.init();

      // CH0 STATUS at word addr = (0x08 + 0) << 5 | 1 = 0x101
      // Channel 0 registers start at addr where bits [11:5] = 0x08
      // CH_STATUS is offset 1 within the channel
      // word addr = (0x08 << 5) | 1 = 0x101
      final val = await tb.read(0x101);
      // After reset: busy=0, complete=0, error=0
      expect(val, equals(0));

      await Simulator.endSimulation();
    });

    test('write channel 0 source address and read back', () async {
      final dma = HarborDmaController(baseAddress: 0xD000);
      dma.port('dma_rdata').getsLogic(Const(0, width: 32));
      dma.port('dma_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(dma);
      await tb.init();

      // CH0 SRC at word addr = (0x08 << 5) | 2 = 0x102
      await tb.write(0x102, 0x80000000);
      final val = await tb.read(0x102);
      expect(val, equals(0x80000000));

      await Simulator.endSimulation();
    });

    test('write channel 0 destination address and read back', () async {
      final dma = HarborDmaController(baseAddress: 0xD000);
      dma.port('dma_rdata').getsLogic(Const(0, width: 32));
      dma.port('dma_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(dma);
      await tb.init();

      // CH0 DST at word addr = (0x08 << 5) | 3 = 0x103
      await tb.write(0x103, 0x90000000);
      final val = await tb.read(0x103);
      expect(val, equals(0x90000000));

      await Simulator.endSimulation();
    });

    test('write channel 0 length and read back', () async {
      final dma = HarborDmaController(baseAddress: 0xD000);
      dma.port('dma_rdata').getsLogic(Const(0, width: 32));
      dma.port('dma_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(dma);
      await tb.init();

      // CH0 LEN at word addr = (0x08 << 5) | 4 = 0x104
      await tb.write(0x104, 0x1000);
      final val = await tb.read(0x104);
      expect(val, equals(0x1000));

      await Simulator.endSimulation();
    });

    test('channel 0 CTRL enable', () async {
      final dma = HarborDmaController(baseAddress: 0xD000);
      dma.port('dma_rdata').getsLogic(Const(0, width: 32));
      dma.port('dma_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(dma);
      await tb.init();

      // CH0 CTRL at word addr = (0x08 << 5) | 0 = 0x100
      // bit 0 = enable
      await tb.write(0x100, 0x01);
      final val = await tb.read(0x100);
      expect(val & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });
  });
}
