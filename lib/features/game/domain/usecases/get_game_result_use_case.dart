// GetGameResultUseCase — produces the post-game `GameResult` for the four
// practice drills (Around the Clock, Catch 40, Bob's 27, 170 Checkout) and
// Shanghai by replaying recorded `game_events` through the existing engine
// for that game type. Count-Up is intentionally NOT covered — it stays on
// the shared `gameStatsProvider` (x01-shaped chrome fits it).
//
// No new scoring math: every field comes from the final `CompetitorState` /
// `GameState` that the engine produces, with two exceptions that observe
// engine output rather than recompute it —
//   - `CheckoutPracticeResult.dartsThrown` counts surviving `DartThrown`
//     events directly (the checkout engine pads bust turns with phantom
//     `MISS` darts, so `dartThrows.length` over-counts).
//   - `ShanghaiResult.bestRound` walks events a second time and accumulates
//     per-round score deltas off the engine's score field between
//     `TurnEnded` boundaries.

import 'dart:math' as math;

import '../engines/base_game_engine.dart';
import '../engines/event_replay.dart';
import '../engines/stateless_around_the_clock_engine.dart';
import '../engines/stateless_bobs_27_engine.dart';
import '../engines/stateless_catch_40_engine.dart';
import '../engines/stateless_checkout_practice_engine.dart';
import '../engines/stateless_shanghai_engine.dart';
import '../entities/game_event.dart';
import '../models/game_result.dart';
import '../models/game_state.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/game_repository.dart';
import '../../../../core/utils/constants.dart';

class GetGameResultUseCase {
  final GameRepository _gameRepo;
  final GameEventRepository _eventRepo;
  final StatelessAroundTheClockEngine _aroundTheClockEngine;
  final StatelessCatch40Engine _catch40Engine;
  final StatelessBobs27Engine _bobs27Engine;
  final StatelessShanghaiEngine _shanghaiEngine;
  final StatelessCheckoutPracticeEngine _checkoutPracticeEngine;

  GetGameResultUseCase(
    this._gameRepo,
    this._eventRepo,
    this._aroundTheClockEngine,
    this._catch40Engine,
    this._bobs27Engine,
    this._shanghaiEngine,
    this._checkoutPracticeEngine,
  );

  /// Returns the post-game `GameResult` for [gameId], or `null` when the game
  /// is missing or its `GameType` is not one of the practice/Shanghai variants
  /// `GameResult` represents.
  Future<GameResult?> execute(String gameId) async {
    final game = await _gameRepo.getGame(gameId);
    if (game == null) return null;

    final engine = _engineFor(game.gameType);
    if (engine == null) return null;

    final competitors = await _gameRepo.getCompetitors(gameId);
    final events = await _eventRepo.getEventsForGame(gameId);

    // Override `isComplete: false` for replay: `GameState.initial` copies
    // `game.isComplete` from the DB row (true for the completed games this
    // use case is called on), which would cause the Shanghai and Catch-40
    // engines — both of which short-circuit `apply` when `state.isComplete`
    // — to skip every event. Recover completion from the event log instead.
    final initial =
        GameState.initial(game, competitors).copyWith(isComplete: false);
    final finalState =
        replayEvents(initial: initial, events: events, engine: engine);

    final subject = _subjectCompetitor(finalState);
    if (subject == null) return null;

    return switch (game.gameType) {
      GameType.aroundTheClock => GameResult.aroundTheClock(
          competitorName: subject.name,
          turnsToComplete: subject.practiceRound,
          totalDarts: _countDarts(events, subject.competitorId),
          doublesOnly: finalState.aroundTheClockVariant == 'doublesOnly',
        ),
      GameType.catch40 => GameResult.catch40(
          competitorName: subject.name,
          score: subject.score,
          targetsCleared: subject.practiceSuccesses,
        ),
      GameType.bobs27 => GameResult.bobs27(
          competitorName: subject.name,
          finalScore: subject.score,
          // practiceRound is bumped after a round's 3rd dart finalises that
          // round's scoring, so `practiceRound - 1` is the last round
          // actually played (1..20).
          roundReached: math.max(1, subject.practiceRound - 1).clamp(1, 20),
          bustedToZero: subject.score <= 0,
        ),
      GameType.checkoutPractice => GameResult.checkoutPractice(
          competitorName: subject.name,
          checkedOut: subject.score == 0,
          dartsThrown: _countDarts(events, subject.competitorId),
          fromScore: subject.startingScore,
          remainingScore: subject.score,
        ),
      GameType.shanghai => GameResult.shanghai(
          competitorName: subject.name,
          totalScore: subject.score,
          shanghaiBonuses: subject.practiceSuccesses,
          bestRound: _bestRoundScore(
            initial: initial,
            events: events,
            engine: engine,
            competitorId: subject.competitorId,
          ),
          // practiceRound stops incrementing once the cap is hit; clamp
          // for the Shanghai-instant-win case where the game ends mid-round.
          roundsPlayed:
              math.min(subject.practiceRound, finalState.shanghaiTotalRounds),
        ),
      _ => null,
    };
  }

  GameEngine? _engineFor(GameType type) => switch (type) {
        GameType.aroundTheClock => _aroundTheClockEngine,
        GameType.catch40 => _catch40Engine,
        GameType.bobs27 => _bobs27Engine,
        GameType.shanghai => _shanghaiEngine,
        GameType.checkoutPractice => _checkoutPracticeEngine,
        _ => null,
      };

  /// The competitor whose result the post-game screen displays — the winner
  /// if the engine recorded one, otherwise the first competitor (covers
  /// solo drills like Bob's 27 where `winnerCompetitorId` is intentionally
  /// null even on completion).
  CompetitorState? _subjectCompetitor(GameState state) {
    if (state.competitors.isEmpty) return null;
    final winnerId = state.winnerCompetitorId;
    if (winnerId != null) {
      final match = state.competitors
          .where((c) => c.competitorId == winnerId)
          .firstOrNull;
      if (match != null) return match;
    }
    return state.competitors.first;
  }

  /// Counts the surviving `DartThrown` events for [competitorId], applying
  /// the same DartCorrected / superseded skip handling as `replayEvents`.
  /// Authoritative for "darts the user actually threw" — distinct from
  /// `CompetitorState.dartThrows.length`, which can include phantom MISS
  /// padding the checkout-practice engine inserts on bust.
  int _countDarts(List<GameEvent> events, String competitorId) {
    final skip = _buildSkipSets(events);
    var count = 0;
    for (final e in events) {
      if (e.eventType != 'DartThrown') continue;
      if (skip.correctedDartIds.contains(e.eventId)) continue;
      if (skip.supersededEventIds.contains(e.eventId)) continue;
      if (e.payload['competitor_id'] != competitorId) continue;
      count++;
    }
    return count;
  }

  /// Highest single-round score the [competitorId] accumulated in Shanghai.
  /// Observes the engine's score deltas between `TurnEnded` boundaries for
  /// that competitor; does not recompute scoring.
  int _bestRoundScore({
    required GameState initial,
    required List<GameEvent> events,
    required GameEngine engine,
    required String competitorId,
  }) {
    final skip = _buildSkipSets(events);

    int compIndex(GameState gs) =>
        gs.competitors.indexWhere((c) => c.competitorId == competitorId);

    var gs = initial;
    var idx = compIndex(gs);
    if (idx < 0) return 0;
    var prevScore = gs.competitors[idx].score;
    var currentRoundScore = 0;
    var best = 0;

    for (final event in events) {
      if (event.eventType == 'DartThrown' &&
          skip.correctedDartIds.contains(event.eventId)) {
        continue;
      }
      if (skip.supersededEventIds.contains(event.eventId)) continue;

      // Close out the round just before applying TurnEnded for this
      // competitor, so the round's score deltas are correctly bucketed.
      if (event.eventType == 'TurnEnded' &&
          event.payload['competitor_id'] == competitorId) {
        best = math.max(best, currentRoundScore);
        currentRoundScore = 0;
      }

      gs = engine.apply(gs, event).state;
      idx = compIndex(gs);
      if (idx < 0) continue;
      final cur = gs.competitors[idx].score;
      if (cur > prevScore) currentRoundScore += (cur - prevScore);
      prevScore = cur;
    }

    // The final round (and any Shanghai-instant-win round) ends without a
    // matching TurnEnded — flush whatever's accumulated.
    best = math.max(best, currentRoundScore);
    return best;
  }

  _SkipSets _buildSkipSets(List<GameEvent> events) {
    final corrected = <String>{};
    final superseded = <String>{};
    for (final e in events) {
      if (e.eventType != 'DartCorrected') continue;
      final origId = e.payload['original_event_id'];
      if (origId is String) corrected.add(origId);
      final list = e.payload['superseded_event_ids'];
      if (list is List) {
        for (final id in list) {
          if (id is String) superseded.add(id);
        }
      }
    }
    return _SkipSets(corrected, superseded);
  }
}

class _SkipSets {
  final Set<String> correctedDartIds;
  final Set<String> supersededEventIds;
  const _SkipSets(this.correctedDartIds, this.supersededEventIds);
}
