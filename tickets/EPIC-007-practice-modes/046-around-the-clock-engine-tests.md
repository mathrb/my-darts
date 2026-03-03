# TICKET-046: AroundTheClockEngine Tests

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Write comprehensive unit tests for `StatelessAroundTheClockEngine`, covering all 12 transition tables from `docs/games/around-the-clock.md`, all three variants, win conditions, and `isValid` rejection cases. Tests must be fully deterministic and run without a database or Flutter runtime.

Depends on: TICKET-045 (`StatelessAroundTheClockEngine` implementation).

---

## Acceptance Criteria

### Test file
- [ ] `test/features/game/domain/engines/around_the_clock_engine_test.dart` exists
- [ ] All tests pass with `flutter test`
- [ ] No database or Flutter widget dependencies

### Standard variant — target advancement (Table D1 / E1)
- [ ] Single on correct number advances target (`'5'` when target=5 → target=6)
- [ ] Double on correct number advances target (`'D5'` when target=5 → target=6)
- [ ] Triple on correct number advances target (`'T5'` when target=5 → target=6)
- [ ] Wrong number (any multiplier) does not advance target
- [ ] Miss (`'MISS'`) does not advance target
- [ ] Bull (`'SB'`, `'DB'`) does not advance target (Table 5 Note 3)
- [ ] Dart count increments regardless of hit/miss

### Standard variant — win sequence (Table E1 + F)
- [ ] Hitting target 20 sets `completed = true` and triggers `LegCompleted`
- [ ] Win on first dart of turn ends turn immediately (remaining darts not thrown)
- [ ] Win on second dart of turn ends turn immediately
- [ ] After win, `GameCompleted` is reflected in state (single-player, 1-leg game)

### Reverse variant (Table D1 / E2)
- [ ] Starts at target 20
- [ ] Any multiplier on correct number decrements target
- [ ] Hitting target 1 sets `completed = true` and triggers win
- [ ] Non-target numbers do not decrement

### DoublesOnly variant (Table D2 / E3)
- [ ] Single on correct number does NOT advance target
- [ ] Triple on correct number does NOT advance target
- [ ] Double on correct number advances target
- [ ] Double on wrong number does not advance target
- [ ] Win still requires double on target 20 (`'D20'` when target=20 → win)

### Multi-dart turn flow (Tables G + H)
- [ ] Turn ends after 3 darts (even if all missed)
- [ ] `dartsThrownInTurn` resets to 0 on `TurnStarted`
- [ ] `TurnEnded` advances to next competitor in multi-player game

### `isValid` rejections (Table B)
- [ ] Rejects `DartThrown` when game is complete (`isComplete == true`)
- [ ] Rejects `DartThrown` when turn is not active
- [ ] Rejects `DartThrown` when `dartsThrownInTurn == 3`
- [ ] Rejects `DartThrown` when current competitor has `completed == true`
- [ ] Rejects `TurnStarted` while turn is already active
- [ ] Accepts `DartThrown` in normal mid-turn state

### Leg reset (Table K)
- [ ] Standard/DoublesOnly: after `LegCompleted`, `currentTarget` resets to 1
- [ ] Reverse: after `LegCompleted`, `currentTarget` resets to 20
- [ ] `completed` resets to `false` after leg reset

---

## Files

- `test/features/game/domain/engines/around_the_clock_engine_test.dart` — **to create**

---

## Implementation Notes

- Use `GameState.initial(game, competitors)` with an `AroundTheClockGameConfig` to build starting states.
- Call `engine.apply(state, event)` for each event; accumulate state through multiple `apply()` calls in sequence tests.
- Helper function: `buildState({String variant = 'standard', int target = 1, int dartsThrown = 0, bool complete = false})` that constructs the minimal `GameState` for a given scenario.
- Test the win-mid-turn case by verifying the returned `GameState.isComplete == true` after the winning dart apply, without needing to call `apply` for subsequent darts.
- Spec references: `docs/games/around-the-clock.md` §§ D, E, F, B and "Notes on Ambiguities".

---
