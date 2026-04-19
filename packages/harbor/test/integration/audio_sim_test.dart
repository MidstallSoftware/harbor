import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';
import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('Audio Controller sim', () {
    test('write VOLUME_L and read back', () async {
      final audio = HarborAudioController(baseAddress: 0x10060000);

      audio.port('sdata_in').getsLogic(Const(0));
      audio.port('dma_read_data').getsLogic(Const(0, width: 32));
      audio.port('dma_read_valid').getsLogic(Const(0));
      audio.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(audio);
      await tb.init();

      // VOLUME_L at word address 16 (byte 0x40)
      await tb.write(16, 200);
      final volL = await tb.read(16);
      expect(volL & 0xFF, equals(200));

      await Simulator.endSimulation();
    });

    test('write VOLUME_R and read back', () async {
      final audio = HarborAudioController(baseAddress: 0x10060000);

      audio.port('sdata_in').getsLogic(Const(0));
      audio.port('dma_read_data').getsLogic(Const(0, width: 32));
      audio.port('dma_read_valid').getsLogic(Const(0));
      audio.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(audio);
      await tb.init();

      // VOLUME_R at word address 17 (byte 0x44)
      await tb.write(17, 128);
      final volR = await tb.read(17);
      expect(volR & 0xFF, equals(128));

      await Simulator.endSimulation();
    });

    test('write MUTE register', () async {
      final audio = HarborAudioController(baseAddress: 0x10060000);

      audio.port('sdata_in').getsLogic(Const(0));
      audio.port('dma_read_data').getsLogic(Const(0, width: 32));
      audio.port('dma_read_valid').getsLogic(Const(0));
      audio.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(audio);
      await tb.init();

      // MUTE at word address 18 (byte 0x48)
      await tb.write(18, 0x03);
      final mute = await tb.read(18);
      expect(mute & 0x03, equals(0x03));

      await Simulator.endSimulation();
    });

    test('write CTRL enable and read back', () async {
      final audio = HarborAudioController(baseAddress: 0x10060000);

      audio.port('sdata_in').getsLogic(Const(0));
      audio.port('dma_read_data').getsLogic(Const(0, width: 32));
      audio.port('dma_read_valid').getsLogic(Const(0));
      audio.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(audio);
      await tb.init();

      // CTRL at word address 0
      await tb.write(0, 0x01);
      final ctrl = await tb.read(0);
      expect(ctrl & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });

    test('write INT_ENABLE and read back', () async {
      final audio = HarborAudioController(baseAddress: 0x10060000);

      audio.port('sdata_in').getsLogic(Const(0));
      audio.port('dma_read_data').getsLogic(Const(0, width: 32));
      audio.port('dma_read_valid').getsLogic(Const(0));
      audio.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(audio);
      await tb.init();

      // INT_ENABLE at word address 15 (byte 0x3C)
      await tb.write(15, 0xFF);
      final intEn = await tb.read(15);
      expect(intEn & 0xFF, equals(0xFF));

      await Simulator.endSimulation();
    });
  });
}
