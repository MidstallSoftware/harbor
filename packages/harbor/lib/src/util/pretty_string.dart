/// Options controlling the output of [HarborPrettyString.toPrettyString].
class HarborPrettyStringOptions {
  /// Indentation string per level (e.g. `'  '` or `'    '`).
  final String indent;

  /// Current nesting depth. Incremented by container types.
  final int depth;

  /// Whether to include type annotations in the output.
  final bool showTypes;

  const HarborPrettyStringOptions({
    this.indent = '  ',
    this.depth = 0,
    this.showTypes = false,
  });

  /// Returns a copy with depth incremented by one level.
  HarborPrettyStringOptions nested() => HarborPrettyStringOptions(
    indent: indent,
    depth: depth + 1,
    showTypes: showTypes,
  );

  /// The full indentation string for the current depth.
  String get prefix => indent * depth;

  /// The full indentation string for one level deeper.
  String get childPrefix => indent * (depth + 1);
}

/// Mixin for types that support formatted multi-line string output.
///
/// Implement [toPrettyString] to provide a human-readable, indented
/// representation. Useful for debug output, logging, and CLI display.
///
/// ```dart
/// class MyComponent with HarborPrettyString {
///   final String name;
///   final int width;
///   MyComponent(this.name, this.width);
///
///   @override
///   String toPrettyString([HarborPrettyStringOptions options = const HarborPrettyStringOptions()]) {
///     return '${options.prefix}MyComponent(\n'
///            '${options.childPrefix}name: $name,\n'
///            '${options.childPrefix}width: $width,\n'
///            '${options.prefix})';
///   }
/// }
/// ```
mixin HarborPrettyString {
  /// Returns a formatted, potentially multi-line string representation.
  ///
  /// The [options] control indentation depth and style.
  String toPrettyString([
    HarborPrettyStringOptions options = const HarborPrettyStringOptions(),
  ]);
}
