# TICKET-036: StatelessCricketEngine

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Implement `StatelessCricketEngine`, a pure-function game engine for all three Cricket variants (Standard, NoScore, CutThroat). It implements the shared `GameEngine` interface and covers all transition tables in `docs/games/cricket.transitions.md`. Like `StatelessX01Engine`, it has no side effects, no persistence, and no Flutter dependencies — it is fully testable without a database or runtime.

Also wire the cricket case in `GameEngineFactory` so the application can select the correct engine from a `Game` object's `gameType`.

Depends on: TICKET-035 (`CompetitorState` cricket fields).

---

## Acceptance Criteria

### Engine class
- [ ] `lib/features/game/domain/engines/stateless_cricket_engine.dart` exists and implements `GameEngine`
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Reads variant from the `GameState`'s embedded config (parsed from `CricketGameConfig` stored in `game.configJson`): `Standard`, `NoScore`, or `CutThroat`

### Event routing — `apply(GameState state, GameEvent event)`
- [ ] `GameCreated` → returns state unchanged (creation already reflected in initial state)
- [ ] `TurnStarted` → advances `currentTurnIndex` to the next competitor; resets `dartsThrownInTurn` to 0
- [ ] `DartThrown` → full scoring logic (see below); increments `dartsThrownInTurn`; auto-emits `TurnEnded` logic when 3 darts thrown or a win condition is met
- [ ] `TurnEnded` → rotates `currentTurnIndex` to next competitor; resets `dartsThrownInTurn` to 0
- [ ] `LegCompleted` → resets per-leg state: all `marksPerNumber` maps cleared, all `closeOrder` set to `null`, scores reset per variant rules
- [ ] `GameCompleted` → sets `isComplete = true`; sets `winnerCompetitorId`

### `isValid(GameState state, GameEvent event)`
- [ ] Returns `false` (rejects) if `state.isComplete`
- [ ] Returns `false` if event is `DartThrown` and `dartsThrownInTurn >= 3`
- [ ] Returns `false` if a `TurnStarted` event is issued when a turn is already active (darts in flight)
- [ ] Returns `true` for all other valid event types in a valid state

### DartThrown scoring logic
- [ ] **Segment parsing**: parse segment string into number and multiplier
  - `'20'` → number `20`, multiplier `1`
  - `'D20'` → number `20`, multiplier `2`
  - `'T20'` → number `20`, multiplier `3`
  - `'SB'` → cricket number `'Bull'`, mark count `1`
  - `'DB'` → cricket number `'Bull'`, mark count `2`
  - `'MISS'` → no cricket number; dart consumed, no effect
- [ ] **Invalid numbers**: segments for numbers 1–14 and non-bull numbers 21–24 are consumed (dart count incremented) but have no effect on marks or score
- [ ] **Mark count per segment type**: Single → 1 mark, Double → 2 marks, Triple → 3 marks; `SB` → 1 mark on `'Bull'`; `DB` → 2 marks on `'Bull'`
- [ ] **Mark capping**: marks for a number are capped at 3; excess marks beyond 3 are overflow marks
- [ ] **Closing**: when a competitor's marks for a number reach 3, that number is closed for them; set `marksPerNumber['<num>'] = 3`
- [ ] **closeOrder**: when a competitor closes their last open cricket number (all 7 closed), set `closeOrder = currentRound` (or the dart index within the leg)

### Overflow scoring by variant
- [ ] **Standard**: overflow marks score `numberValue × overflowMarks` points for the current competitor, BUT only if at least one opponent has not yet closed that number
- [ ] **NoScore**: no overflow scoring — closing only; overflow marks have no effect
- [ ] **CutThroat**: overflow marks score `numberValue × overflowMarks` points AGAINST each opponent who has NOT yet closed that number (i.e. points added to opponents' scores, not the current player)
- [ ] **Bull scoring**: bull number value is always `25` per mark regardless of `SB` or `DB` segment (not 50 for `DB`); i.e. `DB` is 2 marks × 25 = 50 total possible overflow points

### Win condition — evaluated after every dart
- [ ] **Standard / NoScore**: a competitor wins when all 7 cricket numbers are closed AND that competitor has a score ≥ all opponents' scores (highest or equal to all)
- [ ] **CutThroat**: a competitor wins when all 7 cricket numbers are closed AND that competitor has a score ≤ all opponents' scores (lowest or equal to all)
- [ ] **Tie-break**: if scores are equal among potential winners, the competitor with the lower `closeOrder` value (closed all numbers first) wins
- [ ] **No bust**: cricket never produces a bust; `isBust` is never set to `true` in any returned state

### GameEngineFactory
- [ ] `lib/features/game/domain/engines/game_engine_factory.dart` updated to return `StatelessCricketEngine()` for `GameType.cricketStandard`, `GameType.cricketNoScore`, and `GameType.cricketCutThroat` (or equivalent cricket game type enum values)

---

## Files

- `lib/features/game/domain/engines/stateless_cricket_engine.dart` — **to create**
- `lib/features/game/domain/engines/game_engine_factory.dart` — **to update**

---

## Implementation Notes

- Cricket numbers as strings: `['15', '16', '17', '18', '19', '20', 'Bull']`. Always use this exact set — do not include numbers outside this list in mark or score logic.
- The `'Bull'` key (capital B) is canonical for both `SB` and `DB` segments. Map both to the same `marksPerNumber['Bull']` entry.
- When evaluating the win condition after a dart, check all competitors — not just the current one. Any competitor who satisfies the condition should be flagged as the winner.
- Score in `CompetitorState.score` is always the surplus score:
  - Standard: points scored by overflow (good for you)
  - CutThroat: points scored against you by opponents' overflow
- Leg reset on `LegCompleted`: clear `marksPerNumber` to `{}`, reset `closeOrder` to `null`, reset `score` to 0 for all competitors. The variant does not change across legs.
- `currentLegRound` or equivalent: use `dartsThrownInTurn` and competitor index to derive a monotonically increasing round counter for `closeOrder`. A simple approach is to use the total dart index within the leg.
- Spec references: `docs/games/cricket.transitions.md` (all tables), `docs/GAME-EVENT-SPECIFICATIONS.md` §"DartThrown", `CLAUDE.md` §"Critical Cricket rules".

---
