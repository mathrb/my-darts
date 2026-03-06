# TICKET-057: PracticeBoardPage + Router Wiring

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `PracticeBoardPage` — the shared full-screen board page used by all five practice modes. Wire it into the router with a `/practice-board/:gameId` route. Update `GameSetupNotifier.startGame()` (or the equivalent navigation logic) to route to this page for all practice game types.

Depends on: TICKET-054 (`ActivePracticeNotifier`), TICKET-055 (input widgets), TICKET-056 (dartboard widget).

---

## Acceptance Criteria

### `PracticeBoardPage` — `lib/features/game/presentation/pages/practice_board_page.dart`
- [ ] File exists; class named `PracticeBoardPage` extends `ConsumerWidget`
- [ ] Constructor: `const PracticeBoardPage({required String gameId, super.key})`
- [ ] Watches `activePracticeProvider(gameId)` for state

### AsyncValue handling
- [ ] Loading state: shows `CircularProgressIndicator` centred on screen
- [ ] Error state: shows error message with retry option
- [ ] Null state (game not found): shows `'Game not found'` message with back navigation
- [ ] Data state: renders the full practice board UI

### AppBar (data state)
- [ ] Displays mode name (e.g., `'Around the Clock'`, `'Bob\'s 27'`, `'Shanghai'`, `'Catch 40'`, `'Checkout Practice'`) derived from `gameState.gameType`
- [ ] Displays progress indicator in the title or subtitle: e.g., `'Number: 7 / 20'` for ATC, `'Round: 3 / 8'` for Catch40
- [ ] Back button navigates to home screen

### Body layout (data state, top to bottom)
- [ ] `DartboardHighlightWidget` — receives `currentTarget` from current competitor's `CompetitorState.currentTarget`; `doublesOnly = (gameType == GameType.aroundTheClock && variant == 'doublesOnly') || gameType == GameType.bobs27`
- [ ] `PracticeTargetDisplayWidget` — receives all required fields from `gameState` and current competitor state
- [ ] `PracticeInputButtonsWidget` — receives `currentTarget`, `gameType`, `onDartThrown: (seg) => notifier.processDart(seg)`, `enabled: !gameState.isComplete && dartsThrownInTurn < 3`

### Bottom action bar
- [ ] UNDO button: calls `notifier.undoDart()`; disabled when no darts thrown in current turn or game complete
- [ ] MISS button: calls `notifier.processDart('MISS')`; disabled when turn complete or game complete (same as input buttons enabled state)
- [ ] NEXT ROUND button: shown and active when `dartsThrownInTurn == 3` and `!gameState.isComplete`; triggers `TurnEnded` → next turn via a `notifier.startNextTurn()` method or by calling the use case directly
- [ ] END DRILL button (checkout practice only): shown instead of NEXT ROUND; calls `notifier.endDrill()`

### Game complete modal
- [ ] Displayed via `WidgetsBinding.addPostFrameCallback` when `state.pendingGameWinnerId != null` OR `gameState.isComplete && pendingGameWinnerId == null` (for drill complete with no winner)
- [ ] Winner modal (when `pendingGameWinnerId != null`): shows winner name, a `NEW DRILL` button
- [ ] Drill complete modal (when no winner): shows drill summary (total score or checkout rate), a `NEW DRILL` button
- [ ] `NEW DRILL` / back: calls `context.go('/')` (home screen); `notifier.dismissGameModal()` to clear pending state
- [ ] Modal is not dismissible by tapping outside

### Router wiring — `lib/app/app_router.dart`
- [ ] Named route added: `/practice-board/:gameId`
- [ ] Route instantiates `PracticeBoardPage(gameId: gameId)` where `gameId` is extracted from the path parameter
- [ ] Route name constant: `'practiceBoardRoute'` (or follow existing naming convention)

### `GameSetupNotifier` navigation update
- [ ] After a successful `startGame()` call where the resulting `Game.gameType` is any practice type (`aroundTheClock`, `bobs27`, `shanghai`, `catch40`, `checkoutPractice`): navigate to `/practice-board/{gameId}` instead of the X01/cricket board
- [ ] Existing navigation for X01 and Cricket game types is unchanged

---

## Files

- `lib/features/game/presentation/pages/practice_board_page.dart` — **to create**
- `lib/app/app_router.dart` — **to update**
- `lib/features/game/presentation/providers/game_setup_provider.dart` — **to update** (navigation routing)

---

## Implementation Notes

- Follow the same `WidgetsBinding.addPostFrameCallback` modal pattern used in `CricketBoardPage` and `GameBoardPage` (EPIC-005/006).
- "Current competitor" is `gameState.competitors[gameState.currentTurnIndex]`. All display fields come from this competitor's `CompetitorState`.
- The `aroundTheClockVariant` for `doublesOnly` detection: read from `gameState.aroundTheClockVariant == 'doublesOnly'`.
- NEXT ROUND button logic: practice turns always have exactly 3 darts (no early turn end except ATC win-on-dart). When `dartsThrownInTurn == 3`, the current turn is complete and the NEXT ROUND button should call `TurnEnded` via a notifier method or directly advance to next turn start.
- The `startNextTurn()` method on `ActivePracticeNotifier` should emit `TurnEnded` + `TurnStarted` events and update state accordingly.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Practice Board", `EPIC-007-practice-modes.md` §"Shared Practice Board UI".

---
