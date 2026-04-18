import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborInterruptRouting', () {
    test('PLIC-based routing', () {
      final plic = HarborPlic(
        baseAddress: 0x0C000000,
        sources: 32,
        contexts: 2,
      );
      final routing = HarborInterruptRouting.plic(plic: plic);
      expect(routing.numHarts, equals(2));
    });

    test('APLIC wired routing', () {
      final aplic = HarborAplic(baseAddress: 0x0C000000, sources: 64, harts: 4);
      final routing = HarborInterruptRouting.aplicWired(aplic: aplic);
      expect(routing.numHarts, equals(4));
    });

    test('AIA routing with IMSIC', () {
      final aplic = HarborAplic(baseAddress: 0x0C000000, sources: 64, harts: 2);
      final imsic0 = HarborImsic(baseAddress: 0x24000000, hartIndex: 0);
      final imsic1 = HarborImsic(baseAddress: 0x24001000, hartIndex: 1);
      final routing = HarborInterruptRouting.aia(
        aplic: aplic,
        imsics: [imsic0, imsic1],
      );
      expect(routing.numHarts, equals(2));
    });

    test('connectSource assigns incrementing indices', () {
      final plic = HarborPlic(
        baseAddress: 0x0C000000,
        sources: 32,
        contexts: 1,
      );
      final routing = HarborInterruptRouting.plic(plic: plic);

      final uart = HarborUart(baseAddress: 0x10000000);
      final gpio = HarborGpio(baseAddress: 0x10001000);

      final uartIdx = routing.connectSource(uart);
      final gpioIdx = routing.connectSource(gpio);

      expect(uartIdx, equals(1)); // source 0 is reserved
      expect(gpioIdx, equals(2));
      expect(routing.sourceCount, equals(3));
    });

    test('connectSources skips interrupt controllers', () {
      final plic = HarborPlic(
        baseAddress: 0x0C000000,
        sources: 32,
        contexts: 1,
      );
      final routing = HarborInterruptRouting.plic(plic: plic);

      final uart = HarborUart(baseAddress: 0x10000000);
      final result = routing.connectSources([plic, uart]);

      // PLIC itself should be skipped
      expect(result, isNot(contains('plic')));
      expect(result.containsKey(uart.name), isTrue);
    });

    test('hartInterrupt returns PLIC ext_irq', () {
      final plic = HarborPlic(
        baseAddress: 0x0C000000,
        sources: 32,
        contexts: 2,
      );
      final routing = HarborInterruptRouting.plic(plic: plic);

      final irq0 = routing.hartInterrupt(0);
      final irq1 = routing.hartInterrupt(1);
      expect(irq0.width, equals(1));
      expect(irq1.width, equals(1));
    });

    test('hartInterrupt with IMSIC returns seip', () {
      final aplic = HarborAplic(baseAddress: 0x0C000000, sources: 32, harts: 1);
      final imsic = HarborImsic(baseAddress: 0x24000000, hartIndex: 0);
      final routing = HarborInterruptRouting.aia(aplic: aplic, imsics: [imsic]);

      final irq = routing.hartInterrupt(0);
      expect(irq.width, equals(1));
    });

    test('hartMachineInterrupt only with IMSIC', () {
      final plic = HarborPlic(
        baseAddress: 0x0C000000,
        sources: 32,
        contexts: 1,
      );
      final plicRouting = HarborInterruptRouting.plic(plic: plic);
      expect(plicRouting.hartMachineInterrupt(0), isNull);

      final aplic = HarborAplic(baseAddress: 0x0C000000, sources: 32, harts: 1);
      final imsic = HarborImsic(baseAddress: 0x24000000, hartIndex: 0);
      final aiaRouting = HarborInterruptRouting.aia(
        aplic: aplic,
        imsics: [imsic],
      );
      expect(aiaRouting.hartMachineInterrupt(0), isNotNull);
    });

    test('hartInterrupt out of range throws', () {
      final plic = HarborPlic(
        baseAddress: 0x0C000000,
        sources: 32,
        contexts: 1,
      );
      final routing = HarborInterruptRouting.plic(plic: plic);
      expect(() => routing.hartInterrupt(5), throwsRangeError);
    });

    test('source overflow throws', () {
      final plic = HarborPlic(baseAddress: 0x0C000000, sources: 3, contexts: 1);
      final routing = HarborInterruptRouting.plic(plic: plic);

      routing.connectSource(HarborUart(baseAddress: 0x10000000));
      routing.connectSource(HarborGpio(baseAddress: 0x10001000));
      expect(
        () =>
            routing.connectSource(HarborSpiController(baseAddress: 0x10002000)),
        throwsStateError,
      );
    });
  });
}
