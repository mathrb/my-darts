import 'package:freezed_annotation/freezed_annotation.dart';

part 'leg_stats_breakdown.freezed.dart';

@freezed
abstract class LegStatsBreakdown with _$LegStatsBreakdown {
  const factory LegStatsBreakdown({
    required int legNumber,
    required String? winnerCompetitorId,
    required String winnerName,
    required List<LegCompetitorStats> byCompetitor,
  }) = _LegStatsBreakdown;
}

@freezed
abstract class LegCompetitorStats with _$LegCompetitorStats {
  const factory LegCompetitorStats({
    required String competitorId,
    required String competitorName,
    required int dartsThrown,
    double? threeDartAverage,
    double? checkoutPercentage,
    int? highestCheckout,
    @Default(0) int oneEightyTurns,
    @Default(0) int sixtyPlusTurns,
    @Default(0) int oneHundredPlusTurns,
    @Default(0) int oneFortyPlusTurns,
    double? marksPerRound,
    double? firstNineMarksPerRound,
    @Default(0) int fiveMarkTurns,
    @Default(0) int sixMarkTurns,
    @Default(0) int sevenMarkTurns,
    @Default(0) int eightMarkTurns,
    @Default(0) int nineMarkTurns,
  }) = _LegCompetitorStats;
}
