import 'package:rohd/rohd.dart';

import '../bus.dart';
import 'wishbone_interface.dart';

/// Decodes a single Wishbone master to N Wishbone slaves based on
/// address mappings.
///
/// Each slave is associated with an [HarborAddressMapping] that determines
/// which addresses route to it. Unmatched addresses receive no ACK.
class WishboneDecoder extends Module {
  /// Per-slave hit signals (one-hot, which slave is selected).
  Logic get hit => output('hit');

  WishboneDecoder(
    WishboneInterface master,
    List<(WishboneInterface, HarborAddressMapping)> slaves, {
    super.name = 'wishbone_decoder',
  }) : super(definitionName: 'WishboneDecoder_S${slaves.length}') {
    if (slaves.isEmpty) {
      throw ArgumentError('At least one slave is required.');
    }

    final config = slaves.first.$1.config;

    // Validate address mappings
    final mappings = slaves.map((s) => s.$2).toList();
    final errors = validateAddressMappings(mappings);
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid address mappings: ${errors.join("; ")}');
    }

    // Master inputs
    final mCyc = addInput('m_cyc', master.cyc);
    final mStb = addInput('m_stb', master.stb);
    final mWe = addInput('m_we', master.we);
    final mAdr = addInput('m_adr', master.adr, width: config.addressWidth);
    final mDatMosi = addInput(
      'm_dat_mosi',
      master.datMosi,
      width: config.dataWidth,
    );
    final mSel = addInput('m_sel', master.sel, width: config.effectiveSelWidth);

    // Master response outputs
    final mAck = addOutput('m_ack');
    final mDatMiso = addOutput('m_dat_miso', width: config.dataWidth);
    master.ack <= mAck;
    master.datMiso <= mDatMiso;

    // Generate per-slave hit signals from address ranges
    addOutput('hit', width: slaves.length);
    final slaveAcks = <Logic>[];
    final slaveDatas = <Logic>[];

    for (var i = 0; i < slaves.length; i++) {
      final (slaveIntf, mapping) = slaves[i];
      final range = mapping.range;

      // Address hit: CYC && (ADR >= start) && (ADR < end)
      final startConst = Const(range.start, width: config.addressWidth);
      final endConst = Const(range.end, width: config.addressWidth);
      final hitI = mCyc & mAdr.gte(startConst) & mAdr.lt(endConst);
      hit[i] <= hitI;

      // Forward master signals to slave, gated by hit
      slaveIntf.cyc <= mCyc & hitI;
      slaveIntf.stb <= mStb & hitI;
      slaveIntf.we <= mWe;
      slaveIntf.adr <= mAdr - Const(range.start, width: config.addressWidth);
      slaveIntf.datMosi <= mDatMosi;
      slaveIntf.sel <= mSel;

      // Collect slave responses
      final sAck = addInput('s${i}_ack', slaveIntf.ack);
      final sDatMiso = addInput(
        's${i}_dat_miso',
        slaveIntf.datMiso,
        width: config.dataWidth,
      );
      slaveAcks.add(sAck);
      slaveDatas.add(sDatMiso);
    }

    // Mux slave responses back to master
    final muxedAck = Logic(name: 'muxed_ack');
    final muxedData = Logic(name: 'muxed_data', width: config.dataWidth);

    Combinational([
      muxedAck < Const(0),
      muxedData < Const(0, width: config.dataWidth),
      for (var i = slaves.length - 1; i >= 0; i--)
        If(hit[i], then: [muxedAck < slaveAcks[i], muxedData < slaveDatas[i]]),
    ]);

    mAck <= muxedAck;
    mDatMiso <= muxedData;
  }
}
