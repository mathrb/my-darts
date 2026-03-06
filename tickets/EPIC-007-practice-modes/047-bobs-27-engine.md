# TICKET-047: StatelessBobs27Engine

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `StatelessBobs27Engine`, a pure-function game engine for the Bob's 27 doubles drill. The drill runs for 20 rounds; each round's target is the double of the round number (D1 in round 1, D2 in round 2, …, D20 in round 20). Hitting the required double scores points; missing all three darts deducts points. The drill ends after all 20 rounds complete, or early if the score drops to ≤ 0.

Also wire the Bob's 27 case in `GameEngineFactory`.

Depends on: TICKET-044 (practice model additions — `practiceRound` on `CompetitorState`, starting score of 27 set in `GameState.initial()`).

---

## Acceptance Criteria

### Engine class
- [ ] `lib/features/game/domain/engines/stateless_bobs_27_engine.dart` exists and implements `GameEngine`
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Reads current round from `CompetitorState.practiceRound` (1–20)

### Event routing — `apply(GameState state, GameEvent event)`
- [ ] `GameCreated` → returns state unchanged
- [ ] `TurnStarted` → sets `dartsThrownInTurn = 0`
- [ ] `DartThrown` → full scoring logic (see below); increments `dartsThrownInTurn`; on 3rd dart: applies turn result (hit count vs miss penalty), increments `practiceRound`; checks end condition
- [ ] `TurnEnded` → rotates turn to next competitor (always only one in practice); resets `dartsThrownInTurn = 0`
- [ ] `GameCompleted` → sets `isComplete = true`, `winnerCompetitorId` (may be `null` for drill completion without win)

### Scoring logic — per turn (applied after the 3rd dart)
- [ ] **Required double**: segment `D{round}` where `round = practiceRound`
- [ ] **Hit scoring**: count how many darts in the turn hit the required double; `score += (round × 2) × hitCount`
  - Example: round 5, hit D5 twice → `score += 10 × 2 = 20`
- [ ] **Miss penalty**: if ZERO darts in the turn hit the required double → `score -= (round × 2)`
  - Example: round 5, no D5 hit → `score -= 10`
- [ ] **Non-target segments**: any dart that is not `D{round}` (including `D{other}`, singles, triples, MISS, Bull) does NOT score and does NOT count as hitting the required double
- [ ] Only `D{round}` (exact match) counts as hitting the required double

### End conditions
- [ ] After completing round 20 (the 3rd dart of turn 20): emit `GameCompleted` with `winnerCompetitorId = null` (drill complete — no winner in single-player)
- [ ] After any round, if `score <= 0`: emit `GameCompleted` with `winnerCompetitorId = null` (drill failed early)
- [ ] Score is clamped at the actual value (may go negative before clamping is applied); the check is `score <= 0` after deduction

### `isValid(GameState state, GameEvent event)`
- [ ] Returns `false` if `state.isComplete`
- [ ] Returns `false` if event is `DartThrown` and `dartsThrownInTurn >= 3`
- [ ] Returns `false` if event is `TurnStarted` while turn is already active
- [ ] Returns `true` for all other valid events

### GameEngineFactory
- [ ] `lib/features/game/domain/engines/game_engine_factory.dart` updated to return `StatelessBobs27Engine()` for `GameType.bobs27`

---

## Files

- `lib/features/game/domain/engines/stateless_bobs_27_engine.dart` — **to create**
- `lib/features/game/domain/engines/game_engine_factory.dart` — **to update**

---

## Implementation Notes

- Starting score is 27 — this is set in `GameState.initial()` in TICKET-044, not in the engine. The engine reads `competitor.score` on first apply and trusts the initial value.
- The "hit count" for a turn must be tracked within the `apply()` call for the 3rd dart. Since `apply()` is applied dart-by-dart, the engine needs to accumulate hits across the turn. Consider storing intermediate turn hits in `CompetitorState` (e.g., a `practiceHitsThisTurn` field), or derive them by tracking all DartThrown events within a TurnStarted–TurnEnded window.
- If no additional `CompetitorState` field is available, a simpler alternative: accumulate hits inside a private list that is part of `GameState` as a transient field (e.g., `@Default([]) List<String> currentTurnSegments`) so the engine can count after 3 darts. Discuss with team before choosing approach — use the pattern consistent with the existing codebase.
- The turn result (score change) is applied on the 3rd dart's `DartThrown` event — it is not deferred to `TurnEnded`. The `TurnEnded` event only rotates the competitor.
- `practiceRound` increments from 1 to 20. On the 3rd dart of round 20, increment to 21 (or leave at 20) before emitting `GameCompleted`.
- Spec references: `EPIC-007-practice-modes.md` §"Bob's 27", `docs/GAME-EVENT-SPECIFICATIONS.md`.

---
