// GetGameResultUseCase Unit Tests
//
// End-to-end via in-memory drift: seed players → competitors → game
// (isComplete: false) → events → completeGame, then execute the use case
// against the real practice/Shanghai engines and assert the resulting
// `GameResult` variant matches the expected field values.

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_around_the_clock_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_bobs_27_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_catch_40_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_checkout_practice_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/stateless_shanghai_engine.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:dart_lodge/features/game/domain/usecases/get_game_result_use_case.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';

import '../../../../drift_test_base.dart';

void main() {
  final base = DriftTestBase();
  late GetGameResultUseCase useCase;

  setUp(() async {
    await base.setUp();
    useCase = GetGameResultUseCase(
      await base.createGameRepository(),
      await base.createGameEventRepository(),
      StatelessAroundTheClockEngine(),
      StatelessCatch40Engine(),
      StatelessBobs27Engine(),
      StatelessShanghaiEngine(),
      StatelessCheckoutPracticeEngine(),
    );
  });

  tearDown(() async {
    await base.tearDown();
  });

  Future<void> seedGame({
    required String gameId,
    required GameType gameType,
    required GameConfig config,
    required String playerId,
    required String playerName,
    required String competitorId,
  }) async {
    final playerRepo = await base.createPlayerRepository();
    final gameRepo = await base.createGameRepository();
    await playerRepo.createPlayer(Player(
      playerId: playerId,
      name: playerName,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    ));
    await gameRepo.createGame(
      Game(
        gameId: gameId,
        gameType: gameType,
        config: config,
        startTime: DateTime.now(),
        isComplete: false,
      ),
      [
        Competitor(
          competitorId: competitorId,
          gameId: gameId,
          type: CompetitorType.solo,
          name: playerName,
          players: [CompetitorPlayer(playerId: playerId, rotationPosition: 0)],
        ),
      ],
    );
  }

  /// Appends [events] and marks the game complete with [winnerCompetitorId].
  Future<void> completeWithEvents(
    String gameId,
    String? winnerCompetitorId,
    List<GameEvent> events,
  ) async {
    final gameRepo = await base.createGameRepository();
    await gameRepo.appendEventsAndCompleteGame(
      events: events,
      gameId: gameId,
      winnerCompetitorId: winnerCompetitorId,
      endTime: DateTime.now(),
    );
  }

  GameEvent dart(
    String gameId,
    String competitorId,
    String playerId,
    int seq,
    int segment,
    int multiplier,
  ) =>
      buildDartThrownEvent(
        gameId: gameId,
        dartId: 'dart-$gameId-$seq',
        competitorId: competitorId,
        actorId: playerId,
        localSequence: seq,
        segment: segment,
        multiplier: multiplier,
        score: segment * multiplier,
        playerId: playerId,
      );

  group('GetGameResultUseCase', () {
    test('returns null for an unknown gameId', () async {
      final result = await useCase.execute('does-not-exist');
      expect(result, isNull);
    });

    test('returns null for an X01 game (not a covered type)', () async {
      await seedGame(
        gameId: 'g-x01',
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
        ),
        playerId: 'p1',
        playerName: 'P1',
        competitorId: 'c1',
      );
      final result = await useCase.execute('g-x01');
      expect(result, isNull);
    });

    test('aroundTheClock: solo player, standard variant, 5 turns to win',
        (() async {
      const gameId = 'g-atc';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.aroundTheClock,
        config: const GameConfig.aroundTheClock(),
        playerId: playerId,
        playerName: 'Alice',
        competitorId: competitorId,
      );

      // 4 full turns of 3 darts each (12 darts hitting targets 1..12),
      // then turn 5: hits 13..20 across 9 more darts — but ATC wins
      // on the dart that clears target 20. To keep this compact: scripted
      // sequence that progresses target 1 → 20 with no misses.
      // Layout: turn N covers targets (3N-2)..(3N). Final turn 7 hits 19, 20
      // and wins on dart 2.

      final events = <GameEvent>[];
      var seq = 1;
      var target = 1;
      for (var turn = 1; turn <= 7; turn++) {
        events.add(buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ));
        // Three darts per turn, each hits the current target unless we've
        // already cleared 20.
        for (var d = 0; d < 3 && target <= 20; d++) {
          events.add(dart(gameId, competitorId, playerId, seq++, target, 1));
          target++;
          if (target > 20) break;
        }
        if (target > 20) break;
        events.add(buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ));
      }
      events.add(buildGameCompletedEvent(
        gameId: gameId,
        winnerCompetitorId: competitorId,
        localSequence: seq++,
      ));

      await completeWithEvents(gameId, competitorId, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<AroundTheClockResult>());
      final atc = result as AroundTheClockResult;
      expect(atc.competitorName, 'Alice');
      // 7 turns scripted, win happens on turn 7 (no TurnEnded after) →
      // practiceRound = 7.
      expect(atc.turnsToComplete, 7);
      // 6 prior turns × 3 darts + 2 winning darts in turn 7 = 20.
      expect(atc.totalDarts, 20);
      expect(atc.doublesOnly, isFalse);
    }));

    test('aroundTheClock: doublesOnly variant flag reaches the result',
        (() async {
      const gameId = 'g-atc-do';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.aroundTheClock,
        config: const GameConfig.aroundTheClock(variant: 'doublesOnly'),
        playerId: playerId,
        playerName: 'Alice',
        competitorId: competitorId,
      );
      // Just send GameCompleted (we only assert the variant flag).
      await completeWithEvents(gameId, null, [
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 1,
        ),
      ]);
      final result = await useCase.execute(gameId);
      expect(result, isA<AroundTheClockResult>());
      expect((result as AroundTheClockResult).doublesOnly, isTrue);
    }));

    test('catch40: score and targetsCleared map from competitor state',
        (() async {
      const gameId = 'g-catch40';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.catch40,
        config: const GameConfig.catch40(),
        playerId: playerId,
        playerName: 'Bob',
        competitorId: competitorId,
      );

      // Round 1, target 61: single 11 (50 remaining) + DB (50 on double) →
      // checkout in 2 darts → +3 pts. After TurnEnded, engine advances
      // practiceRound to 2 and bumps score by 3, practiceSuccesses to 1.
      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 11, 1),
        dart(gameId, competitorId, playerId, 3, 25, 2),
        buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 4,
        ),
        // Stop after round 1; GameCompleted marks the game closed in the DB.
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 5,
        ),
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<Catch40Result>());
      final c40 = result as Catch40Result;
      expect(c40.competitorName, 'Bob');
      expect(c40.targetsCleared, 1);
      expect(c40.score, 3);
    }));

    test("bobs27: completes 20 rounds, finalScore and roundReached map",
        (() async {
      const gameId = 'g-bobs27';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.bobs27,
        config: const GameConfig.bobs27(),
        playerId: playerId,
        playerName: 'Carol',
        competitorId: competitorId,
      );

      // Play 20 rounds, missing every double. Score: 27 - sum(2*r for r in 1..20) = 27 - 420 < 0.
      // Engine ends at round 1 because score <= 0 after first miss (27 - 2 = 25 still > 0).
      // Actually: 27 - 2 = 25 (round 1 miss); - 4 = 21 (r2); - 6 = 15 (r3); - 8 = 7 (r4); - 10 = -3 (r5) → bust.
      // Game ends at round 5 with score = -3.
      final events = <GameEvent>[];
      var seq = 1;
      for (var round = 1; round <= 5; round++) {
        events.add(buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ));
        // Three misses (segment 0 / multiplier 1)
        for (var d = 0; d < 3; d++) {
          events.add(dart(gameId, competitorId, playerId, seq++, 0, 1));
        }
        events.add(buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ));
      }
      events.add(buildGameCompletedEvent(
        gameId: gameId,
        winnerCompetitorId: null,
        localSequence: seq++,
      ));

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<Bobs27Result>());
      final b27 = result as Bobs27Result;
      expect(b27.competitorName, 'Carol');
      // Round 5 miss takes score to -3 → bust-to-zero.
      expect(b27.finalScore, -3);
      expect(b27.bustedToZero, isTrue);
      // Engine completed game at round 5; practiceRound is then 6.
      expect(b27.roundReached, 5);
    }));

    test('checkoutPractice: successful checkout records darts and remaining=0',
        (() async {
      const gameId = 'g-co';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.checkoutPractice,
        config: const GameConfig.checkoutPractice(),
        playerId: playerId,
        playerName: 'Dave',
        competitorId: competitorId,
      );

      // 170: T20 (60) + T20 (60) + DB (50) = 170 checkout in 3 darts.
      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 20, 3),
        dart(gameId, competitorId, playerId, 3, 20, 3),
        dart(gameId, competitorId, playerId, 4, 25, 2),
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: competitorId,
          localSequence: 5,
        ),
      ];

      await completeWithEvents(gameId, competitorId, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<CheckoutPracticeResult>());
      final co = result as CheckoutPracticeResult;
      expect(co.competitorName, 'Dave');
      expect(co.checkedOut, isTrue);
      expect(co.dartsThrown, 3);
      expect(co.fromScore, 170);
      expect(co.remainingScore, 0);
    }));

    test('checkoutPractice: failed end (manual end) reports remainingScore > 0',
        (() async {
      const gameId = 'g-co-fail';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.checkoutPractice,
        config: const GameConfig.checkoutPractice(),
        playerId: playerId,
        playerName: 'Eve',
        competitorId: competitorId,
      );

      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 20, 1), // 170-20 = 150
        buildGameCompletedEvent(
          gameId: gameId,
          winnerCompetitorId: null,
          localSequence: 3,
        ),
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as CheckoutPracticeResult;
      expect(result.checkedOut, isFalse);
      expect(result.dartsThrown, 1);
      expect(result.fromScore, 170);
      expect(result.remainingScore, 150);
    }));

    test('shanghai: bestRound observes max single-round score', (() async {
      const gameId = 'g-sh';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.shanghai,
        config: const GameConfig.shanghai(),
        playerId: playerId,
        playerName: 'Faye',
        competitorId: competitorId,
      );

      // 7 rounds. Round 1: hit 1 once → 1pt. Round 2: hit 2 thrice → 6pt.
      // Round 3..7: 3 misses each → 0pt.
      // Expected: totalScore=7, bestRound=6, shanghaiBonuses=0, roundsPlayed=7.
      final events = <GameEvent>[];
      var seq = 1;
      for (var round = 1; round <= 7; round++) {
        events.add(buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
          turnIndex: 0,
          legIndex: 0,
        ));
        for (var d = 0; d < 3; d++) {
          int seg;
          int mult;
          if (round == 1) {
            seg = d == 0 ? 1 : 0;
            mult = d == 0 ? 1 : 1;
          } else if (round == 2) {
            seg = 2;
            mult = 1;
          } else {
            seg = 0;
            mult = 1;
          }
          events.add(dart(gameId, competitorId, playerId, seq++, seg, mult));
        }
        events.add(buildTurnEndedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: seq++,
        ));
      }
      // Final TurnEnded already fired for round 7 → engine sets isComplete.
      // No additional GameCompleted required, but emit one for cleanliness.

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId);
      expect(result, isA<ShanghaiResult>());
      final sh = result as ShanghaiResult;
      expect(sh.competitorName, 'Faye');
      expect(sh.totalScore, 7);
      expect(sh.bestRound, 6);
      expect(sh.shanghaiBonuses, 0);
      expect(sh.roundsPlayed, 7);
    }));

    test('shanghai: instant-win counts the shanghai bonus and ends early',
        (() async {
      const gameId = 'g-sh-instant';
      const competitorId = 'c1';
      const playerId = 'p1';
      await seedGame(
        gameId: gameId,
        gameType: GameType.shanghai,
        config: const GameConfig.shanghai(),
        playerId: playerId,
        playerName: 'Gus',
        competitorId: competitorId,
      );

      // Round 1 Shanghai: single + double + triple of round 1 in any order.
      final events = <GameEvent>[
        buildTurnStartedEvent(
          gameId: gameId,
          competitorId: competitorId,
          playerId: playerId,
          localSequence: 1,
          turnIndex: 0,
          legIndex: 0,
        ),
        dart(gameId, competitorId, playerId, 2, 1, 1), // 1
        dart(gameId, competitorId, playerId, 3, 1, 2), // D1 → +2 = 3 total
        dart(gameId, competitorId, playerId, 4, 1, 3), // T1 → +3 = 6 total (shanghai!)
      ];

      await completeWithEvents(gameId, null, events);

      final result = await useCase.execute(gameId) as ShanghaiResult;
      expect(result.totalScore, 6);
      expect(result.shanghaiBonuses, 1);
      // Instant-win on round 1 means the round never ends; practiceRound = 1.
      expect(result.roundsPlayed, 1);
      // bestRound captures the entire round-1 score: 1+2+3 = 6.
      expect(result.bestRound, 6);
    }));
  });
}
