import 'package:rohd/rohd.dart';

import '../bus.dart';
import 'tilelink_interface.dart';

/// Routes a single TileLink master to N TileLink slaves based on
/// address mappings.
///
/// Channel A requests are routed by address. Channel D responses
/// are muxed back to the master.
class TileLinkDecoder extends Module {
  /// Per-slave hit signals (one-hot).
  Logic get hit => output('hit');

  TileLinkDecoder(
    TileLinkInterface master,
    List<(TileLinkInterface, HarborAddressMapping)> slaves, {
    super.name = 'tilelink_decoder',
  }) : super(definitionName: 'TileLinkDecoder_S${slaves.length}') {
    if (slaves.isEmpty) {
      throw ArgumentError('At least one slave is required.');
    }

    final config = master.config;

    final mappings = slaves.map((s) => s.$2).toList();
    final errors = validateAddressMappings(mappings);
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid address mappings: ${errors.join("; ")}');
    }

    // Generate per-slave hit from Channel A address
    addOutput('hit', width: slaves.length);

    final slaveIntfs = <TileLinkInterface>[];
    for (var i = 0; i < slaves.length; i++) {
      final (slaveIntf, mapping) = slaves[i];
      slaveIntfs.add(slaveIntf);
      final range = mapping.range;

      final startConst = Const(range.start, width: config.addressWidth);
      final endConst = Const(range.end, width: config.addressWidth);
      final hitI =
          master.aValid &
          master.aAddress.gte(startConst) &
          master.aAddress.lt(endConst);
      hit[i] <= hitI;

      // Forward Channel A to slave, gated by hit
      slaveIntf.aValid <= master.aValid & hitI;
      slaveIntf.aOpcode <= master.aOpcode;
      slaveIntf.aParam <= master.aParam;
      slaveIntf.aSize <= master.aSize;
      slaveIntf.aSource <= master.aSource;
      slaveIntf.aAddress <=
          master.aAddress - Const(range.start, width: config.addressWidth);
      slaveIntf.aMask <= master.aMask;
      slaveIntf.aData <= master.aData;
      slaveIntf.aCorrupt <= master.aCorrupt;
    }

    // Channel A ready: OR of hit slaves' ready
    Logic aReady = Const(0);
    for (var i = 0; i < slaves.length; i++) {
      aReady = aReady | (hit[i] & slaveIntfs[i].aReady);
    }
    master.aReady <= aReady;

    // Mux Channel D responses back to master
    final dValid = Logic(name: 'mux_d_valid');
    final dOpcode = Logic(name: 'mux_d_opcode', width: 3);
    final dParam = Logic(name: 'mux_d_param', width: 2);
    final dSize = Logic(name: 'mux_d_size', width: config.sizeWidth);
    final dSource = Logic(name: 'mux_d_source', width: config.sourceWidth);
    final dSink = Logic(name: 'mux_d_sink', width: config.sinkWidth);
    final dData = Logic(name: 'mux_d_data', width: config.dataWidth);
    final dCorrupt = Logic(name: 'mux_d_corrupt');
    final dDenied = Logic(name: 'mux_d_denied');

    Combinational([
      dValid < Const(0),
      dOpcode < Const(0, width: 3),
      dParam < Const(0, width: 2),
      dSize < Const(0, width: config.sizeWidth),
      dSource < Const(0, width: config.sourceWidth),
      dSink < Const(0, width: config.sinkWidth),
      dData < Const(0, width: config.dataWidth),
      dCorrupt < Const(0),
      dDenied < Const(0),
      for (var i = slaves.length - 1; i >= 0; i--)
        If(
          slaveIntfs[i].dValid,
          then: [
            dValid < slaveIntfs[i].dValid,
            dOpcode < slaveIntfs[i].dOpcode,
            dParam < slaveIntfs[i].dParam,
            dSize < slaveIntfs[i].dSize,
            dSource < slaveIntfs[i].dSource,
            dSink < slaveIntfs[i].dSink,
            dData < slaveIntfs[i].dData,
            dCorrupt < slaveIntfs[i].dCorrupt,
            dDenied < slaveIntfs[i].dDenied,
          ],
        ),
    ]);

    master.dValid <= dValid;
    master.dOpcode <= dOpcode;
    master.dParam <= dParam;
    master.dSize <= dSize;
    master.dSource <= dSource;
    master.dSink <= dSink;
    master.dData <= dData;
    master.dCorrupt <= dCorrupt;
    master.dDenied <= dDenied;

    // D_READY: forward to all slaves
    for (final slaveIntf in slaveIntfs) {
      slaveIntf.dReady <= master.dReady;
    }
  }
}
