# TICKET-015: UndoLastDartUseCase

**Status:** Todo
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Implement `UndoLastDartUseCase` — the domain use case that corrects the most-recently thrown dart by appending a `DartCorrected` event, deleting the associated `DartThrow` row, and replaying all events from game start to rebuild the authoritative `GameState`.

---

## Acceptance Criteria

- [ ] `UndoLastDartUseCase` lives in `lib/features/game/domain/usecases/undo_last_dart_use_case.dart`
- [ ] Constructor accepts `GameRepository`, `GameEventRepository`, `DartThrowRepository` interfaces — no concrete types
- [ ] Retrieves the most recent `DartThrown` event for the active game
- [ ] Appends a `DartCorrected` event with: `gameId`, `correctedDartId`, `correctedEventId`, and `timestamp`
- [ ] Calls `DartThrowRepository.deleteDart(dartId)` to remove the physical throw record
- [ ] Replays all game events from `GameCreated` through the event log (excluding the corrected dart) to compute the new authoritative `GameState`
- [ ] Returns the rebuilt `GameState` on success
- [ ] Throws `NoDartsToUndoException` if there are no `DartThrown` events in the current turn to undo
- [ ] Throws `GameAlreadyCompleteException` if called on a finished game — completed games are read-only
- [ ] Restricts undo to the current turn only: cannot undo the last dart of a previous turn without explicit spec guidance
- [ ] No Flutter, sqflite, drift, or dio imports — pure Dart domain only

---

## Files

- `lib/features/game/domain/usecases/undo_last_dart_use_case.dart` — **to create** (file does not exist)

---

## Implementation Notes

- `DartCorrected` is the canonical correction event per `docs/GAME-EVENT-SPECIFICATIONS.md`. Appending it before deleting the row ensures the event log remains the single source of truth even if deletion fails.
- Full replay (not delta patching) is mandatory per the statistics architecture rules: `DartCorrected` events require full replay from the correction point forward. Replay uses the same `GameEngine.apply` loop that statistics projections use.
- The undo boundary is the current turn. If the active turn has zero darts thrown (i.e. the player is on their first dart), throw `NoDartsToUndoException`. Undoing across turn boundaries requires a spec extension — do not implement silently.
- `NoDartsToUndoException` must extend `RepositoryException` from `lib/core/error/repository_exception.dart`.
- After replay, the returned `GameState` must reflect the score and dart index as if the corrected dart was never thrown.
- Refer to `docs/GAME-EVENT-SPECIFICATIONS.md` for the exact `DartCorrected` payload shape.
- Refer to `docs/REPOSITORY_INTERFACES.md` for `DartThrowRepository.deleteDart` and `GameEventRepository.getEventsForGame` signatures.
