# TICKET-014: ProcessDartUseCase

**Status:** Done
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Implement `ProcessDartUseCase` — the domain use case that receives a dart segment, validates it through the game engine, persists the `DartThrow` row, appends all resulting game events atomically, and returns the updated `GameState`.

---

## Acceptance Criteria

- [x] `ProcessDartUseCase` lives in `lib/features/game/domain/usecases/process_dart_use_case.dart`
- [x] Constructor accepts `GameRepository`, `GameEventRepository`, `DartThrowRepository`, and `GameEngine` (or `GameEngineFactory`) interfaces — no concrete types
- [x] Calls `engine.isValid(state, event)` before any persistence; returns an error result immediately if invalid
- [x] Appends `DartThrown` event for every dart (including busts and failed in-darts)
- [x] If the dart ends the turn: appends `TurnEnded` event, then `TurnStarted` for the next competitor
- [x] If the turn ends a leg: appends `LegCompleted` before `TurnStarted`
- [x] If the leg completes the game: appends `GameCompleted` instead of `TurnStarted`; marks game as complete in `GameRepository`
- [x] All event appends within a single dart are written in the correct canonical order with no gaps
- [x] Throws `GameAlreadyCompleteException` if called on a finished game
- [x] No Flutter, sqflite, drift, or dio imports — pure Dart domain only

---

## Files

- `lib/features/game/domain/usecases/process_dart_use_case.dart` — created

---

## Implementation Notes

- The canonical event order for a game-completing dart is: `DartThrown` → `TurnEnded` → `LegCompleted` → `GameCompleted`. No `TurnStarted` is appended after `GameCompleted`.
- For a turn-ending-but-not-leg-completing dart: `DartThrown` → `TurnEnded` → `TurnStarted` (next player).
- For a leg-completing-but-not-game-completing dart: `DartThrown` → `TurnEnded` → `LegCompleted` → `TurnStarted` (first player of new leg, determined by leg start rotation config).
- Busting dart still appends `DartThrown` (with bust flag in payload) followed by `TurnEnded`. Score is reset to pre-turn value — this reset is reflected in the engine result state, not via a separate event.
- Refer to `docs/GAME-EVENT-SPECIFICATIONS.md` for exact payload shapes.
- Refer to `docs/REPOSITORY_INTERFACES.md` for `DartThrowRepository.insertDart` and `GameEventRepository.appendEvent` signatures.
