# TICKET-037: StatelessCricketEngine Unit Tests

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Full unit test suite for `StatelessCricketEngine` (TICKET-036). Covers every transition table row and every resolved ambiguity from `docs/games/cricket.transitions.md`. Tests are grouped by table letter (B–M) to mirror the spec document structure, making it straightforward to verify coverage against the spec.

Depends on: TICKET-035 (`CompetitorState` cricket fields), TICKET-036 (`StatelessCricketEngine`).

---

## Acceptance Criteria

### File
- [ ] `test/features/game/domain/engines/stateless_cricket_engine_test.dart` exists
- [ ] All tests pass with `flutter test` — no skips, no `// TODO` placeholders

### Table B — Acceptance guards
- [ ] `isValid` returns `false` when `state.isComplete == true`
- [ ] `isValid` returns `false` when `dartsThrownInTurn >= 3` and event is `DartThrown`
- [ ] `isValid` returns `false` for `TurnStarted` when a turn is already active
- [ ] `isValid` returns `true` for `DartThrown` when 0, 1, or 2 darts thrown in turn

### Table C — Invalid numbers ignored
- [ ] Throwing any segment for numbers 1–14 (e.g. `'1'`, `'T14'`, `'D7'`) increments `dartsThrownInTurn` but leaves all marks and scores unchanged
- [ ] Throwing any segment for non-bull numbers 21–24 (e.g. `'21'`, `'D22'`) increments `dartsThrownInTurn` but leaves all marks and scores unchanged
- [ ] `'MISS'` increments `dartsThrownInTurn` but leaves all marks and scores unchanged

### Table D — Mark count per segment type
- [ ] Single segment (e.g. `'20'`) adds exactly 1 mark to the number
- [ ] Double segment (e.g. `'D20'`) adds exactly 2 marks to the number
- [ ] Triple segment (e.g. `'T20'`) adds exactly 3 marks (immediately closes the number)
- [ ] `'SB'` adds 1 mark to `'Bull'`
- [ ] `'DB'` adds 2 marks to `'Bull'`
- [ ] Marks are capped at 3; second `'T20'` on an already-closed 20 produces 3 overflow marks
- [ ] Throwing `'S20'` three separate times results in 3 marks (closed), not more

### Table E — Overflow scoring
- [ ] **Standard**: after closing a number, overflow marks score `numberValue × overflowMarks` for the current competitor when at least one opponent is open
- [ ] **Standard**: overflow marks do NOT score when all opponents have already closed the number
- [ ] **NoScore**: overflow marks produce zero score change for any competitor regardless of open/closed state
- [ ] **CutThroat**: overflow marks add `numberValue × overflowMarks` to each opponent who has NOT closed the number
- [ ] **CutThroat**: opponent who has already closed the number is NOT scored against
- [ ] **Bull overflow**: 1 overflow mark on `'Bull'` = 25 points (not 50), regardless of `SB` or `DB` origin

### Table F — closeOrder set on full closure
- [ ] `closeOrder` remains `null` while any cricket number is still open for the competitor
- [ ] `closeOrder` is set (non-null) the moment the last open number is closed
- [ ] `closeOrder` is not changed after being set (subsequent darts on already-closed competitor do not update it)
- [ ] `closeOrder` is reset to `null` on `LegCompleted`

### Table G — Win conditions per variant
- [ ] **Standard**: competitor who closes all 7 numbers AND has the highest (or tied-highest) score wins
- [ ] **Standard**: competitor who closes all 7 numbers but has a lower score than an opponent does NOT win yet
- [ ] **NoScore**: competitor who closes all 7 numbers wins immediately (score is always 0, so "highest" is trivially satisfied)
- [ ] **CutThroat**: competitor who closes all 7 numbers AND has the lowest (or tied-lowest) score wins
- [ ] **CutThroat**: competitor who closes all 7 numbers but has a higher score than an opponent does NOT win yet
- [ ] **Tie-break**: when two competitors close all numbers and have equal scores, the competitor with the lower `closeOrder` wins
- [ ] Win condition triggers `isComplete = true` and sets `winnerCompetitorId` on `GameState`

### Table H — Dart count and auto turn-end
- [ ] After 3 darts thrown in a turn, `dartsThrownInTurn` is 3 and a `TurnEnded` event causes rotation to next competitor
- [ ] `TurnStarted` resets `dartsThrownInTurn` to 0 for the new competitor
- [ ] Turn does not auto-end mid-turn on a win — the engine still marks the game complete but the `TurnEnded` event is still required to close the turn

### Table I — No bust
- [ ] No `DartThrown` event ever produces a state where `isBust == true`
- [ ] Throwing a segment that would generate large overflow (e.g. `'T20'` when all opponents closed 20) does not produce a bust even in Standard variant

### Table K — Leg completion
- [ ] `LegCompleted` event resets all `marksPerNumber` maps to `{}` for all competitors
- [ ] `LegCompleted` event resets all `closeOrder` values to `null` for all competitors
- [ ] `LegCompleted` event resets all `score` values to `0` for all competitors
- [ ] `LegCompleted` does not change `currentLegIndex` — that is driven by `TurnStarted` for the new leg

### Table L — Leg index advancement
- [ ] After a win and `LegCompleted`, the leg counter (`currentLegIndex`) increments correctly when the next leg's `TurnStarted` is processed
- [ ] `legsWon` for the winning competitor increments on `LegCompleted`

### Table M — Game complete, no further darts
- [ ] After `GameCompleted` event is applied, `state.isComplete == true`
- [ ] `isValid` returns `false` for any `DartThrown` after `GameCompleted`

### Edge cases
- [ ] Closing multiple numbers in one triple (e.g. hypothetical — triples only close one number; verify single-number-per-dart behaviour)
- [ ] All competitors close a number simultaneously is impossible (darts are sequential); verify the engine does not produce concurrent close states
- [ ] Competitor already closed all numbers, opponent throws overflow — verify only still-open competitors are scored against (CutThroat) or score is awarded (Standard)
- [ ] 2-player game: single opponent; verify Standard and CutThroat scoring with exactly one other competitor
- [ ] 3-player game: verify CutThroat overflow distributes to each open opponent individually

---

## Files

- `test/features/game/domain/engines/stateless_cricket_engine_test.dart` — **to create**

---

## Implementation Notes

- Set up a helper function `makeGameState({required CricketVariant variant, required List<CompetitorState> competitors, ...})` to reduce boilerplate across test cases.
- Use `GameState.initial(game, competitors)` where available, then apply a `GameCreated` event to get a clean starting state before each test.
- For multi-competitor tests, always use at least 2 competitors; use 3 for CutThroat overflow distribution tests.
- Do not use mocks for the engine itself — call `engine.apply(state, event)` directly.
- Spec references: `docs/games/cricket.transitions.md`, `CLAUDE.md` §"Critical Cricket rules", `CLAUDE.md` §"Testing Requirements".

---
