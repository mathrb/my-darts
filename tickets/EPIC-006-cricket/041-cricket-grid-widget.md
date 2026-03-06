# TICKET-041: CricketGridWidget

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Build `CricketGridWidget`, the main interactive input surface for the cricket board. It is a pure `StatelessWidget` presenting a 3-column × 7-row grid (Single | Double | Triple columns; 20, 19, 18, 17, 16, 15, Bull rows). Tapping a cell emits the canonical segment string via callback. Each cell also shows the current player's `CricketMarkIndicatorWidget` for that number. This widget has no provider access; all state flows in through `gameState` and events flow out through `onSegmentTapped`.

Depends on: TICKET-040 (`CricketMarkIndicatorWidget`).

---

## Acceptance Criteria

### Widget declaration
- [ ] `lib/features/game/presentation/widgets/cricket_grid_widget.dart` exists
- [ ] Class is a `StatelessWidget` — no `ConsumerWidget`, no providers
- [ ] Constructor:
  ```dart
  const CricketGridWidget({
    required GameState gameState,
    required void Function(String segment) onSegmentTapped,
    super.key,
  });
  ```

### Grid layout
- [ ] **Rows** (top to bottom): 20, 19, 18, 17, 16, 15, Bull — exactly 7 rows, in this order
- [ ] **Columns** (left to right): Single, Double, Triple — exactly 3 columns with visible column header labels
- [ ] Column headers are labelled "S" / "D" / "T" (or "Single" / "Double" / "Triple" abbreviated as appropriate)
- [ ] Row labels (number) appear on the far left, outside the 3 tap columns, as read-only text

### Cell behaviour
- [ ] Tapping **Single column**, number N → emits `'N'` (e.g. `'20'`, `'15'`)
- [ ] Tapping **Double column**, number N → emits `'DN'` (e.g. `'D20'`, `'D15'`)
- [ ] Tapping **Triple column**, number N → emits `'TN'` (e.g. `'T20'`, `'T15'`)
- [ ] Tapping **Single column**, Bull row → emits `'SB'`
- [ ] Tapping **Double column**, Bull row → emits `'DB'`
- [ ] Tapping **Triple column**, Bull row → emits `'DB'` (no triple bull in darts; triple bull tap maps to double bull)
- [ ] Each cell contains a `CricketMarkIndicatorWidget` showing the **current player's** marks for that row number
- [ ] Current player is identified by `gameState.competitors[gameState.currentTurnIndex]`
- [ ] Mark count read from `currentCompetitor.marksPerNumber['<number>'] ?? 0`; for Bull row use key `'Bull'`

### Visual states
- [ ] **Closed row** (current player's marks == 3): entire row (all 3 cells) has a visually muted / greyed-out background colour to indicate the number is closed for the active player
- [ ] **Open opponent row** (at least one opponent has marks < 3): highlight the row with an accent border or subtle background to indicate opponents are still open and overflow scoring is possible
- [ ] **Game complete** (`gameState.isComplete == true`): all cells are non-interactive (`onPressed: null` or `InkWell.onTap: null`) and visually indicate disabled state
- [ ] **Game not complete**: all cells are tappable

---

## Files

- `lib/features/game/presentation/widgets/cricket_grid_widget.dart` — **to create**

---

## Implementation Notes

- Row order must be `['20', '19', '18', '17', '16', '15', 'Bull']` — this is the canonical cricket board order from top to bottom, matching physical scoreboards.
- Build the grid with a `Column` of rows; each row is a `Row` containing a row-label widget + 3 cell widgets.
- Cells should have equal widths; use `Expanded` inside the row for balanced layout.
- For the Bull row, the Triple cell tap emits `'DB'` (not `'TB'` which does not exist in darts). Consider labelling the triple-bull cell with a visual indicator that it maps to DB — e.g. a small `"= DB"` label or similar.
- The "open opponent row" highlight helps the player identify numbers where overflow scoring is possible (Standard) or where opponents could score against them (CutThroat). This is a visual aid, not a gameplay rule.
- Opponent mark status: iterate `gameState.competitors` (excluding `currentTurnIndex`) and check each one's `marksPerNumber[number] ?? 0 < 3`.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Cricket Board — Grid", `CLAUDE.md` §"Segment Format Convention".

---
