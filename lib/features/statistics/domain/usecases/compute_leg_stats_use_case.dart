import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/assemblers/player_stats_assembler.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';

class ComputeLegStatsUseCase {
  const ComputeLegStatsUseCase({
    PlayerStatsAssembler? assembler,
  }) : _assembler = assembler ?? const PlayerStatsAssembler();

  final PlayerStatsAssembler _assembler;

  /// Events must be sorted by `localSequence` ascending.
  List<LegStatsBreakdown> execute({
    required List<GameEvent> events,
    required List<Competitor> competitors,
    required GameType gameType,
  }) {
    if (competitors.isEmpty) return const [];
    if (gameType != GameType.x01 && gameType != GameType.cricket) {
      return const [];
    }

    final allPlayerIds = <String>[
      for (final c in competitors)
        for (final p in c.players) p.playerId,
    ];

    final legs = <LegStatsBreakdown>[];
    var legNumber = 1;
    var legStart = 0;
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      if (event.eventType != 'LegCompleted') continue;

      final legEvents = events.sublist(legStart, i + 1);
      final winnerCompetitorId =
          event.payload['winner_competitor_id'] as String?;
      final winnerName = competitors
              .where((c) => c.competitorId == winnerCompetitorId)
              .map((c) => c.name)
              .firstOrNull ??
          '—';

      legs.add(LegStatsBreakdown(
        legNumber: legNumber++,
        winnerCompetitorId: winnerCompetitorId,
        winnerName: winnerName,
        byCompetitor: [
          for (final competitor in competitors)
            _assembler.legCompetitorStatsFromEvents(
              events: legEvents,
              competitor: competitor,
              allPlayerIds: allPlayerIds,
              gameType: gameType,
            ),
        ],
      ));
      legStart = i + 1;
    }
    return legs;
  }
}
