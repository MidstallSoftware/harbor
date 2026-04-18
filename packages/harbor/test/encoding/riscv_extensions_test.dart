import 'package:harbor/harbor.dart';
import 'package:rohd/rohd.dart';
import 'package:test/test.dart';

void main() {
  group('Vector extension', () {
    test('vArithType has correct widths', () {
      expect(vArithType.width, equals(32));
      expect(vArithType['opcode']!.width, equals(7));
      expect(vArithType['vd']!.width, equals(5));
      expect(vArithType['funct3']!.width, equals(3));
      expect(vArithType['vs1']!.width, equals(5));
      expect(vArithType['vs2']!.width, equals(5));
      expect(vArithType['vm']!.width, equals(1));
      expect(vArithType['funct6']!.width, equals(6));
    });

    test('vLoadStoreType has correct widths', () {
      expect(vLoadStoreType.width, equals(32));
      expect(vLoadStoreType['nf']!.width, equals(3));
      expect(vLoadStoreType['mew']!.width, equals(1));
      expect(vLoadStoreType['mop']!.width, equals(2));
    });

    test('vtypeStruct decode', () {
      // LMUL=1, SEW=32, vta=1, vma=1 → 0b11_010_000 = 0xD0
      final vtype = vtypeStruct.decode(0xD0);
      expect(vtype['vlmul'], equals(Vlmul.m1));
      expect(vtype['vsew'], equals(Vsew.e32));
      expect(vtype['vta'], equals(1));
      expect(vtype['vma'], equals(1));
    });

    test('encode vadd instruction', () {
      final encoded = vArithType.encode({
        'opcode': vectorOpcode,
        'vd': 1,
        'funct3': VectorFunct3.opivv,
        'vs1': 2,
        'vs2': 3,
        'vm': 1, // unmasked
        'funct6': VectorFunct6.vadd,
      });

      final decoded = vArithType.decode(encoded);
      expect(decoded['opcode'], equals(vectorOpcode));
      expect(decoded['funct6'], equals(VectorFunct6.vadd));
      expect(decoded['funct3'], equals(VectorFunct3.opivv));
      expect(decoded['vd'], equals(1));
      expect(decoded['vs1'], equals(2));
      expect(decoded['vs2'], equals(3));
      expect(decoded['vm'], equals(1));
    });

    test('hardware view works', () {
      final signal = Logic(name: 'vinstr', width: 32);
      final view = vArithType.view(signal);

      expect(view['funct6'].width, equals(6));
      expect(view['vm'].width, equals(1));
      expect(view['vs2'].width, equals(5));
    });

    test('vector CSR addresses match spec', () {
      expect(VectorCsr.vstart, equals(0x008));
      expect(VectorCsr.vl, equals(0xC20));
      expect(VectorCsr.vtype, equals(0xC21));
      expect(VectorCsr.vlenb, equals(0xC22));
    });

    test('VLMUL constants', () {
      expect(Vlmul.m1, equals(0));
      expect(Vlmul.m2, equals(1));
      expect(Vlmul.m4, equals(2));
      expect(Vlmul.m8, equals(3));
      expect(Vlmul.mf2, equals(7));
      expect(Vlmul.mf4, equals(6));
      expect(Vlmul.mf8, equals(5));
    });
  });

  group('Hypervisor extension', () {
    test('hypervisor CSR addresses match spec', () {
      expect(HypervisorCsr.hstatus, equals(0x600));
      expect(HypervisorCsr.hedeleg, equals(0x602));
      expect(HypervisorCsr.hideleg, equals(0x603));
      expect(HypervisorCsr.hgatp, equals(0x680));
      expect(HypervisorCsr.htval, equals(0x643));
    });

    test('virtual supervisor CSR addresses', () {
      expect(HypervisorCsr.vsstatus, equals(0x200));
      expect(HypervisorCsr.vsepc, equals(0x241));
      expect(HypervisorCsr.vscause, equals(0x242));
      expect(HypervisorCsr.vsatp, equals(0x280));
    });

    test('hgatp modes match spec', () {
      expect(HgatpMode.bare, equals(0));
      expect(HgatpMode.sv39x4, equals(8));
      expect(HgatpMode.sv48x4, equals(9));
      expect(HgatpMode.sv57x4, equals(10));
    });

    test('hypervisor trap causes', () {
      expect(HypervisorTrap.virtualInstruction, equals(22));
      expect(HypervisorTrap.guestInstructionPageFault, equals(20));
      expect(HypervisorTrap.guestLoadPageFault, equals(21));
      expect(HypervisorTrap.guestStorePageFault, equals(23));
    });
  });

  group('CSR addresses', () {
    test('machine CSRs match spec', () {
      expect(MachineCsr.mstatus, equals(0x300));
      expect(MachineCsr.misa, equals(0x301));
      expect(MachineCsr.mie, equals(0x304));
      expect(MachineCsr.mtvec, equals(0x305));
      expect(MachineCsr.mepc, equals(0x341));
      expect(MachineCsr.mcause, equals(0x342));
      expect(MachineCsr.mhartid, equals(0xF14));
      expect(MachineCsr.mvendorid, equals(0xF11));
    });

    test('supervisor CSRs match spec', () {
      expect(SupervisorCsr.sstatus, equals(0x100));
      expect(SupervisorCsr.sie, equals(0x104));
      expect(SupervisorCsr.stvec, equals(0x105));
      expect(SupervisorCsr.sepc, equals(0x141));
      expect(SupervisorCsr.satp, equals(0x180));
    });

    test('user CSRs match spec', () {
      expect(UserCsr.cycle, equals(0xC00));
      expect(UserCsr.time, equals(0xC01));
      expect(UserCsr.instret, equals(0xC02));
    });

    test('misa extension bits', () {
      expect(MisaExtension.i, equals(8));
      expect(MisaExtension.m, equals(12));
      expect(MisaExtension.a, equals(0));
      expect(MisaExtension.c, equals(2));
      expect(MisaExtension.f, equals(5));
      expect(MisaExtension.d, equals(3));
      expect(MisaExtension.v, equals(21));
      expect(MisaExtension.h, equals(7));
      expect(MisaExtension.s, equals(18));
      expect(MisaExtension.u, equals(20));
    });

    test('privilege modes', () {
      expect(PrivilegeMode.user, equals(0));
      expect(PrivilegeMode.supervisor, equals(1));
      expect(PrivilegeMode.machine, equals(3));
    });

    test('satp modes', () {
      expect(SatpMode.bare, equals(0));
      expect(SatpMode.sv39, equals(8));
      expect(SatpMode.sv48, equals(9));
      expect(SatpMode.sv57, equals(10));
    });
  });
}
