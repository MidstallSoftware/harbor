import 'dart:async';

/// A single hold within a [HarborRetainer].
///
/// Call [release] when the associated work is complete.
class HarborRetainerHold {
  final HarborRetainer _retainer;
  bool _released = false;

  HarborRetainerHold._(this._retainer);

  /// Whether this hold has been released.
  bool get isReleased => _released;

  /// Releases this hold. Once all holds on the parent [HarborRetainer] are
  /// released, the retainer completes.
  ///
  /// Throws [StateError] if called more than once.
  void release() {
    if (_released) {
      throw StateError('HarborRetainerHold has already been released.');
    }
    _released = true;
    _retainer._onHoldReleased();
  }
}

/// Pools multiple [HarborRetainerHold]s. Completes when ALL holds are released.
///
/// ```dart
/// final retainer = HarborRetainer();
/// final h1 = retainer.apply();
/// final h2 = retainer.apply();
///
/// // ... do work ...
/// h1.release();
/// h2.release();
///
/// await retainer.wait; // completes after both released
/// ```
class HarborRetainer {
  final List<HarborRetainerHold> _holds = [];
  int _releasedCount = 0;
  Completer<void>? _completer;

  /// Creates a new hold. The caller is responsible for releasing it.
  ///
  /// Throws [StateError] if the retainer has already completed.
  HarborRetainerHold apply() {
    if (_completer != null && _completer!.isCompleted) {
      throw StateError('Cannot add holds to a completed HarborRetainer.');
    }
    final hold = HarborRetainerHold._(this);
    _holds.add(hold);
    return hold;
  }

  void _onHoldReleased() {
    _releasedCount++;
    if (_completer != null && _releasedCount == _holds.length) {
      _completer!.complete();
    }
  }

  /// Suspends until all holds have been released.
  ///
  /// Completes immediately if no holds were created.
  Future<void> get wait {
    if (_holds.isEmpty) return Future.value();
    if (_releasedCount == _holds.length) return Future.value();
    _completer ??= Completer<void>();
    return _completer!.future;
  }
}
