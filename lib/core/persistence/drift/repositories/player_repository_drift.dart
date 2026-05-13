// Player Repository Drift Implementation
// Concrete implementation of PlayerRepository interface using Drift

import 'package:drift/drift.dart';
import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';
import '../database.dart' as drift_db;
import '../sqlite_error_codes.dart';

class PlayerRepositoryDrift implements PlayerRepository {
  final drift_db.AppDatabase _db;

  PlayerRepositoryDrift(this._db);

  @override
  Future<List<Player>> getAllPlayers() async {
    final query = _db.select(_db.players)
      ..orderBy([(t) => OrderingTerm(expression: t.lastActive, mode: OrderingMode.desc)]);

    final results = await query.get();

    return results.map((row) => Player(
      playerId: row.playerId,
      name: row.name,
      createdAt: DateTime.parse(row.createdAt),
      lastActive: DateTime.parse(row.lastActive),
    )).toList();
  }

  @override
  Future<Player?> getPlayer(String playerId) async {
    final query = _db.select(_db.players)
      ..where((t) => t.playerId.equals(playerId))
      ..limit(1);

    final result = await query.getSingleOrNull();

    if (result == null) return null;
    
    return Player(
      playerId: result.playerId,
      name: result.name,
      createdAt: DateTime.parse(result.createdAt),
      lastActive: DateTime.parse(result.lastActive),
    );
  }

  @override
  Future<void> createPlayer(Player player) async {
    try {
      await _db.into(_db.players).insert(
        drift_db.PlayersCompanion.insert(
          playerId: player.playerId,
          name: player.name,
          createdAt: player.createdAt.toIso8601String(),
          lastActive: player.lastActive.toIso8601String(),
        ),
        mode: InsertMode.insertOrFail,
      );
    } on Exception catch (e) {
      if (isUniqueConstraintViolation(e)) {
        throw DuplicatePlayerException(player.playerId);
      }
      if (e is RepositoryException) rethrow;
      throw DatabaseException(
        'Failed to create player ${player.playerId}',
        cause: e,
      );
    }
  }

  @override
  Future<void> updatePlayerName(String playerId, String name) async {
    final rowsAffected = await (_db.update(_db.players)
      ..where((t) => t.playerId.equals(playerId)))
      .write(
        drift_db.PlayersCompanion(
          name: Value(name),
          lastActive: Value(DateTime.now().toIso8601String()),
        ),
      );

    if (rowsAffected == 0) {
      throw PlayerNotFoundException(playerId);
    }
  }

  @override
  Future<void> touchPlayer(String playerId) async {
    final rowsAffected = await (_db.update(_db.players)
      ..where((t) => t.playerId.equals(playerId)))
      .write(
        drift_db.PlayersCompanion(
          lastActive: Value(DateTime.now().toIso8601String()),
        ),
      );

    if (rowsAffected == 0) {
      throw PlayerNotFoundException(playerId);
    }
  }

  @override
  Future<void> deletePlayer(String playerId) async {
    await _db.transaction(() async {
      // Fast-path check: if the player has competitor_players rows we know
      // the delete will hit ON DELETE RESTRICT. We still rely on the FK below
      // as the canonical guarantee (TOCTOU-safe inside the transaction).
      final rows = await (_db.select(_db.competitorPlayers)
            ..where((t) => t.playerId.equals(playerId)))
          .get();

      if (rows.isNotEmpty) {
        throw PlayerHasGameHistoryException(
            'Player $playerId has game history');
      }

      try {
        final rowsAffected = await (_db.delete(_db.players)
              ..where((t) => t.playerId.equals(playerId)))
            .go();

        if (rowsAffected == 0) throw PlayerNotFoundException(playerId);
      } on Exception catch (e) {
        if (isForeignKeyConstraintViolation(e)) {
          // A competitor_players row appeared between the scan and the delete;
          // the FK with ON DELETE RESTRICT blocked us. Surface the typed
          // exception rather than leaking a raw SqliteException.
          throw PlayerHasGameHistoryException(
            'Player $playerId has game history');
        }
        if (e is RepositoryException) rethrow;
        throw DatabaseException(
          'Failed to delete player $playerId',
          cause: e,
        );
      }
    });
  }

  @override
  Stream<List<Player>> watchAllPlayers() {
    return (_db.select(_db.players)
      ..orderBy([(t) => OrderingTerm(expression: t.lastActive, mode: OrderingMode.desc)]))
      .watch()
      .map((rows) => rows.map((row) => Player(
            playerId: row.playerId,
            name: row.name,
            createdAt: DateTime.parse(row.createdAt),
            lastActive: DateTime.parse(row.lastActive),
          )).toList());
  }
}