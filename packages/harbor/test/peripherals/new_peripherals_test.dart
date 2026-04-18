import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('HarborResetController', () {
    test('creates with default domains', () {
      final rc = HarborResetController(baseAddress: 0x10007000);
      expect(rc.domainCount, equals(4));
      expect(rc.systemReset.width, equals(1));
      expect(rc.domainResets.width, equals(4));
      expect(rc.resetCause.width, equals(3));
    });

    test('custom domain count', () {
      final rc = HarborResetController(baseAddress: 0x10007000, domainCount: 8);
      expect(rc.domainResets.width, equals(8));
    });

    test('DT node', () {
      final rc = HarborResetController(baseAddress: 0x10007000, domainCount: 4);
      final dt = rc.dtNode;
      expect(dt.compatible.first, equals('harbor,reset-controller'));
      expect(dt.reg.start, equals(0x10007000));
      expect(dt.properties['#reset-cells'], equals(1));
      expect(dt.properties['num-domains'], equals(4));
    });
  });

  group('HarborImsic', () {
    test('creates with default config', () {
      final imsic = HarborImsic(baseAddress: 0x24000000, hartIndex: 0);
      expect(imsic.numIds, equals(256));
      expect(imsic.meip.width, equals(1));
      expect(imsic.seip.width, equals(1));
    });

    test('DT node has MSI controller', () {
      final imsic = HarborImsic(baseAddress: 0x24000000, hartIndex: 0);
      final dt = imsic.dtNode;
      expect(dt.compatible.first, equals('riscv,imsics'));
      expect(dt.properties['msi-controller'], equals(true));
      expect(dt.properties['riscv,num-ids'], equals(256));
    });

    test('with guests', () {
      final imsic = HarborImsic(
        baseAddress: 0x24000000,
        hartIndex: 0,
        numGuests: 4,
      );
      expect(imsic.vseip, isNotNull);
      expect(imsic.vseip!.width, equals(4));
    });
  });

  group('HarborIommu', () {
    test('creates with defaults', () {
      final iommu = HarborIommu(baseAddress: 0x20000000);
      expect(iommu.iotlbEntries, equals(64));
      expect(iommu.interrupt.width, equals(1));
    });

    test('DT node', () {
      final iommu = HarborIommu(baseAddress: 0x20000000);
      final dt = iommu.dtNode;
      expect(dt.compatible.first, equals('riscv,iommu'));
      expect(dt.properties['#iommu-cells'], equals(1));
    });

    test('MSI translation', () {
      final iommu = HarborIommu(baseAddress: 0x20000000, msiTranslation: true);
      expect(iommu.output('msi_valid').width, equals(1));
      expect(iommu.output('msi_addr').width, equals(64));
    });
  });

  group('HarborHpmCounters', () {
    test('creates with default config', () {
      final hpm = HarborHpmCounters();
      expect(hpm.numCounters, equals(8));
      expect(hpm.output('mcycle').width, equals(64));
      expect(hpm.output('minstret').width, equals(64));
      expect(hpm.output('hpmcounter3').width, equals(64));
    });

    test('custom counter count', () {
      final hpm = HarborHpmCounters(numCounters: 16);
      expect(hpm.output('hpmcounter18').width, equals(64));
    });

    test('event inputs exist', () {
      final hpm = HarborHpmCounters();
      expect(hpm.input('event_cycles').width, equals(1));
      expect(hpm.input('event_instret').width, equals(1));
      expect(hpm.input('event_l1iMiss').width, equals(1));
      expect(hpm.input('event_branchMispredict').width, equals(1));
    });
  });

  group('HarborCryptoUnit', () {
    test('creates with all operations', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.output('result').width, equals(64));
      expect(crypto.output('result_valid').width, equals(1));
      expect(crypto.output('busy').width, equals(1));
    });

    test('supports all RVA23 crypto ops', () {
      final crypto = HarborCryptoUnit();
      expect(crypto.operations, contains(HarborCryptoOp.aesEncrypt));
      expect(crypto.operations, contains(HarborCryptoOp.aesDecrypt));
      expect(crypto.operations, contains(HarborCryptoOp.sha256));
      expect(crypto.operations, contains(HarborCryptoOp.sha512));
      expect(crypto.operations, contains(HarborCryptoOp.clmul));
      expect(crypto.operations, contains(HarborCryptoOp.bitManip));
      expect(crypto.operations, contains(HarborCryptoOp.crossbar));
    });
  });

  group('HarborTemperatureSensor', () {
    test('creates with external source', () {
      final temp = HarborTemperatureSensor(baseAddress: 0x10009000);
      expect(temp.source, equals(HarborTemperatureSource.external_));
      expect(temp.interrupt.width, equals(1));
    });

    test('DT node', () {
      final temp = HarborTemperatureSensor(baseAddress: 0x10009000);
      final dt = temp.dtNode;
      expect(dt.compatible.first, equals('harbor,temp-sensor'));
      expect(dt.properties['#thermal-sensor-cells'], equals(0));
    });

    // Note: fromTarget with FPGA targets requires proper ROHD module
    // hierarchy (addSubModule) for cross-module signal connection.
    // These are integration tests that need a full SoC context.

    test('fromTarget with iCE40 throws', () {
      expect(
        () => HarborTemperatureSensor.fromTarget(
          baseAddress: 0x10009000,
          target: const HarborFpgaTarget.ice40(device: 'up5k', package: 'sg48'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('HarborDebugModule', () {
    test('creates with defaults', () {
      final dm = HarborDebugModule(baseAddress: 0x0);
      expect(dm.numHarts, equals(1));
      expect(dm.progBufSize, equals(8));
      expect(dm.output('ndmreset').width, equals(1));
    });

    test('multi-hart', () {
      final dm = HarborDebugModule(baseAddress: 0x0, numHarts: 4);
      expect(dm.output('hart0_halt_req').width, equals(1));
      expect(dm.output('hart3_halt_req').width, equals(1));
    });

    test('DT node', () {
      final dm = HarborDebugModule(baseAddress: 0x0);
      final dt = dm.dtNode;
      expect(dt.compatible, contains('riscv,debug-013'));
    });
  });

  group('HarborTraceEncoder', () {
    test('creates with defaults', () {
      final trace = HarborTraceEncoder(baseAddress: 0x10010000);
      expect(trace.bufferSize, equals(4096));
      expect(trace.syncInterval, equals(256));
      expect(trace.output('trace_data').width, equals(32));
      expect(trace.output('trace_valid').width, equals(1));
    });

    test('DT node', () {
      final trace = HarborTraceEncoder(baseAddress: 0x10010000);
      final dt = trace.dtNode;
      expect(dt.compatible.first, equals('riscv,trace'));
      expect(dt.properties['buffer-size'], equals(4096));
    });
  });

  group('HarborBootSequencer', () {
    test('creates with defaults', () {
      final boot = HarborBootSequencer();
      expect(boot.resetVector, equals(0x00001000));
      expect(boot.resetDomains, equals(4));
      expect(boot.output('boot_state').width, equals(4));
      expect(boot.output('boot_done').width, equals(1));
      expect(boot.output('boot_error').width, equals(1));
      expect(boot.output('reset_vector').width, equals(32));
    });

    test('boot state enum', () {
      expect(HarborBootState.values, hasLength(7));
      expect(HarborBootState.reset.index, equals(0));
      expect(HarborBootState.running.index, equals(5));
      expect(HarborBootState.error.index, equals(6));
    });
  });
}
