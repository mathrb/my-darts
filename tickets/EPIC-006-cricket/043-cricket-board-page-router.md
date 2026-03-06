# TICKET-043: CricketBoardPage + Router Wiring

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Build `CricketBoardPage`, the top-level screen for all Cricket game variants. It is the only widget in EPIC-006 that accesses providers directly. Assemble the cricket-specific sub-widgets (TICKETS 040–042) together with reused EPIC-005 widgets (`DartIndicatorWidget`, `BustOverlayWidget`, `LegCompleteModalWidget`, `GameCompleteModalWidget`). Also wire the new `/cricket-board/:gameId` route in `app_router.dart` and update the game-start navigation so cricket games navigate here instead of the X01 board.

Depends on: TICKET-039 (`ActiveCricketGameNotifier`), TICKET-040–042 (cricket widgets), TICKET-031 (`DartIndicatorWidget`), TICKET-032 (overlay/modal widgets).

---

## Acceptance Criteria

### Widget declaration
- [ ] `lib/features/game/presentation/pages/cricket_board_page.dart` exists
- [ ] Class is a `ConsumerWidget`
- [ ] Constructor:
  ```dart
  const CricketBoardPage({required String gameId, super.key});
  ```

### AsyncValue state handling
- [ ] `loading` state → centered `CircularProgressIndicator`
- [ ] `error` state → centered error message text
- [ ] `data` with `null` → centered `"Game not found"` message
- [ ] `data` with non-null `ActiveCricketGameState` → full board layout

### Layout (top to bottom)
- [ ] `AppBar`: title `"Cricket"` (or variant name if desired: `"Standard"`, `"No Score"`, `"Cut Throat"`); actions include a menu icon (`Icons.more_vert`); subtitle or trailing text shows current leg / round counter
- [ ] `DartIndicatorWidget(dartsThrown: gameState.dartsThrownInTurn)` (reuse from TICKET-031)
- [ ] `CricketScoreSidebarWidget(gameState: gameState)` — displays player scores and MPR
- [ ] Expanded area: `CricketGridWidget(gameState: gameState, onSegmentTapped: notifier.processDart)` — fills remaining space; grid is the primary input surface
- [ ] Bottom bar: `Row` containing:
  - Left: `IconButton` with undo icon (`Icons.undo`) → calls `notifier.undoDart()`
  - Centre: `OutlinedButton` or `TextButton` labelled `"MISS"` → calls `notifier.processDart('MISS')` (convenience button for missed darts)
  - Right: `FilledButton` labelled `"NEXT ROUND"` → calls `notifier.dismissLegModal()` (acknowledgement button)
- [ ] All interactive elements disabled when `gameState.isComplete`

### Leg complete modal
- [ ] When `activeCricketGameState.pendingLegWinnerId != null`: show `LegCompleteModalWidget` via `showDialog`
- [ ] `winnerName` resolved from `gameState.competitors` by matching `competitorId == pendingLegWinnerId`
- [ ] `legNumber` is `gameState.currentLegIndex`
- [ ] `onNextLeg` calls `notifier.dismissLegModal()`
- [ ] Dialog shown in `WidgetsBinding.addPostFrameCallback` to avoid calling `showDialog` during `build`

### Game complete modal
- [ ] When `activeCricketGameState.pendingGameWinnerId != null`: show `GameCompleteModalWidget` via `showDialog`
- [ ] `winnerName` resolved from `gameState.competitors` by matching `competitorId == pendingGameWinnerId`
- [ ] `onNewGame` calls `context.go(GameRoutes.home)` (or equivalent home route constant)
- [ ] `onViewStats` calls `context.go('/stats')`
- [ ] Dialog shown in `WidgetsBinding.addPostFrameCallback`

### No bust overlay
- [ ] `BustOverlayWidget` is NOT used in `CricketBoardPage` — cricket has no bust; do not include it

### Router wiring
- [ ] `lib/app/app_router.dart` updated to add a named route `/cricket-board/:gameId`
- [ ] Route maps to `CricketBoardPage(gameId: gameId)` with `gameId` extracted from path parameters
- [ ] `GameSetupNotifier.startGame()` (or equivalent post-game-creation navigation) navigates to `/cricket-board/:gameId` when `gameType` is a cricket variant, and to `/x01-board/:gameId` when `gameType` is X01 — update whichever file performs the post-creation navigation

---

## Files

- `lib/features/game/presentation/pages/cricket_board_page.dart` — **to create**
- `lib/app/app_router.dart` — **to update**

---

## Implementation Notes

- Use `ref.watch(activeCricketGameNotifierProvider(gameId))` to get `AsyncValue<ActiveCricketGameState?>`.
- Resolve `notifier` via `ref.read(activeCricketGameNotifierProvider(gameId).notifier)` inside callbacks — do NOT use `ref.watch` for notifier access.
- `showDialog` calls inside `build` will cause Flutter errors; always defer with:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(context: context, builder: (_) => LegCompleteModalWidget(...));
  });
  ```
- The `isComplete` flag on `GameState` should disable the grid and bottom-bar buttons to prevent further input after the game ends.
- The `"NEXT ROUND"` button calls `dismissLegModal()` only. On a non-leg-complete turn, this is a no-op. The button effectively serves as a "acknowledge leg win" action.
- The `"MISS"` bottom-bar shortcut reduces tapping — players often throw misses. It is an addition not present on the X01 board; do not add it there.
- Navigation routing: the decision of which board page to navigate to after game creation can live in `GameSetupNotifier.startGame()` (return a discriminated result), a router guard, or a post-creation hook — whichever is already established in the codebase. Inspect `GameSetupNotifier` before deciding.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Cricket Board Page", `docs/STATE_MANAGEMENT.md` §"Widget Patterns".

---
