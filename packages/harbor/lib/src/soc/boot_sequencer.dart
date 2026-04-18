import 'package:rohd/rohd.dart';
import 'package:rohd_bridge/rohd_bridge.dart';

/// Boot sequencer state.
enum HarborBootState {
  /// Held in reset.
  reset,

  /// Running from mask ROM (cache-as-RAM).
  maskRom,

  /// Loading bootloader from SPI flash.
  spiLoad,

  /// Executing bootloader (e.g., U-Boot SPL).
  bootloader,

  /// Loading OpenSBI + payload from flash/DDR.
  firmware,

  /// Running OS.
  running,

  /// Error state (boot failed).
  error,
}

/// Boot sequencer for managing the power-on boot flow.
///
/// Orchestrates the sequence from power-on reset through to OS boot:
/// 1. Assert all resets, wait for PLL lock
/// 2. Release mask ROM reset, CPU starts executing from reset vector
/// 3. Mask ROM code loads bootloader from SPI flash into SRAM
/// 4. Jump to bootloader (initializes DDR, loads firmware)
/// 5. OpenSBI initializes, boots Linux
///
/// The sequencer controls:
/// - Per-domain reset release ordering
/// - PLL lock waiting
/// - Reset vector selection
/// - Boot mode pins (SPI, UART, JTAG boot)
/// - Boot status LEDs/GPIOs
class HarborBootSequencer extends BridgeModule {
  /// Number of boot mode pins.
  final int bootModePins;

  /// Reset vector address.
  final int resetVector;

  /// Number of reset domains to sequence.
  final int resetDomains;

  HarborBootSequencer({
    this.bootModePins = 2,
    this.resetVector = 0x00001000,
    this.resetDomains = 4,
    super.name = 'boot_seq',
  }) : super('HarborBootSequencer') {
    createPort('clk', PortDirection.input);
    createPort('por', PortDirection.input); // power-on reset

    // PLL status
    createPort('pll_locked', PortDirection.input);

    // Boot mode pins
    createPort('boot_mode', PortDirection.input, width: bootModePins);

    // Reset domain control outputs
    addOutput('domain_resets', width: resetDomains);

    // Reset vector output (muxed by boot mode)
    addOutput('reset_vector', width: 32);

    // Boot state output
    addOutput('boot_state', width: 4);

    // SPI flash interface control
    addOutput('spi_boot_start');
    createPort('spi_boot_done', PortDirection.input);
    createPort('spi_boot_error', PortDirection.input);

    // DDR ready
    createPort('ddr_ready', PortDirection.input);

    // Status
    addOutput('boot_done');
    addOutput('boot_error');

    final clk = input('clk');
    final por = input('por');

    final state = Logic(name: 'boot_state', width: 4);
    final delayCounter = Logic(name: 'delay_counter', width: 16);

    output('boot_state') <= state;
    output('reset_vector') <= Const(resetVector, width: 32);

    Sequential(clk, [
      If(
        por,
        then: [
          state < Const(HarborBootState.reset.index, width: 4),
          delayCounter < Const(0, width: 16),
          output('domain_resets') <
              Const((1 << resetDomains) - 1, width: resetDomains),
          output('spi_boot_start') < Const(0),
          output('boot_done') < Const(0),
          output('boot_error') < Const(0),
        ],
        orElse: [
          Case(state, [
            // Wait for PLL lock
            CaseItem(Const(HarborBootState.reset.index, width: 4), [
              If(
                input('pll_locked'),
                then: [
                  state < Const(HarborBootState.maskRom.index, width: 4),
                  // Release CPU domain reset (domain 0)
                  output('domain_resets') <
                      Const((1 << resetDomains) - 2, width: resetDomains),
                ],
              ),
            ]),

            // CPU running from mask ROM
            CaseItem(Const(HarborBootState.maskRom.index, width: 4), [
              // Wait a few cycles, then start SPI load
              delayCounter < delayCounter + 1,
              If(
                delayCounter.eq(Const(100, width: 16)),
                then: [
                  state < Const(HarborBootState.spiLoad.index, width: 4),
                  output('spi_boot_start') < Const(1),
                ],
              ),
            ]),

            // Loading from SPI flash
            CaseItem(Const(HarborBootState.spiLoad.index, width: 4), [
              output('spi_boot_start') < Const(0),
              If(
                input('spi_boot_done'),
                then: [
                  state < Const(HarborBootState.bootloader.index, width: 4),
                  // Release peripheral domain resets
                  output('domain_resets') < Const(0, width: resetDomains),
                ],
              ),
              If(
                input('spi_boot_error'),
                then: [
                  state < Const(HarborBootState.error.index, width: 4),
                  output('boot_error') < Const(1),
                ],
              ),
            ]),

            // Bootloader running (initializing DDR)
            CaseItem(Const(HarborBootState.bootloader.index, width: 4), [
              If(
                input('ddr_ready'),
                then: [state < Const(HarborBootState.firmware.index, width: 4)],
              ),
            ]),

            // Firmware (OpenSBI) loading
            CaseItem(Const(HarborBootState.firmware.index, width: 4), [
              state < Const(HarborBootState.running.index, width: 4),
              output('boot_done') < Const(1),
            ]),

            // Running
            CaseItem(Const(HarborBootState.running.index, width: 4), [
              // Normal operation
            ]),

            // Error
            CaseItem(Const(HarborBootState.error.index, width: 4), [
              // Stuck in error state until POR
            ]),
          ]),
        ],
      ),
    ]);
  }
}
