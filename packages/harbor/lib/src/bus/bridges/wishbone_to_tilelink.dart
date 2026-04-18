import 'package:rohd/rohd.dart';

import '../tilelink/tilelink_interface.dart';
import '../wishbone/wishbone_interface.dart';

/// Bridges a Wishbone master to a TileLink slave.
///
/// Converts Wishbone bus transactions to TileLink Channel A/D
/// transactions. Useful for connecting Wishbone peripherals to a
/// TileLink fabric.
class WishboneToTileLinkBridge extends Module {
  WishboneToTileLinkBridge(
    WishboneInterface wb,
    TileLinkInterface tl, {
    super.name = 'wb2tl',
  }) : super(definitionName: 'WishboneToTileLinkBridge') {
    final config = tl.config;

    // Wishbone -> TileLink Channel A
    tl.aValid <= wb.cyc & wb.stb;
    tl.aOpcode <=
        mux(wb.we, Const(0, width: 3), Const(4, width: 3)); // Put=0, Get=4
    tl.aParam <= Const(0, width: 3);
    tl.aSize <= Const(2, width: config.sizeWidth); // 4 bytes
    tl.aSource <= Const(0, width: config.sourceWidth);
    tl.aAddress <= wb.adr.zeroExtend(config.addressWidth);
    tl.aMask <= wb.sel.zeroExtend(config.maskWidth);
    tl.aData <= wb.datMosi.zeroExtend(config.dataWidth);
    tl.aCorrupt <= Const(0);

    // TileLink Channel D -> Wishbone
    wb.ack <= tl.dValid;
    wb.datMiso <= tl.dData.getRange(0, wb.config.dataWidth);
    tl.dReady <= Const(1);

    // Error (if Wishbone supports it)
    if (wb.err != null) {
      wb.err! <= tl.dDenied;
    }

    // Backpressure: Wishbone doesn't have ready, so stall via ACK timing
    // TileLink A_READY feeds back implicitly through the ACK path
  }
}
