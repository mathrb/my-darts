// Game Event Repository Drift Implementation
// Concrete implementation of GameEventRepository interface using Drift

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:my_darts/core/error/repository_exception.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/game/domain/repositories/game_event_repository.dart';
import '../database.dart' as drift_db;

// Import SqlException from drift
import 'package:drift/native.dart' show SqliteException;

class GameEventRepositoryDrift implements GameEventRepository {
  final drift_db.AppDatabase _db;

  GameEventRepositoryDrift(this._db);

  @override
  Future<List<GameEvent>> getEventsSince(String gameId, int afterSequence) async {
    final query = _db.select(_db.gameEvents)
      ..where((t) => t.gameId.equals(gameId) & t.localSequence.isBiggerThanValue(afterSequence))
      ..orderBy([
        (t) => OrderingTerm(expression: t.localSequence, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => GameEvent(
      eventId: row.eventId,
      gameId: row.gameId,
      eventType: row.eventType,
      localSequence: row.localSequence,
      occurredAt: DateTime.parse(row.occurredAt),
      payload: json.decode(row.payloadJson),
      synced: row.synced == 1,
      actorId: row.actorId,
      globalSequence: row.globalSequence,
      source: _parseEventSource(row.source),
    )).toList();
  }

  @override
  Future<int> getLatestSequence(String gameId) async {
    final query = _db.selectOnly(_db.gameEvents)
      ..addColumns([_db.gameEvents.localSequence.max()])
      ..where(_db.gameEvents.gameId.equals(gameId));

    final result = await query.getSingleOrNull();
    final maxSequence = result?.read(_db.gameEvents.localSequence.max());

    return maxSequence ?? -1;
  }

  @override
  Future<void> appendEvent(GameEvent event) async {
    try {
      await _db.into(_db.gameEvents).insert(
        drift_db.GameEventsCompanion.insert(
          eventId: event.eventId,
          gameId: event.gameId,
          eventType: event.eventType,
          localSequence: event.localSequence,
          occurredAt: event.occurredAt.toIso8601String(),
          payloadJson: json.encode(event.payload),
          synced: Value(event.synced ? 1 : 0),
          actorId: event.actorId,
          globalSequence: Value.absentIfNull(event.globalSequence),
          source: Value(event.source.index),
        ),
        mode: InsertMode.insertOrFail,
      );
    } on SqliteException catch (e) {
      if (e.extendedResultCode == 1555 || // SQLITE_CONSTRAINT_PRIMARYKEY
          e.extendedResultCode == 2067) { // SQLITE_CONSTRAINT_UNIQUE
        throw SequenceConflictException(event.gameId, event.localSequence);
      }
      rethrow;
    }
  }

  @override
  Future<void> appendEvents(List<GameEvent> events) async {
    if (events.isEmpty) return;

    await _db.transaction(() async {
      for (final event in events) {
        try {
          await _db.into(_db.gameEvents).insert(
            drift_db.GameEventsCompanion.insert(
              eventId: event.eventId,
              gameId: event.gameId,
              eventType: event.eventType,
              localSequence: event.localSequence,
              occurredAt: event.occurredAt.toIso8601String(),
              payloadJson: json.encode(event.payload),
              synced: Value(event.synced ? 1 : 0),
              actorId: event.actorId,
              globalSequence: Value.absentIfNull(event.globalSequence),
              source: Value(event.source.index),
            ),
            mode: InsertMode.insertOrFail,
          );
        } on SqliteException catch (e) {
          if (e.extendedResultCode == 1555 || // SQLITE_CONSTRAINT_PRIMARYKEY
              e.extendedResultCode == 2067) { // SQLITE_CONSTRAINT_UNIQUE
            throw SequenceConflictException(event.gameId, event.localSequence);
          }
          rethrow;
        }
      }
    });
  }

  @override
  Future<void> markSynced(List<String> eventIds) async {
    if (eventIds.isEmpty) return;

    await _db.transaction(() async {
      for (final eventId in eventIds) {
        await (_db.update(_db.gameEvents)
          ..where((t) => t.eventId.equals(eventId)))
          .write(
            drift_db.GameEventsCompanion(
              synced: Value(1),
            ),
          );
      }
    });
  }

  @override
  Future<void> updateGlobalSequences(Map<String, int> eventIdToSequence) async {
    if (eventIdToSequence.isEmpty) return;

    await _db.transaction(() async {
      for (final entry in eventIdToSequence.entries) {
        await (_db.update(_db.gameEvents)
          ..where((t) => t.eventId.equals(entry.key)))
          .write(
            drift_db.GameEventsCompanion(
              globalSequence: Value(entry.value),
            ),
          );
      }
    });
  }

  @override
  Future<List<GameEvent>> getEventsForGame(String gameId) async {
    final query = _db.select(_db.gameEvents)
      ..where((t) => t.gameId.equals(gameId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.localSequence, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => GameEvent(
      eventId: row.eventId,
      gameId: row.gameId,
      eventType: row.eventType,
      localSequence: row.localSequence,
      occurredAt: DateTime.parse(row.occurredAt),
      payload: json.decode(row.payloadJson),
      synced: row.synced == 1,
      actorId: row.actorId,
      globalSequence: row.globalSequence,
      source: _parseEventSource(row.source),
    )).toList();
  }

  Future<GameEvent?> getEvent(String eventId) async {
    final query = _db.select(_db.gameEvents)
      ..where((t) => t.eventId.equals(eventId))
      ..limit(1);

    final result = await query.getSingleOrNull();

    if (result == null) return null;
    
    return GameEvent(
      eventId: result.eventId,
      gameId: result.gameId,
      eventType: result.eventType,
      localSequence: result.localSequence,
      occurredAt: DateTime.parse(result.occurredAt),
      payload: json.decode(result.payloadJson),
      synced: result.synced == 1,
      actorId: result.actorId,
      globalSequence: result.globalSequence,
      source: _parseEventSource(result.source),
    );
  }

  Future<void> insertEvent(GameEvent event) async {
    try {
      await _db.into(_db.gameEvents).insert(
        drift_db.GameEventsCompanion.insert(
          eventId: event.eventId,
          gameId: event.gameId,
          eventType: event.eventType,
          localSequence: event.localSequence,
          occurredAt: event.occurredAt.toIso8601String(),
          payloadJson: json.encode(event.payload),
          synced: Value(event.synced ? 1 : 0),
          actorId: event.actorId,
          globalSequence: Value.absentIfNull(event.globalSequence),
          source: Value(event.source.index),
        ),
        mode: InsertMode.insertOrFail,
      );
    } on SqliteException catch (e) {
      if (e.extendedResultCode == 1555 || // SQLITE_CONSTRAINT_PRIMARYKEY
          e.extendedResultCode == 2067) { // SQLITE_CONSTRAINT_UNIQUE
        throw SequenceConflictException(event.gameId, event.localSequence);
      }
      rethrow;
    }
  }

  Future<void> insertEvents(List<GameEvent> events) async {
    if (events.isEmpty) return;

    await _db.transaction(() async {
      for (final event in events) {
        try {
          await _db.into(_db.gameEvents).insert(
            drift_db.GameEventsCompanion.insert(
              eventId: event.eventId,
              gameId: event.gameId,
              eventType: event.eventType,
              localSequence: event.localSequence,
              occurredAt: event.occurredAt.toIso8601String(),
              payloadJson: json.encode(event.payload),
              synced: Value(event.synced ? 1 : 0),
              actorId: event.actorId,
              globalSequence: Value.absentIfNull(event.globalSequence),
              source: Value(event.source.index),
            ),
            mode: InsertMode.insertOrFail,
          );
        } on SqliteException catch (e) {
          if (e.extendedResultCode == 1555 || // SQLITE_CONSTRAINT_PRIMARYKEY
              e.extendedResultCode == 2067) { // SQLITE_CONSTRAINT_UNIQUE
            throw SequenceConflictException(event.gameId, event.localSequence);
          }
          rethrow;
        }
      }
    });
  }

  Future<void> updateEventSyncStatus(String eventId, bool synced) async {
    final rowsAffected = await (_db.update(_db.gameEvents)
      ..where((t) => t.eventId.equals(eventId)))
      .write(
        drift_db.GameEventsCompanion(
          synced: Value(synced ? 1 : 0),
        ),
      );

    if (rowsAffected == 0) {
      throw EventNotFoundException(eventId);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    final rowsAffected = await (_db.delete(_db.gameEvents)
      ..where((t) => t.eventId.equals(eventId)))
      .go();

    if (rowsAffected == 0) {
      throw EventNotFoundException(eventId);
    }
  }

  @override
  Future<List<GameEvent>> getUnsyncedEvents() async {
    final query = _db.select(_db.gameEvents)
      ..where((t) => t.synced.equals(0))
      ..orderBy([
        (t) => OrderingTerm(expression: t.localSequence, mode: OrderingMode.asc),
      ]);

    final results = await query.get();

    return results.map((row) => GameEvent(
      eventId: row.eventId,
      gameId: row.gameId,
      eventType: row.eventType,
      localSequence: row.localSequence,
      occurredAt: DateTime.parse(row.occurredAt),
      payload: json.decode(row.payloadJson),
      synced: row.synced == 1,
      actorId: row.actorId,
      globalSequence: row.globalSequence,
      source: _parseEventSource(row.source),
    )).toList();
  }

  Future<int> getNextLocalSequence(String gameId) async {
    final query = _db.selectOnly(_db.gameEvents)
      ..addColumns([_db.gameEvents.localSequence.max()])
      ..where(_db.gameEvents.gameId.equals(gameId));

    final result = await query.getSingleOrNull();
    final maxSequence = result?.read(_db.gameEvents.localSequence.max());

    return (maxSequence ?? 0) + 1;
  }

  @override
  Stream<List<GameEvent>> watchEventsForGame(String gameId) {
    return Stream.fromFuture(getEventsForGame(gameId));
  }

  // Helper method to parse event source from int
  EventSource _parseEventSource(int sourceInt) {
    return EventSource.values.firstWhere(
      (source) => source.index == sourceInt,
      orElse: () => EventSource.values.first,
    );
  }
}
