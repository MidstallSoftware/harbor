import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart' show PriorityArbiter, RoundRobinArbiter;

import '../bus.dart';
import 'wishbone_interface.dart';

/// Arbitrates N Wishbone masters onto a single Wishbone slave.
///
/// Supports [BusArbitration.roundRobin] and [BusArbitration.fixed]
/// strategies. The selected master's signals are forwarded to the
/// slave, and the slave's responses are routed back.
class WishboneArbiter extends Module {
  /// The slave-side interface (output of the arbiter).
  late final WishboneInterface slave;

  /// Which master is currently granted (one-hot).
  Logic get grant => output('grant');

  WishboneArbiter(
    List<WishboneInterface> masters,
    WishboneInterface slaveInterface, {
    required Logic clk,
    required Logic reset,
    BusArbitration arbitration = BusArbitration.roundRobin,
    super.name = 'wishbone_arbiter',
  }) : super(definitionName: 'WishboneArbiter_M${masters.length}') {
    if (masters.isEmpty) {
      throw ArgumentError('At least one master is required.');
    }

    final config = slaveInterface.config;
    slave = slaveInterface;

    final clkIn = addInput('clk', clk);
    final resetIn = addInput('reset', reset);

    // Add master inputs
    final masterInputs =
        <
          ({
            Logic cyc,
            Logic stb,
            Logic we,
            Logic adr,
            Logic datMosi,
            Logic sel,
          })
        >[];

    for (var i = 0; i < masters.length; i++) {
      masterInputs.add((
        cyc: addInput('m${i}_cyc', masters[i].cyc),
        stb: addInput('m${i}_stb', masters[i].stb),
        we: addInput('m${i}_we', masters[i].we),
        adr: addInput('m${i}_adr', masters[i].adr, width: config.addressWidth),
        datMosi: addInput(
          'm${i}_dat_mosi',
          masters[i].datMosi,
          width: config.dataWidth,
        ),
        sel: addInput(
          'm${i}_sel',
          masters[i].sel,
          width: config.effectiveSelWidth,
        ),
      ));
    }

    // Add slave outputs
    final sCyc = addOutput('s_cyc');
    final sStb = addOutput('s_stb');
    final sWe = addOutput('s_we');
    final sAdr = addOutput('s_adr', width: config.addressWidth);
    final sDatMosi = addOutput('s_dat_mosi', width: config.dataWidth);
    final sSel = addOutput('s_sel', width: config.effectiveSelWidth);

    // Slave → master response inputs
    final sAck = addInput('s_ack', slaveInterface.ack);
    final sDatMiso = addInput(
      's_dat_miso',
      slaveInterface.datMiso,
      width: config.dataWidth,
    );

    // Connect slave outputs
    slaveInterface.cyc <= sCyc;
    slaveInterface.stb <= sStb;
    slaveInterface.we <= sWe;
    slaveInterface.adr <= sAdr;
    slaveInterface.datMosi <= sDatMosi;
    slaveInterface.sel <= sSel;

    // Arbitration: build request signals from CYC
    final requests = masterInputs.map((m) => m.cyc).toList();

    // Generate grant signals
    final grantSignals = <Logic>[];
    switch (arbitration) {
      case BusArbitration.roundRobin:
        final arbiter = RoundRobinArbiter(requests, clk: clkIn, reset: resetIn);
        grantSignals.addAll(arbiter.grants);
      case BusArbitration.fixed:
      case BusArbitration.priority:
        final arbiter = PriorityArbiter(requests);
        grantSignals.addAll(arbiter.grants);
    }

    addOutput('grant', width: masters.length);
    for (var i = 0; i < masters.length; i++) {
      grant[i] <= grantSignals[i];
    }

    // Mux master signals to slave based on grant
    final muxedCyc = Logic(name: 'muxed_cyc');
    final muxedStb = Logic(name: 'muxed_stb');
    final muxedWe = Logic(name: 'muxed_we');
    final muxedAdr = Logic(name: 'muxed_adr', width: config.addressWidth);
    final muxedDatMosi = Logic(name: 'muxed_dat_mosi', width: config.dataWidth);
    final muxedSel = Logic(name: 'muxed_sel', width: config.effectiveSelWidth);

    Combinational([
      muxedCyc < Const(0),
      muxedStb < Const(0),
      muxedWe < Const(0),
      muxedAdr < Const(0, width: config.addressWidth),
      muxedDatMosi < Const(0, width: config.dataWidth),
      muxedSel < Const(0, width: config.effectiveSelWidth),
      for (var i = masters.length - 1; i >= 0; i--)
        If(
          grantSignals[i],
          then: [
            muxedCyc < masterInputs[i].cyc,
            muxedStb < masterInputs[i].stb,
            muxedWe < masterInputs[i].we,
            muxedAdr < masterInputs[i].adr,
            muxedDatMosi < masterInputs[i].datMosi,
            muxedSel < masterInputs[i].sel,
          ],
        ),
    ]);

    sCyc <= muxedCyc;
    sStb <= muxedStb;
    sWe <= muxedWe;
    sAdr <= muxedAdr;
    sDatMosi <= muxedDatMosi;
    sSel <= muxedSel;

    // Route slave responses back to all masters
    // ACK is gated per-master, DAT_MISO is broadcast
    for (var i = 0; i < masters.length; i++) {
      masters[i].ack <= sAck & grantSignals[i];
      masters[i].datMiso <= sDatMiso;
    }
  }
}
