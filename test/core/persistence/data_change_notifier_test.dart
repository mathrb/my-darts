import 'package:dart_lodge/core/persistence/data_change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changes is a broadcast stream — multiple subscribers receive ticks',
      () async {
    final notifier = DataChangeNotifier();
    addTearDown(notifier.dispose);

    final a = <void>[];
    final b = <void>[];
    final subA = notifier.changes.listen(a.add);
    final subB = notifier.changes.listen(b.add);
    addTearDown(() async {
      await subA.cancel();
      await subB.cancel();
    });

    notifier.notify();
    notifier.notify();
    await Future<void>.delayed(Duration.zero);

    expect(a.length, 2);
    expect(b.length, 2);
  });

  test('notify after dispose is a no-op (does not throw)', () {
    final notifier = DataChangeNotifier();
    notifier.dispose();
    // Must not throw.
    notifier.notify();
  });

  test('dispose is idempotent', () {
    final notifier = DataChangeNotifier();
    notifier.dispose();
    notifier.dispose();
  });
}
