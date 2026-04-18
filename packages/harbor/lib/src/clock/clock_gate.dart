import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

/// Integrated clock gating cell (ICG).
///
/// Provides glitch-free clock gating using a latch-based design.
/// When `enable` is deasserted, the output clock stops low,
/// reducing dynamic power consumption.
///
/// On ASIC, this maps to a standard cell ICG (e.g., sky130_fd_sc_hd__dlclkp).
/// On FPGA, this maps to a BUFGCE (Xilinx) or similar.
class HarborClockGate extends BridgeModule {
  /// Gated clock output.
  Logic get gatedClk => output('gated_clk');

  HarborClockGate({super.name = 'clk_gate'}) : super('HarborClockGate') {
    createPort('clk', PortDirection.input);
    createPort('enable', PortDirection.input);
    createPort('test_enable', PortDirection.input); // scan test bypass
    addOutput('gated_clk');

    final clk = input('clk');
    final enable = input('enable');
    final testEnable = input('test_enable');

    // Latch-based clock gating: latch enable on low phase, AND with clock
    final latchedEn = Logic(name: 'latched_en');

    // Active-low latch (transparent when clk is low)
    // In synthesis, this becomes a proper ICG cell
    Combinational([
      If(~clk, then: [latchedEn < (enable | testEnable)]),
    ]);

    gatedClk <= clk & latchedEn;
  }
}
