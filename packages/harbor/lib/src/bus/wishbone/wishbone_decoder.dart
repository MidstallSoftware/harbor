import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

import '../bus.dart';
import 'wishbone_interface.dart';

/// Decodes a single Wishbone master to N Wishbone slaves based on
/// address mappings.
class WishboneDecoder extends BridgeModule {
  WishboneDecoder(
    WishboneConfig config,
    List<HarborAddressMapping> mappings, {
    String name = 'wishbone_decoder',
  }) : super('WishboneDecoder_S${mappings.length}', name: name) {
    if (mappings.isEmpty) {
      throw ArgumentError('At least one slave is required.');
    }

    final errors = validateAddressMappings(mappings);
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid address mappings: ${errors.join("; ")}');
    }

    // Master: consumer role (we receive from bus master)
    final masterRef = addInterface(
      WishboneInterface(config),
      name: 'master',
      role: PairRole.consumer,
    );
    final m = masterRef.internalInterface as WishboneInterface;

    // Slaves: provider role (we drive to peripherals)
    final slaveIntfs = <WishboneInterface>[];
    for (var i = 0; i < mappings.length; i++) {
      final slaveRef = addInterface(
        WishboneInterface(config),
        name: 'slave_$i',
        role: PairRole.provider,
      );
      slaveIntfs.add(slaveRef.internalInterface as WishboneInterface);
    }

    // Address decode + route
    final hitBits = <Logic>[];
    final slaveAcks = <Logic>[];
    final slaveDatas = <Logic>[];

    for (var i = 0; i < mappings.length; i++) {
      final range = mappings[i].range;
      final s = slaveIntfs[i];

      final hitI =
          (m.cyc &
                  m.adr.gte(Const(range.start, width: config.addressWidth)) &
                  m.adr.lt(Const(range.end, width: config.addressWidth)))
              .named('hit_$i');
      hitBits.add(hitI);

      s.cyc <= m.cyc & hitI;
      s.stb <= m.stb & hitI;
      s.we <= m.we;
      s.adr <= m.adr - Const(range.start, width: config.addressWidth);
      s.datMosi <= m.datMosi;
      s.sel <= m.sel;

      slaveAcks.add(s.ack);
      slaveDatas.add(s.datMiso);
    }

    // Mux responses back to master
    final muxedAck = Logic(name: 'muxed_ack');
    final muxedData = Logic(name: 'muxed_data', width: config.dataWidth);

    Combinational([
      muxedAck < Const(0),
      muxedData < Const(0, width: config.dataWidth),
      for (var i = mappings.length - 1; i >= 0; i--)
        If(
          hitBits[i],
          then: [muxedAck < slaveAcks[i], muxedData < slaveDatas[i]],
        ),
    ]);

    m.ack <= muxedAck;
    m.datMiso <= muxedData;
  }
}
