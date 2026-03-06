# TICKET-045: StatelessAroundTheClockEngine

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `StatelessAroundTheClockEngine`, a pure-function game engine for all three Around the Clock variants (Standard, Reverse, DoublesOnly). It implements the shared `GameEngine` interface and covers all 12 transition tables in `docs/games/around-the-clock.md`. Like all other stateless engines, it has no side effects, no persistence, and no Flutter dependencies.

Also wire the Around the Clock case in `GameEngineFactory`.

Depends on: TICKET-044 (practice model additions — `aroundTheClockVariant` on `GameState`, `currentTarget` on `CompetitorState`).

---

## Acceptance Criteria

### Engine class
- [ ] `lib/features/game/domain/engines/stateless_around_the_clock_engine.dart` exists and implements `GameEngine`
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Reads variant from `GameState.aroundTheClockVariant` (`'standard'`, `'reverse'`, `'doublesOnly'`)

### Event routing — `apply(GameState state, GameEvent event)`
- [ ] `GameCreated` → returns state unchanged
- [ ] `TurnStarted` (Table A) → sets `dartsThrownInTurn = 0`; `turnActive = true`
- [ ] `DartThrown` → full scoring logic (Tables D–H); increments `dartsThrownInTurn`
- [ ] `TurnEnded` (Table I) → sets `turnActive = false`; advances `currentTurnIndex`
- [ ] `LegCompleted` (Table J+K) → increments `legsWon` for the winning competitor; resets per-leg state (resets `currentTarget`, `completed`, `turnActive`); if `legsWon == legsToWin` → `isComplete = true`
- [ ] `GameCompleted` (Table L) → sets `isComplete = true`, sets `winnerCompetitorId`

### `isValid(GameState state, GameEvent event)` — Table B
- [ ] Returns `false` if `state.isComplete`
- [ ] Returns `false` if event is `DartThrown` and `dartsThrownInTurn >= 3`
- [ ] Returns `false` if event is `TurnStarted` while a turn is already active
- [ ] Returns `false` if event is `DartThrown` and current competitor's `currentTarget` is already completed
- [ ] Returns `true` for all other valid events in a valid state

### DartThrown — Standard & Reverse (Table D1)
- [ ] Parses segment string into number and multiplier using canonical segment format (`'5'` → 5 ×1, `'D5'` → 5 ×2, `'T5'` → 5 ×3, `'SB'` / `'DB'` → Bull, `'MISS'` → no number)
- [ ] Hit: any multiplier counts if `segmentNumber == currentTarget`
- [ ] Miss on correct number or wrong number: no target advance
- [ ] Bull (`SB`/`DB`) does NOT count as any number 1–20; ignored (Table 5, Note 3)
- [ ] Dart is always counted as thrown regardless of hit/miss

### DartThrown — DoublesOnly (Table D2)
- [ ] Hit: ONLY double (`multiplier == 2`) on `segmentNumber == currentTarget` advances
- [ ] Single or triple on correct number: no advance
- [ ] Wrong number: no advance

### Target Advancement (Table E)
- [ ] Standard (E1): `currentTarget < 20` → `currentTarget += 1`; `currentTarget == 20` → `completed = true`
- [ ] Reverse (E2): `currentTarget > 1` → `currentTarget -= 1`; `currentTarget == 1` → `completed = true`
- [ ] DoublesOnly (E3): same advancement logic as Standard (E1)

### Win Condition (Table F)
- [ ] Evaluated immediately after each `DartThrown` that sets `completed = true`
- [ ] On win: emit `LegCompleted` within the same `apply()` call chain
- [ ] Remaining darts in turn are not thrown — turn ends on the winning dart

### Turn End (Table H)
- [ ] Turn ends when `dartsThrownInTurn == 3`
- [ ] Turn also ends when player completes on 1st or 2nd dart

### Leg Reset (Table K)
- [ ] Standard/DoublesOnly: `currentTarget = 1`, `completed = false`
- [ ] Reverse: `currentTarget = 20`, `completed = false`
- [ ] All variants: `turnActive = false`, `currentLegIndex += 1`

### GameEngineFactory
- [ ] `lib/features/game/domain/engines/game_engine_factory.dart` updated to return `StatelessAroundTheClockEngine()` for `GameType.aroundTheClock`

---

## Files

- `lib/features/game/domain/engines/stateless_around_the_clock_engine.dart` — **to create**
- `lib/features/game/domain/engines/game_engine_factory.dart` — **to update**

---

## Implementation Notes

- The canonical segment format used throughout the codebase: `'20'` = single 20, `'D20'` = double 20, `'T20'` = triple 20, `'SB'` = single bull, `'DB'` = double bull, `'MISS'` = miss.
- Parse multiplier: prefix `'T'` → 3, `'D'` → 2, no prefix → 1. Extract number from remainder.
- `CompetitorState.currentTarget` tracks each competitor's current target independently. In a multi-player game, each player has their own target (the game is parallel, not turn-by-turn shared target).
- `CompetitorState.completed` (or check `currentTarget > 20` / `< 1` depending on direction) signals that a competitor finished. Add a `completed` boolean to `CompetitorState` if not present — or derive from `currentTarget` sentinel value.
- Win evaluation: check only the current competitor (the one who just threw). In a single-player drill, this is always the only competitor.
- The engine's `apply()` is a pure function — it returns a new `GameState`. Events are already committed by the use case layer; the engine just derives the new state from an event.
- Spec references: `docs/games/around-the-clock.md` (all 12 tables), `docs/GAME-EVENT-SPECIFICATIONS.md`.

---
