import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../riscv/paging.dart';

class HarborTlbPermissions {
  final bool read;
  final bool write;
  final bool execute;
  final bool user;
  final bool global;
  final bool accessed;
  final bool dirty;

  const HarborTlbPermissions({
    this.read = false,
    this.write = false,
    this.execute = false,
    this.user = false,
    this.global = false,
    this.accessed = false,
    this.dirty = false,
  });
}

class HarborTlb extends BridgeModule {
  final int entries;
  final List<RiscVPagingMode> pagingModes;
  final bool twoStage;
  final bool isInstruction;

  HarborTlb({
    this.entries = 32,
    this.pagingModes = const [RiscVPagingMode.sv39, RiscVPagingMode.sv48],
    this.twoStage = false,
    this.isInstruction = false,
    String? name,
  }) : super('HarborTlb', name: name ?? (isInstruction ? 'itlb' : 'dtlb')) {
    createPort('clk', PortDirection.input);
    createPort('reset', PortDirection.input);

    createPort('lookup_vpn', PortDirection.input, width: 44);
    createPort('lookup_valid', PortDirection.input);
    createPort('lookup_asid', PortDirection.input, width: 16);
    if (twoStage) createPort('lookup_vmid', PortDirection.input, width: 14);
    addOutput('lookup_ppn', width: 44);
    addOutput('lookup_hit');
    addOutput('lookup_fault');
    addOutput('lookup_perms', width: 7);
    addOutput('lookup_page_level', width: 3);

    createPort('write_valid', PortDirection.input);
    createPort('write_vpn', PortDirection.input, width: 44);
    createPort('write_ppn', PortDirection.input, width: 44);
    createPort('write_asid', PortDirection.input, width: 16);
    if (twoStage) createPort('write_vmid', PortDirection.input, width: 14);
    createPort('write_perms', PortDirection.input, width: 7);
    createPort('write_level', PortDirection.input, width: 3);

    createPort('sfence', PortDirection.input);
    createPort('sfence_asid', PortDirection.input, width: 16);
    createPort('sfence_vpn', PortDirection.input, width: 44);
    createPort('sfence_asid_valid', PortDirection.input);
    createPort('sfence_vpn_valid', PortDirection.input);

    if (twoStage) {
      createPort('hfence_gvma', PortDirection.input);
      createPort('hfence_vvma', PortDirection.input);
    }

    createPort('satp_mode', PortDirection.input, width: 4);
    if (twoStage) createPort('hgatp_mode', PortDirection.input, width: 4);

    final clk = input('clk');
    final reset = input('reset');

    // Per-entry storage
    final entryValid = List.generate(
      entries,
      (i) => Logic(name: 'tlb_valid_$i'),
    );
    final entryVpn = List.generate(
      entries,
      (i) => Logic(name: 'tlb_vpn_$i', width: 44),
    );
    final entryPpn = List.generate(
      entries,
      (i) => Logic(name: 'tlb_ppn_$i', width: 44),
    );
    final entryAsid = List.generate(
      entries,
      (i) => Logic(name: 'tlb_asid_$i', width: 16),
    );
    final entryPerms = List.generate(
      entries,
      (i) => Logic(name: 'tlb_perms_$i', width: 7),
    );
    final entryLevel = List.generate(
      entries,
      (i) => Logic(name: 'tlb_level_$i', width: 3),
    );
    final entryAge = List.generate(
      entries,
      (i) => Logic(name: 'tlb_age_$i', width: entries.bitLength),
    );

    final lookupVpn = input('lookup_vpn');
    final lookupValid = input('lookup_valid');
    final lookupAsid = input('lookup_asid');

    // CAM lookup (combinational)
    Logic hitSignal = Const(0);
    Logic hitPpn = Const(0, width: 44);
    Logic hitPerms = Const(0, width: 7);
    Logic hitLevel = Const(0, width: 3);

    for (var i = entries - 1; i >= 0; i--) {
      final globalBit = entryPerms[i][4]; // bit 4 = global
      final asidMatch = globalBit | entryAsid[i].eq(lookupAsid);
      final vpnMatch = entryVpn[i].eq(lookupVpn);
      final isHit = entryValid[i] & asidMatch & vpnMatch;

      hitSignal = mux(isHit, Const(1), hitSignal);
      hitPpn = mux(isHit, entryPpn[i], hitPpn);
      hitPerms = mux(isHit, entryPerms[i], hitPerms);
      hitLevel = mux(isHit, entryLevel[i], hitLevel);
    }

    output('lookup_hit') <= lookupValid & hitSignal;
    output('lookup_fault') <= Const(0);
    output('lookup_ppn') <= hitPpn;
    output('lookup_perms') <= hitPerms;
    output('lookup_page_level') <= hitLevel;

    // Find LRU victim for write
    Logic victimIdx = Const(0, width: entries.bitLength);
    Logic oldestAge = Const(
      (1 << entries.bitLength) - 1,
      width: entries.bitLength,
    );

    for (var i = 0; i < entries; i++) {
      final isFree = ~entryValid[i];
      final isOlder = entryAge[i].lt(oldestAge);
      final isVictim = isFree | (entryValid[i] & isOlder);
      victimIdx = mux(isVictim, Const(i, width: entries.bitLength), victimIdx);
      oldestAge = mux(isVictim & entryValid[i], entryAge[i], oldestAge);
    }

    final sfence = input('sfence');
    final sfenceAsid = input('sfence_asid');
    final sfenceVpn = input('sfence_vpn');
    final sfenceAsidValid = input('sfence_asid_valid');
    final sfenceVpnValid = input('sfence_vpn_valid');

    final writeValid = input('write_valid');
    final writeVpn = input('write_vpn');
    final writePpn = input('write_ppn');
    final writeAsid = input('write_asid');
    final writePerms = input('write_perms');
    final writeLevel = input('write_level');

    Sequential(clk, [
      If(
        reset,
        then: [
          ...List.generate(entries, (i) => entryValid[i] < 0),
          ...List.generate(entries, (i) => entryAge[i] < 0),
        ],
        orElse: [
          // SFENCE.VMA invalidation
          If(
            sfence,
            then: [
              for (var i = 0; i < entries; i++)
                If(
                  entryValid[i],
                  then: [
                    If(
                      mux(
                        sfenceAsidValid,
                        mux(
                          sfenceVpnValid,
                          entryAsid[i].eq(sfenceAsid) &
                              entryVpn[i].eq(sfenceVpn) &
                              ~entryPerms[i][4],
                          entryAsid[i].eq(sfenceAsid) & ~entryPerms[i][4],
                        ),
                        mux(
                          sfenceVpnValid,
                          entryVpn[i].eq(sfenceVpn),
                          Const(1),
                        ),
                      ),
                      then: [entryValid[i] < 0],
                    ),
                  ],
                ),
            ],
          ),

          // Write new entry
          If(
            writeValid,
            then: [
              Case(victimIdx, [
                for (var i = 0; i < entries; i++)
                  CaseItem(Const(i, width: entries.bitLength), [
                    entryValid[i] < 1,
                    entryVpn[i] < writeVpn,
                    entryPpn[i] < writePpn,
                    entryAsid[i] < writeAsid,
                    entryPerms[i] < writePerms,
                    entryLevel[i] < writeLevel,
                    entryAge[i] <
                        Const(
                          (1 << entries.bitLength) - 1,
                          width: entries.bitLength,
                        ),
                  ]),
              ]),
              // Age all other entries
              for (var i = 0; i < entries; i++)
                If(
                  ~victimIdx.eq(Const(i, width: entries.bitLength)) &
                      entryValid[i],
                  then: [
                    If(
                      entryAge[i].gt(0),
                      then: [entryAge[i] < entryAge[i] - 1],
                    ),
                  ],
                ),
            ],
          ),

          // Update age on hit (promote to newest)
          If(
            lookupValid & hitSignal,
            then: [
              for (var i = 0; i < entries; i++)
                If(
                  entryValid[i] & entryVpn[i].eq(lookupVpn),
                  then: [
                    entryAge[i] <
                        Const(
                          (1 << entries.bitLength) - 1,
                          width: entries.bitLength,
                        ),
                  ],
                ),
            ],
          ),
        ],
      ),
    ]);
  }
}
