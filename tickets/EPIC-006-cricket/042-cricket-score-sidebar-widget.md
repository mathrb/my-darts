# TICKET-042: CricketScoreSidebarWidget

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Build `CricketScoreSidebarWidget`, a pure `StatelessWidget` that displays per-player scores and marks-per-round (MPR) statistics for the cricket board. It replaces the X01-oriented `PlayerScoreSectionWidget` for the cricket game type. Like all presentation widgets, it receives all data through its constructor and has no provider access.

---

## Acceptance Criteria

### Widget declaration
- [ ] `lib/features/game/presentation/widgets/cricket_score_sidebar_widget.dart` exists
- [ ] Class is a `StatelessWidget` — no `ConsumerWidget`, no providers
- [ ] Constructor:
  ```dart
  const CricketScoreSidebarWidget({
    required GameState gameState,
    super.key,
  });
  ```

### Layout — per-player panel
- [ ] One panel rendered per competitor in `gameState.competitors`; panels stacked vertically
- [ ] **Active player** (index == `gameState.currentTurnIndex`): prominent styling — larger name text, highlighted background, or border accent
- [ ] **Other players**: condensed styling — smaller text, subdued background

### Panel content (per competitor)
- [ ] **Player name**: display name (or competitor label if name not available); truncated with ellipsis if too long
- [ ] **Score**: the competitor's `competitorState.score` value displayed as a number
  - Standard / NoScore variants: label as points scored (`"Pts"` or unlabelled)
  - CutThroat variant: label as points against (`"Pts vs"` or `"Against"`) and highlight **lowest** score (not highest) as the leading player
- [ ] **MPR (Marks Per Round)**: computed inline as `totalMarksThisLeg / roundsPlayed`
  - `totalMarksThisLeg` = sum of all values in `competitorState.marksPerNumber` (clamped to max 3 per number)
  - `roundsPlayed` = number of full turns completed by this competitor in the current leg (derive from `dartsThrownInTurn` and turn index)
  - Display `"0.0"` when `roundsPlayed == 0` (avoids division by zero)
  - Format to one decimal place (e.g. `"2.3"`)
- [ ] **Leading player indicator** (Standard / NoScore): the competitor with the highest score has a visual accent (e.g. star icon, colour tint, or bold score text)
- [ ] **Leading player indicator** (CutThroat): the competitor with the lowest score has the same visual accent

---

## Files

- `lib/features/game/presentation/widgets/cricket_score_sidebar_widget.dart` — **to create**

---

## Implementation Notes

- MPR approximation: since `GameState` may not store a per-player round counter directly, derive `roundsPlayed` from `gameState.competitors` turn ordering. A simple approximation: `(gameState.currentTurnIndex >= competitorIndex) ? currentLegRound : currentLegRound - 1` where `currentLegRound` is the number of complete turns since the leg started. Alternatively, track via `DartThrown` count if accessible on state.
- The `totalMarksThisLeg` computation: sum all values in `marksPerNumber` (each entry is already capped 0–3 by the engine), so `marksPerNumber.values.fold(0, (a, b) => a + b)` gives the total marks.
- CutThroat "leading" means the player with the fewest points against them — i.e. `min(score)`. The widget should highlight this competitor.
- The sidebar is intended to be placed alongside the `CricketGridWidget` (or above it on narrow screens). Do not enforce a specific layout direction — let the board page (`CricketBoardPage`, TICKET-043) decide orientation.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Cricket Board — Score Sidebar".

---
