# TICKET-032: Overlay and Modal Widgets

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

Build three standalone display widgets used by `X01BoardPage` (TICKET-033) to surface transient game events: a bust overlay, a leg-complete modal, and a game-complete modal. All three are self-contained with no provider access — callbacks wire them to the notifier from the parent page.

---

## Acceptance Criteria

### `BustOverlayWidget`
- [ ] `lib/features/game/presentation/widgets/bust_overlay_widget.dart` exists
- [ ] Class is a `StatefulWidget`
- [ ] Constructor:
  ```dart
  BustOverlayWidget({required VoidCallback onDismiss, super.key});
  ```
- [ ] Renders a full-screen semi-transparent overlay (e.g. `Colors.red.withOpacity(0.6)`) with prominent `"BUST"` text centered
- [ ] Auto-dismisses after ~1 500 ms by calling `onDismiss` via `Future.delayed` in `initState`
- [ ] Cancels the timer on `dispose` to prevent calling `onDismiss` after the widget is removed
- [ ] No provider access

### `LegCompleteModalWidget`
- [ ] `lib/features/game/presentation/widgets/leg_complete_modal_widget.dart` exists
- [ ] Class is a `StatelessWidget`
- [ ] Constructor:
  ```dart
  const LegCompleteModalWidget({
    required String winnerName,
    required int legNumber,
    required VoidCallback onNextLeg,
    super.key,
  });
  ```
- [ ] Renders as a dialog-style card (used inside `showDialog`)
- [ ] Displays: `"Leg [legNumber] won by [winnerName]"` heading
- [ ] Displays a `"Next Leg"` button that calls `onNextLeg` and closes the dialog (`Navigator.of(context).pop()`)
- [ ] No provider access

### `GameCompleteModalWidget`
- [ ] `lib/features/game/presentation/widgets/game_complete_modal_widget.dart` exists
- [ ] Class is a `StatelessWidget`
- [ ] Constructor:
  ```dart
  const GameCompleteModalWidget({
    required String winnerName,
    required VoidCallback onNewGame,
    required VoidCallback onViewStats,
    super.key,
  });
  ```
- [ ] Renders as a dialog-style card (used inside `showDialog`)
- [ ] Displays: `"[winnerName] wins!"` heading
- [ ] Displays a `"New Game"` button that calls `onNewGame`
- [ ] Displays a `"View Stats"` button that calls `onViewStats`
- [ ] Both buttons also close the dialog (`Navigator.of(context).pop()`) before invoking their callbacks
- [ ] No provider access

---

## Files

- `lib/features/game/presentation/widgets/bust_overlay_widget.dart` — **to create**
- `lib/features/game/presentation/widgets/leg_complete_modal_widget.dart` — **to create**
- `lib/features/game/presentation/widgets/game_complete_modal_widget.dart` — **to create**

---

## Implementation Notes

- `BustOverlayWidget` must store the `Timer` in state and cancel in `dispose`:
  ```dart
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), widget.onDismiss);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  ```
  Import `dart:async` for `Timer`.
- `LegCompleteModalWidget` and `GameCompleteModalWidget` are shown via `showDialog(context: context, builder: (_) => ...)` in `X01BoardPage` — they do not call `showDialog` themselves. Return an `AlertDialog` or a custom `Dialog` widget.
- `X01BoardPage` will call `showDialog` inside `WidgetsBinding.addPostFrameCallback` to avoid calling it during `build`.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"X01 Board — Overlays and Modals".

---
