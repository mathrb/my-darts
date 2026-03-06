# BUG-002: UI flashes / reloads on every score input

**Status:** Todo
**Type:** Bug
**Severity:** Medium

---

## Description

Each time a score is entered on the game board (X01 or Cricket), the entire board widget visibly flashes — a brief blank or rebuild artifact is shown before the updated state is rendered. This is caused by the notifier transitioning through `AsyncValue.loading` between the previous data state and the new data state when `processDart()` or equivalent is called.

---

## Root Cause

`AsyncNotifier` subclasses (`ActiveGameNotifier`, `ActiveCricketGameNotifier`) use `state = AsyncValue.loading()` (implicitly, via `AsyncValue.guard()`) when an async method runs. Widgets that watch `activeGameProvider` / `activeCricketGameProvider` re-render for the loading state, producing the visible flash.

---

## Expected Behaviour

Dart input feels instant. The score, dart indicators, and player sidebar update atomically — no blank frame or loading spinner is shown between the previous and next scored state.

---

## Current Behaviour

A flash (white/blank frame) is visible for ~1 frame every time a dart is entered, making the input feel laggy and unpolished.

---

## Affected Files

- `lib/features/game/presentation/providers/active_game_provider.dart` — `ActiveGameNotifier`
- `lib/features/game/presentation/providers/active_cricket_game_provider.dart` — `ActiveCricketGameNotifier`
- `lib/features/game/presentation/pages/x01_board_page.dart` — consumer rebuild handling
- `lib/features/game/presentation/pages/cricket_board_page.dart` — consumer rebuild handling

---

## Acceptance Criteria

- [ ] Entering a score on the X01 board produces no visible flash or blank frame.
- [ ] Entering a score on the Cricket board produces no visible flash or blank frame.
- [ ] The board UI does not show a loading indicator during normal dart input.
- [ ] Turn transitions (end of turn, bust, leg win) are equally flash-free.
- [ ] All existing tests still pass.

---

## Recommended Fix

Use optimistic state updates: before the async persistence call completes, update state immediately with the new computed value from the engine, then confirm (or roll back) once the database write returns.

Concrete approach:
1. In `processDart()` / equivalent, compute the next `GameState` synchronously via the engine's `apply()` method.
2. Set `state = AsyncData(nextUiState)` **before** awaiting the use-case call.
3. If the use case throws, restore the previous state and surface the error.

This eliminates the loading frame entirely for the happy path.

---

## Notes

- The engine `apply()` is a pure synchronous function, so computing the optimistic next state is cheap and safe.
- Rolling back on error is acceptable because persistence failures are rare and always unexpected.
- Do not use `state = const AsyncValue.loading()` inside dart-input methods. Reserve loading states for initial `build()` and explicit long-running operations (game creation, navigation).
