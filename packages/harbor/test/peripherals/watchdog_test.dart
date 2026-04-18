import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborWatchdog', () {
    test('creates with correct outputs', () {
      final wdt = HarborWatchdog(baseAddress: 0x10005000);
      expect(wdt.bus, isNotNull);
      expect(wdt.resetOut.width, equals(1));
      expect(wdt.interrupt.width, equals(1));
    });

    test('kick magic value', () {
      expect(HarborWatchdog.kickMagic, equals(0x4B494B));
    });

    test('DT node', () {
      final wdt = HarborWatchdog(baseAddress: 0x10005000);
      final dt = wdt.dtNode;
      expect(dt.compatible.first, equals('harbor,watchdog'));
      expect(dt.reg.start, equals(0x10005000));
    });

    test('supports both protocols', () {
      final wb = HarborWatchdog(
        baseAddress: 0x1000,
        protocol: BusProtocol.wishbone,
      );
      final tl = HarborWatchdog(
        baseAddress: 0x1000,
        protocol: BusProtocol.tilelink,
      );
      expect(wb.bus.protocol, equals(BusProtocol.wishbone));
      expect(tl.bus.protocol, equals(BusProtocol.tilelink));
    });
  });
}
