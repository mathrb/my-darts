# TICKET-013: CreateGameUseCase

**Status:** Done
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Implement `CreateGameUseCase` — the domain use case that validates a new game configuration, writes the initial game row, and emits the canonical opening event sequence (`GameCreated` + `TurnStarted`) so the game is immediately ready for dart input.

---

## Acceptance Criteria

- [x] `CreateGameUseCase` lives in `lib/features/game/domain/usecases/create_game_use_case.dart`
- [x] Constructor accepts `GameRepository` and `GameEventRepository` interfaces (no concrete types)
- [x] Validates game config: at least 2 competitors (or 1 for practice), valid `startingScore` (101/201/301/401/501/701/1001), valid `legsToWin` (≥ 1), valid in/out strategy enum values
- [x] On success: writes the `Game` row, appends `GameCreated` event, then appends `TurnStarted` event for the first competitor
- [x] Returns the created `Game` entity on success
- [x] Throws `ValidationException` (subclass of `RepositoryException`) on invalid config — never throws raw `Exception`
- [x] No Flutter, sqflite, drift, or dio imports — pure Dart domain only

---

## Files

- `lib/features/game/domain/usecases/create_game_use_case.dart` — implemented
- `lib/features/game/domain/models/game_config.dart` — added `legsToWin` field to `X01GameConfig` (default 1, backward-compatible)
- `lib/core/error/repository_exception.dart` — added `ValidationException`
- `test/features/game/domain/usecases/create_game_use_case_test.dart` — 27 tests, all passing

---

## Implementation Notes

- Event ordering is critical: `GameCreated` must be appended before `TurnStarted`. The use case must not fire-and-forget — await each append before the next.
- `TurnStarted` payload must include: `gameId`, `competitorId` of the first player, `turnIndex: 0`, and `legIndex: 0`.
- The first competitor's turn order is determined by the order of the `competitors` list in the config (index 0 goes first).
- Do not generate any statistics or pre-calculate scores here. The event log is the sole source of truth from game creation onwards.
- Refer to `docs/GAME-EVENT-SPECIFICATIONS.md` for the exact payload shape of `GameCreated` and `TurnStarted`.

---

## Summary

Full implementation was missing: the stub had no validation, an incorrect `TurnStarted` payload (missing `gameId` and `legIndex`), and `ValidationException` did not exist. Implemented:

1. **`ValidationException`** added to `lib/core/error/repository_exception.dart`.
2. **`legsToWin`** added to `X01GameConfig` with `@Default(1)` for backward compatibility; all existing call sites unaffected.
3. **`CreateGameUseCase`** rewired: validates competitors count (≥ 1), X01 `startingScore` from the set {101,201,301,401,501,701,1001}, `inStrategy`/`outStrategy` from {straight,double,master}, and `legsToWin ≥ 1`. Sequences events off `getLatestSequence`. `TurnStarted` payload now includes all four required fields.
4. **27 unit tests** covering happy path, event ordering, payload shape, sequence numbering, and every validation branch.
