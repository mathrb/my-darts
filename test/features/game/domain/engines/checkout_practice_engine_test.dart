// Checkout Practice Engine Unit Tests
// Covers route matching, success/failure detection, turn flow, and drill progression.

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/game/domain/engines/stateless_checkout_practice_engine.dart';
import 'package:my_darts/features/game/domain/engines/checkout_table.dart';
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

/// Build a minimal CheckoutPractice game state.
GameState _makeState({
  int? currentTarget,
  int routeProgress = 0,
  int practiceAttempts = 0,
  int practiceSuccesses = 0,
  List<String> dartThrows = const [],
  int dartsThrownInTurn = 0,
  bool turnActive = false,
  bool isComplete = false,
  String? winnerCompetitorId,
  List<int>? checkoutPracticeOrder,
}) {
  // Default order: first few checkouts from the standard table
  final order = checkoutPracticeOrder ??
      kCheckoutTable.map((e) => e['finish'] as int).toList();
  final target = currentTarget ?? order[0];

  return GameState(
    gameId: 'game-1',
    gameType: GameType.checkoutPractice,
    competitors: [
      CompetitorState(
        competitorId: 'c1',
        name: 'Player 1',
        playerIds: ['p1'],
        score: 0,
        isComplete: isComplete,
        dartThrows: dartThrows,
        currentTarget: target,
        routeProgress: routeProgress,
        practiceAttempts: practiceAttempts,
        practiceSuccesses: practiceSuccesses,
      ),
    ],
    currentTurnIndex: 0,
    dartsThrownInTurn: dartsThrownInTurn,
    isComplete: isComplete,
    winnerCompetitorId: winnerCompetitorId,
    status: isComplete ? GameEngineStatus.completed : GameEngineStatus.inProgress,
    turnActive: turnActive,
    checkoutPracticeOrder: order,
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

/// Apply TurnStarted + darts to the given state. Does NOT apply TurnEnded.
GameState _applyTurn(
    StatelessCheckoutPracticeEngine engine, GameState state, List<String> darts) {
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
  late StatelessCheckoutPracticeEngine engine;

  setUp(() {
    _seq = 0;
    engine = StatelessCheckoutPracticeEngine();
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
  // Success detection
  // -------------------------------------------------------------------------
  group('Success detection', () {
    test('1-dart route DB: throwing DB increments practiceSuccesses', () {
      // finish=50 → route=['DB']
      final state = _makeState(currentTarget: 50, checkoutPracticeOrder: [50, 40, 32]);
      final after = _applyTurn(engine, state, ['DB']);
      expect(after.competitors[0].practiceSuccesses, 1);
      expect(after.competitors[0].routeProgress, 0);
    });

    test('2-dart route T20+D20: both darts in order → success', () {
      // finish=100 → route=['T20','D20']
      final state = _makeState(currentTarget: 100, checkoutPracticeOrder: [100, 50]);
      final after = _applyTurn(engine, state, ['T20', 'D20']);
      expect(after.competitors[0].practiceSuccesses, 1);
      expect(after.competitors[0].routeProgress, 0);
    });

    test('3-dart route T20+T20+DB: all three darts → success', () {
      // finish=170 → route=['T20','T20','DB']
      final state = _makeState(currentTarget: 170, checkoutPracticeOrder: [170, 167]);
      final after = _applyTurn(engine, state, ['T20', 'T20', 'DB']);
      expect(after.competitors[0].practiceSuccesses, 1);
    });

    test('routeProgress is 0 after a completed route', () {
      final state = _makeState(currentTarget: 50, checkoutPracticeOrder: [50, 40]);
      final after = _applyTurn(engine, state, ['DB']);
      expect(after.competitors[0].routeProgress, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Failure on first dart
  // -------------------------------------------------------------------------
  group('Failure on first dart', () {
    test('wrong first dart: routeProgress stays 0, no success', () {
      // finish=170 → route=['T20','T20','DB']; throw T19 instead of T20
      final state = _makeState(currentTarget: 170, checkoutPracticeOrder: [170, 167]);
      final after = _applyTurn(engine, state, ['T19', 'T20', 'DB']);
      expect(after.competitors[0].practiceSuccesses, 0);
      expect(after.competitors[0].routeProgress, 0);
    });

    test('wrong first dart does not prevent recording the dart', () {
      final state = _makeState(
          currentTarget: 170,
          checkoutPracticeOrder: [170, 167],
          turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 19, multiplier: 3));
      expect(result.state.competitors[0].dartThrows, contains('T19'));
    });
  });

  // -------------------------------------------------------------------------
  // Failure on second dart
  // -------------------------------------------------------------------------
  group('Failure on second dart', () {
    test('first dart matches, second dart wrong: routeProgress resets to 0', () {
      // finish=170 → route=['T20','T20','DB']; throw T20 then T19
      final state = _makeState(currentTarget: 170, checkoutPracticeOrder: [170, 167]);
      var s = engine.apply(state, _turnStarted('c1')).state;
      s = engine.apply(s, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      // After T20: routeProgress should be 1
      expect(s.competitors[0].routeProgress, 1);
      // Now throw T19 (wrong)
      s = engine.apply(s, _dartThrown(competitorId: 'c1', segment: 19, multiplier: 3)).state;
      expect(s.competitors[0].routeProgress, 0);
      expect(s.competitors[0].practiceSuccesses, 0);
    });

    test('first dart matches: routeProgress is 1', () {
      final state = _makeState(currentTarget: 170, checkoutPracticeOrder: [170, 167],
          turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.competitors[0].routeProgress, 1);
    });
  });

  // -------------------------------------------------------------------------
  // MISS always fails
  // -------------------------------------------------------------------------
  group('MISS always fails', () {
    test('MISS as first dart resets routeProgress to 0', () {
      final state = _makeState(
          currentTarget: 170, checkoutPracticeOrder: [170], turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].routeProgress, 0);
    });

    test('MISS after progress resets routeProgress to 0', () {
      // finish=100 → route=['T20','D20']; throw T20 then MISS
      final state = _makeState(currentTarget: 100, checkoutPracticeOrder: [100]);
      var s = engine.apply(state, _turnStarted('c1')).state;
      s = engine.apply(s, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3)).state;
      expect(s.competitors[0].routeProgress, 1);
      s = engine.apply(s, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1)).state;
      expect(s.competitors[0].routeProgress, 0);
    });

    test('MISS is recorded as MISS in dartThrows', () {
      final state = _makeState(
          currentTarget: 50, checkoutPracticeOrder: [50], turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });
  });

  // -------------------------------------------------------------------------
  // TurnEnded advances checkout
  // -------------------------------------------------------------------------
  group('TurnEnded advances checkout', () {
    test('practiceAttempts incremented on TurnEnded', () {
      final state = _makeState(
          currentTarget: 170,
          checkoutPracticeOrder: [170, 167, 164],
          practiceAttempts: 0);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      final s2 = engine.apply(after, _turnEnded('c1')).state;
      expect(s2.competitors[0].practiceAttempts, 1);
    });

    test('currentTarget advances to next in order after TurnEnded', () {
      final state = _makeState(
          currentTarget: 170, checkoutPracticeOrder: [170, 167, 164]);
      final after = _applyTurn(engine, state, ['MISS', 'MISS', 'MISS']);
      final s2 = engine.apply(after, _turnEnded('c1')).state;
      expect(s2.competitors[0].currentTarget, 167);
    });

    test('routeProgress is 0 after TurnEnded', () {
      final state = _makeState(
          currentTarget: 170,
          routeProgress: 1,
          checkoutPracticeOrder: [170, 167]);
      final s2 = engine.apply(state, _turnEnded('c1')).state;
      expect(s2.competitors[0].routeProgress, 0);
    });

    test('dartsThrownInTurn reset to 0 on TurnEnded', () {
      final state = _makeState(
          currentTarget: 170,
          dartsThrownInTurn: 3,
          checkoutPracticeOrder: [170, 167]);
      final s2 = engine.apply(state, _turnEnded('c1')).state;
      expect(s2.dartsThrownInTurn, 0);
    });

    test('turnActive set to false on TurnEnded', () {
      final state = _makeState(
          currentTarget: 170,
          checkoutPracticeOrder: [170, 167],
          turnActive: true);
      final s2 = engine.apply(state, _turnEnded('c1')).state;
      expect(s2.turnActive, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // TurnEnded wraps around
  // -------------------------------------------------------------------------
  group('TurnEnded wraps around', () {
    test('last checkout in sequence wraps to first', () {
      final state = _makeState(
          currentTarget: 32, checkoutPracticeOrder: [170, 40, 32]);
      final s2 = engine.apply(state, _turnEnded('c1')).state;
      expect(s2.competitors[0].currentTarget, 170);
    });

    test('second-to-last advances to last', () {
      final state = _makeState(
          currentTarget: 40, checkoutPracticeOrder: [170, 40, 32]);
      final s2 = engine.apply(state, _turnEnded('c1')).state;
      expect(s2.competitors[0].currentTarget, 32);
    });
  });

  // -------------------------------------------------------------------------
  // Sequential order
  // -------------------------------------------------------------------------
  group('Sequential order', () {
    test('first checkout in standard order is 170', () {
      final order = kCheckoutTable.map((e) => e['finish'] as int).toList();
      expect(order[0], 170);
    });

    test('standard order descends from 170', () {
      final order = kCheckoutTable.map((e) => e['finish'] as int).toList();
      // First entry is 170, and finishes decrease overall
      expect(order[0], 170);
      expect(order[1], 167);
      expect(order[2], 164);
    });

    test('last entry in standard table is 2', () {
      expect(kCheckoutTable.last['finish'], 2);
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
  // GameCompleted
  // -------------------------------------------------------------------------
  group('GameCompleted', () {
    test('sets isComplete=true, status=completed, turnActive=false', () {
      final state = _makeState();
      final result = engine.apply(
          state, _event(type: 'GameCompleted', payload: {'winner_id': null}));
      expect(result.state.isComplete, isTrue);
      expect(result.state.status, GameEngineStatus.completed);
      expect(result.state.turnActive, isFalse);
      expect(result.outcome, LegOutcome.gameCompleted);
    });
  });

  // -------------------------------------------------------------------------
  // isValid rejections
  // -------------------------------------------------------------------------
  group('isValid rejections', () {
    test('DartThrown rejected when isComplete = true', () {
      final state = _makeState(isComplete: true, turnActive: true);
      expect(
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when dartsThrownInTurn = 3', () {
      final state = _makeState(turnActive: true, dartsThrownInTurn: 3);
      expect(
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
        isFalse,
      );
    });

    test('DartThrown rejected when turn is not active', () {
      final state = _makeState(turnActive: false);
      expect(
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
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
        engine.isValid(
            state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 1)),
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
    test('T20 recorded as T20', () {
      final state = _makeState(
          currentTarget: 170, checkoutPracticeOrder: [170], turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 3));
      expect(result.state.competitors[0].dartThrows, contains('T20'));
    });

    test('D20 recorded as D20', () {
      final state = _makeState(
          currentTarget: 40, checkoutPracticeOrder: [40], turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 20, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('D20'));
    });

    test('DB recorded as DB', () {
      final state = _makeState(
          currentTarget: 50, checkoutPracticeOrder: [50], turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 2));
      expect(result.state.competitors[0].dartThrows, contains('DB'));
    });

    test('SB recorded as SB', () {
      final state = _makeState(
          currentTarget: 50, checkoutPracticeOrder: [50], turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 25, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('SB'));
    });

    test('MISS recorded as MISS', () {
      final state = _makeState(
          currentTarget: 50, checkoutPracticeOrder: [50], turnActive: true);
      final result = engine.apply(
          state, _dartThrown(competitorId: 'c1', segment: 0, multiplier: 1));
      expect(result.state.competitors[0].dartThrows, contains('MISS'));
    });
  });
}
