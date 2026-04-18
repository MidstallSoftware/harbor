import 'package:harbor/harbor.dart';
import 'package:test/test.dart';

void main() {
  group('JtagInterface', () {
    test('creates with core signals', () {
      final intf = JtagInterface();
      expect(intf.tck.width, equals(1));
      expect(intf.tms.width, equals(1));
      expect(intf.tdi.width, equals(1));
      expect(intf.tdo.width, equals(1));
      expect(intf.trst, isNull);
    });

    test('creates with TRST', () {
      final intf = JtagInterface(useTrst: true);
      expect(intf.trst, isNotNull);
      expect(intf.trst!.width, equals(1));
    });

    test('clone preserves config', () {
      final intf = JtagInterface(useTrst: true);
      final cloned = intf.clone();
      expect(cloned.useTrst, isTrue);
      expect(cloned.trst, isNotNull);
    });
  });

  group('JtagTapController', () {
    test('creates with correct port widths', () {
      final tap = JtagTapController(irWidth: 5, idcode: 0x10001FFF);
      expect(tap.output('state').width, equals(4));
      expect(tap.output('instruction').width, equals(5));
      expect(tap.output('tdo').width, equals(1));
    });

    test('builds without errors', () async {
      final tap = JtagTapController(irWidth: 5, idcode: 0x10001FFF);
      await tap.build();
    });

    test('addInstruction registers instruction', () {
      final tap = JtagTapController(irWidth: 5);
      tap.addInstruction(
        const JtagInstruction(opcode: 0x11, name: 'DMI_ACCESS', drWidth: 41),
      );
      // Instruction is registered for later use
    });
  });

  group('JtagInstruction', () {
    test('stores opcode and width', () {
      const instr = JtagInstruction(opcode: 0x10, name: 'DTMCS', drWidth: 32);
      expect(instr.opcode, equals(0x10));
      expect(instr.name, equals('DTMCS'));
      expect(instr.drWidth, equals(32));
    });
  });

  group('DmiInterface', () {
    test('creates with default widths', () {
      final dmi = DmiInterface();
      expect(dmi.reqAddr.width, equals(7));
      expect(dmi.reqData.width, equals(32));
      expect(dmi.reqOp.width, equals(2));
      expect(dmi.rspData.width, equals(32));
      expect(dmi.rspOp.width, equals(2));
    });

    test('creates with custom address width', () {
      final dmi = DmiInterface(addressWidth: 12);
      expect(dmi.reqAddr.width, equals(12));
    });

    test('clone preserves config', () {
      final dmi = DmiInterface(addressWidth: 10);
      final cloned = dmi.clone();
      expect(cloned.addressWidth, equals(10));
    });
  });

  group('DmiOp', () {
    test('opcodes match spec', () {
      expect(DmiOp.nop.value, equals(0));
      expect(DmiOp.read.value, equals(1));
      expect(DmiOp.write.value, equals(2));
    });
  });

  group('DmiStatus', () {
    test('status codes match spec', () {
      expect(DmiStatus.success.value, equals(0));
      expect(DmiStatus.failed.value, equals(2));
      expect(DmiStatus.busy.value, equals(3));
    });
  });

  group('JtagDtm', () {
    test('creates with DMI ports', () {
      final dtm = JtagDtm(dmiAddressWidth: 7);
      expect(dtm.output('dmi_req_valid').width, equals(1));
      expect(dtm.output('dmi_req_addr').width, equals(7));
      expect(dtm.output('dmi_req_data').width, equals(32));
      expect(dtm.output('dmi_req_op').width, equals(2));
    });

    test('builds without errors', () async {
      final dtm = JtagDtm();
      await dtm.build();
    });
  });
}
