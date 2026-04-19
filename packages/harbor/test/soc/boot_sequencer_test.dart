import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborBootSequencer', () {
    test('creates with defaults (resetVector=0x00001000, resetDomains=4)', () {
      final seq = HarborBootSequencer();
      expect(seq, isNotNull);
      expect(seq.resetVector, equals(0x00001000));
      expect(seq.resetDomains, equals(4));
    });

    test('boot_state output width=4', () {
      final seq = HarborBootSequencer();
      expect(seq.output('boot_state').width, equals(4));
    });

    test('reset_vector output width=32', () {
      final seq = HarborBootSequencer();
      expect(seq.output('reset_vector').width, equals(32));
    });

    test('domain_resets output width matches resetDomains', () {
      final seq = HarborBootSequencer(resetDomains: 4);
      expect(seq.output('domain_resets').width, equals(4));

      final seq8 = HarborBootSequencer(resetDomains: 8);
      expect(seq8.output('domain_resets').width, equals(8));
    });

    test('boot_done and boot_error outputs exist', () {
      final seq = HarborBootSequencer();
      expect(seq.output('boot_done').width, equals(1));
      expect(seq.output('boot_error').width, equals(1));
    });

    test('custom resetVector and resetDomains', () {
      final seq = HarborBootSequencer(resetVector: 0x80000000, resetDomains: 2);
      expect(seq.resetVector, equals(0x80000000));
      expect(seq.resetDomains, equals(2));
      expect(seq.output('domain_resets').width, equals(2));
    });
  });

  group('HarborBootState', () {
    test('has 7 values', () {
      expect(HarborBootState.values.length, equals(7));
    });

    test('correct indices', () {
      expect(HarborBootState.reset.index, equals(0));
      expect(HarborBootState.maskRom.index, equals(1));
      expect(HarborBootState.spiLoad.index, equals(2));
      expect(HarborBootState.bootloader.index, equals(3));
      expect(HarborBootState.firmware.index, equals(4));
      expect(HarborBootState.running.index, equals(5));
      expect(HarborBootState.error.index, equals(6));
    });
  });
}
