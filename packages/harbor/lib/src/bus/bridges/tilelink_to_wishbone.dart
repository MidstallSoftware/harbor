import 'package:rohd/rohd.dart';

import '../tilelink/tilelink_interface.dart';
import '../wishbone/wishbone_interface.dart';

/// Bridges a TileLink master to a Wishbone slave.
///
/// Converts TileLink Channel A requests to Wishbone transactions
/// and routes Wishbone responses back through Channel D.
/// Useful for connecting a TileLink CPU to Wishbone peripherals.
class TileLinkToWishboneBridge extends Module {
  TileLinkToWishboneBridge(
    TileLinkInterface tl,
    WishboneInterface wb, {
    super.name = 'tl2wb',
  }) : super(definitionName: 'TileLinkToWishboneBridge') {
    // TileLink Channel A -> Wishbone
    wb.cyc <= tl.aValid;
    wb.stb <= tl.aValid;
    wb.we <=
        tl.aOpcode.eq(Const(0, width: 3)) | // PutFullData
            tl.aOpcode.eq(Const(1, width: 3)); // PutPartialData
    wb.adr <= tl.aAddress.getRange(0, wb.config.addressWidth);
    wb.datMosi <= tl.aData.getRange(0, wb.config.dataWidth);
    wb.sel <= tl.aMask.getRange(0, wb.config.effectiveSelWidth);

    // Wishbone -> TileLink Channel D
    tl.dValid <= wb.ack;
    tl.dOpcode <= mux(wb.we, Const(0, width: 3), Const(1, width: 3));
    tl.dParam <= Const(0, width: 2);
    tl.dSize <= tl.aSize;
    tl.dSource <= tl.aSource;
    tl.dSink <= Const(0, width: tl.config.sinkWidth);
    tl.dData <= wb.datMiso.zeroExtend(tl.config.dataWidth);
    tl.dCorrupt <= Const(0);
    if (wb.err != null) {
      tl.dDenied <= wb.err!;
    } else {
      tl.dDenied <= Const(0);
    }

    // TileLink A_READY: accept when Wishbone is not stalling
    tl.aReady <= wb.ack | ~wb.cyc;
  }
}
