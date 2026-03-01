# TICKET-026: ActiveGameState Freezed Class

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

Define `ActiveGameState`, a thin presentation-layer wrapper around `GameState` that adds UI-only overlay flags. It holds no business logic — the engine's `GameState` is embedded verbatim, and three boolean/nullable fields signal transient display states (bust animation, leg complete modal, game complete modal). All EPIC-005 tickets that touch the notifier or board page depend on this state class existing first.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/state/active_game_state.dart` exists and is `@freezed`
- [ ] Single variant constructor:
  ```dart
  const factory ActiveGameState({
    required GameState gameState,
    @Default(false) bool showBust,
    String? pendingLegWinnerId,
    String? pendingGameWinnerId,
  }) = _ActiveGameState;
  ```
- [ ] `GameState` is imported from `lib/features/game/domain/models/game_state.dart`
- [ ] All three overlay fields default to off: `showBust` defaults `false`, `pendingLegWinnerId` and `pendingGameWinnerId` default `null`
- [ ] No imports of `package:flutter`, `package:sqflite`, `package:drift`, or `package:dio` — pure Dart
- [ ] Code generation (`build_runner`) produces `.freezed.dart` without errors

---

## Files

- `lib/features/game/presentation/state/active_game_state.dart` — **to create**
- `lib/features/game/presentation/state/active_game_state.freezed.dart` — generated

---

## Implementation Notes

- This is a single-variant freezed class (not a union). The overlay flags are fields on the one and only variant, not separate variants.
- `pendingLegWinnerId` and `pendingGameWinnerId` are competitor IDs (UUIDs) — the board page resolves display names from `gameState.competitors` when rendering modals.
- Do not add `isLoading`, `error`, or any async state here — `ActiveGameNotifier` wraps this in `AsyncValue<ActiveGameState?>` itself.
- Spec references: `docs/STATE_MANAGEMENT.md` §"State Classes", `docs/ARCHITECTURE_COMPLETE.md` §"Presentation Layer".

---
