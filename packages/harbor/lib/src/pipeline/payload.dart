/// A named, typed key for data flowing through pipeline stages.
///
/// Define payloads as constants and reference them across plugins:
/// ```dart
/// const pc = HarborPayload('PC', width: 32);
/// const instruction = HarborPayload('INSTRUCTION', width: 32);
///
/// // In a pipeline node:
/// final pcSignal = node[pc];
/// ```
class HarborPayload {
  /// Human-readable name for this payload.
  final String name;

  /// Bit width of the payload signal.
  final int width;

  const HarborPayload(this.name, {this.width = 1});

  @override
  String toString() => 'HarborPayload($name, width: $width)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarborPayload && name == other.name && width == other.width;

  @override
  int get hashCode => Object.hash(name, width);
}
