import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborDisplayTiming', () {
    test('VGA 640x480 timing', () {
      const t = HarborDisplayTiming.vga640x480();
      expect(t.hActive, equals(640));
      expect(t.vActive, equals(480));
      expect(t.pixelClock, equals(25175000));
      expect(t.refreshRate, closeTo(59.94, 0.1));
      expect(t.resolution, equals('640x480'));
    });

    test('720p timing', () {
      const t = HarborDisplayTiming.hd720();
      expect(t.hActive, equals(1280));
      expect(t.vActive, equals(720));
      expect(t.refreshRate, closeTo(60.0, 0.1));
    });

    test('1080p timing', () {
      const t = HarborDisplayTiming.fhd1080();
      expect(t.hActive, equals(1920));
      expect(t.vActive, equals(1080));
      expect(t.refreshRate, closeTo(60.0, 0.1));
    });

    test('hTotal and vTotal', () {
      const t = HarborDisplayTiming.vga640x480();
      expect(t.hTotal, equals(640 + 16 + 96 + 48)); // 800
      expect(t.vTotal, equals(480 + 10 + 2 + 33)); // 525
    });

    test('toPrettyString', () {
      const t = HarborDisplayTiming.hd720();
      expect(t.toPrettyString(), contains('1280x720'));
      expect(t.toPrettyString(), contains('60'));
    });
  });

  group('HarborDisplayConfig', () {
    test('basic config', () {
      const config = HarborDisplayConfig(
        interface_: HarborDisplayInterface.hdmi,
        timing: HarborDisplayTiming.fhd1080(),
      );
      expect(config.pixelFormat, equals(HarborPixelFormat.xrgb8888));
      expect(config.maxWidth, equals(1920));
    });

    test('toPrettyString', () {
      const config = HarborDisplayConfig(
        interface_: HarborDisplayInterface.vga,
        timing: HarborDisplayTiming.vga640x480(),
      );
      expect(config.toPrettyString(), contains('vga'));
      expect(config.toPrettyString(), contains('640x480'));
    });
  });

  group('HarborDisplayController', () {
    test('creates with VGA config', () {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.vga,
          timing: HarborDisplayTiming.vga640x480(),
        ),
        baseAddress: 0x70000000,
      );
      expect(display.bus, isNotNull);
      expect(display.interrupt.width, equals(1));
    });

    test('has video output signals', () {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.hdmi,
          timing: HarborDisplayTiming.hd720(),
        ),
        baseAddress: 0x70000000,
      );
      expect(display.output('hsync').width, equals(1));
      expect(display.output('vsync').width, equals(1));
      expect(display.output('de').width, equals(1));
      expect(display.output('pixel_r').width, equals(8));
      expect(display.output('pixel_g').width, equals(8));
      expect(display.output('pixel_b').width, equals(8));
    });

    test('DT node', () {
      final display = HarborDisplayController(
        config: const HarborDisplayConfig(
          interface_: HarborDisplayInterface.hdmi,
          timing: HarborDisplayTiming.fhd1080(),
          maxWidth: 3840,
          maxHeight: 2160,
        ),
        baseAddress: 0x70000000,
      );
      final dt = display.dtNode;
      expect(dt.compatible.first, equals('harbor,display'));
      expect(dt.properties['output-interface'], equals('hdmi'));
      expect(dt.properties['max-width'], equals(3840));
    });
  });

  group('HarborPixelFormat', () {
    test('bits per pixel', () {
      expect(HarborPixelFormat.rgb565.bitsPerPixel, equals(16));
      expect(HarborPixelFormat.rgb888.bitsPerPixel, equals(24));
      expect(HarborPixelFormat.xrgb8888.bitsPerPixel, equals(32));
      expect(HarborPixelFormat.argb8888.bitsPerPixel, equals(32));
    });
  });
}
