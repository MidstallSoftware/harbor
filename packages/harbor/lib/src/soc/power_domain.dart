import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../clock/clock_gate.dart';
import '../peripherals/pmu.dart' show HarborPowerManagementUnit;

/// Assigns a peripheral to a power domain.
class HarborPowerDomainAssignment {
  /// The peripheral module.
  final BridgeModule peripheral;

  /// Power domain index (matches PMU domain index).
  final int domainIndex;

  const HarborPowerDomainAssignment({
    required this.peripheral,
    required this.domainIndex,
  });
}

/// Automatic power domain integration.
///
/// Given a PMU and a set of peripheral-to-domain assignments,
/// automatically inserts clock gating cells between the system
/// clock and each peripheral's clock input, controlled by the
/// PMU's per-domain power enable outputs.
///
/// ```dart
/// final pmu = HarborPowerManagementUnit(
///   baseAddress: 0x10008000,
///   config: HarborPmuConfig(domains: [
///     HarborPowerDomain(name: 'core', index: 0),
///     HarborPowerDomain(name: 'periph', index: 1),
///     HarborPowerDomain(name: 'ddr', index: 2),
///   ]),
/// );
///
/// final powerIntegration = HarborPowerDomainIntegration(pmu: pmu);
///
/// powerIntegration.assign(uart, domain: 1);
/// powerIntegration.assign(spi, domain: 1);
/// powerIntegration.assign(ddrCtrl, domain: 2);
///
/// // Insert clock gates for all assigned peripherals
/// powerIntegration.insertClockGates(parentModule: soc, systemClk: clk);
/// ```
class HarborPowerDomainIntegration {
  /// The PMU controlling the power domains.
  final HarborPowerManagementUnit pmu;

  /// Peripheral-to-domain assignments.
  final List<HarborPowerDomainAssignment> _assignments = [];

  /// Generated clock gate instances (one per domain that has peripherals).
  final Map<int, HarborClockGate> _clockGates = {};

  HarborPowerDomainIntegration({required this.pmu});

  /// Assigns a peripheral to a power domain.
  void assign(BridgeModule peripheral, {required int domain}) {
    if (domain < 0) {
      throw ArgumentError('Domain index must be non-negative');
    }
    _assignments.add(
      HarborPowerDomainAssignment(peripheral: peripheral, domainIndex: domain),
    );
  }

  /// Assigns multiple peripherals to the same domain.
  void assignAll(List<BridgeModule> peripherals, {required int domain}) {
    for (final p in peripherals) {
      assign(p, domain: domain);
    }
  }

  /// Returns all peripherals assigned to a specific domain.
  List<BridgeModule> peripheralsInDomain(int domain) {
    return _assignments
        .where((a) => a.domainIndex == domain)
        .map((a) => a.peripheral)
        .toList();
  }

  /// Returns the domain index for a peripheral, or null if not assigned.
  int? domainOf(BridgeModule peripheral) {
    for (final a in _assignments) {
      if (identical(a.peripheral, peripheral)) return a.domainIndex;
    }
    return null;
  }

  /// Inserts clock gating cells for each power domain.
  ///
  /// For each domain that has at least one peripheral assigned:
  /// 1. Creates a [HarborClockGate] instance
  /// 2. Connects the system clock as input
  /// 3. Connects the PMU's domain power enable as the gate enable
  /// 4. Routes the gated clock to all peripherals in that domain
  ///
  /// The [parentModule] is the SoC or top-level module where the
  /// clock gates will be instantiated. [systemClk] is the ungated
  /// clock signal. [testEnable] is an optional scan-test bypass.
  void insertClockGates({
    required BridgeModule parentModule,
    required Logic systemClk,
    Logic? testEnable,
  }) {
    // Find which domains have peripherals
    final domainsUsed = <int>{};
    for (final a in _assignments) {
      domainsUsed.add(a.domainIndex);
    }

    // Create one clock gate per domain
    for (final domain in domainsUsed) {
      final gate = HarborClockGate(name: 'clk_gate_domain$domain');
      parentModule.addSubModule(gate);

      gate.input('clk') <= systemClk;
      // Find the domain's power output by matching domain index
      // to the PMU's domain list position
      final domainListIdx = pmu.config.domains.indexWhere(
        (d) => d.index == domain,
      );
      if (domainListIdx >= 0) {
        gate.input('enable').srcConnection! <= pmu.domainPower[domainListIdx];
      } else {
        gate.input('enable').srcConnection! <=
            Const(1); // always on if not in PMU
      }
      if (testEnable != null) {
        gate.input('test_enable').srcConnection! <= testEnable;
      } else {
        gate.input('test_enable').srcConnection! <= Const(0);
      }

      _clockGates[domain] = gate;

      // Connect gated clock to all peripherals in this domain
      for (final a in _assignments.where((a) => a.domainIndex == domain)) {
        // Disconnect the peripheral's clock from system clock
        // and reconnect to gated clock
        a.peripheral.input('clk') <= gate.gatedClk;
      }
    }
  }

  /// Returns the clock gate for a specific domain, or null if no
  /// peripherals are assigned to that domain.
  HarborClockGate? clockGateForDomain(int domain) => _clockGates[domain];

  /// Returns all domain indices that have peripherals assigned.
  Set<int> get usedDomains => _assignments.map((a) => a.domainIndex).toSet();

  /// Summary of domain assignments for debugging.
  String summary() {
    final buf = StringBuffer('Power Domain Assignments:\n');
    for (final domain in usedDomains.toList()..sort()) {
      final peripherals = peripheralsInDomain(domain);
      buf.writeln('  Domain $domain:');
      for (final p in peripherals) {
        buf.writeln('    - ${p.name}');
      }
    }
    return buf.toString();
  }
}
