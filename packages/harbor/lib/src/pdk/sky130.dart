import 'analog_block.dart';
import 'pdk_provider.dart';
import 'standard_cell_library.dart';

/// SkyWater 130nm PDK provider.
///
/// Provides standard cell library paths, IO pad cells, and PLL
/// descriptors for the Sky130 process.
///
/// ```dart
/// final pdk = Sky130Provider(pdkRoot: '$PDK_ROOT/sky130A');
/// ```
class Sky130Provider extends PdkProvider {
  /// Root path to the Sky130 PDK installation.
  final String pdkRoot;

  /// Which standard cell library variant to use.
  final Sky130Variant variant;

  Sky130Provider({required this.pdkRoot, this.variant = Sky130Variant.hd});

  @override
  String get name => 'SkyWater SKY130';

  @override
  String get node => '130nm';

  @override
  int get metalLayers => 5;

  @override
  double get supplyVoltage => 1.8;

  String get _libName => switch (variant) {
    Sky130Variant.hd => 'sky130_fd_sc_hd',
    Sky130Variant.hs => 'sky130_fd_sc_hs',
    Sky130Variant.ms => 'sky130_fd_sc_ms',
    Sky130Variant.ls => 'sky130_fd_sc_ls',
    Sky130Variant.lp => 'sky130_fd_sc_lp',
    Sky130Variant.hdll => 'sky130_fd_sc_hdll',
  };

  @override
  StandardCellLibrary get standardCellLibrary => StandardCellLibrary(
    name: _libName,
    libertyPath:
        '$pdkRoot/libs.ref/$_libName/lib/${_libName}__tt_025C_1v80.lib',
    lefPath: '$pdkRoot/libs.ref/$_libName/lef/$_libName.lef',
    techLefPath: '$pdkRoot/libs.ref/$_libName/techlef/${_libName}__nom.tlef',
    verilogPath: '$pdkRoot/libs.ref/$_libName/verilog/$_libName.v',
    cellPrefix: '${_libName}__',
    siteName: 'unithd',
    tieHighCell: '${_libName}__conb_1',
    tieLowCell: '${_libName}__conb_1',
    clockBufferCells: [
      '${_libName}__clkbuf_1',
      '${_libName}__clkbuf_2',
      '${_libName}__clkbuf_4',
      '${_libName}__clkbuf_8',
      '${_libName}__clkbuf_16',
    ],
    fillCells: [
      '${_libName}__fill_1',
      '${_libName}__fill_2',
      '${_libName}__fill_4',
      '${_libName}__fill_8',
    ],
  );

  @override
  AnalogBlock ioCell({required int index}) => AnalogBlock(
    symbolPath: '$pdkRoot/libs.ref/sky130_fd_io/lef/sky130_fd_io.lef',
    pinMapping: {
      'padIn': 'PAD',
      'padOut': 'PAD',
      'padOutputEnable': 'OE_N',
      'fabricIn': 'IN',
      'fabricOut': 'OUT',
    },
    properties: {'name': 'io_$index'},
  );

  @override
  AnalogBlock pll({required int index}) => AnalogBlock(
    symbolPath:
        '$pdkRoot/libs.ref/sky130_fd_pr/cells/pll/sky130_fd_pr__pll.lef',
    pinMapping: {
      'refClk': 'CLK',
      'reset': 'RST',
      'clkOut': 'CLKOUT',
      'locked': 'LOCK',
    },
    properties: {'name': 'pll_$index'},
  );

  @override
  bool get hasTemperatureSensor => true;

  @override
  AnalogBlock? temperatureSensor() => AnalogBlock(
    symbolPath:
        '$pdkRoot/libs.ref/sky130_fd_pr/cells/npn_05v5/sky130_fd_pr__npn_05v5_W1p00L1p00.lef',
    pinMapping: {'vbe': 'B', 'collector': 'C', 'emitter': 'E'},
    properties: {
      'type': 'bandgap_bjt',
      'description': 'BJT for bandgap temp sensing',
    },
  );

  @override
  bool get hasEfuse => true;

  @override
  AnalogBlock? efuse({required int bits}) => AnalogBlock(
    symbolPath:
        '$pdkRoot/libs.ref/sky130_fd_pr/cells/efuse/sky130_fd_pr__efuse.lef',
    pinMapping: {'program': 'PGM', 'sense': 'SNS', 'data': 'Q'},
    properties: {'name': 'efuse_${bits}b', 'bits': '$bits'},
  );
}

/// Sky130 standard cell library variants.
enum Sky130Variant {
  /// High density (default).
  hd,

  /// High speed.
  hs,

  /// Medium speed.
  ms,

  /// Low speed.
  ls,

  /// Low power.
  lp,

  /// High density, low leakage.
  hdll,
}
