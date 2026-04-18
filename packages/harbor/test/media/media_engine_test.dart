import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborCodecFormat', () {
    test('video codecs are video', () {
      expect(HarborCodecFormat.h264.isVideo, isTrue);
      expect(HarborCodecFormat.h265.isVideo, isTrue);
      expect(HarborCodecFormat.vp9.isVideo, isTrue);
      expect(HarborCodecFormat.av1.isVideo, isTrue);
    });

    test('image codecs are not video', () {
      expect(HarborCodecFormat.jpeg.isVideo, isFalse);
      expect(HarborCodecFormat.jpeg2000.isVideo, isFalse);
    });

    test('all codecs are image', () {
      for (final fmt in HarborCodecFormat.values) {
        expect(fmt.isImage, isTrue);
      }
    });

    test('display names', () {
      expect(HarborCodecFormat.h264.displayName, equals('H.264/AVC'));
      expect(HarborCodecFormat.av1.displayName, equals('AV1'));
    });
  });

  group('HarborCodecInstance', () {
    test('decode only', () {
      const inst = HarborCodecInstance(
        format: HarborCodecFormat.h264,
        capability: HarborCodecCapability.decodeOnly,
      );
      expect(inst.canDecode, isTrue);
      expect(inst.canEncode, isFalse);
    });

    test('both encode and decode', () {
      const inst = HarborCodecInstance(
        format: HarborCodecFormat.h265,
        capability: HarborCodecCapability.both,
      );
      expect(inst.canDecode, isTrue);
      expect(inst.canEncode, isTrue);
    });

    test('4K support', () {
      const inst4k = HarborCodecInstance(
        format: HarborCodecFormat.av1,
        capability: HarborCodecCapability.decodeOnly,
        maxWidth: 3840,
        maxHeight: 2160,
      );
      expect(inst4k.supports4K, isTrue);
      expect(inst4k.supports8K, isFalse);
    });

    test('8K support', () {
      const inst8k = HarborCodecInstance(
        format: HarborCodecFormat.av1,
        capability: HarborCodecCapability.decodeOnly,
        maxWidth: 7680,
        maxHeight: 4320,
      );
      expect(inst8k.supports4K, isTrue);
      expect(inst8k.supports8K, isTrue);
    });

    test('bit depths', () {
      const inst = HarborCodecInstance(
        format: HarborCodecFormat.h265,
        capability: HarborCodecCapability.both,
        bitDepths: [8, 10, 12],
      );
      expect(inst.bitDepths, containsAll([8, 10, 12]));
    });
  });

  group('HarborMediaEngine', () {
    test('creates with codec list', () {
      final engine = HarborMediaEngine(
        baseAddress: 0x20000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.h264,
            capability: HarborCodecCapability.both,
          ),
          HarborCodecInstance(
            format: HarborCodecFormat.h265,
            capability: HarborCodecCapability.decodeOnly,
          ),
          HarborCodecInstance(
            format: HarborCodecFormat.jpeg,
            capability: HarborCodecCapability.both,
          ),
        ],
      );
      expect(engine.codecs, hasLength(3));
      expect(engine.maxSessions, equals(4));
      expect(engine.interrupt.width, equals(1));
    });

    test('codec capability queries', () {
      final engine = HarborMediaEngine(
        baseAddress: 0x20000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.h264,
            capability: HarborCodecCapability.both,
          ),
          HarborCodecInstance(
            format: HarborCodecFormat.av1,
            capability: HarborCodecCapability.decodeOnly,
          ),
        ],
      );

      expect(engine.supportsCodec(HarborCodecFormat.h264), isTrue);
      expect(engine.supportsCodec(HarborCodecFormat.vp9), isFalse);

      expect(engine.canDecode(HarborCodecFormat.h264), isTrue);
      expect(engine.canEncode(HarborCodecFormat.h264), isTrue);
      expect(engine.canDecode(HarborCodecFormat.av1), isTrue);
      expect(engine.canEncode(HarborCodecFormat.av1), isFalse);
    });

    test('decodable and encodable format lists', () {
      final engine = HarborMediaEngine(
        baseAddress: 0x20000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.h264,
            capability: HarborCodecCapability.both,
          ),
          HarborCodecInstance(
            format: HarborCodecFormat.h265,
            capability: HarborCodecCapability.decodeOnly,
          ),
          HarborCodecInstance(
            format: HarborCodecFormat.jpeg,
            capability: HarborCodecCapability.encodeOnly,
          ),
        ],
      );

      expect(
        engine.decodableFormats,
        containsAll([HarborCodecFormat.h264, HarborCodecFormat.h265]),
      );
      expect(
        engine.encodableFormats,
        containsAll([HarborCodecFormat.h264, HarborCodecFormat.jpeg]),
      );
    });

    test('DT node', () {
      final engine = HarborMediaEngine(
        baseAddress: 0x20000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.h264,
            capability: HarborCodecCapability.both,
            maxWidth: 3840,
            maxHeight: 2160,
          ),
        ],
        maxSessions: 8,
      );
      final dt = engine.dtNode;
      expect(dt.compatible.first, equals('harbor,media-engine'));
      expect(dt.reg.start, equals(0x20000000));
      expect(dt.properties['max-sessions'], equals(8));
      expect(dt.properties['harbor,max-width'], equals(3840));
      expect(dt.properties['harbor,max-height'], equals(2160));
    });

    test('DMA interface widths', () {
      final engine = HarborMediaEngine(
        baseAddress: 0x20000000,
        codecs: const [
          HarborCodecInstance(
            format: HarborCodecFormat.h264,
            capability: HarborCodecCapability.decodeOnly,
          ),
        ],
        dmaAddrWidth: 40,
      );
      expect(engine.dmaReadAddr.width, equals(40));
      expect(engine.dmaWriteAddr.width, equals(40));
      expect(engine.dmaReadData.width, equals(128));
      expect(engine.dmaWriteData.width, equals(128));
    });
  });

  group('HarborMediaPixelFormat', () {
    test('all formats defined', () {
      expect(HarborMediaPixelFormat.values, hasLength(7));
      expect(HarborMediaPixelFormat.nv12.name, equals('nv12'));
      expect(HarborMediaPixelFormat.p010.name, equals('p010'));
    });
  });

  group('HarborRateControlMode', () {
    test('all modes defined', () {
      expect(HarborRateControlMode.values, hasLength(4));
      expect(HarborRateControlMode.cqp.name, equals('cqp'));
      expect(HarborRateControlMode.cbr.name, equals('cbr'));
      expect(HarborRateControlMode.vbr.name, equals('vbr'));
      expect(HarborRateControlMode.crf.name, equals('crf'));
    });
  });
}
