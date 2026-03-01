# TICKET-033: X01BoardPage

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

Build the main X01 game board page. It receives a `gameId` from the route, watches `activeGameNotifierProvider(gameId)`, assembles all sub-widgets (TICKETS 029–032), and handles all user callbacks and overlay coordination. This is the only widget in EPIC-005 that accesses providers.

Depends on: TICKET-026 (`ActiveGameState`), TICKET-028 (`ActiveGameNotifier`), TICKET-029 (`DartInputGridWidget`), TICKET-030 (`PlayerScoreSectionWidget`), TICKET-031 (`DartIndicatorWidget`), TICKET-032 (overlay widgets).

---

## Acceptance Criteria

### Widget declaration
- [ ] `lib/features/game/presentation/pages/x01_board_page.dart` exists
- [ ] Class is a `ConsumerWidget`
- [ ] Constructor:
  ```dart
  const X01BoardPage({required String gameId, super.key});
  ```

### AsyncValue state handling
- [ ] `loading` state → centered `CircularProgressIndicator`
- [ ] `error` state → centered error message text
- [ ] `data` with `null` → centered `"Game not found"` message
- [ ] `data` with non-null `ActiveGameState` → full board layout

### Layout (top to bottom)
- [ ] `AppBar`: title shows game type label (e.g. `"501"`); actions include a menu icon (`Icons.more_vert`) and info icon (`Icons.info_outline`); subtitle or trailing text shows current leg/round counter
- [ ] `DartIndicatorWidget(dartsThrown: gameState.dartsThrownInTurn)`
- [ ] `PlayerScoreSectionWidget(gameState: gameState.gameState)`
- [ ] Expanded area: `DartInputGridWidget(onSegmentTapped: notifier.processDart, enabled: !activeGameState.gameState.isComplete)`
- [ ] Bottom bar: `Row` containing:
  - Left: `IconButton` with undo icon (`Icons.undo`) → calls `notifier.undoDart()`
  - Right: `FilledButton` labelled `"NEXT ROUND"` → calls `notifier.dismissBust()` then `notifier.dismissLegModal()` (acts as acknowledgement; always enabled)

### Bust overlay
- [ ] When `activeGameState.showBust == true`: `Stack` the `BustOverlayWidget` on top of all content
- [ ] `BustOverlayWidget.onDismiss` calls `notifier.dismissBust()`

### Leg complete modal
- [ ] When `activeGameState.pendingLegWinnerId != null`: show `LegCompleteModalWidget` via `showDialog`
- [ ] `winnerName` resolved from `gameState.competitors` by matching `competitorId == pendingLegWinnerId`
- [ ] `legNumber` is `gameState.gameState.currentLegIndex`
- [ ] `onNextLeg` calls `notifier.dismissLegModal()`
- [ ] Dialog shown in `WidgetsBinding.addPostFrameCallback` to avoid calling `showDialog` during `build`

### Game complete modal
- [ ] When `activeGameState.pendingGameWinnerId != null`: show `GameCompleteModalWidget` via `showDialog`
- [ ] `winnerName` resolved from `gameState.competitors` by matching `competitorId == pendingGameWinnerId`
- [ ] `onNewGame` calls `context.go(GameRoutes.home)` (or equivalent home route constant)
- [ ] `onViewStats` calls `context.go('/stats')`
- [ ] Dialog shown in `WidgetsBinding.addPostFrameCallback`

---

## Files

- `lib/features/game/presentation/pages/x01_board_page.dart` — **to create**

---

## Implementation Notes

- Use `ref.watch(activeGameNotifierProvider(gameId))` to get the `AsyncValue<ActiveGameState?>`.
- Resolve `notifier` via `ref.read(activeGameNotifierProvider(gameId).notifier)` inside callbacks — do NOT use `ref.watch` for notifier access.
- `showDialog` calls inside `build` will cause Flutter errors; always defer them with:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(context: context, builder: (_) => LegCompleteModalWidget(...));
  });
  ```
- The `isComplete` flag on `GameState` disables the input grid but does not close the page — the game complete modal handles navigation.
- `GameRoutes.home` constant should already exist from EPIC-004 router setup; import it or use the equivalent string literal if not.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"X01 Board Page", `docs/STATE_MANAGEMENT.md` §"Widget Patterns".

---
