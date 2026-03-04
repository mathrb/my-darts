// Stateless Shanghai Game Engine
// Pure functional implementation of the Shanghai darts practice drill.
// Runs shanghaiTotalRounds rounds (default 7). Each round targets that round's number.
// Per-dart scoring: roundNum * multiplier if segment matches round number.
// Shanghai (single + double + triple in one turn) → instant win.
// After all rounds: single-player ends with no winner; multi-player: highest score wins.

import '../models/game_state.dart';
import '../entities/game_event.dart';
import 'base_game_engine.dart';

class StatelessShanghaiEngine implements GameEngine {
  @override
  EngineResult apply(GameState state, GameEvent event) {
    return switch (event.eventType) {
      'GameCreated' => EngineResult(
          state: state.copyWith(status: GameEngineStatus.inProgress)),
      'TurnStarted' => EngineResult(state: _applyTurnStarted(state, event)),
      'DartThrown' => _applyDartThrownWithOutcome(state, event),
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

  EngineResult _applyDartThrownWithOutcome(GameState state, GameEvent event) {
    final (newState, outcome, winnerId) = _applyDartThrown(state, event);
    return EngineResult(
      state: newState,
      outcome: outcome,
      winnerCompetitorId: winnerId,
      isBust: false,
    );
  }

  (GameState, LegOutcome, String?) _applyDartThrown(
      GameState state, GameEvent event) {
    final payload = event.payload;
    final segmentNum = payload['segment'] as int;
    final multiplier = payload['multiplier'] as int;

    final canonicalString = _toCanonicalString(segmentNum, multiplier);
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final currentCompetitor = updatedCompetitors[state.currentTurnIndex];
    final roundNum = currentCompetitor.practiceRound;

    // Per-dart scoring: score if segment matches round number (Bull excluded)
    int scoreToAdd = 0;
    if (segmentNum == roundNum && segmentNum != 0 && segmentNum != 25) {
      scoreToAdd = roundNum * multiplier;
    }

    updatedCompetitors[state.currentTurnIndex] = currentCompetitor.copyWith(
      dartThrows: [...currentCompetitor.dartThrows, canonicalString],
      score: currentCompetitor.score + scoreToAdd,
    );

    var newState = state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: state.dartsThrownInTurn + 1,
    );

    // Only evaluate end conditions on 3rd dart
    if (newState.dartsThrownInTurn < 3) {
      return (newState, LegOutcome.none, null);
    }

    // 3rd dart: check for Shanghai (single + double + triple of round number)
    final competitor = newState.competitors[newState.currentTurnIndex];
    final dartThrows = competitor.dartThrows;
    final turnThrows = dartThrows.sublist(dartThrows.length - 3).toSet();
    final isShanghai = turnThrows
        .containsAll({'$roundNum', 'D$roundNum', 'T$roundNum'});

    if (isShanghai) {
      final completedState = newState.copyWith(
        isComplete: true,
        status: GameEngineStatus.completed,
        winnerCompetitorId: competitor.competitorId,
        turnActive: false,
      );
      return (
        completedState,
        LegOutcome.gameCompleted,
        competitor.competitorId
      );
    }

    // End condition: last competitor to complete the final round
    final isLastInFinalRound = roundNum >= state.shanghaiTotalRounds &&
        state.competitors
            .where((c) => c.competitorId != competitor.competitorId)
            .every((c) => c.practiceRound > state.shanghaiTotalRounds);

    if (isLastInFinalRound) {
      String? winnerId;
      if (newState.competitors.length == 1) {
        winnerId = null;
      } else {
        // Highest score wins; current competitor wins on a tie
        int maxScore = competitor.score;
        winnerId = competitor.competitorId;
        for (final c in newState.competitors) {
          if (c.competitorId != competitor.competitorId && c.score > maxScore) {
            maxScore = c.score;
            winnerId = c.competitorId;
          }
        }
      }

      final completedState = newState.copyWith(
        isComplete: true,
        status: GameEngineStatus.completed,
        winnerCompetitorId: winnerId,
        turnActive: false,
      );
      return (completedState, LegOutcome.gameCompleted, winnerId);
    }

    // Normal end of turn — caller sends TurnEnded
    return (newState.copyWith(turnActive: false), LegOutcome.none, null);
  }

  // TurnEnded: increment practiceRound for current competitor, then rotate index
  GameState _applyTurnEnded(GameState state, GameEvent event) {
    final updatedCompetitors = List<CompetitorState>.from(state.competitors);
    final cur = updatedCompetitors[state.currentTurnIndex];
    updatedCompetitors[state.currentTurnIndex] =
        cur.copyWith(practiceRound: cur.practiceRound + 1);
    final nextIndex = (state.currentTurnIndex + 1) % state.competitors.length;
    return state.copyWith(
      competitors: updatedCompetitors,
      dartsThrownInTurn: 0,
      turnActive: false,
      currentTurnIndex: nextIndex,
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

  String _toCanonicalString(int segment, int multiplier) {
    if (segment == 0) return 'MISS';
    if (segment == 25) return multiplier == 2 ? 'DB' : 'SB';
    return switch (multiplier) {
      1 => '$segment',
      2 => 'D$segment',
      3 => 'T$segment',
      _ => '$segment',
    };
  }
}
