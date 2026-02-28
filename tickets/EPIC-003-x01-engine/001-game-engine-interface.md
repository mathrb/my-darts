# TICKET-011: Game Engine Interface

**Status:** Done
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Define the abstract `GameEngine` interface and the `EngineResult` return type that all game engine implementations must satisfy. This provides the stable contract between the domain use cases and the concrete engine logic.

---

## Acceptance Criteria

- [x] `GameEngine` abstract class defined in `lib/features/game/domain/engines/base_game_engine.dart`
- [x] `GameEngine.apply(GameState state, GameEvent event)` returns an `EngineResult`
- [x] `GameEngine.isValid(GameState state, GameEvent event)` returns `bool`
- [x] `EngineResult` carries: updated `GameState`, a `LegOutcome` enum (`none | legCompleted | gameCompleted`), and an optional `winnerCompetitorId`
- [x] No imports of Flutter, sqflite, drift, or dio in this file — pure Dart domain code only
- [x] `GameEngineFactory` or equivalent wires the correct engine for a given `GameType`

---

## Files

- `lib/features/game/domain/engines/base_game_engine.dart` — created
- `lib/features/game/domain/engines/game_engine_factory.dart` — created

---

## Implementation Notes

- `apply` and `isValid` are pure functions: no side effects, no I/O. They take immutable state and return a new value.
- `EngineResult` uses a `LegOutcome` enum (`none | legCompleted | gameCompleted`) rather than a list of derived events. This avoids tight coupling between the engine and event types — the use-case layer reads the outcome and decides which `GameEvent`s to emit and persist.
- Bust is handled entirely inside the engine: the state's score is restored to `turnStartScore` and the turn is force-ended. No separate bust flag is exposed on `EngineResult`; the calling use case infers a bust from the resulting state if needed.
- `winnerCompetitorId` is non-null only when `outcome == LegOutcome.gameCompleted`.
- The factory pattern (`GameEngineFactory`) allows `ProcessDartUseCase` to remain generic across game types without a switch statement in the use case itself.
- Domain entities must not import any Flutter or persistence packages.

---

## Summary

Both implementation files are complete and verified:

- `lib/features/game/domain/engines/base_game_engine.dart` — defines `GameEngine` abstract class, `EngineResult`, and `LegOutcome` enum. No Flutter/persistence imports.
- `lib/features/game/domain/engines/game_engine_factory.dart` — factory switches on `GameType` and returns `StatelessX01Engine()` for X01.

**Key divergence from original AC #4:** The initial acceptance criterion described a "list of derived events" and a "bust flag" on `EngineResult`. The actual implementation uses a `LegOutcome` enum and optional `winnerCompetitorId` instead. This is a deliberate design choice: the engine signals outcomes via enum; the use-case layer owns event emission and persistence ordering. Bust is internal to the engine and does not require a separate signal on the result type.
