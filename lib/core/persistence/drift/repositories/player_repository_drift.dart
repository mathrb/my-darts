// Player Repository Drift Implementation
// Concrete implementation of PlayerRepository interface using Drift

import 'package:drift/drift.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';
import '../database.dart' as drift_db;

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
      // Handle drift-specific exceptions using DriftWrappedException
      if (e is DriftWrappedException) {
        final cause = e.cause.toString();
        if (cause.contains('UNIQUE constraint failed') ||
            cause.contains('unique constraint failed') ||
            cause.contains('already exists')) {
          throw DuplicatePlayerException(player.playerId);
        }
      }
      rethrow;
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
  Stream<List<Player>> watchAllPlayers() {
    // For drift, we need to implement a proper stream
    // This is a simplified version - in production you'd want to use
    // drift's watch() method with proper transformation
    return Stream.fromFuture(getAllPlayers());
  }
}