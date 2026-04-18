import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('OpenSbiPlatform', () {
    late OpenSbiPlatform platform;

    setUp(() {
      platform = OpenSbiPlatform(
        name: 'test_soc',
        isa: RiscVIsaConfig(
          mxlen: RiscVMxlen.rv64,
          extensions: [rv32i, rv64i, rvM, rvA, rvC],
          hasSupervisor: true,
        ),
        hartCount: 2,
        clintBase: 0x02000000,
        plicBase: 0x0C000000,
        plicSources: 64,
        uartBase: 0x10000000,
        uartClock: 48000000,
        uartBaud: 115200,
        memBase: 0x80000000,
        memSize: 0x40000000,
      );
    });

    test('generates header with correct defines', () {
      final header = platform.generatePlatformHeader();
      expect(header, contains('#define HARBOR_HART_COUNT        2'));
      expect(header, contains('0x2000000'));
      expect(header, contains('0xc000000'));
      expect(header, contains('0x10000000'));
      expect(header, contains('HARBOR_PLIC_NUM_SOURCES  64'));
      expect(header, contains('HARBOR_UART_CLOCK        48000000'));
      expect(header, contains('HARBOR_MEM_SIZE          0x40000000'));
    });

    test('generates source with platform struct', () {
      final source = platform.generatePlatformSource();
      expect(source, contains('sbi_platform_operations'));
      expect(source, contains('sbi_platform platform'));
      expect(source, contains('.name              = "test_soc"'));
      expect(source, contains('.hart_count        = 2'));
    });

    test('generates CLINT addresses', () {
      final source = platform.generatePlatformSource();
      expect(source, contains('0x2000000'));
      expect(source, contains('mtime_addr'));
      expect(source, contains('mtimecmp_addr'));
      expect(source, contains('0xBFF8'));
      expect(source, contains('0x4000'));
    });

    test('generates PLIC init', () {
      final source = platform.generatePlatformSource();
      expect(source, contains('plic_cold_irqchip_init'));
      expect(source, contains('plic_warm_irqchip_init'));
      expect(source, contains('HARBOR_PLIC_NUM_SOURCES'));
    });

    test('generates UART console init', () {
      final source = platform.generatePlatformSource();
      expect(source, contains('uart8250_init'));
      expect(source, contains('48000000'));
      expect(source, contains('115200'));
    });

    test('header has include guard', () {
      final header = platform.generatePlatformHeader();
      expect(header, contains('#ifndef HARBOR_TEST_SOC_PLATFORM_H'));
      expect(header, contains('#define HARBOR_TEST_SOC_PLATFORM_H'));
      expect(header, contains('#endif'));
    });

    test('toPrettyString', () {
      final pretty = platform.toPrettyString();
      expect(pretty, contains('test_soc'));
      expect(pretty, contains('harts: 2'));
      expect(pretty, contains('RV64IMAC'));
    });

    test('single hart platform', () {
      final single = OpenSbiPlatform(
        name: 'minimal',
        isa: RiscVIsaConfig(mxlen: RiscVMxlen.rv32, extensions: [rv32i]),
        clintBase: 0x02000000,
        plicBase: 0x0C000000,
        uartBase: 0x10000000,
        memBase: 0x80000000,
        memSize: 0x1000000,
      );
      final source = single.generatePlatformSource();
      expect(source, contains('.hart_count = 1'));
    });
  });
}
