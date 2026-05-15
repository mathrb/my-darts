// Shared resolver for UNIQUE-constraint violations on `game_events` inserts.
//
// Three sites perform an `insertOrFail` against the events table and must
// reconcile the violation identically:
//   - `GameEventRepositoryDrift.appendEvent`
//   - `GameEventRepositoryDrift.appendEvents`
//   - `GameRepositoryDrift.appendEventsAndCompleteGame`
//
// Centralising the reconciliation here avoids drift between the three
// implementations (and the bug surface that comes with it). The body must
// run inside the same drift transaction as the failed insert so the
// diagnostic SELECTs see a consistent snapshot.
//
// Behaviour:
//   - Same `event_id` already present → idempotent duplicate; returns true.
//     Callers should treat this as a no-op (return / continue / skip).
//   - Different event at same `(game_id, local_sequence)` → throws
//     `SequenceConflictException`.
//   - Anything else (or not a UNIQUE violation at all) → throws
//     `DatabaseException`. A pre-typed `RepositoryException` is re-thrown
//     unchanged.

import 'package:drift/drift.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'database.dart' as drift_db;
import 'sqlite_error_codes.dart';

Future<bool> resolveGameEventUniqueViolation(
  drift_db.AppDatabase db,
  GameEvent event,
  Exception e,
) async {
  if (!isUniqueConstraintViolation(e)) {
    if (e is RepositoryException) throw e;
    throw DatabaseException(
      'Failed to append game event ${event.eventId} to game ${event.gameId}',
      cause: e,
    );
  }

  // Idempotent insert: same event_id already exists.
  final existing = await (db.select(db.gameEvents)
        ..where((t) => t.eventId.equals(event.eventId))
        ..limit(1))
      .getSingleOrNull();
  if (existing != null) return true;

  // Different event already occupies (game_id, local_sequence).
  final seqExisting = await (db.select(db.gameEvents)
        ..where((t) =>
            t.gameId.equals(event.gameId) &
            t.localSequence.equals(event.localSequence))
        ..limit(1))
      .getSingleOrNull();
  if (seqExisting != null && seqExisting.eventId != event.eventId) {
    throw SequenceConflictException(event.gameId, event.localSequence);
  }

  // UNIQUE on some other column — surface as a generic database error.
  throw DatabaseException(
    'Failed to append game event ${event.eventId} to game ${event.gameId}',
    cause: e,
  );
}
