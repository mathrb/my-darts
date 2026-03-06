// Stateless Checkout Practice Engine
// Pure functional implementation of the 170 Checkout Practice drill.
// Players cycle through standard checkout routes, attempting each in ≤3 darts.
// Success = all route segments hit in order within the turn.
// Failure = wrong/missed dart resets progress. Drill runs until explicit GameCompleted.

import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';
import 'checkout_table.dart';

class StatelessCheckoutPracticeEngine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => EngineResult(state: _applyDartThrown(state, event)),
      'TurnEnded' => EngineResult(state: _applyTurnEnded(state, event)),
      'GameCompleted' => EngineResult(
          state: _applyGameCompleted(state, event),
          outcome: LegOutcome.gameCompleted),
      _ => EngineResult(state: state),
    };
  }

  @override
  bool isValid(GameState state, GameEvent event) {
    if (state.isComplete && event.eventType != 'GameCompleted') return false;

    switch (event.eventType) {
      case 'TurnStarted':
        return !state.turnActive;
      case 'DartThrown':
        if (!state.turnActive) return false;
        if (state.dartsThrownInTurn >= 3) return false;
        return true;
      default:
        return true;
    }
  }

  GameState _applyTurnStarted(GameState state, GameEvent event) {
    final competitorId = event.payload['competitor_id'] as String;
    final competitorIndex =
        state.competitors.indexWhere((c) => c.competitorId == competitorId);
    return state.copyWith(
      currentTurnIndex:
          competitorIndex >= 0 ? competitorIndex : state.currentTurnIndex,
      dartsThrownInTurn: 0,
      turnActive: true,
    );
  }

  GameState _applyDartThrown(GameState state, GameEvent event) {
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;

    final canonical = _toCanonicalString(segmentNum, multiplier);
    final competitor = state.competitors[state.currentTurnIndex];

    // Record the dart throw
    final updatedThrows = [...competitor.dartThrows, canonical];
    var updatedCompetitor = competitor.copyWith(dartThrows: updatedThrows);

    // Look up the current checkout route
    final route = _routeFor(updatedCompetitor.currentTarget, state);

    // Match dart against expected segment in route
    if (route != null && canonical == route[updatedCompetitor.routeProgress]) {
      final newProgress = updatedCompetitor.routeProgress + 1;
      if (newProgress == route.length) {
        // Success: completed the route
        updatedCompetitor = updatedCompetitor.copyWith(
          practiceSuccesses: updatedCompetitor.practiceSuccesses + 1,
          routeProgress: 0,
        );
      } else {
        updatedCompetitor = updatedCompetitor.copyWith(routeProgress: newProgress);
      }
    } else {
      // Failure: wrong dart or MISS — reset progress
      updatedCompetitor = updatedCompetitor.copyWith(routeProgress: 0);
    }

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    updatedCompetitors[state.currentTurnIndex] = updatedCompetitor;

    return state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );
  }

  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final competitor = state.competitors[state.currentTurnIndex];

    // Advance to next checkout in the order (wrapping)
    final currentIndex =
        state.checkoutPracticeOrder.indexOf(competitor.currentTarget ?? -1);
    final nextIndex = (currentIndex + 1) % state.checkoutPracticeOrder.length;
    final nextTarget = state.checkoutPracticeOrder.isNotEmpty
        ? state.checkoutPracticeOrder[nextIndex]
        : competitor.currentTarget;

    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    updatedCompetitors[state.currentTurnIndex] = competitor.copyWith(
      practiceAttempts: competitor.practiceAttempts + 1,
      currentTarget: nextTarget,
      routeProgress: 0,
    );

    return state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: 0,
      turnActive: false,
    );
  }

  GameState _applyGameCompleted(GameState state, GameEvent event) {
    return state.copyWith(
      isComplete: true,
      status: GameEngineStatus.completed,
      winnerCompetitorId: event.payload['winner_id'] as String?,
      turnActive: false,
    );
  }

  List<String>? _routeFor(int? finish, GameState state) {
    if (finish == null) return null;
    final entry = kCheckoutTable.cast<Map<String, Object>?>().firstWhere(
          (e) => e!['finish'] == finish,
          orElse: () => null,
        );
    if (entry == null) return null;
    return (entry['route'] as List).cast<String>();
  }

  String _toCanonicalString(int segment, int multiplier) {
    if (segment == 0) return 'MISS';
    if (segment == 25) {
      return multiplier == 2 ? 'DB' : 'SB';
    }
    return switch (multiplier) {
      1 => '$segment',
      2 => 'D$segment',
      3 => 'T$segment',
      _ => '$segment',
    };
  }
}
