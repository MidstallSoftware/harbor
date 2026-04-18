import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import 'mmu_config.dart';

/// Synthesizable PMA (Physical Memory Attributes) checker.
///
/// Performs combinational lookup of physical addresses against a
/// compile-time-fixed PMA region table. Outputs the memory type,
/// ordering, and permission flags for the addressed region.
///
/// Used after address translation (post-TLB) to enforce physical
/// memory attributes on every access. An access to an empty region
/// or a permission violation causes an access fault.
///
/// ```dart
/// final pma = HarborPmaChecker(config: HarborPmaConfig(regions: [
///   HarborPmaRegion.memory(start: 0x80000000, size: 0x40000000),
///   HarborPmaRegion.io(start: 0x10000000, size: 0x10000000),
/// ]));
/// ```
class HarborPmaChecker extends BridgeModule {
  /// PMA configuration (compile-time fixed).
  final HarborPmaConfig config;

  /// Address width.
  final int addressWidth;

  HarborPmaChecker({
    required this.config,
    this.addressWidth = 64,
    super.name = 'pma_checker',
  }) : super('HarborPmaChecker') {
    // Input: physical address and access type
    createPort('addr', PortDirection.input, width: addressWidth);
    createPort('is_read', PortDirection.input);
    createPort('is_write', PortDirection.input);
    createPort('is_execute', PortDirection.input);
    createPort('is_atomic', PortDirection.input);
    createPort('access_width', PortDirection.input, width: 3); // log2 bytes

    // Output: attributes and fault
    addOutput('mem_type', width: 2); // HarborPmaMemoryType index
    addOutput('ordering', width: 2); // HarborPmaOrdering index
    addOutput('cacheable');
    addOutput('idempotent');
    addOutput('fault'); // access not permitted

    final addr = input('addr');
    final isRead = input('is_read');
    final isWrite = input('is_write');
    final isExecute = input('is_execute');
    final isAtomic = input('is_atomic');

    // Default: empty region (fault)
    Logic memType = Const(HarborPmaMemoryType.empty.index, width: 2);
    Logic ordering = Const(HarborPmaOrdering.strong.index, width: 2);
    Logic cacheable = Const(0);
    Logic idempotent = Const(0);
    Logic readable = Const(0);
    Logic writable = Const(0);
    Logic executable = Const(0);
    Logic atomicOk = Const(0);

    // Priority-encoded region match (last match wins)
    for (final region in config.regions) {
      final inRange =
          addr.gte(Const(region.start, width: addressWidth)) &
          addr.lt(Const(region.end, width: addressWidth));

      memType = mux(inRange, Const(region.memoryType.index, width: 2), memType);
      ordering = mux(inRange, Const(region.ordering.index, width: 2), ordering);
      cacheable = mux(
        inRange,
        Const(region.memoryType == HarborPmaMemoryType.memory ? 1 : 0),
        cacheable,
      );
      idempotent = mux(inRange, Const(region.idempotent ? 1 : 0), idempotent);
      readable = mux(inRange, Const(region.readable ? 1 : 0), readable);
      writable = mux(inRange, Const(region.writable ? 1 : 0), writable);
      executable = mux(inRange, Const(region.executable ? 1 : 0), executable);
      atomicOk = mux(inRange, Const(region.atomicSupport ? 1 : 0), atomicOk);
    }

    output('mem_type') <= memType;
    output('ordering') <= ordering;
    output('cacheable') <= cacheable;
    output('idempotent') <= idempotent;

    // Fault: access type not permitted by region attributes
    final readFault = isRead & ~readable;
    final writeFault = isWrite & ~writable;
    final execFault = isExecute & ~executable;
    final atomicFault = isAtomic & ~atomicOk;
    final emptyFault = memType.eq(
      Const(HarborPmaMemoryType.empty.index, width: 2),
    );

    output('fault') <=
        readFault | writeFault | execFault | atomicFault | emptyFault;
  }
}
