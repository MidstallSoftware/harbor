import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborDataPortInterface', () {
    test('creates with correct widths', () {
      final port = HarborDataPortInterface(32, 32);
      expect(port.dataWidth, equals(32));
      expect(port.addrWidth, equals(32));
      expect(port.ready.width, equals(1));
      expect(port.valid.width, equals(1));
    });

    test('creates with different widths', () {
      final port = HarborDataPortInterface(64, 48);
      expect(port.dataWidth, equals(64));
      expect(port.addrWidth, equals(48));
    });

    test('clone preserves config', () {
      final port = HarborDataPortInterface(64, 48);
      final cloned = port.clone();
      expect(cloned, isA<HarborDataPortInterface>());
      expect(cloned.dataWidth, equals(64));
      expect(cloned.addrWidth, equals(48));
      expect(cloned.ready.width, equals(1));
      expect(cloned.valid.width, equals(1));
    });
  });
}
