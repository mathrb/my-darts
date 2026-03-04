// Catch 40 Engine Unit Tests
// Covers scoring rules, round progression, turn flow, and end conditions.

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/domain/engines/stateless_catch_40_engine.dart';
import 'package:my_darts/features/game/domain/models/game_state.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/engines/base_game_engine.dart';

int _seq = 0;

GameEvent _event({
  required String type,
  required Map<String, dynamic> payload,
  String gameId = 'game-1',
}) {
  _seq++;
  return GameEvent(
    eventId: 'e$_seq',
    gameId: gameId,
    eventType: type,
    localSequence: _seq,
    occurredAt: DateTime.utc(2024, 1, 1),
    payload: payload,
    synced: false,
    actorId: 'test',
    source: EventSource.client,
  );
}

GameEvent _dartThrown({
  required String competitorId,
  required int segment,
  required int multiplier,
}) =>
    _event(
      type: 'DartThrown',
      payload: {
        'competitor_id': competitorId,
        'segment': segment,
        'multiplier': multiplier,
      },
    );

GameEvent _turnStarted(String competitorId) => _event(
      type: 'TurnStarted',
      payload: {'competitor_id': competitorId},
    );

GameEvent _turnEnded(String competitorId) => _event(
      type: 'TurnEnded',
      payload: {'competitor_id': competitorId},
    );

/// Build a minimal Catch 40 game state.
GameState _makeState({
  int score = 0,
  int practiceRound = 1,
  List<String> dartThrows = const [],
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  String? winnerCompetitorId,
  int catch40TotalRounds = 8,
  List<int> catch40RoundTargets = const [10, 15, 20, 25, 30, 35, 40, 45],
}) {
  return GameState(
    gameId: 'game-1',
    gameType: GameType.catch40,
    competitors: [
      CompetitorState(
        competitorId: 'c1',
        name: 'Player 1',
        playerIds: ['p1'],
        score: score,
        isComplete: isComplete,
        dartThrows: dartThrows,
        practiceRound: practiceRound,
      ),
    ],
    currentTurnIndex: 0,
    dartsThrownInTurn: dartsThrownInTurn,
    isComplete: isComplete,
    winnerCompetitorId: winnerCompetitorId,
    status: isComplete ? GameEngineStatus.completed : GameEngineStatus.inProgress,
    turnActive: turnActive,
    catch40TotalRounds: catch40TotalRounds,
    catch40RoundTargets: catch40RoundTargets,
  );
}

/// Parse a canonical dart string to (segment, multiplier) for _dartThrown.
({int segment, int multiplier}) _parseCanonical(String c) {
  if (c == 'MISS') return (segment: 0, multiplier: 1);
  if (c == 'DB') return (segment: 25, multiplier: 2);
  if (c == 'SB') return (segment: 25, multiplier: 1);
  if (c.startsWith('D')) return (segment: int.parse(c.substring(1)), multiplier: 2);
  if (c.startsWith('T')) return (segment: int.parse(c.substring(1)), multiplier: 3);
  return (segment: int.parse(c), multiplier: 1);
}

/// Apply TurnStarted + up to 3 darts to the given state. Does NOT apply TurnEnded.
GameState _applyTurn(StatelessCatch40Engine engine, GameState state, List<String> darts) {
  var s = engine.apply(state, _turnStarted('c1')).state;
  for (final d in darts) {
    final p = _parseCanonical(d);
    s = engine.apply(
      s,
      _dartThrown(competitorId: 'c1', segment: p.segment, multiplier: p.multiplier),
    ).state;
  }
  return s;
}

void main() {
  late StatelessCatch40Engine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessCatch40Engine();
  });

  // -------------------------------------------------------------------------
  // GameCreated
  // -------------------------------------------------------------------------
  group('GameCreated', () {
    test('sets status to inProgress', () {
      final state = _makeState().copyWith(status: GameEngineStatus.initialized);
      final result = engine.apply(state, _event(type: 'GameCreated', payload: {}));
      expect(result.state.status, GameEngineStatus.inProgress);
    });
  });

  // -------------------------------------------------------------------------
  // Catch success — turnTotal >= roundTarget
  // -------------------------------------------------------------------------
  group('Catch success — turnTotal >= roundTarget', () {
    test('R1 (target=10): 20+20+MISS=40 >= 10 → score += 10', () {
      final state = _makeState(score: 0, practiceRound: 1);
      final after = _applyTurn(engine, state, ['20', '20', 'MISS']);
      // turnTotal=40 >= 10 → score = 0 + 10 = 10
      expect(after.competitors[0].score, 10);
    });

    test('R3 (target=20): T7=21 >= 20 → score += 20', () {
      final state = _makeState(score: 10, practiceRound: 3);
      final after = _applyTurn(engine, state, ['T7', 'MISS', 'MISS']);
      // turnTotal=21 >= 20 → score = 10 + 20 = 30
      expect(after.competitors[0].score, 30);
    });

    test('R8 (target=45): T15=45 exactly meets target → score += 45', () {
      final state = _makeState(score: 0, practiceRound: 8);
      final after = _applyTurn(engine, state, ['T15', 'MISS', 'MISS']);
      // turnTotal=45 >= 45 → score = 0 + 45 = 45
      expect(after.competitors[0].score, 45);
    });

    test('R8 (target=45): T20+5=65 > 45 → only target value added', () {
      final state = _makeState(score: 20, practiceRound: 8);
      final after = _applyTurn(engine, state, ['T20', '5', 'MISS']);
      // turnTotal=65 >= 45 → score = 20 + 45 = 65
      expect(after.competitors[0].score, 65);
    });
  });

  // -------------------------------------------------------------------------
  // Catch failure — turnTotal < roundTarget
  // -------------------------------------------------------------------------
  group('Catch failure — turnTotal < roundTarget', () {
    test('R1 (target=10): 3+3+3=9 < 10 → score unchanged', () {
      final state = _makeState(score: 5, practiceRound: 1);
      final after = _applyTurn(engine, state, ['3', '3', '3']);
      // turnTotal=9 < 10 → score stays 5
      expect(after.competitors[0].score, 5);
    });

    test('R5 (target=30): 10+10+9=29 < 30 → score unchanged', () {
      final state = _makeState(score: 100, practiceRound: 5);
      final after = _applyTurn(engine, state, ['10', '10', '9']);
      // turnTotal=29 < 30 → score stays 100
      expect(after.competitors[0].score, 100);
    });

    test('R2 (target=15): 14+MISS+MISS=14 < 15 → score unchanged', () {
      final state = _makeState(score: 0, practiceRound: 2);
      final after = _applyTurn(engine, state, ['14', 'MISS', 'MISS']);
      expect(after.competitors[0].score, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Edge: exactly at target
  // -------------------------------------------------------------------------
  group('Edge: exactly at target', () {
    test('R4 (target=25): 10+10+5=25 == 25 → success, score += 25', () {
      final state = _makeState(score: 0, practiceRound: 4);
      final after = _applyTurn(engine, state, ['10', '10', '5']);
      expect(after.competitors[0].score, 25);
    });

    test('R6 (target=35): 11+12+12=35 == 35 → success, score += 35', () {
      final state = _makeState(score: 0, practiceRound: 6);
      final after = _applyTurn(engine, state, ['11', '12', '12']);
      expect(after.competitors[0].score, 35);
    });
  });

  // -------------------------------------------------------------------------
  // Round progression
  // -------------------------------------------------------------------------
  group('Round progression', () {
    test('practiceRound starts at 1', () {
      final state = _makeState();
      expect(state.competitors[0].practiceRound, 1);
    });

    test('after full turn for R1, practiceRound advances to 2', () {
      final state = _makeState(score: 0, practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceRound, 2);
    });

    test('after full turn for R7, practiceRound advances to 8', () {
      final state = _makeState(score: 0, practiceRound: 7);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.competitors[0].practiceRound, 8);
      expect(after.isComplete, isFalse);
    });

    test('after full turn for R8 (last round), game ends', () {
      final state = _makeState(score: 0, practiceRound: 8);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Score evaluated only on 3rd dart
  // -------------------------------------------------------------------------
  group('Score evaluated only on 3rd dart', () {
    test('score unchanged after 1st dart', () {
      final state = _makeState(score: 0, practiceRound: 1, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 0);
    });

    test('score unchanged after 2nd dart', () {
      final state = _makeState(
        score: 0,
        practiceRound: 1,
        dartsThrownInTurn: 1,
        dartThrows: ['20'],
        turnActive: true,
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1),
      );
      expect(result.state.competitors[0].score, 0);
    });

    test('turnActive remains true after 1st dart', () {
      final state = _makeState(score: 0, practiceRound: 1, turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.state.turnActive, isTrue);
    });

    test('turnActive becomes false after 3rd dart', () {
      final state = _makeState(score: 0, practiceRound: 1);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.turnActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Normal end — all 8 rounds complete
  // -------------------------------------------------------------------------
  group('Normal end — all rounds complete', () {
    test('R8 completes: isComplete=true, no winner', () {
      final state = _makeState(score: 0, practiceRound: 8);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isTrue);
      expect(after.winnerCompetitorId, isNull);
      expect(after.status, GameEngineStatus.completed);
    });

    test('R8 hit target: score updated AND game ends', () {
      final state = _makeState(score: 0, practiceRound: 8);
      // R8 target=45; T15=45 → success
      final after = _applyTurn(engine, state, ['T15', 'MISS', 'MISS']);
      expect(after.competitors[0].score, 45);
      expect(after.isComplete, isTrue);
    });

    test('R8 result has outcome = gameCompleted', () {
      final state = _makeState(
        score: 0,
        practiceRound: 8,
        turnActive: true,
        dartsThrownInTurn: 2,
        dartThrows: ['MISS', 'MISS'],
      );
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.outcome, LegOutcome.gameCompleted);
    });

    test('game NOT ended after R7 (not the last round)', () {
      final state = _makeState(score: 0, practiceRound: 7);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // TurnStarted
  // -------------------------------------------------------------------------
  group('TurnStarted', () {
    test('sets dartsThrownInTurn=0 and turnActive=true', () {
      final state = _makeState(turnActive: false, dartsThrownInTurn: 2);
      final result = engine.apply(state, _turnStarted('c1'));
      expect(result.state.dartsThrownInTurn, 0);
      expect(result.state.turnActive, isTrue);
    });

    test('isValid returns false when turn is already active', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('isValid returns true when no active turn', () {
      final state = _makeState(turnActive: false);
      expect(engine.isValid(state, _turnStarted('c1')), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // TurnEnded
  // -------------------------------------------------------------------------
  group('TurnEnded', () {
    test('sets turnActive=false and resets dartsThrownInTurn', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      final result = engine.apply(state, _turnEnded('c1'));
      expect(result.state.turnActive, isFalse);
      expect(result.state.dartsThrownInTurn, 0);
    });
  });

  // -------------------------------------------------------------------------
  // isValid rejections
  // -------------------------------------------------------------------------
  group('isValid rejections', () {
    test('DartThrown rejected when isComplete = true', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when dartsThrownInTurn = 3', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when turn is not active', () {
      final state = _makeState(turnActive: false);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('TurnStarted rejected when turnActive = true', () {
      final state = _makeState(turnActive: true);
      expect(engine.isValid(state, _turnStarted('c1')), isFalse);
    });

    test('DartThrown accepted in normal mid-turn state', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 1);
      expect(
        engine.isValid(state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isTrue,
      );
    });

    test('unknown event type always valid', () {
      final state = _makeState();
      expect(engine.isValid(state, _event(type: 'UnknownEvent', payload: {})), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Canonical string recording
  // -------------------------------------------------------------------------
  group('Canonical string recording', () {
    test('MISS recorded as MISS', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1),
      );
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });

    test('D20 recorded as D20', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2),
      );
      expect(result.state.competitors[0].dartThrows, contains('D20'));
    });

    test('T20 recorded as T20', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3),
      );
      expect(result.state.competitors[0].dartThrows, contains('T20'));
    });

    test('DB recorded as DB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2),
      );
      expect(result.state.competitors[0].dartThrows, contains('DB'));
    });

    test('SB recorded as SB', () {
      final state = _makeState(turnActive: true);
      final result = engine.apply(
        state,
        _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1),
      );
      expect(result.state.competitors[0].dartThrows, contains('SB'));
    });
  });

  // -------------------------------------------------------------------------
  // GameCompleted event replay
  // -------------------------------------------------------------------------
  group('GameCompleted event replay', () {
    test('sets isComplete=true, status=completed, turnActive=false', () {
      final state = _makeState(isComplete: true);
      final result = engine.apply(
        state,
        _event(type: 'GameCompleted', payload: {'winner_id': null}),
      );
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.state.turnActive, isFalse);
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });

  // -------------------------------------------------------------------------
  // DB and SB score values
  // -------------------------------------------------------------------------
  group('Bull scoring', () {
    test('DB (50) + SB (25) + MISS = 75 — checked against R8 target 45', () {
      final state = _makeState(score: 0, practiceRound: 8);
      final after = _applyTurn(engine, state, ['DB', 'SB', 'MISS']);
      // turnTotal = 50 + 25 + 0 = 75 >= 45 → score += 45
      expect(after.competitors[0].score, 45);
    });

    test('SB (25) alone does not meet R8 target (45)', () {
      final state = _makeState(score: 10, practiceRound: 8);
      final after = _applyTurn(engine, state, ['SB', 'MISS', 'MISS']);
      // turnTotal = 25 < 45 → score stays 10
      expect(after.competitors[0].score, 10);
    });
  });

  // -------------------------------------------------------------------------
  // Custom totalRounds
  // -------------------------------------------------------------------------
  group('Custom totalRounds', () {
    test('game ends after custom totalRounds=3', () {
      final state = _makeState(
        score: 0,
        practiceRound: 3,
        catch40TotalRounds: 3,
        catch40RoundTargets: [10, 20, 30],
      );
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isTrue);
    });

    test('game does NOT end after round 2 when totalRounds=3', () {
      final state = _makeState(
        score: 0,
        practiceRound: 2,
        catch40TotalRounds: 3,
        catch40RoundTargets: [10, 20, 30],
      );
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      expect(after.isComplete, isFalse);
    });
  });
}
