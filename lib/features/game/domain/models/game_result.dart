// Game Result — sealed sum type produced by `GetGameResultUseCase` for the
// post-game summary screen of practice drills and Shanghai.
//
// Constraint #4 — "Statistics Are Projections — Never Stored" — applies: every
// field on every variant is derived by replaying `game_events` through the
// existing practice/Shanghai engine. No new scoring math lives here; the
// use case reads fields off the final `CompetitorState`/`GameState` and
// observes per-round score deltas where the engine doesn't expose them
// directly (Shanghai's `bestRound`).
//
// Count-Up is intentionally NOT a variant: it stays on the shared
// `gameStatsProvider` (x01-shaped summary chrome fits it).

import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_result.freezed.dart';
part 'game_result.g.dart';

@freezed
sealed class GameResult with _$GameResult {
  const factory GameResult.aroundTheClock({
    required String competitorName,
    required int turnsToComplete,
    required int totalDarts,
    required bool doublesOnly,
  }) = AroundTheClockResult;

  const factory GameResult.catch40({
    required String competitorName,
    required int score,
    required int targetsCleared,
  }) = Catch40Result;

  const factory GameResult.bobs27({
    required String competitorName,
    required int finalScore,
    required int roundReached,
    required bool bustedToZero,
  }) = Bobs27Result;

  const factory GameResult.checkoutPractice({
    required String competitorName,
    required bool checkedOut,
    required int dartsThrown,
    required int fromScore,
    required int remainingScore,
  }) = CheckoutPracticeResult;

  const factory GameResult.shanghai({
    required String competitorName,
    required int totalScore,
    required int shanghaiBonuses,
    required int bestRound,
    required int roundsPlayed,
  }) = ShanghaiResult;

  factory GameResult.fromJson(Map<String, dynamic> json) =>
      _$GameResultFromJson(json);
}
