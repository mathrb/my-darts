# BUG-001: Undo raises exception when no darts have been thrown

**Status:** Todo
**Type:** Bug
**Severity:** High

---

## Description

The undo action in `ActiveGameNotifier` (and `ActiveCricketGameNotifier`) can be triggered when no darts have been thrown in the entire game, causing an exception to be raised inside `UndoLastDartUseCase`. The UI exposes the undo button without guarding against this empty-game state.

Additionally, when undo is triggered at the start of a turn (i.e. no darts have been thrown in the *current* turn but previous turns exist), the expected behaviour is to step back into the previous turn so the user can correct a previously entered dart. Currently this rollback to the previous turn does not work correctly.

---

## Expected Behaviour

1. **No darts thrown in the game at all:** Undo is a no-op — the button should be disabled (or the notifier silently ignores the call). No exception is raised.
2. **No darts thrown in the current turn (but previous turns exist):** Undo moves back to the last dart of the previous turn, allowing the user to edit it. The UI reflects the previous turn's state.

---

## Current Behaviour

- Calling undo when zero darts have been thrown in the game causes an unhandled exception (propagates from `UndoLastDartUseCase` through the notifier to the `AsyncValue` error state, crashing the board UI).
- Calling undo at the start of a new turn (after a turn has been committed) does not correctly restore the previous turn.

---

## Affected Files

- `lib/features/game/presentation/providers/active_game_provider.dart` — `ActiveGameNotifier.undo()`
- `lib/features/game/presentation/providers/active_cricket_game_provider.dart` — `ActiveCricketGameNotifier.undo()`
- `lib/features/game/presentation/pages/x01_board_page.dart` — undo button enabled/disabled state
- `lib/features/game/presentation/pages/cricket_board_page.dart` — undo button enabled/disabled state
- `lib/features/game/domain/usecases/undo_last_dart_use_case.dart` — may need a guard for the empty-game case

---

## Acceptance Criteria

- [ ] Calling `undo()` on a notifier when `dartThrowsInGame == 0` is a silent no-op; no exception is thrown or surfaced to the UI.
- [ ] The undo button is visually disabled when there are no darts to undo (i.e. `canUndo == false`).
- [ ] Calling `undo()` when `dartsInCurrentTurn == 0` but previous turns exist correctly restores the state of the last dart in the previous turn.
- [ ] After undoing into a previous turn the score, dart indicators, and current-player highlight all reflect the restored state.
- [ ] All existing tests still pass.
- [ ] New unit tests cover:
  - `undo()` is a no-op when no darts have been thrown
  - `undo()` at turn boundary correctly moves back to the previous turn

---

## Notes

- `UndoLastDartUseCase` replays events up to (but not including) the last `DartThrown` event. If there are no `DartThrown` events the replay base is ambiguous — the use case should return early/throw a typed exception that the notifier catches and ignores.
- "Previous turn" navigation requires that the notifier reloads the replayed `GameState` after the undo, which already happens via `_replayState()`. Verify this replay correctly reconstructs the previous turn's dart indicators.
