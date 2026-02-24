// Statistics Repository Drift Implementation
// Concrete implementation of StatisticsRepository interface using Drift

import 'package:drift/drift.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:my_darts/features/statistics/domain/entities/player_stats.dart';
import 'package:my_darts/features/statistics/domain/entities/game_stats.dart';
import '../database.dart' as drift_db;

class StatisticsRepositoryDrift implements StatisticsRepository {
  final drift_db.AppDatabase _db;

  StatisticsRepositoryDrift(this._db);

  @override
  Future<GameStats> getGameStats(String gameId) async {
    // Count darts in game
    final dartCountQuery = _db.selectOnly(_db.dartThrows)
      ..addColumns([_db.dartThrows.dartId.count()])
      ..where(_db.dartThrows.gameId.equals(gameId));

    final dartCountResult = await dartCountQuery.getSingle();
    final dartCount = dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

    // Count events in game
    final eventCountQuery = _db.selectOnly(_db.gameEvents)
      ..addColumns([_db.gameEvents.eventId.count()])
      ..where(_db.gameEvents.gameId.equals(gameId));

    final eventCountResult = await eventCountQuery.getSingle();
    final eventCount = eventCountResult.read(_db.gameEvents.eventId.count()) ?? 0;

    // Return a simplified GameStats with empty competitor data
    // A full implementation would calculate proper statistics
    return GameStats(
      gameId: gameId,
      byCompetitor: [], // Empty list for now
    );
  }

  @override
  Stream<GameStats> watchGameStats(String gameId) {
    // Implement a simple stream that polls for changes
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      return await getGameStats(gameId);
    }).asyncMap((future) => future);
  }

  @override
  Future<PlayerStats> getPlayerStats(
    String playerId, {
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  }) async {
    // Count total darts thrown by player
    final dartCountQuery = _db.selectOnly(_db.dartThrows)
      ..addColumns([_db.dartThrows.dartId.count()])
      ..where(_db.dartThrows.playerId.equals(playerId));

    final GameType effectiveGameType = gameType ?? GameType.x01;
    
    if (gameType != null) {
      dartCountQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ]);
      dartCountQuery.where(_db.games.gameType.equals(gameType.name));
    }

    if (from != null) {
      dartCountQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ]);
      dartCountQuery.where(_db.games.startTime.isBiggerOrEqualValue(from.toIso8601String()));
    }

    if (to != null) {
      dartCountQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ]);
      dartCountQuery.where(_db.games.startTime.isSmallerOrEqualValue(to.toIso8601String()));
    }

    final dartCountResult = await dartCountQuery.getSingle();
    final dartCount = dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

    // Calculate average score
    final avgScoreQuery = _db.selectOnly(_db.dartThrows)
      ..addColumns([_db.dartThrows.score.avg()])
      ..where(_db.dartThrows.playerId.equals(playerId));

    if (gameType != null) {
      avgScoreQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ]);
      avgScoreQuery.where(_db.games.gameType.equals(gameType.name));
    }

    if (from != null) {
      avgScoreQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ]);
      avgScoreQuery.where(_db.games.startTime.isBiggerOrEqualValue(from.toIso8601String()));
    }

    if (to != null) {
      avgScoreQuery.join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ]);
      avgScoreQuery.where(_db.games.startTime.isSmallerOrEqualValue(to.toIso8601String()));
    }

    final avgScoreResult = await avgScoreQuery.getSingle();
    final avgScore = avgScoreResult.read(_db.dartThrows.score.avg()) ?? 0;

    // Return a simplified PlayerStats with minimal data
    // A full implementation would calculate proper statistics
    return PlayerStats(
      playerId: playerId,
      gameType: effectiveGameType,
      totalGames: 1, // Placeholder
      gamesWon: 0, // Placeholder
      winRate: 0.0, // Placeholder
      threeDartAverage: avgScore.toDouble(),
      checkoutPercentage: null, // Placeholder
      highestCheckout: null, // Placeholder
      highestTurnScore: 0, // Placeholder
      totalDartsThrown: dartCount,
      dartsPerLeg: dartCount > 0 ? dartCount / 1.0 : 0.0, // Placeholder
      bustRate: 0.0, // Placeholder
    );
  }

  @override
  Future<PlayerStats> getPlayerStatsForGame(String playerId, String gameId) async {
    // Get game type from the game
    final gameQuery = _db.selectOnly(_db.games)
      ..addColumns([_db.games.gameType])
      ..where(_db.games.gameId.equals(gameId));

    final gameResult = await gameQuery.getSingle();
    final gameType = GameType.values.firstWhere(
      (type) => type.name == gameResult.read(_db.games.gameType),
      orElse: () => GameType.x01,
    );

    // Count darts in game for player
    final dartCountQuery = _db.selectOnly(_db.dartThrows)
      ..addColumns([_db.dartThrows.dartId.count()])
      ..where(_db.dartThrows.playerId.equals(playerId) & _db.dartThrows.gameId.equals(gameId));

    final dartCountResult = await dartCountQuery.getSingle();
    final dartCount = dartCountResult.read(_db.dartThrows.dartId.count()) ?? 0;

    // Calculate average score
    final avgScoreQuery = _db.selectOnly(_db.dartThrows)
      ..addColumns([_db.dartThrows.score.avg()])
      ..where(_db.dartThrows.playerId.equals(playerId) & _db.dartThrows.gameId.equals(gameId));

    final avgScoreResult = await avgScoreQuery.getSingle();
    final avgScore = avgScoreResult.read(_db.dartThrows.score.avg()) ?? 0;

    // Return a simplified PlayerStats with minimal data
    // A full implementation would calculate proper statistics
    return PlayerStats(
      playerId: playerId,
      gameType: gameType,
      totalGames: 1, // Placeholder
      gamesWon: 0, // Placeholder
      winRate: 0.0, // Placeholder
      threeDartAverage: avgScore.toDouble(),
      checkoutPercentage: null, // Placeholder
      highestCheckout: null, // Placeholder
      highestTurnScore: 0, // Placeholder
      totalDartsThrown: dartCount,
      dartsPerLeg: dartCount > 0 ? dartCount / 1.0 : 0.0, // Placeholder
      bustRate: 0.0, // Placeholder
    );
  }

  @override
  Stream<PlayerStats> watchPlayerStats(String playerId, {GameType? gameType}) {
    // Implement a simple stream that polls for changes
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      return await getPlayerStats(playerId, gameType: gameType);
    }).asyncMap((future) => future);
  }

  @override
  Future<List<PlayerStats>> getLeaderboard({
    required GameType gameType,
    int minGames = 1,
    int limit = 50,
  }) async {
    // Count games per player
    final gamesPerPlayerQuery = _db.selectOnly(_db.dartThrows)
      ..addColumns([_db.dartThrows.playerId, _db.dartThrows.gameId.count()])
      ..join([
        innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId))
      ])
      ..where(_db.games.gameType.equals(gameType.name))
      ..groupBy([_db.dartThrows.playerId]);

    final gamesPerPlayerResults = await gamesPerPlayerQuery.get();
    final playerGameCounts = <String, int>{};
    for (final row in gamesPerPlayerResults) {
      final playerId = row.read(_db.dartThrows.playerId);
      final gameCount = row.read(_db.dartThrows.gameId.count()) ?? 0;
      if (playerId != null && gameCount >= minGames) {
        playerGameCounts[playerId] = gameCount;
      }
    }

    // Calculate average score for each player
    final leaderboard = <PlayerStats>[];
    for (final playerId in playerGameCounts.keys) {
      final stats = await getPlayerStats(playerId, gameType: gameType);
      leaderboard.add(stats);
    }

    // Sort by average score descending
    leaderboard.sort((a, b) => b.threeDartAverage.compareTo(a.threeDartAverage));

    return leaderboard.take(limit).toList();
  }
}
