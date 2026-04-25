import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

/// ECP5 EHXPLLL - Primary PLL.
class Ecp5Ehxplll extends BridgeModule {
  Ecp5Ehxplll({
    required int clkiDiv,
    required int clkfbDiv,
    required int clkopDiv,
    required Logic clk,
    required Logic clkfb,
    Logic? rst,
    String feedbackPath = 'CLKOP',
    super.name = 'pll',
  }) : super('EHXPLLL', isSystemVerilogLeaf: true) {
    clk = addInput('CLKI', clk);
    clkfb = addInput('CLKFB', clkfb);
    addInput('RST', rst ?? Const(0));
    addOutput('CLKOP');
    addOutput('CLKOS');
    addOutput('CLKOS2');
    addOutput('CLKOS3');
    addOutput('LOCK');
    addOutput('INTLOCK');

    createParameter('CLKI_DIV', '$clkiDiv');
    createParameter('CLKFB_DIV', '$clkfbDiv');
    createParameter('CLKOP_DIV', '$clkopDiv');
    createParameter('FEEDBK_PATH', '"$feedbackPath"');
  }
}

/// ECP5 DCCA - Dynamic clock control with clock mux.
class Ecp5Dcca extends BridgeModule {
  Ecp5Dcca({super.name = 'dcca'}) : super('DCCA', isSystemVerilogLeaf: true) {
    createPort('CLKI', PortDirection.input);
    createPort('CE', PortDirection.input);
    addOutput('CLKO');
  }
}

/// ECP5 BB - Bidirectional I/O buffer.
class Ecp5Bb extends BridgeModule {
  Ecp5Bb({super.name = 'bb'}) : super('BB', isSystemVerilogLeaf: true) {
    createPort('I', PortDirection.input);
    createPort('T', PortDirection.input);
    addOutput('O');
    createPort('B', PortDirection.inOut);
  }
}

/// ECP5 IB - Input buffer.
class Ecp5Ib extends BridgeModule {
  Ecp5Ib({super.name = 'ib'}) : super('IB', isSystemVerilogLeaf: true) {
    createPort('I', PortDirection.input);
    addOutput('O');
  }
}

/// ECP5 OB - Output buffer.
class Ecp5Ob extends BridgeModule {
  Ecp5Ob({super.name = 'ob'}) : super('OB', isSystemVerilogLeaf: true) {
    createPort('I', PortDirection.input);
    addOutput('O');
  }
}

/// ECP5 DP16KD - 16Kbit dual-port block RAM.
///
/// Ports use per-bit naming to match Yosys's cells_sim.v definition.
class Ecp5Dp16kd extends BridgeModule {
  Ecp5Dp16kd({
    required Logic clkA,
    required Logic ceA,
    required Logic weA,
    required Logic oceA,
    required Logic rstA,
    required Logic adA,
    required Logic diA,
    required Logic clkB,
    required Logic ceB,
    required Logic weB,
    required Logic oceB,
    required Logic rstB,
    required Logic adB,
    required Logic diB,
    Logic? csA,
    Logic? csB,
    super.name = 'bram',
  }) : super('DP16KD', isSystemVerilogLeaf: true) {
    // Port A inputs (per-bit)
    for (var i = 0; i < 18; i++) {
      addInput('DIA$i', diA.width > i ? diA[i] : Const(0));
    }
    for (var i = 0; i < 14; i++) {
      addInput('ADA$i', adA.width > i ? adA[i] : Const(0));
    }
    addInput('CLKA', clkA);
    addInput('CEA', ceA);
    addInput('OCEA', oceA);
    addInput('WEA', weA);
    addInput('RSTA', rstA);
    for (var i = 0; i < 3; i++) {
      addInput('CSA$i', csA != null && csA.width > i ? csA[i] : Const(0));
    }

    // Port A outputs (per-bit)
    for (var i = 0; i < 18; i++) {
      addOutput('DOA$i');
    }

    // Port B inputs (per-bit)
    for (var i = 0; i < 18; i++) {
      addInput('DIB$i', diB.width > i ? diB[i] : Const(0));
    }
    for (var i = 0; i < 14; i++) {
      addInput('ADB$i', adB.width > i ? adB[i] : Const(0));
    }
    addInput('CLKB', clkB);
    addInput('CEB', ceB);
    addInput('OCEB', oceB);
    addInput('WEB', weB);
    addInput('RSTB', rstB);
    for (var i = 0; i < 3; i++) {
      addInput('CSB$i', csB != null && csB.width > i ? csB[i] : Const(0));
    }

    // Port B outputs (per-bit)
    for (var i = 0; i < 18; i++) {
      addOutput('DOB$i');
    }
  }

  /// Port A read data as a bus.
  Logic get doA => [for (var i = 17; i >= 0; i--) output('DOA$i')].swizzle();

  /// Port B read data as a bus.
  Logic get doB => [for (var i = 17; i >= 0; i--) output('DOB$i')].swizzle();
}

/// ECP5 DTR - Die temperature readout.
class Ecp5Dtr extends BridgeModule {
  Ecp5Dtr({super.name = 'dtr'}) : super('DTR', isSystemVerilogLeaf: true) {
    createPort('STARTPULSE', PortDirection.input);
    addOutput('DTROUT8', width: 8);
  }
}

/// ECP5 JTAGG - JTAG interface access.
class Ecp5Jtagg extends BridgeModule {
  Ecp5Jtagg({super.name = 'jtag'}) : super('JTAGG', isSystemVerilogLeaf: true) {
    addOutput('JTCK');
    addOutput('JTDI');
    addOutput('JSHIFT');
    addOutput('JUPDATE');
    addOutput('JRSTN');
    addOutput('JCE1');
    addOutput('JCE2');
    addOutput('JRTI1');
    addOutput('JRTI2');
    createPort('JTDO1', PortDirection.input);
    createPort('JTDO2', PortDirection.input);
  }
}
