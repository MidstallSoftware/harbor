import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart'
    show Axi4ReadInterface, Axi4WriteInterface;

import '../wishbone/wishbone_interface.dart';

/// Bridges a Wishbone master to AXI4 read/write slave interfaces.
///
/// Converts Wishbone read/write transactions to AXI4 AR/R and AW/W/B
/// channels. Single-beat transfers only (no burst).
class WishboneToAxi4Bridge extends Module {
  WishboneToAxi4Bridge(
    WishboneInterface wb,
    Axi4ReadInterface axiRead,
    Axi4WriteInterface axiWrite, {
    super.name = 'wb2axi4',
  }) : super(definitionName: 'WishboneToAxi4Bridge') {
    final isRead = wb.cyc & wb.stb & ~wb.we;
    final isWrite = wb.cyc & wb.stb & wb.we;

    // Wishbone -> AXI4 Read (AR channel)
    axiRead.arValid <= isRead;
    axiRead.arAddr <= wb.adr.zeroExtend(axiRead.addrWidth);
    axiRead.arProt <= Const(0, width: 3);
    if (axiRead.arId != null) {
      axiRead.arId! <= Const(0, width: axiRead.idWidth);
    }
    if (axiRead.arLen != null) {
      axiRead.arLen! <= Const(0, width: axiRead.lenWidth); // single beat
    }
    if (axiRead.arSize != null) {
      axiRead.arSize! <= Const(2, width: 3); // 4 bytes
    }
    if (axiRead.arBurst != null) {
      axiRead.arBurst! <= Const(1, width: 2); // INCR
    }

    // AXI4 Read -> Wishbone (R channel)
    axiRead.rReady <= isRead;

    // Wishbone -> AXI4 Write (AW + W channels)
    axiWrite.awValid <= isWrite;
    axiWrite.awAddr <= wb.adr.zeroExtend(axiWrite.addrWidth);
    axiWrite.awProt <= Const(0, width: 3);
    if (axiWrite.awId != null) {
      axiWrite.awId! <= Const(0, width: axiWrite.idWidth);
    }
    if (axiWrite.awLen != null) {
      axiWrite.awLen! <= Const(0, width: axiWrite.lenWidth);
    }
    if (axiWrite.awSize != null) {
      axiWrite.awSize! <= Const(2, width: 3);
    }
    if (axiWrite.awBurst != null) {
      axiWrite.awBurst! <= Const(1, width: 2);
    }

    axiWrite.wData <= wb.datMosi.zeroExtend(axiWrite.dataWidth);
    axiWrite.wStrb <= wb.sel.zeroExtend(axiWrite.strbWidth);
    axiWrite.wLast <= Const(1);
    axiWrite.wValid <= isWrite;

    // AXI4 Write -> Wishbone (B channel)
    axiWrite.bReady <= isWrite;

    // Wishbone ACK from either read or write completion
    wb.ack <= (axiRead.rValid & isRead) | (axiWrite.bValid & isWrite);
    wb.datMiso <= axiRead.rData.getRange(0, wb.config.dataWidth);

    if (wb.err != null) {
      wb.err! <=
          (axiRead.rResp != null ? axiRead.rResp!.or() : Const(0)) |
              (axiWrite.bResp != null ? axiWrite.bResp!.or() : Const(0));
    }
  }
}
