import 'package:rohd_bridge/rohd_bridge.dart';

/// ECP5 EHXPLLL - Primary PLL.
class Ecp5Ehxplll extends BridgeModule {
  Ecp5Ehxplll({
    required int clkiDiv,
    required int clkfbDiv,
    required int clkopDiv,
    String feedbackPath = 'CLKOP',
    super.name = 'pll',
  }) : super('EHXPLLL', isSystemVerilogLeaf: true) {
    createPort('CLKI', PortDirection.input);
    createPort('CLKFB', PortDirection.input);
    createPort('RST', PortDirection.input);
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
class Ecp5Dp16kd extends BridgeModule {
  Ecp5Dp16kd({super.name = 'bram'})
    : super('DP16KD', isSystemVerilogLeaf: true) {
    // Port A
    createPort('DIA', PortDirection.input, width: 18);
    createPort('ADA', PortDirection.input, width: 14);
    createPort('CLKA', PortDirection.input);
    createPort('CEA', PortDirection.input);
    createPort('WEA', PortDirection.input);
    createPort('OCEA', PortDirection.input);
    createPort('RSTA', PortDirection.input);
    createPort('DOA', PortDirection.output, width: 18);
    // Port B
    createPort('DIB', PortDirection.input, width: 18);
    createPort('ADB', PortDirection.input, width: 14);
    createPort('CLKB', PortDirection.input);
    createPort('CEB', PortDirection.input);
    createPort('WEB', PortDirection.input);
    createPort('OCEB', PortDirection.input);
    createPort('RSTB', PortDirection.input);
    createPort('DOB', PortDirection.output, width: 18);
  }
}

/// ECP5 DTR - Die temperature readout.
///
/// Provides an 8-bit digital reading of the on-die temperature.
/// The STARTPULSE input triggers a measurement; DTROUT8 provides the result.
class Ecp5Dtr extends BridgeModule {
  Ecp5Dtr({super.name = 'dtr'}) : super('DTR', isSystemVerilogLeaf: true) {
    createPort('STARTPULSE', PortDirection.input);
    addOutput('DTROUT8', width: 8);
  }
}

/// ECP5 JTAGG - JTAG interface primitive.
class Ecp5Jtagg extends BridgeModule {
  Ecp5Jtagg({super.name = 'jtag'}) : super('JTAGG', isSystemVerilogLeaf: true) {
    addOutput('JTCK');
    addOutput('JTDI');
    createPort('JTDO1', PortDirection.input);
    createPort('JTDO2', PortDirection.input);
    addOutput('JSHIFT');
    addOutput('JUPDATE');
    addOutput('JRSTN');
    addOutput('JCE1');
    addOutput('JCE2');
    addOutput('JRTI1');
    addOutput('JRTI2');
  }
}
