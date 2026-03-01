# TICKET-030: PlayerScoreSectionWidget

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

Build the score header section displayed above the dart input grid. The active player's score is shown prominently with a computed PPR (points per round) metric. Inactive players are shown in a condensed row below. This widget is a pure `StatelessWidget` — all data is passed in via `GameState`.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/widgets/player_score_section_widget.dart` exists
- [ ] Class is a `StatelessWidget` — no `ConsumerWidget`, no providers
- [ ] Constructor:
  ```dart
  const PlayerScoreSectionWidget({
    required GameState gameState,
    super.key,
  });
  ```
- [ ] **Active player** (index `gameState.currentTurnIndex`):
  - Displayed with a visually distinct background or border
  - Large, bold score text showing remaining score (`competitorState.score`)
  - Player name displayed
  - PPR metric displayed below score: `(totalScoreReduction / dartsThrown) * 3`; shows `"0.0"` when `dartsThrown == 0`
- [ ] **Inactive players**: each shown with name + remaining score in smaller, subdued font; arranged below the active player section
- [ ] Handles 1 through 4 competitors without overflow or layout errors
- [ ] Pure `StatelessWidget` — no providers, no async

---

## Files

- `lib/features/game/presentation/widgets/player_score_section_widget.dart` — **to create**

---

## Implementation Notes

- `GameState` is imported from `lib/features/game/domain/models/game_state.dart`.
- `CompetitorState` fields used:
  - `score` — remaining score to display
  - `dartsThrown` — denominator for PPR; guard against zero
  - `totalScoreReduction` — numerator for PPR (total points scored, excluding busts)
  - `name` or equivalent display name field — confirm field name against `CompetitorState` definition
- PPR formula: `(totalScoreReduction / dartsThrown) * 3` — multiply by 3 to express as points per 3-dart round. Format to one decimal place (`toStringAsFixed(1)`).
- Active player should be visually prominent: larger score font (e.g. `TextStyle(fontSize: 48, fontWeight: FontWeight.bold)`), contrasting background chip or card.
- Inactive players can be rendered in a horizontal `Row` or vertical `Column` of compact tiles below the active player section.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"X01 Board — Score Section", `docs/statistics/x01.projections.md` §"PPR".

---
