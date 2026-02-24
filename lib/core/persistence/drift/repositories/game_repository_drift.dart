// Game Repository Drift Implementation
// Concrete implementation of GameRepository interface using Drift

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/domain/models/game_state_snapshot.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import '../database.dart' as drift_db;




class GameRepositoryDrift implements GameRepository {
  final drift_db.AppDatabase _db;

  GameRepositoryDrift(this._db);

  Future<List<Game>> getAllGames() async {
    final query = _db.select(_db.games)
      ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]);

    final results = await query.get();

    return results.map((row) => Game(
      gameId: row.gameId,
      gameType: _parseGameType(row.gameType),
      config: GameConfig.fromJson(json.decode(row.configJson)),
      startTime: DateTime.parse(row.startTime),
      endTime: row.endTime != null ? DateTime.parse(row.endTime!) : null,
      winnerCompetitorId: row.winnerCompetitorId,
      isComplete: row.isComplete == 1,
      activeState: row.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(row.gameStateJson!)) : null,
    )).toList();
  }

  @override
  Future<Game?> getGame(String gameId) async {
    final query = _db.select(_db.games)
      ..where((t) => t.gameId.equals(gameId))
      ..limit(1);

    final result = await query.getSingleOrNull();

    if (result == null) return null;
    
    return Game(
      gameId: result.gameId,
      gameType: _parseGameType(result.gameType),
      config: GameConfig.fromJson(json.decode(result.configJson)),
      startTime: DateTime.parse(result.startTime),
      endTime: result.endTime != null ? DateTime.parse(result.endTime!) : null,
      winnerCompetitorId: result.winnerCompetitorId,
      isComplete: result.isComplete == 1,
      activeState: result.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(result.gameStateJson!)) : null,
    );
  }

  @override
  Future<void> createGame(Game game, List<Competitor> competitors) async {
    try {
      await _db.transaction(() async {
        // Insert game
        await _db.into(_db.games).insert(
          drift_db.GamesCompanion.insert(
            gameId: game.gameId,
            gameType: game.gameType.name,
            configJson: json.encode(game.config.toJson()),
            startTime: game.startTime.toIso8601String(),
            endTime: Value.absentIfNull(game.endTime?.toIso8601String()),
            winnerCompetitorId: Value.absentIfNull(game.winnerCompetitorId),
            isComplete: Value(game.isComplete == true ? 1 : 0),
            gameStateJson: Value.absentIfNull(game.activeState?.toJson() != null ? json.encode(game.activeState!.toJson()) : null),
          ),
          mode: InsertMode.insertOrFail,
        );

        // Insert competitors
        for (final competitor in competitors) {
          await _db.into(_db.competitors).insert(
            drift_db.CompetitorsCompanion.insert(
              competitorId: competitor.competitorId,
              gameId: game.gameId,
              type: competitor.type.name,
              name: competitor.name,
            ),
            mode: InsertMode.insertOrFail,
          );
        }
      });
    } on Exception catch (e) {
      // Handle drift-specific exceptions using DriftWrappedException
      if (e is DriftWrappedException) {
        final cause = e.cause.toString();
        
        // Index-specific constraint detection
        if (cause.contains('idx_games_single_active')) {
          throw const ActiveGameAlreadyExistsException();
        }
        // Generic unique constraint detection
        else if (cause.contains('UNIQUE constraint failed') ||
                 cause.contains('unique constraint failed') ||
                 cause.contains('constraint failed')) {
          throw DuplicateGameException(game.gameId);
        }
      }
      rethrow;
    }
  }

  Future<void> updateGame(Game game) async {
    final rowsAffected = await (_db.update(_db.games)
      ..where((t) => t.gameId.equals(game.gameId)))
      .write(
        drift_db.GamesCompanion(
          gameType: Value(game.gameType.name),
          configJson: Value(json.encode(game.config.toJson())),
          startTime: Value(game.startTime.toIso8601String()),
          endTime: Value.absentIfNull(game.endTime?.toIso8601String()),
          winnerCompetitorId: Value.absentIfNull(game.winnerCompetitorId),
          isComplete: Value(game.isComplete == true ? 1 : 0),
          gameStateJson: Value.absentIfNull(game.activeState?.toJson() != null ? json.encode(game.activeState!.toJson()) : null),
        ),
      );

    if (rowsAffected == 0) {
      throw GameNotFoundException(game.gameId);
    }
  }

  @override
  Future<void> completeGame({
    required String gameId,
    required String? winnerCompetitorId,
    required DateTime endTime,
  }) async {
    final rowsAffected = await (_db.update(_db.games)
      ..where((t) => t.gameId.equals(gameId)))
      .write(
        drift_db.GamesCompanion(
          isComplete: Value(1),
          winnerCompetitorId: Value(winnerCompetitorId),
          endTime: Value(endTime.toIso8601String()),
        ),
      );

    if (rowsAffected == 0) {
      throw GameNotFoundException(gameId);
    }
  }

  Future<void> deleteGame(String gameId) async {
    final rowsAffected = await (_db.delete(_db.games)
      ..where((t) => t.gameId.equals(gameId)))
      .go();

    if (rowsAffected == 0) {
      throw GameNotFoundException(gameId);
    }
  }

  @override
  Future<Game?> getActiveGame() async {
    final query = _db.select(_db.games)
      ..where((t) => t.isComplete.equals(0))
      ..limit(1);

    final result = await query.getSingleOrNull();

    if (result == null) return null;
    
    return Game(
      gameId: result.gameId,
      gameType: _parseGameType(result.gameType),
      config: GameConfig.fromJson(json.decode(result.configJson)),
      startTime: DateTime.parse(result.startTime),
      endTime: result.endTime != null ? DateTime.parse(result.endTime!) : null,
      winnerCompetitorId: result.winnerCompetitorId,
      isComplete: result.isComplete == 1,
      activeState: result.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(result.gameStateJson!)) : null,
    );
  }

  Stream<List<Game>> watchAllGames() {
    return Stream.fromFuture(getAllGames());
  }

  @override
  Future<List<Competitor>> getCompetitors(String gameId) async {
    final query = _db.select(_db.competitors)
      ..where((t) => t.gameId.equals(gameId));

    final results = await query.get();

    // For now, return competitors with empty player lists
    // A full implementation would join with competitor_players table
    return results.map((row) => Competitor(
      competitorId: row.competitorId,
      gameId: row.gameId,
      type: _parseCompetitorType(row.type),
      name: row.name,
      players: [], // Empty list for now
    )).toList();
  }

  // Helper method to parse competitor type from string
  CompetitorType _parseCompetitorType(String typeString) {
    return CompetitorType.values.firstWhere(
      (type) => type.name == typeString,
      orElse: () => CompetitorType.solo,
    );
  }

  @override
  Future<List<Game>> getCompletedGames({
    int limit = 20,
    int offset = 0,
    GameType? filterByType,
  }) async {
    final query = _db.select(_db.games)
      ..where((t) => t.isComplete.equals(1))
      ..orderBy([(t) => OrderingTerm(expression: t.endTime, mode: OrderingMode.desc)])
      ..limit(limit, offset: offset);

    if (filterByType != null) {
      query.where((t) => t.gameType.equals(filterByType.name));
    }

    final results = await query.get();

    return results.map((row) => Game(
      gameId: row.gameId,
      gameType: _parseGameType(row.gameType),
      config: GameConfig.fromJson(json.decode(row.configJson)),
      startTime: DateTime.parse(row.startTime),
      endTime: row.endTime != null ? DateTime.parse(row.endTime!) : null,
      winnerCompetitorId: row.winnerCompetitorId,
      isComplete: row.isComplete == 1,
      activeState: row.gameStateJson != null ? GameStateSnapshot.fromJson(json.decode(row.gameStateJson!)) : null,
    )).toList();
  }

  @override
  Future<void> saveGameState(String gameId, GameStateSnapshot state) async {
    final rowsAffected = await (_db.update(_db.games)
      ..where((t) => t.gameId.equals(gameId)))
      .write(
        drift_db.GamesCompanion(
          gameStateJson: Value(json.encode(state.toJson())),
        ),
      );

    if (rowsAffected == 0) {
      throw GameNotFoundException(gameId);
    }
  }

  @override
  Stream<Game?> watchActiveGame() {
    // Implement a simple stream that polls for changes
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      return await getActiveGame();
    }).asyncMap((future) => future);
  }

  @override
  Stream<List<Game>> watchCompletedGames({GameType? filterByType}) {
    // Implement a simple stream that polls for changes
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      return await getCompletedGames(filterByType: filterByType);
    }).asyncMap((future) => future);
  }

  // Helper method to parse game type from string
  GameType _parseGameType(String gameTypeString) {
    return GameType.values.firstWhere(
      (type) => type.name == gameTypeString,
      orElse: () => GameType.x01,
    );
  }

}