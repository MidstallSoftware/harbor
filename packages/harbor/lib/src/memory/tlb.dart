import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../riscv/paging.dart';

/// TLB entry permission flags.
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

/// Translation Lookaside Buffer (TLB).
///
/// Fully-associative or set-associative TLB for virtual-to-physical
/// address translation. Supports RISC-V Sv39/Sv48/Sv57 paging modes
/// and two-stage translation for the H extension (VS-stage + G-stage).
///
/// The TLB stores page table entries and performs permission checking.
/// On a miss, it signals the page table walker to perform a walk.
class HarborTlb extends BridgeModule {
  /// Number of TLB entries.
  final int entries;

  /// Supported paging modes.
  final List<RiscVPagingMode> pagingModes;

  /// Whether to support two-stage translation (hypervisor).
  final bool twoStage;

  /// Whether this is an instruction TLB (affects permission checks).
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

    // Lookup interface
    createPort(
      'lookup_vpn',
      PortDirection.input,
      width: 44,
    ); // max VPN width (Sv57)
    createPort('lookup_valid', PortDirection.input);
    createPort('lookup_asid', PortDirection.input, width: 16);
    createPort('lookup_vmid', PortDirection.input, width: 14); // for two-stage
    addOutput('lookup_ppn', width: 44);
    addOutput('lookup_hit');
    addOutput('lookup_fault');
    addOutput('lookup_perms', width: 7); // R/W/X/U/G/A/D

    // Page size output (for superpage support)
    addOutput('lookup_page_level', width: 3); // 0=4K, 1=2M, 2=1G, 3=512G

    // Write interface (from page table walker)
    createPort('write_valid', PortDirection.input);
    createPort('write_vpn', PortDirection.input, width: 44);
    createPort('write_ppn', PortDirection.input, width: 44);
    createPort('write_asid', PortDirection.input, width: 16);
    createPort('write_vmid', PortDirection.input, width: 14);
    createPort('write_perms', PortDirection.input, width: 7);
    createPort('write_level', PortDirection.input, width: 3);

    // Invalidation interface
    createPort('sfence', PortDirection.input); // SFENCE.VMA
    createPort('sfence_asid', PortDirection.input, width: 16);
    createPort('sfence_vpn', PortDirection.input, width: 44);
    createPort('sfence_asid_valid', PortDirection.input);
    createPort('sfence_vpn_valid', PortDirection.input);

    if (twoStage) {
      createPort('hfence_gvma', PortDirection.input); // HFENCE.GVMA
      createPort('hfence_vvma', PortDirection.input); // HFENCE.VVMA
    }

    // Current paging mode
    createPort('satp_mode', PortDirection.input, width: 4);
    if (twoStage) {
      createPort('hgatp_mode', PortDirection.input, width: 4);
    }

    final clk = input('clk');
    final reset = input('reset');

    // TLB storage would be implemented as registers or BRAM
    // depending on entry count. Framework provides the interface.
    Sequential(clk, [
      If(
        reset,
        then: [
          output('lookup_hit') < Const(0),
          output('lookup_fault') < Const(0),
          output('lookup_ppn') < Const(0, width: 44),
          output('lookup_perms') < Const(0, width: 7),
          output('lookup_page_level') < Const(0, width: 3),
        ],
        orElse: [
          output('lookup_hit') < Const(0),
          output('lookup_fault') < Const(0),

          // SFENCE.VMA handling
          If(
            input('sfence'),
            then: [
              // Invalidate matching entries based on ASID/VPN
            ],
          ),

          // Lookup: compare VPN against all entries
          If(
            input('lookup_valid'),
            then: [
              // CAM lookup across all entries
              // Check ASID match (or global bit)
              // Check VPN match at appropriate level
              // Return PPN and permissions
            ],
          ),

          // Write: install new entry (from PTW)
          If(
            input('write_valid'),
            then: [
              // Find victim entry (LRU or random)
              // Write new TLB entry
            ],
          ),
        ],
      ),
    ]);
  }
}
