# TICKET-051: StatelessCatch40Engine

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `StatelessCatch40Engine`, a pure-function game engine for the Catch 40 practice drill. Each round has a fixed target total. The player accumulates the raw score of 3 darts in a turn; if the accumulated score meets or exceeds the round's target, the round target is added to the player's running score. After all rounds complete, the drill ends.

Also wire the Catch 40 case in `GameEngineFactory`.

Depends on: TICKET-044 (practice model additions — `practiceRound` on `CompetitorState`; `Catch40GameConfig` with `totalRounds` and `roundTargets`).

---

## Acceptance Criteria

### Engine class
- [ ] `lib/features/game/domain/engines/stateless_catch_40_engine.dart` exists and implements `GameEngine`
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Reads `totalRounds` and `roundTargets` from `Catch40GameConfig` embedded in `GameState`
- [ ] Reads current round from `CompetitorState.practiceRound` (1-based index into `roundTargets` array)

### Event routing — `apply(GameState state, GameEvent event)`
- [ ] `GameCreated` → returns state unchanged
- [ ] `TurnStarted` → sets `dartsThrownInTurn = 0`
- [ ] `DartThrown` → accumulates dart's score value toward turn total; increments `dartsThrownInTurn`; on 3rd dart: applies catch logic and advances round
- [ ] `TurnEnded` → rotates competitor (single-player: no-op); resets `dartsThrownInTurn = 0`
- [ ] `GameCompleted` → sets `isComplete = true`, `winnerCompetitorId = null` (drill complete)

### Catch logic (applied on the 3rd dart)
- [ ] Turn total = sum of raw score values of all 3 darts thrown in the turn (standard dart scoring: single=face value, double=face×2, triple=face×3; MISS=0)
- [ ] Round target = `roundTargets[practiceRound - 1]` (zero-indexed into the config list)
- [ ] If `turnTotal >= roundTarget`: `score += roundTarget` (the target value, not the raw dart total)
- [ ] If `turnTotal < roundTarget`: no score added for this round
- [ ] After applying catch logic: `practiceRound += 1`
- [ ] After `practiceRound > totalRounds`: emit `GameCompleted` with `winnerCompetitorId = null`

### `isValid(GameState state, GameEvent event)`
- [ ] Returns `false` if `state.isComplete`
- [ ] Returns `false` if event is `DartThrown` and `dartsThrownInTurn >= 3`
- [ ] Returns `false` if event is `TurnStarted` while turn already active
- [ ] Returns `true` for all other valid events

### GameEngineFactory
- [ ] `lib/features/game/domain/engines/game_engine_factory.dart` updated to return `StatelessCatch40Engine()` for `GameType.catch40`

---

## Files

- `lib/features/game/domain/engines/stateless_catch_40_engine.dart` — **to create**
- `lib/features/game/domain/engines/game_engine_factory.dart` — **to update**

---

## Implementation Notes

- The default `roundTargets` is `[10, 15, 20, 25, 30, 35, 40, 45]` (8 rounds). The engine reads this from the config each time — do not hardcode.
- Dart score values: segment `'20'` = 20, `'D20'` = 40, `'T20'` = 60, `'SB'` = 25, `'DB'` = 50, `'MISS'` = 0. Use a shared `Segment.parse(segment).scoreValue` utility if it exists in the codebase; otherwise implement inline.
- Like Bob's 27 (TICKET-047), per-turn accumulation requires either a transient `CompetitorState` field or reading all `DartThrown` events within the current `TurnStarted–TurnEnded` window. Coordinate with TICKET-047 implementor on which approach is used and be consistent.
- The `score` field on `CompetitorState` represents the "catches" score — it starts at 0 and only increases.
- `practiceRound` increments on the 3rd dart of each turn (before `TurnEnded` is emitted). After incrementing past `totalRounds`, `GameCompleted` fires.
- This is a solo drill — no competitive winner. `winnerCompetitorId` is always `null` in `GameCompleted`.
- Spec references: `EPIC-007-practice-modes.md` §"Catch 40".

---
