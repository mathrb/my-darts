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
- [x] `EngineResult` carries: updated `GameState`, list of derived events to append (e.g. `TurnEnded`, `LegCompleted`, `GameCompleted`), and a bust flag
- [x] No imports of Flutter, sqflite, drift, or dio in this file — pure Dart domain code only
- [x] `GameEngineFactory` or equivalent wires the correct engine for a given `GameType`

---

## Files

- `lib/features/game/domain/engines/base_game_engine.dart` — created
- `lib/features/game/domain/engines/game_engine_factory.dart` — created

---

## Implementation Notes

- `apply` and `isValid` are pure functions: no side effects, no I/O. They take immutable state and return a new value.
- `EngineResult` keeps derived events separate from the returned state so the use case layer controls persistence ordering.
- The factory pattern (`GameEngineFactory`) allows `ProcessDartUseCase` to remain generic across game types without a switch statement in the use case itself.
- Domain entities must not import any Flutter or persistence packages.
