import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';
import 'test_harness.dart';

void main() {
  tearDown(() async {
    await Simulator.reset();
  });

  group('Media Engine sim', () {
    test('read ENGINE_CAPS has correct codec bits', () async {
      final media = HarborMediaEngine(
        baseAddress: 0x40000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.h264,
            capability: HarborCodecCapability.both,
          ),
          HarborCodecInstance(
            format: HarborCodecFormat.jpeg,
            capability: HarborCodecCapability.decodeOnly,
          ),
        ],
      );

      media.port('dma_read_data').getsLogic(Const(0, width: 128));
      media.port('dma_read_valid').getsLogic(Const(0));
      media.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(media);
      await tb.init();

      // ENGINE_CAPS at word address 2
      final caps = await tb.read(2);
      expect(caps & 0x01, equals(0x01), reason: 'H.264 bit');
      expect(caps & 0x10, equals(0x10), reason: 'JPEG bit');

      await Simulator.endSimulation();
    });

    test('write and read INT_ENABLE', () async {
      final media = HarborMediaEngine(
        baseAddress: 0x40000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.h264,
            capability: HarborCodecCapability.both,
          ),
        ],
      );

      media.port('dma_read_data').getsLogic(Const(0, width: 128));
      media.port('dma_read_valid').getsLogic(Const(0));
      media.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(media);
      await tb.init();

      // INT_ENABLE at word address 5
      await tb.write(5, 0x0F);
      final intEn = await tb.read(5);
      expect(intEn & 0x0F, equals(0x0F));

      await Simulator.endSimulation();
    });

    test('write ENGINE_CTRL and read back', () async {
      final media = HarborMediaEngine(
        baseAddress: 0x40000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.av1,
            capability: HarborCodecCapability.decodeOnly,
          ),
        ],
      );

      media.port('dma_read_data').getsLogic(Const(0, width: 128));
      media.port('dma_read_valid').getsLogic(Const(0));
      media.port('dma_write_ack').getsLogic(Const(0));

      final tb = PeripheralTestBench(media);
      await tb.init();

      // ENGINE_CTRL at word address 0
      await tb.write(0, 0x01);
      final ctrl = await tb.read(0);
      expect(ctrl & 0x01, equals(0x01));

      await Simulator.endSimulation();
    });
  });
}
