import 'handle.dart';

/// A reference-counted lock for coordinating elaboration ordering.
///
/// Tasks call [retain] to prevent the lock from completing, and
/// [release] to indicate they are done. When all retains have been
/// released, any tasks awaiting [wait] proceed.
///
/// ```dart
/// final lock = HarborLock()..retain();
///
/// // Later, after setup work is done:
/// lock.release();
///
/// // Elsewhere:
/// await lock.wait; // completes after release()
/// ```
class HarborLock {
  int _count = 0;
  HarborHandle<void>? _handle;

  /// Whether any retains are outstanding.
  bool get isLocked => _count > 0;

  /// Increments the retain count, preventing [wait] from completing.
  void retain() {
    if (_count == 0) {
      _handle = HarborHandle<void>();
    }
    _count++;
  }

  /// Decrements the retain count. When it reaches zero, [wait] completes.
  ///
  /// Throws [StateError] if called more times than [retain].
  void release() {
    if (_count <= 0) {
      throw StateError('Cannot release a HarborLock that is not retained.');
    }
    _count--;
    if (_count == 0) {
      _handle!.load(null);
    }
  }

  /// Suspends until all retains have been released.
  ///
  /// Completes immediately if nothing is retained.
  Future<void> get wait async {
    if (_count == 0) return;
    await _handle!.value;
  }
}
