# TICKET-048: Bobs27Engine Tests

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Write comprehensive unit tests for `StatelessBobs27Engine`, covering all scoring rules, deduction rules, turn flow, and end conditions. Tests must be fully deterministic and run without a database or Flutter runtime.

Depends on: TICKET-047 (`StatelessBobs27Engine` implementation).

---

## Acceptance Criteria

### Test file
- [ ] `test/features/game/domain/engines/bobs_27_engine_test.dart` exists
- [ ] All tests pass with `flutter test`
- [ ] No database or Flutter widget dependencies

### Score increment — hitting required double
- [ ] Round 1, hit D1 once → `score += 2` (1 × 2 × 1 hit)
- [ ] Round 5, hit D5 twice → `score += 20` (5 × 2 × 2 hits)
- [ ] Round 5, hit D5 three times → `score += 30` (5 × 2 × 3 hits)
- [ ] Round 10, hit D10 once → `score += 20` (10 × 2 × 1 hit)
- [ ] Round 20, hit D20 twice → `score += 80` (20 × 2 × 2 hits)

### Score decrement — missing required double
- [ ] Round 1, no D1 hit → `score -= 2`
- [ ] Round 7, no D7 hit → `score -= 14`
- [ ] Round 20, no D20 hit → `score -= 40`
- [ ] Mixed turn (1 D5, 2 non-D5): 1 hit → score increments, not decrements

### Non-target doubles do not score
- [ ] Round 3, throw D5 (wrong double) → does not count as hit; if no D3 thrown, penalty applies
- [ ] Round 3, throw D3 (correct) + D5 (wrong) + D5 (wrong) → 1 hit, score increments by `3 × 2 × 1 = 6`

### Non-double hits on target number do not score
- [ ] Round 7, throw `'7'` (single 7) → does not count as hitting D7; counts as miss for this round
- [ ] Round 7, throw `'T7'` (triple 7) → does not count as hitting D7; counts as miss for this round

### Turn flow — round counter
- [ ] `practiceRound` starts at 1 after `GameState.initial()`
- [ ] After completing turn for round 1 (3rd dart), `practiceRound` advances to 2
- [ ] After completing turn for round 20 (3rd dart), game ends

### Early end — score drops to zero or below
- [ ] Game ends after a miss penalty that reduces score to exactly 0
- [ ] Game ends after a miss penalty that reduces score below 0
- [ ] `GameCompleted` is emitted with `winnerCompetitorId = null` on early end
- [ ] Score may go temporarily below zero before `GameCompleted`; the check is applied after the deduction

### Normal end — all 20 rounds complete
- [ ] After round 20 completes (regardless of hit/miss), `GameCompleted` emitted with `winnerCompetitorId = null`
- [ ] Drill complete without winner is a valid end state

### `isValid` rejections
- [ ] Rejects `DartThrown` when `state.isComplete == true`
- [ ] Rejects `DartThrown` when `dartsThrownInTurn >= 3`
- [ ] Rejects `TurnStarted` while turn is already active
- [ ] Accepts `DartThrown` in normal mid-turn state

---

## Files

- `test/features/game/domain/engines/bobs_27_engine_test.dart` — **to create**

---

## Implementation Notes

- Helper: `buildInitialState()` returns a `GameState` from `GameState.initial(bobs27Game, competitors)` with starting score=27, round=1.
- Helper: `applyTurn(state, [seg1, seg2, seg3])` applies `TurnStarted` + three `DartThrown` events + `TurnEnded` in sequence, returning final state.
- Use `expect(state.competitors.first.score, equals(expectedScore))` to verify score changes.
- Use `expect(state.isComplete, isTrue)` + `expect(state.winnerCompetitorId, isNull)` to verify drill completion.
- Spec references: `EPIC-007-practice-modes.md` §"Bob's 27".

---
