import 'package:rohd_bridge/rohd_bridge.dart';

/// Xilinx 7-series MMCME2_ADV - Mixed-mode clock manager.
class XilinxMmcme2Adv extends BridgeModule {
  XilinxMmcme2Adv({
    required double clkfboutMult,
    required double clkout0Divide,
    required double divclkDivide,
    required double clkinPeriod,
    super.name = 'mmcm',
  }) : super('MMCME2_ADV', isSystemVerilogLeaf: true) {
    createPort('CLKIN1', PortDirection.input);
    createPort('CLKIN2', PortDirection.input);
    createPort('CLKINSEL', PortDirection.input);
    createPort('CLKFBIN', PortDirection.input);
    createPort('RST', PortDirection.input);
    createPort('PWRDWN', PortDirection.input);
    addOutput('CLKOUT0');
    addOutput('CLKOUT1');
    addOutput('CLKOUT2');
    addOutput('CLKOUT3');
    addOutput('CLKOUT4');
    addOutput('CLKOUT5');
    addOutput('CLKOUT6');
    addOutput('CLKFBOUT');
    addOutput('LOCKED');

    createParameter('CLKFBOUT_MULT_F', '$clkfboutMult');
    createParameter('CLKOUT0_DIVIDE_F', '$clkout0Divide');
    createParameter('DIVCLK_DIVIDE', '${divclkDivide.toInt()}');
    createParameter('CLKIN1_PERIOD', '$clkinPeriod');
  }
}

/// Xilinx 7-series BUFG - Global clock buffer.
class XilinxBufg extends BridgeModule {
  XilinxBufg({super.name = 'bufg'}) : super('BUFG', isSystemVerilogLeaf: true) {
    createPort('I', PortDirection.input);
    addOutput('O');
  }
}

/// Xilinx 7-series IBUF - Input buffer.
class XilinxIbuf extends BridgeModule {
  XilinxIbuf({super.name = 'ibuf'}) : super('IBUF', isSystemVerilogLeaf: true) {
    createPort('I', PortDirection.input);
    addOutput('O');
  }
}

/// Xilinx 7-series OBUF - Output buffer.
class XilinxObuf extends BridgeModule {
  XilinxObuf({super.name = 'obuf'}) : super('OBUF', isSystemVerilogLeaf: true) {
    createPort('I', PortDirection.input);
    addOutput('O');
  }
}

/// Xilinx 7-series IOBUF - Bidirectional I/O buffer.
class XilinxIobuf extends BridgeModule {
  XilinxIobuf({super.name = 'iobuf'})
    : super('IOBUF', isSystemVerilogLeaf: true) {
    createPort('I', PortDirection.input);
    createPort('T', PortDirection.input); // tristate (active low)
    addOutput('O');
    createPort('IO', PortDirection.inOut);
  }
}

/// Xilinx 7-series RAMB36E1 - 36Kbit block RAM.
class XilinxRamb36e1 extends BridgeModule {
  XilinxRamb36e1({
    int readWidthA = 36,
    int writeWidthA = 36,
    int readWidthB = 36,
    int writeWidthB = 36,
    super.name = 'bram',
  }) : super('RAMB36E1', isSystemVerilogLeaf: true) {
    // Port A
    createPort('DIADI', PortDirection.input, width: 32);
    createPort('DIPADIP', PortDirection.input, width: 4);
    createPort('ADDRARDADDR', PortDirection.input, width: 16);
    createPort('CLKARDCLK', PortDirection.input);
    createPort('ENARDEN', PortDirection.input);
    createPort('WEA', PortDirection.input, width: 4);
    createPort('REGCEAREGCE', PortDirection.input);
    createPort('RSTRAMARSTRAM', PortDirection.input);
    createPort('DOADO', PortDirection.output, width: 32);
    createPort('DOPADOP', PortDirection.output, width: 4);
    // Port B
    createPort('DIBDI', PortDirection.input, width: 32);
    createPort('DIPBDIP', PortDirection.input, width: 4);
    createPort('ADDRBWRADDR', PortDirection.input, width: 16);
    createPort('CLKBWRCLK', PortDirection.input);
    createPort('ENBWREN', PortDirection.input);
    createPort('WEBWE', PortDirection.input, width: 8);
    createPort('REGCEB', PortDirection.input);
    createPort('RSTRAMB', PortDirection.input);
    createPort('DOBDO', PortDirection.output, width: 32);
    createPort('DOPBDOP', PortDirection.output, width: 4);

    createParameter('READ_WIDTH_A', '$readWidthA');
    createParameter('WRITE_WIDTH_A', '$writeWidthA');
    createParameter('READ_WIDTH_B', '$readWidthB');
    createParameter('WRITE_WIDTH_B', '$writeWidthB');
  }
}

/// Xilinx 7-series BSCANE2 - Boundary scan (JTAG) primitive.
class XilinxBscane2 extends BridgeModule {
  XilinxBscane2({int jtagChain = 1, super.name = 'bscan'})
    : super('BSCANE2', isSystemVerilogLeaf: true) {
    addOutput('CAPTURE');
    addOutput('DRCK');
    addOutput('RESET');
    addOutput('RUNTEST');
    addOutput('SEL');
    addOutput('SHIFT');
    addOutput('TCK');
    addOutput('TDI');
    createPort('TDO', PortDirection.input);
    addOutput('TMS');
    addOutput('UPDATE');

    createParameter('JTAG_CHAIN', '$jtagChain');
  }
}

/// Xilinx 7-series XADC - Dual 12-bit analog-to-digital converter.
///
/// Provides on-die temperature and voltage monitoring.
/// Channel 0 = temperature, channel 1 = VCCINT, channel 2 = VCCAUX.
class XilinxXadc extends BridgeModule {
  XilinxXadc({super.name = 'xadc'}) : super('XADC', isSystemVerilogLeaf: true) {
    createPort('DCLK', PortDirection.input);
    createPort('DEN', PortDirection.input);
    createPort('DWE', PortDirection.input);
    createPort('DADDR', PortDirection.input, width: 7);
    createPort('DI', PortDirection.input, width: 16);
    addOutput('DO', width: 16);
    addOutput('DRDY');
    addOutput('OT'); // over-temperature alarm
    addOutput('ALM', width: 8); // alarm outputs
    createPort('CONVST', PortDirection.input);
    createPort('CONVSTCLK', PortDirection.input);
    createPort('RESET', PortDirection.input);
    createPort('VP', PortDirection.input);
    createPort('VN', PortDirection.input);
    addOutput('CHANNEL', width: 5);
    addOutput('EOC');
    addOutput('EOS');
    addOutput('BUSY');
  }
}

/// Xilinx 7-series DSP48E1 - DSP slice.
class XilinxDsp48e1 extends BridgeModule {
  XilinxDsp48e1({super.name = 'dsp'})
    : super('DSP48E1', isSystemVerilogLeaf: true) {
    createPort('A', PortDirection.input, width: 30);
    createPort('B', PortDirection.input, width: 18);
    createPort('C', PortDirection.input, width: 48);
    createPort('D', PortDirection.input, width: 25);
    createPort('CLK', PortDirection.input);
    createPort('CEP', PortDirection.input);
    createPort('RSTP', PortDirection.input);
    createPort('OPMODE', PortDirection.input, width: 7);
    createPort('ALUMODE', PortDirection.input, width: 4);
    createPort('P', PortDirection.output, width: 48);
    createPort('PCOUT', PortDirection.output, width: 48);
  }
}
