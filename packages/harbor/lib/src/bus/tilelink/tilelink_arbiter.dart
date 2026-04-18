import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart' show RoundRobinArbiter, PriorityArbiter;

import '../bus.dart';
import 'tilelink_interface.dart';

/// Arbitrates N TileLink masters onto a single TileLink slave.
///
/// Arbitrates on Channel A (requests). Channel D responses are
/// routed back by source ID. Source IDs are remapped to avoid
/// conflicts between masters.
class TileLinkArbiter extends Module {
  /// Which master is currently granted (one-hot).
  Logic get grant => output('grant');

  TileLinkArbiter(
    List<TileLinkInterface> masters,
    TileLinkInterface slave, {
    required Logic clk,
    required Logic reset,
    BusArbitration arbitration = BusArbitration.roundRobin,
    super.name = 'tilelink_arbiter',
  }) : super(definitionName: 'TileLinkArbiter_M${masters.length}') {
    if (masters.isEmpty) {
      throw ArgumentError('At least one master is required.');
    }

    final config = slave.config;
    final masterBits = (masters.length - 1).bitLength.clamp(1, 32);

    final clkIn = addInput('clk', clk);
    final resetIn = addInput('reset', reset);

    // Arbitration on Channel A valid signals
    final requests = <Logic>[];
    for (var i = 0; i < masters.length; i++) {
      requests.add(addInput('m${i}_a_valid', masters[i].aValid));
    }

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

    // Mux Channel A signals to slave
    final aOpcode = Logic(name: 'mux_a_opcode', width: 3);
    final aParam = Logic(name: 'mux_a_param', width: 3);
    final aSize = Logic(name: 'mux_a_size', width: config.sizeWidth);
    final aSource = Logic(name: 'mux_a_source', width: config.sourceWidth);
    final aAddress = Logic(name: 'mux_a_address', width: config.addressWidth);
    final aMask = Logic(name: 'mux_a_mask', width: config.maskWidth);
    final aData = Logic(name: 'mux_a_data', width: config.dataWidth);
    final aCorrupt = Logic(name: 'mux_a_corrupt');
    final aValid = Logic(name: 'mux_a_valid');

    Combinational([
      aValid < Const(0),
      aOpcode < Const(0, width: 3),
      aParam < Const(0, width: 3),
      aSize < Const(0, width: config.sizeWidth),
      aSource < Const(0, width: config.sourceWidth),
      aAddress < Const(0, width: config.addressWidth),
      aMask < Const(0, width: config.maskWidth),
      aData < Const(0, width: config.dataWidth),
      aCorrupt < Const(0),
      for (var i = masters.length - 1; i >= 0; i--)
        If(
          grantSignals[i],
          then: [
            aValid < masters[i].aValid,
            aOpcode < masters[i].aOpcode,
            aParam < masters[i].aParam,
            aSize < masters[i].aSize,
            // Remap source: prepend master index bits
            if (masterBits + config.sourceWidth <= config.sourceWidth)
              aSource <
                  ((Const(i, width: masterBits) <<
                          Const(
                            config.sourceWidth - masterBits,
                            width: config.sourceWidth,
                          )) |
                      masters[i].aSource)
            else
              aSource < masters[i].aSource,
            aAddress < masters[i].aAddress,
            aMask < masters[i].aMask,
            aData < masters[i].aData,
            aCorrupt < masters[i].aCorrupt,
          ],
        ),
    ]);

    slave.aValid <= aValid;
    slave.aOpcode <= aOpcode;
    slave.aParam <= aParam;
    slave.aSize <= aSize;
    slave.aSource <= aSource;
    slave.aAddress <= aAddress;
    slave.aMask <= aMask;
    slave.aData <= aData;
    slave.aCorrupt <= aCorrupt;

    // Route Channel A ready back to granted master
    for (var i = 0; i < masters.length; i++) {
      masters[i].aReady <= slave.aReady & grantSignals[i];
    }

    // Channel D: broadcast to all masters, gate valid by source ID
    for (var i = 0; i < masters.length; i++) {
      masters[i].dValid <= slave.dValid;
      masters[i].dOpcode <= slave.dOpcode;
      masters[i].dParam <= slave.dParam;
      masters[i].dSize <= slave.dSize;
      masters[i].dSource <= slave.dSource;
      masters[i].dSink <= slave.dSink;
      masters[i].dData <= slave.dData;
      masters[i].dCorrupt <= slave.dCorrupt;
      masters[i].dDenied <= slave.dDenied;
    }

    // D_READY: OR of all masters' ready (only granted one matters)
    Logic dReady = Const(0);
    for (var i = 0; i < masters.length; i++) {
      dReady = dReady | masters[i].dReady;
    }
    slave.dReady <= dReady;
  }
}
