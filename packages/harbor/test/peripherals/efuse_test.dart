import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborEfuseConfig', () {
    test('default values', () {
      const config = HarborEfuseConfig();
      expect(config.totalBits, equals(256));
      expect(config.bitsPerWord, equals(32));
      expect(config.regions, equals(4));
      expect(config.hasEcc, isFalse);
    });

    test('words computed correctly', () {
      const config = HarborEfuseConfig();
      expect(config.words, equals(8)); // 256 / 32

      const config2 = HarborEfuseConfig(totalBits: 512, bitsPerWord: 64);
      expect(config2.words, equals(8)); // 512 / 64

      const config3 = HarborEfuseConfig(totalBits: 128, bitsPerWord: 32);
      expect(config3.words, equals(4)); // 128 / 32
    });
  });

  group('HarborEfuseBlock', () {
    test('creates with config', () {
      const config = HarborEfuseConfig();
      final block = HarborEfuseBlock(config: config);
      expect(block.config.totalBits, equals(256));
    });

    test('has addr output', () {
      final block = HarborEfuseBlock(config: const HarborEfuseConfig());
      expect(block.addr.width, greaterThan(0));
    });

    test('has wdata output', () {
      final block = HarborEfuseBlock(config: const HarborEfuseConfig());
      expect(block.wdata.width, equals(32));
    });

    test('has read output', () {
      final block = HarborEfuseBlock(config: const HarborEfuseConfig());
      expect(block.read_.width, equals(1));
    });

    test('has program output', () {
      final block = HarborEfuseBlock(config: const HarborEfuseConfig());
      expect(block.pgm.width, equals(1));
    });

    test('has rdata input', () {
      final block = HarborEfuseBlock(config: const HarborEfuseConfig());
      expect(block.rdata.width, equals(32));
    });

    test('has done input', () {
      final block = HarborEfuseBlock(config: const HarborEfuseConfig());
      expect(block.done.width, equals(1));
    });

    test('has busy output', () {
      final block = HarborEfuseBlock(config: const HarborEfuseConfig());
      expect(block.output('busy').width, equals(1));
    });
  });

  group('HarborEfuseDevice', () {
    test('creates with config', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      expect(device.config.totalBits, equals(256));
    });

    test('has bus', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      expect(device.bus, isNotNull);
    });

    test('has interrupt output', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      expect(device.interrupt.width, equals(1));
    });

    test('has fuse_addr output', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      expect(device.output('fuse_addr').width, greaterThan(0));
    });

    test('has fuse_read output', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      expect(device.output('fuse_read').width, equals(1));
    });

    test('has fuse_pgm output', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      expect(device.output('fuse_pgm').width, equals(1));
    });

    test('DT node has correct compatible', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      final dt = device.dtNode;
      expect(dt.compatible, contains('harbor,efuse'));
      expect(dt.compatible, contains('harbor,otp'));
    });

    test('DT node has correct properties', () {
      final device = HarborEfuseDevice(baseAddress: 0x20000000);
      final dt = device.dtNode;
      expect(dt.properties['harbor,total-bits'], equals(256));
      expect(dt.properties['harbor,bits-per-word'], equals(32));
      expect(dt.properties['harbor,regions'], equals(4));
      expect(dt.properties['harbor,unlock-key'], equals(0x4F545021));
    });

    test('custom unlock key works', () {
      final device = HarborEfuseDevice(
        baseAddress: 0x20000000,
        programUnlockKey: 0xDEADBEEF,
      );
      expect(device.programUnlockKey, equals(0xDEADBEEF));
      expect(device.dtNode.properties['harbor,unlock-key'], equals(0xDEADBEEF));
    });
  });
}
