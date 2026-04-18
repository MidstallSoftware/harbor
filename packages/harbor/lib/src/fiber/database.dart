import 'dart:async';

import 'handle.dart';

/// A named, typed key for [HarborDatabase] lookups.
///
/// Define as constants for well-known configuration entries:
/// ```dart
/// const xlen = HarborDatabaseKey<int>('xlen');
/// const physicalWidth = HarborDatabaseKey<int>('physicalWidth');
/// ```
class HarborDatabaseKey<T> {
  /// Human-readable name for this key.
  final String name;

  const HarborDatabaseKey(this.name);

  @override
  String toString() => 'HarborDatabaseKey<$T>($name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarborDatabaseKey<T> && name == other.name;

  @override
  int get hashCode => Object.hash(T, name);
}

/// Base type for values stored in a [HarborDatabase].
sealed class HarborDatabaseElement<T> {
  const HarborDatabaseElement();

  /// Retrieves the value. May complete synchronously or asynchronously
  /// depending on the element type.
  FutureOr<T> get value;
}

/// An immediately available value.
class HarborValueElement<T> extends HarborDatabaseElement<T> {
  T _value;

  HarborValueElement(this._value);

  @override
  T get value => _value;

  set value(T v) => _value = v;
}

/// A fiber-aware element that suspends callers until a value is set.
///
/// Uses [HarborHandle] internally for deferred value delivery.
class HarborBlockingElement<T> extends HarborDatabaseElement<T> {
  final HarborHandle<T> _handle = HarborHandle<T>();

  HarborBlockingElement();

  /// Whether this element has been set.
  bool get isSet => _handle.isLoaded;

  @override
  Future<T> get value => _handle.value;

  /// Sets the value, completing any pending reads.
  void set(T val) => _handle.load(val);
}

/// A lazily-computed element. The value is computed on first access
/// and cached.
class HarborLambdaElement<T> extends HarborDatabaseElement<T> {
  final T Function() _compute;
  T? _cached;
  bool _computed = false;

  HarborLambdaElement(this._compute);

  @override
  T get value {
    if (!_computed) {
      _cached = _compute();
      _computed = true;
    }
    return _cached as T;
  }
}

/// A per-context key-value store for sharing configuration and state
/// across plugins.
///
/// Each [PluginHost] has its own [HarborDatabase] - no global state.
///
/// ```dart
/// const xlen = HarborDatabaseKey<int>('xlen');
///
/// database.set(xlen, HarborValueElement(32));
/// final width = database.get(xlen).value; // 32
/// ```
class HarborDatabase {
  final Map<HarborDatabaseKey<dynamic>, HarborDatabaseElement<dynamic>>
  _elements = {};

  /// Stores an [element] under the given [key].
  void set<T>(HarborDatabaseKey<T> key, HarborDatabaseElement<T> element) {
    _elements[key] = element;
  }

  /// Retrieves the element for [key].
  ///
  /// Throws [StateError] if not found.
  HarborDatabaseElement<T> get<T>(HarborDatabaseKey<T> key) {
    final element = _elements[key];
    if (element == null) {
      throw StateError('No element found for $key');
    }
    return element as HarborDatabaseElement<T>;
  }

  /// Retrieves the element for [key], or `null` if not found.
  HarborDatabaseElement<T>? tryGet<T>(HarborDatabaseKey<T> key) {
    final element = _elements[key];
    return element as HarborDatabaseElement<T>?;
  }

  /// Whether an element exists for [key].
  bool has<T>(HarborDatabaseKey<T> key) => _elements.containsKey(key);

  /// All keys currently stored.
  Iterable<HarborDatabaseKey<dynamic>> get keys => _elements.keys;

  /// Validates that all [HarborBlockingElement]s have been set.
  ///
  /// Returns a list of keys whose blocking elements are still unset.
  List<HarborDatabaseKey<dynamic>> get unresolvedBlockingKeys {
    return _elements.entries
        .where(
          (e) =>
              e.value is HarborBlockingElement &&
              !(e.value as HarborBlockingElement).isSet,
        )
        .map((e) => e.key)
        .toList();
  }
}
