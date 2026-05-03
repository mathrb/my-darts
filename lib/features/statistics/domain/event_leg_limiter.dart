// EventLegLimiter
// Trims an event list to the last N completed legs.
//
// Used by repository implementations before delegating to PlayerStatsAssembler.
// Lives in domain/ so both backends can share the implementation; the trim
// logic is pure event-list processing with no DB or Flutter dependency.

import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

class EventLegLimiter {
  const EventLegLimiter._();

  /// Returns [events] trimmed to the last [legLimit] completed legs.
  ///
  /// Returns [events] unchanged if [legLimit] is null, ≤ 0, or if the input
  /// contains fewer than [legLimit] `LegCompleted` events.
  ///
  /// Caller MUST pass events ordered by `(game_id, local_sequence)` so that
  /// each game's events are contiguous — the trim slices on a global event
  /// index, not on per-game leg counts.
  static List<GameEvent> trim(List<GameEvent> events, int? legLimit) {
    if (legLimit == null || legLimit <= 0) return events;

    final legCompletedIndices = <int>[];
    for (int i = 0; i < events.length; i++) {
      if (events[i].eventType == 'LegCompleted') {
        legCompletedIndices.add(i);
      }
    }
    if (legCompletedIndices.length <= legLimit) return events;

    // Slice from the event after the (N - legLimit)th LegCompleted.
    final prevLegCompletedIdx =
        legCompletedIndices[legCompletedIndices.length - legLimit - 1];
    return events.sublist(prevLegCompletedIdx + 1);
  }
}
