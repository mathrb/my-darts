# TICKET-035: Extend CompetitorState with Cricket Mark Fields

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

`CompetitorState` (in `lib/features/game/domain/models/game_state.dart`) currently holds only X01-relevant fields. Extend it with two new fields required by the cricket engine: a per-number mark map and a close-order index for tie-breaking. The X01 engine ignores these fields entirely; they are only read and written by `StatelessCricketEngine` (TICKET-036).

---

## Acceptance Criteria

- [ ] `CompetitorState` in `lib/features/game/domain/models/game_state.dart` gains two new fields:
  - `marksPerNumber: Map<String, int>` — marks (0–3) for each cricket number (`'15'`, `'16'`, `'17'`, `'18'`, `'19'`, `'20'`, `'Bull'`); defaults to `{}`
  - `closeOrder: int?` — round index when all seven numbers were closed (used for CutThroat tie-breaking when scores are equal); defaults to `null`
- [ ] Both fields are declared with `@Default` annotations so they do not break existing `CompetitorState` constructors in X01 code or tests
- [ ] `@Default({})` for `marksPerNumber`; no default annotation needed for nullable `closeOrder` (freezed treats nullable fields without a default as `null` by default)
- [ ] Code generation (`build_runner`) produces updated `.freezed.dart` without errors
- [ ] All existing X01 tests and contract tests continue to pass without modification

---

## Files

- `lib/features/game/domain/models/game_state.dart` — **to update**
- `lib/features/game/domain/models/game_state.freezed.dart` — regenerated

---

## Implementation Notes

- `marksPerNumber` keys are the canonical cricket number strings: `'15'`, `'16'`, `'17'`, `'18'`, `'19'`, `'20'`, and `'Bull'`. Do not use `'SB'`/`'DB'` as keys — the engine maps bull segments to the `'Bull'` key.
- `closeOrder` is set once (to `GameState.currentLegRound` or equivalent) the moment a competitor's last cricket number is closed. It is never reset or changed after that within a leg; it resets along with all other `CompetitorState` fields on leg completion.
- The `Map<String, int>` type in freezed requires `@JsonSerializable(explicitToJson: true)` or equivalent if JSON serialization is needed; for engine-only usage (no serialization to DB) this is not required. Do not add JSON serialization unless the schema already demands it.
- Spec references: `docs/games/cricket.transitions.md` §"CompetitorState Extensions", `docs/DATA.md` §"CompetitorState fields".

---
