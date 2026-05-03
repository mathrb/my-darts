// DataChangeNotifier
// Coarse-grained "something changed" signal for the sqflite backend.
//
// Drift exposes per-query reactivity natively via `.watch()`. Sqflite has
// no equivalent, so write-side repositories publish to this notifier on
// any data-mutating operation, and read-side repositories subscribe to
// drive their watchXxx streams instead of polling.
//
// The signal is intentionally coarse: every change emits the same
// `Stream<void>` tick. Subscribers re-run their query in response. If
// granularity becomes a bottleneck, swap this for typed events.

import 'dart:async';

class DataChangeNotifier {
  final _controller = StreamController<void>.broadcast();

  /// Emits whenever `notify()` is called.
  Stream<void> get changes => _controller.stream;

  /// Publish a "something changed" tick. Safe to call after dispose
  /// (becomes a no-op).
  void notify() {
    if (_controller.isClosed) return;
    _controller.add(null);
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
