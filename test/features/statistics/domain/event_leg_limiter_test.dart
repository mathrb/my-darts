import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/event_leg_limiter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int seq = 0;
  GameEvent event(String type) {
    seq++;
    return GameEvent(
      eventId: 'e$seq',
      gameId: 'g',
      eventType: type,
      localSequence: seq,
      occurredAt: DateTime.utc(2026, 1, 1),
      payload: const {},
      synced: false,
      actorId: 'p1',
      source: EventSource.client,
    );
  }

  setUp(() {
    seq = 0;
  });

  test('null legLimit returns events unchanged', () {
    final events = [event('TurnStarted'), event('LegCompleted')];
    expect(EventLegLimiter.trim(events, null), same(events));
  });

  test('legLimit ≤ 0 returns events unchanged', () {
    final events = [event('TurnStarted'), event('LegCompleted')];
    expect(EventLegLimiter.trim(events, 0), same(events));
    expect(EventLegLimiter.trim(events, -1), same(events));
  });

  test('input with fewer LegCompleted than legLimit returns unchanged', () {
    // 2 legs in input, asking for last 5 → no trimming.
    final events = [
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
    ];
    expect(EventLegLimiter.trim(events, 5), same(events));
  });

  test('trims to keep last N legs and the events after them', () {
    // 4 legs total; keep last 2.
    // [TS, LC, TS, LC, TS, LC, TS, LC]
    //  0   1   2   3   4   5   6   7
    // legCompleted at indices [1, 3, 5, 7]
    // For legLimit=2: prev = indices[4-2-1] = indices[1] = 3
    // Result: events.sublist(4) → [TS@4, LC@5, TS@6, LC@7]
    final events = [
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'),
    ];

    final result = EventLegLimiter.trim(events, 2);

    expect(result.length, 4);
    expect(result.first.localSequence, 5); // first kept event = TS@4 → seq 5
    expect(result.last.localSequence, 8);
  });

  test('events after the last LegCompleted are kept (open in-progress leg)', () {
    // 2 completed legs + a started-but-uncompleted leg.
    // legLimit=1 should keep last completed leg's events + the trailing
    // events after it.
    final events = [
      event('TurnStarted'),
      event('LegCompleted'),
      event('TurnStarted'),
      event('LegCompleted'), // index 3 — the boundary cut for legLimit=1
      event('TurnStarted'), // these stay
      event('DartThrown'),
    ];

    final result = EventLegLimiter.trim(events, 1);

    // Wait — legCompletedIndices=[1,3], legLimit=1, prev=indices[2-1-1]=indices[0]=1.
    // So result = sublist(2) → events[2..5] = [TS, LC, TS, DT].
    expect(result.length, 4);
    expect(result.first.eventType, 'TurnStarted');
    expect(result[1].eventType, 'LegCompleted');
  });
}
