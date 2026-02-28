# TICKET-015: UndoLastDartUseCase

**Status:** Done
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Implement `UndoLastDartUseCase` — the domain use case that corrects the most-recently thrown dart by appending a `DartCorrected` event, deleting the associated `DartThrow` row, and replaying all events from game start to rebuild the authoritative `GameState`.

---

## Acceptance Criteria

- [x] `UndoLastDartUseCase` lives in `lib/features/game/domain/usecases/undo_last_dart_use_case.dart`
- [x] Constructor accepts `GameRepository`, `GameEventRepository`, `DartThrowRepository` interfaces — no concrete types
- [x] Retrieves the most recent `DartThrown` event for the active game
- [x] Appends a `DartCorrected` event with: `gameId`, `correctedDartId`, `correctedEventId`, and `timestamp`
- [x] Calls `DartThrowRepository.deleteDart(dartId)` to remove the physical throw record
- [x] Replays all game events from `GameCreated` through the event log (excluding the corrected dart) to compute the new authoritative `GameState`
- [x] Returns the rebuilt `GameState` on success
- [x] Throws `NoDartsToUndoException` if there are no `DartThrown` events in the current turn to undo
- [x] Throws `GameAlreadyCompleteException` if called on a finished game — completed games are read-only
- [x] Restricts undo to the current turn only: cannot undo the last dart of a previous turn without explicit spec guidance
- [x] No Flutter, sqflite, drift, or dio imports — pure Dart domain only

---

## Files

- `lib/features/game/domain/usecases/undo_last_dart_use_case.dart` — **created**
- `lib/core/error/repository_exception.dart` — added `NoDartsToUndoException`
- `test/features/game/domain/usecases/undo_last_dart_use_case_test.dart` — **created** (12 tests)
- `test/features/game/domain/usecases/undo_last_dart_use_case_test.mocks.dart` — generated

---

## Implementation Notes

- `DartCorrected` is the canonical correction event per `docs/GAME-EVENT-SPECIFICATIONS.md`. Appending it before deleting the row ensures the event log remains the single source of truth even if deletion fails.
- Full replay (not delta patching) is mandatory per the statistics architecture rules: `DartCorrected` events require full replay from the correction point forward. Replay uses the same `GameEngine.apply` loop that statistics projections use.
- The undo boundary is the current turn. If the active turn has zero darts thrown (i.e. the player is on their first dart), throw `NoDartsToUndoException`. Undoing across turn boundaries requires a spec extension — do not implement silently.
- `NoDartsToUndoException` must extend `RepositoryException` from `lib/core/error/repository_exception.dart`.
- After replay, the returned `GameState` must reflect the score and dart index as if the corrected dart was never thrown.
- Refer to `docs/GAME-EVENT-SPECIFICATIONS.md` for the exact `DartCorrected` payload shape.
- Refer to `docs/REPOSITORY_INTERFACES.md` for `DartThrowRepository.deleteDart` and `GameEventRepository.getEventsForGame` signatures.

---

## Implementation Summary

### Key design decisions

**Replay filtering:** `TurnEnded`, `LegCompleted`, and `GameCompleted` events are skipped during replay because `_applyDartThrown` already folds those state transitions in (bust recovery, legsWon increment, leg reset). Applying them again would double-count. Only `GameCreated`, `TurnStarted`, and non-corrected `DartThrown` events are passed through `GameEngine.apply`.

**Multi-undo correctness:** The replay skips *all* corrected darts (`alreadyCorrectedIds ∪ {newlyCorrectedId}`), not just the current one. This ensures repeated undos within the same turn replay correctly.

**Audit-first ordering:** `DartCorrected` is appended before `deleteDart` is called, so the event log stays consistent even if the deletion fails.

**`NoDartsToUndoException`** added to `lib/core/error/repository_exception.dart` as a `final class` extending `RepositoryException`.

### Tests (12 passing, 236 total suite)

- `GameAlreadyCompleteException` when game is complete (no repo calls made)
- `NoDartsToUndoException` when `dartsThrownInTurn == 0`
- `NoDartsToUndoException` when all darts are already corrected
- Single dart undo: score reverts, `dartsThrownInTurn` decreases by 1
- Second dart undo: first-dart state preserved
- `DartCorrected` appended before `deleteDart` (`verifyInOrder`)
- `DartCorrected` payload has correct `original_event_id` and `corrected_dart_id`
- `deleteDart` called with correct ID
- `DartCorrected` `localSequence` is `getLatestSequence() + 1`
- Replay preserves game-level metadata (strategies, legsToWin, gameType)
- Double-undo: second undo correctly excludes both corrected darts from replay
