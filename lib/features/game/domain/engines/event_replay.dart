// Event replay — pure helper that takes an initial GameState plus the
// recorded event log and returns the final GameState after engine application.
//
// Sole place where DartCorrected / superseded-event skip handling lives, so
// every call site (cold loaders for active-game notifiers, post-game
// `GetGameResultUseCase`) recovers identical state from the same events.

import '../entities/game_event.dart';
import '../models/game_state.dart';
import 'base_game_engine.dart';

GameState replayEvents({
  required GameState initial,
  required List<GameEvent> events,
  required GameEngine engine,
}) {
  // Build skip sets from DartCorrected events so undone darts and the
  // turn-boundary events that bracketed them aren't re-applied on cold load.
  // Without this, an undo that spans a turn boundary leaves a stale
  // TurnStarted in the log; replaying it shifts currentTurnIndex and any
  // later DartThrown gets attributed to the wrong competitor (issue #108).
  final correctedDartIds = <String>{};
  final supersededEventIds = <String>{};
  for (final e in events) {
    if (e.eventType != 'DartCorrected') continue;
    final origId = e.payload['original_event_id'];
    if (origId is String) correctedDartIds.add(origId);
    final superseded = e.payload['superseded_event_ids'];
    if (superseded is List) {
      for (final id in superseded) {
        if (id is String) supersededEventIds.add(id);
      }
    }
  }

  var gs = initial;
  for (final event in events) {
    if (event.eventType == 'DartThrown' &&
        correctedDartIds.contains(event.eventId)) {
      continue;
    }
    if (supersededEventIds.contains(event.eventId)) {
      continue;
    }
    gs = engine.apply(gs, event).state;
  }
  return gs;
}
