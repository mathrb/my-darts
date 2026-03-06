# TICKET-050: ShanghaiEngine Tests

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Write comprehensive unit tests for `StatelessShanghaiEngine`, covering scoring rules, Shanghai win condition, non-target scoring, round advancement, and end conditions. Tests must be fully deterministic and run without a database or Flutter runtime.

Depends on: TICKET-049 (`StatelessShanghaiEngine` implementation).

---

## Acceptance Criteria

### Test file
- [ ] `test/features/game/domain/engines/shanghai_engine_test.dart` exists
- [ ] All tests pass with `flutter test`
- [ ] No database or Flutter widget dependencies

### Non-target hits score 0
- [ ] Round 3, throw `'5'` → no score added
- [ ] Round 3, throw `'MISS'` → no score added
- [ ] Round 3, throw `'SB'` → no score added
- [ ] Round 3, throw `'DB'` → no score added

### Target hits score correctly
- [ ] Round 3, throw `'3'` (single) → `score += 3`
- [ ] Round 3, throw `'D3'` (double) → `score += 6`
- [ ] Round 3, throw `'T3'` (triple) → `score += 9`
- [ ] Round 7, throw `'7'` + `'D7'` + `'T7'` → `score += 7 + 14 + 21 = 42` (also Shanghai)

### Shanghai win condition
- [ ] Round 3, throw `'3'` + `'D3'` + `'T3'` in any order → `GameCompleted` with `winnerCompetitorId = competitorId`
- [ ] Round 3, throw `'T3'` + `'D3'` + `'3'` (different order) → also Shanghai
- [ ] Round 3, throw `'3'` + `'D3'` + `'3'` (missing triple) → NOT Shanghai; game continues

### Not Shanghai — 1 or 2 multiplier types
- [ ] Only single + double hit → no Shanghai
- [ ] Only triple hit → no Shanghai
- [ ] Only single hit → no Shanghai
- [ ] All three hit from different rounds (e.g., `'T3'` from round 3 and `'3'` and `'D3'` from other rounds) — not applicable since scoring is per-dart within a turn; this tests that prior-round darts don't carry over

### Turn advancement — round counter
- [ ] `practiceRound` starts at 1
- [ ] After completing round 1 turn (3 darts, no Shanghai), `practiceRound` = 2
- [ ] After completing round 7 turn (last round, default config), `GameCompleted` emitted

### Final round completion — no Shanghai
- [ ] After all 7 rounds complete with no Shanghai, `GameCompleted` emitted
- [ ] Single-player: `winnerCompetitorId = null`

### Shanghai on final round
- [ ] Shanghai on round 7 (final): `GameCompleted` emitted with winner set

### `isValid` rejections
- [ ] Rejects `DartThrown` when `state.isComplete == true`
- [ ] Rejects `DartThrown` when `dartsThrownInTurn >= 3`
- [ ] Rejects `TurnStarted` while turn already active

---

## Files

- `test/features/game/domain/engines/shanghai_engine_test.dart` — **to create**

---

## Implementation Notes

- Helper: `buildInitialState({int totalRounds = 7})` returns a `GameState` from `GameState.initial(shanghaiGame, competitors)` with `practiceRound=1`.
- Helper: `applyTurn(state, [seg1, seg2, seg3])` applies `TurnStarted` + three `DartThrown` + `TurnEnded`, returning final state.
- For the Shanghai order-independence test, run the same turn with `[S, D, T]`, `[T, D, S]`, `[D, S, T]` and verify all produce `isComplete=true`.
- Spec references: `EPIC-007-practice-modes.md` §"Shanghai".

---
