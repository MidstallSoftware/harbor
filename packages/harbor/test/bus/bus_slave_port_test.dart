import 'package:harbor/harbor.dart';
import 'package:rohd_bridge/rohd_bridge.dart';
import 'package:test/test.dart';

void main() {
  group('BusSlavePort', () {
    test('creates Wishbone port', () {
      final mod = BridgeModule('test_wb', name: 'test');
      final port = BusSlavePort.create(
        module: mod,
        name: 'bus',
        protocol: BusProtocol.wishbone,
        addressWidth: 16,
        dataWidth: 32,
      );
      expect(port.protocol, equals(BusProtocol.wishbone));
      expect(port.addr.width, equals(16));
      expect(port.dataIn.width, equals(32));
      expect(port.dataOut.width, equals(32));
      expect(port.stb.width, equals(1));
      expect(port.we.width, equals(1));
      expect(port.ack.width, equals(1));
    });

    test('creates TileLink port', () {
      final mod = BridgeModule('test_tl', name: 'test');
      final port = BusSlavePort.create(
        module: mod,
        name: 'bus',
        protocol: BusProtocol.tilelink,
        addressWidth: 32,
        dataWidth: 32,
      );
      expect(port.protocol, equals(BusProtocol.tilelink));
      expect(port.addr.width, equals(32));
      expect(port.dataIn.width, equals(32));
      expect(port.dataOut.width, equals(32));
    });

    test('interface reference is set', () {
      final mod = BridgeModule('test', name: 'test');
      final port = BusSlavePort.create(
        module: mod,
        name: 'bus',
        protocol: BusProtocol.wishbone,
        addressWidth: 8,
        dataWidth: 32,
      );
      expect(port.interfaceRef, isNotNull);
    });
  });

  group('BusProtocol', () {
    test('enum values', () {
      expect(BusProtocol.values, hasLength(2));
      expect(BusProtocol.wishbone.name, equals('wishbone'));
      expect(BusProtocol.tilelink.name, equals('tilelink'));
    });
  });
}
