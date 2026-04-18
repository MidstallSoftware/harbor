import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../peripherals/aplic.dart';
import '../peripherals/imsic.dart';
import '../peripherals/plic.dart';

/// Describes the interrupt controller topology for a SoC.
///
/// Supports three configurations:
/// - **PLIC only**: Legacy, used for simpler SoCs
/// - **APLIC + IMSIC**: AIA (Advanced Interrupt Architecture), required for RVA23
/// - **APLIC in MSI mode**: APLIC converts wired interrupts to MSIs for IMSIC
///
/// ```dart
/// final routing = HarborInterruptRouting.aia(
///   aplic: aplic,
///   imsics: [imsic0, imsic1], // one per hart
/// );
///
/// // Wire all peripherals' interrupts
/// for (final peripheral in soc.peripherals) {
///   routing.connectSource(peripheral);
/// }
///
/// // Get per-hart interrupt outputs
/// final hart0Eip = routing.hartInterrupt(0);
/// ```
class HarborInterruptRouting {
  /// The PLIC instance (if using legacy interrupt delivery).
  final HarborPlic? plic;

  /// The APLIC instance (if using AIA).
  final HarborAplic? aplic;

  /// Per-hart IMSIC instances (if using AIA with MSI delivery).
  final List<HarborImsic>? imsics;

  /// Number of harts.
  final int numHarts;

  /// Interrupt sources connected so far.
  int _nextSourceIndex = 1; // source 0 is reserved in PLIC/APLIC

  /// Legacy PLIC-only interrupt routing.
  HarborInterruptRouting.plic({required HarborPlic this.plic})
    : aplic = null,
      imsics = null,
      numHarts = plic.contexts;

  /// AIA interrupt routing (APLIC with wired delivery).
  HarborInterruptRouting.aplicWired({required HarborAplic this.aplic})
    : plic = null,
      imsics = null,
      numHarts = aplic.harts;

  /// AIA interrupt routing (APLIC + IMSIC with MSI delivery).
  ///
  /// This is the recommended configuration for RVA23 SoCs.
  /// APLIC converts wired interrupts from peripherals into MSIs
  /// delivered to per-hart IMSICs.
  HarborInterruptRouting.aia({
    required HarborAplic this.aplic,
    required List<HarborImsic> this.imsics,
  }) : plic = null,
       numHarts = imsics.length;

  /// Map of peripheral name to assigned source index.
  final Map<String, int> _sourceMap = {};

  /// Assigns the next available interrupt source index to a peripheral.
  ///
  /// The peripheral must have an output port named `'interrupt'`.
  /// Returns the assigned source index.
  ///
  /// Actual signal wiring should be done at the SoC level using
  /// `connectPorts` after all sources are assigned:
  /// ```dart
  /// final sourceMap = routing.connectSources(soc.peripherals);
  /// for (final entry in sourceMap.entries) {
  ///   soc.connectPorts(
  ///     peripheral.port('interrupt'),
  ///     plic.port('src_irq_${entry.value}'),
  ///   );
  /// }
  /// ```
  int connectSource(BridgeModule peripheral) {
    final sourceIdx = _nextSourceIndex++;
    final maxSources = plic?.sources ?? aplic?.sources ?? 0;

    if (sourceIdx >= maxSources) {
      throw StateError(
        'Interrupt source overflow: trying to connect source $sourceIdx '
        'but controller only has $maxSources sources',
      );
    }

    _sourceMap[peripheral.name] = sourceIdx;
    return sourceIdx;
  }

  /// Assigns interrupt source indices for multiple peripherals.
  ///
  /// Skips interrupt controllers (PLIC, APLIC, IMSIC) and peripherals
  /// that don't have an `'interrupt'` output port.
  ///
  /// Returns a map of peripheral name to assigned source index.
  Map<String, int> connectSources(List<BridgeModule> peripherals) {
    final result = <String, int>{};
    for (final p in peripherals) {
      // Skip interrupt controllers themselves
      if (p is HarborPlic || p is HarborAplic || p is HarborImsic) continue;
      // Check if peripheral has an interrupt output
      try {
        p.output('interrupt');
      } on Exception {
        continue;
      }
      result[p.name] = connectSource(p);
    }
    return result;
  }

  /// Returns the source index assigned to a peripheral, or null.
  int? sourceIndexOf(String peripheralName) => _sourceMap[peripheralName];

  /// Returns the external interrupt output for hart [index].
  ///
  /// For PLIC: returns `ext_irq_<index>`
  /// For APLIC (wired): returns `ext_irq_<index>`
  /// For APLIC+IMSIC: returns IMSIC's `seip` (supervisor external interrupt)
  Logic hartInterrupt(int index) {
    if (index >= numHarts) {
      throw RangeError('Hart index $index out of range (0-${numHarts - 1})');
    }

    if (imsics != null) {
      return imsics![index].seip;
    } else if (plic != null) {
      return plic!.externalInterrupt[index];
    } else if (aplic != null) {
      return aplic!.externalInterrupt[index];
    }

    throw StateError('No interrupt controller configured');
  }

  /// Returns the machine-level external interrupt for hart [index].
  ///
  /// Only available with IMSIC (AIA mode).
  Logic? hartMachineInterrupt(int index) {
    if (imsics == null || index >= numHarts) return null;
    return imsics![index].meip;
  }

  /// Total number of interrupt sources connected.
  int get sourceCount => _nextSourceIndex;
}
