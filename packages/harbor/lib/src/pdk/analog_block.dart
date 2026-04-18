import '../util/pretty_string.dart';

/// Describes an analog block's symbol and pin mapping for a specific PDK.
///
/// Used by [PdkProvider] to map canonical Harbor pin names to
/// PDK-specific cell/symbol names.
class AnalogBlock with HarborPrettyString {
  /// Symbol or cell path (e.g., xschem `.sym`, LEF macro name).
  final String symbolPath;

  /// Maps canonical pin names to PDK-specific pin names.
  ///
  /// Keys are Harbor names (e.g., `'refClk'`, `'padIn'`).
  /// Values are the PDK pin names (e.g., `'CLK'`, `'PAD'`).
  final Map<String, String> pinMapping;

  /// Additional instance properties (key=value pairs).
  final Map<String, String> properties;

  const AnalogBlock({
    required this.symbolPath,
    required this.pinMapping,
    this.properties = const {},
  });

  @override
  String toString() => 'AnalogBlock($symbolPath)';

  @override
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]) {
    final p = options.prefix;
    final c = options.childPrefix;
    final buf = StringBuffer('${p}AnalogBlock(\n');
    buf.writeln('${c}symbol: $symbolPath,');
    buf.writeln('${c}pins: {');
    for (final entry in pinMapping.entries) {
      buf.writeln(
        '${options.nested().childPrefix}${entry.key} -> ${entry.value},',
      );
    }
    buf.writeln('$c},');
    if (properties.isNotEmpty) {
      buf.writeln('${c}properties: $properties,');
    }
    buf.write('$p)');
    return buf.toString();
  }
}
