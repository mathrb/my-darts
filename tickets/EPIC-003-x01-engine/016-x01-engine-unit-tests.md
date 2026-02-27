# TICKET-016: X01 Engine Unit Tests

**Status:** Todo
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Expand the X01 engine test file to achieve full coverage of every transition table row, every bust condition, every win condition, and all five explicitly-resolved ambiguities from `docs/games/x01.transitions.md`. The existing test file only covers the Table D basic case.

---

## Acceptance Criteria

- [ ] Test file at `test/features/game/domain/engines/stateless_x01_engine_test.dart` covers all items below
- [ ] **Table A** (straight-in): any segment opens scoring; first dart of any value starts the player's score countdown
- [ ] **Table B** (double-in / master-in): non-qualifying first dart is consumed but scores 0; qualifying first dart opens scoring
- [ ] **Table C** (straight-out): any segment can close a leg when score reaches zero
- [ ] **Table D** (double-out): only a double or `'DB'` may close a leg at score 0
- [ ] **Table E** (master-out): double or triple may close a leg at score 0; `'DB'` counts as double
- [ ] **Table F** (bust conditions): dart taking score below 0 is a bust; exact-zero miss without valid out segment is a bust
- [ ] **Table G** (bull handling): `'SB'` scores 25; `'DB'` scores 50; `'DB'` satisfies double requirement for in/out
- [ ] **Table H** (failed in-dart): dart consumed (dart index +1) but score unchanged; turn continues on third failed in-dart; turn ends normally after 3 darts including any failed ones
- [ ] **Tables I–L** (remaining transition rows per spec): all rows covered
- [ ] **Bust ends turn immediately**: no more darts accepted after a bust in the same turn
- [ ] **Score floor**: score cannot go below zero under any combination of darts
- [ ] **Single-leg win detection**: game completes when score reaches 0 with a valid out-strategy dart and `legsToWin == 1`
- [ ] **Multi-leg win detection**: leg resets and game continues until a competitor reaches `legsToWin`; game completes on the final leg checkout
- [ ] **Ambiguity 1**: failed in-dart increments the dart counter — confirmed by test
- [ ] **Ambiguity 2**: bust ends the turn immediately after the busting dart — confirmed by test
- [ ] **Ambiguity 3**: out validation occurs before the terminal dart count is considered — confirmed by test
- [ ] **Ambiguity 4**: `'DB'` counts as a double for both in-strategy and out-strategy — confirmed by test
- [ ] **Ambiguity 5**: `'MISS'` does not trigger C/D/E strategy miss penalties — confirmed by test
- [ ] All tests are pure unit tests with no database, no Flutter runtime, no mocks (engine is a pure function)

---

## Files

- `test/features/game/domain/engines/stateless_x01_engine_test.dart` — to expand (currently covers only Table D basic case)

---

## Implementation Notes

- Tests call `StatelessX01Engine.apply(state, event)` directly with hand-crafted `GameState` inputs. No notifiers, no repositories, no `ProviderContainer`.
- Each transition table row should have its own `test()` or be grouped under a `group()` matching the table letter.
- Bust tests must verify both that the bust flag is set in `EngineResult` AND that `GameState.currentScore` is reset to the pre-turn value.
- Ambiguity tests should include a comment referencing the specific ambiguity number from `docs/games/x01.transitions.md` so future readers can trace the coverage.
- Cover all six in-strategy × out-strategy combinations for completeness: straight×straight, straight×double, straight×master, double×double, double×master, master×master (and partial asymmetric cases if the spec covers them).
- `'MISS'` tests: verify dart index increments, score is unchanged, turn continues unless it is the third dart.
