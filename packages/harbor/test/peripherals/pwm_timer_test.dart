import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborPwmTimer', () {
    test('creates with default channels', () {
      final pwm = HarborPwmTimer(baseAddress: 0x10004000);
      expect(pwm.bus, isNotNull);
      expect(pwm.channels, equals(4));
      expect(pwm.pwmOut, hasLength(4));
    });

    test('creates with custom channel count', () {
      final pwm = HarborPwmTimer(baseAddress: 0x10004000, channels: 8);
      expect(pwm.pwmOut, hasLength(8));
    });

    test('DT node', () {
      final pwm = HarborPwmTimer(baseAddress: 0x10004000, channels: 2);
      final dt = pwm.dtNode;
      expect(dt.compatible.first, equals('harbor,pwm-timer'));
      expect(dt.properties['num-channels'], equals(2));
    });

    test('interrupt output exists', () {
      final pwm = HarborPwmTimer(baseAddress: 0x10004000);
      expect(pwm.interrupt.width, equals(1));
    });
  });
}
