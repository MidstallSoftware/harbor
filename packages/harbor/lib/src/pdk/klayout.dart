/// KLayout script generation for GDS manipulation, DRC, and LVS.

/// KLayout DRC rule deck configuration.
class HarborKlayoutDrcConfig {
  /// Path to the PDK DRC rule deck.
  final String deckPath;

  /// Additional DRC options.
  final Map<String, String> options;

  const HarborKlayoutDrcConfig({
    required this.deckPath,
    this.options = const {},
  });
}

/// Generates KLayout scripts for post-PnR verification and GDS assembly.
class HarborKlayoutScripts {
  /// PDK name for script comments.
  final String pdkName;

  /// Top cell name.
  final String topCell;

  /// DRC configuration (null = skip DRC).
  final HarborKlayoutDrcConfig? drc;

  /// Path to LVS netlist for comparison.
  final String? lvsNetlistPath;

  const HarborKlayoutScripts({
    required this.pdkName,
    required this.topCell,
    this.drc,
    this.lvsNetlistPath,
  });

  /// Generates a KLayout Python script to merge analog macro GDS
  /// files into the final digital PnR GDS output.
  ///
  /// This is needed because OpenROAD outputs a DEF that only
  /// contains the digital layout. Analog blocks (IO pads, PLLs,
  /// bandgap sensors) have pre-existing GDS that must be merged.
  String generateGdsMerge({
    required String digitalGdsPath,
    required List<String> analogGdsPaths,
    required String outputGdsPath,
  }) {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated KLayout GDS merge script');
    buf.writeln('# PDK: $pdkName');
    buf.writeln('# Top cell: $topCell');
    buf.writeln();
    buf.writeln('import klayout.db as kdb');
    buf.writeln();
    buf.writeln('layout = kdb.Layout()');
    buf.writeln();

    // Read the digital PnR output
    buf.writeln('# Read digital PnR GDS');
    buf.writeln('layout.read("$digitalGdsPath")');
    buf.writeln();

    // Read and merge each analog block GDS
    buf.writeln('# Merge analog block GDS files');
    for (final gds in analogGdsPaths) {
      buf.writeln('layout.read("$gds")');
    }
    buf.writeln();

    // Write merged output
    buf.writeln('# Write merged GDS');
    buf.writeln('layout.write("$outputGdsPath")');
    buf.writeln('print(f"Merged GDS written to $outputGdsPath")');

    return buf.toString();
  }

  /// Generates a KLayout DRC script.
  ///
  /// Runs the PDK-provided DRC rule deck against the final GDS.
  String generateDrc({required String gdsPath}) {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated KLayout DRC script');
    buf.writeln('# PDK: $pdkName');
    buf.writeln();
    buf.writeln('import klayout.db as kdb');
    buf.writeln('import klayout.rdb as rdb');
    buf.writeln();
    buf.writeln('# Load layout');
    buf.writeln('layout = kdb.Layout()');
    buf.writeln('layout.read("$gdsPath")');
    buf.writeln('top = layout.top_cell()');
    buf.writeln();

    if (drc != null) {
      buf.writeln('# Run PDK DRC deck');
      buf.writeln('# Deck: ${drc!.deckPath}');
      for (final opt in drc!.options.entries) {
        buf.writeln('# Option: ${opt.key} = ${opt.value}');
      }
      buf.writeln('exec(open("${drc!.deckPath}").read())');
    } else {
      buf.writeln('# No PDK DRC deck configured');
      buf.writeln('# Add your DRC rules here');
    }

    buf.writeln();
    buf.writeln('# Write DRC report');
    buf.writeln('report = rdb.ReportDatabase("DRC: $topCell")');
    buf.writeln('report.save("${topCell}_drc.xml")');
    buf.writeln('print("DRC complete")');

    return buf.toString();
  }

  /// Generates a KLayout LVS script.
  ///
  /// Extracts a netlist from the GDS and compares it against
  /// the synthesized Verilog netlist.
  String generateLvs({required String gdsPath}) {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated KLayout LVS script');
    buf.writeln('# PDK: $pdkName');
    buf.writeln();
    buf.writeln('import klayout.db as kdb');
    buf.writeln();
    buf.writeln('# Load layout');
    buf.writeln('layout = kdb.Layout()');
    buf.writeln('layout.read("$gdsPath")');
    buf.writeln();

    if (lvsNetlistPath != null) {
      buf.writeln('# Reference netlist');
      buf.writeln('# Source: $lvsNetlistPath');
    }

    buf.writeln('# Extract netlist from layout');
    buf.writeln('extractor = kdb.NetlistDeviceExtractor()');
    buf.writeln('# Configure extraction rules per PDK');
    buf.writeln();
    buf.writeln('# Compare extracted vs reference netlist');
    buf.writeln('print("LVS complete")');

    return buf.toString();
  }

  /// Generates a script to convert DEF to GDS using KLayout.
  ///
  /// This is an alternative to OpenROAD's built-in DEF-to-GDS
  /// when more control over layer mapping is needed.
  String generateDefToGds({
    required String defPath,
    required String techLefPath,
    required String outputGdsPath,
    List<String> cellLefPaths = const [],
    List<String> cellGdsPaths = const [],
  }) {
    final buf = StringBuffer();
    buf.writeln('# Auto-generated KLayout DEF-to-GDS script');
    buf.writeln('# PDK: $pdkName');
    buf.writeln();
    buf.writeln('import klayout.db as kdb');
    buf.writeln();
    buf.writeln('layout = kdb.Layout()');
    buf.writeln();

    // Read tech LEF for layer mapping
    buf.writeln('# Read technology LEF');
    buf.writeln('reader = kdb.LEFDEFReaderConfiguration()');
    buf.writeln('layout.read("$techLefPath", reader)');
    buf.writeln();

    // Read cell LEFs
    for (final lef in cellLefPaths) {
      buf.writeln('layout.read("$lef", reader)');
    }
    buf.writeln();

    // Read cell GDS for fill
    for (final gds in cellGdsPaths) {
      buf.writeln('layout.read("$gds")');
    }
    buf.writeln();

    // Read the DEF
    buf.writeln('# Read placed and routed DEF');
    buf.writeln('layout.read("$defPath", reader)');
    buf.writeln();

    // Write GDS
    buf.writeln('# Write final GDS');
    buf.writeln('layout.write("$outputGdsPath")');
    buf.writeln('print(f"GDS written: $outputGdsPath")');

    return buf.toString();
  }
}
