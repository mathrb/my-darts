# TICKET-039: ActiveCricketGameState + ActiveCricketGameNotifier

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Define `ActiveCricketGameState` (a `@freezed` presentation-layer wrapper) and implement `ActiveCricketGameNotifier` (a family `AsyncNotifier` keyed by `gameId`). Mirrors `ActiveGameState` / `ActiveGameNotifier` from EPIC-005 but adapted for cricket: no bust overlay (cricket has no bust), and uses cricket-specific use-case providers for dart processing and undo.

Depends on: TICKET-035 (`CompetitorState` cricket fields), TICKET-036 (`StatelessCricketEngine`), TICKET-038 (provider wiring).

---

## Acceptance Criteria

### ActiveCricketGameState
- [ ] `lib/features/game/presentation/state/active_cricket_game_state.dart` exists and is `@freezed`
- [ ] Single variant constructor:
  ```dart
  const factory ActiveCricketGameState({
    required GameState gameState,
    String? pendingLegWinnerId,
    String? pendingGameWinnerId,
  }) = _ActiveCricketGameState;
  ```
- [ ] No `showBust` field — cricket has no bust
- [ ] `GameState` imported from `lib/features/game/domain/models/game_state.dart`
- [ ] No imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Code generation (`build_runner`) produces `.freezed.dart` without errors

### ActiveCricketGameNotifier — provider shape
- [ ] `lib/features/game/presentation/providers/active_cricket_game_provider.dart` exists
- [ ] `@riverpod` annotation on `ActiveCricketGameNotifier` (Riverpod strips `Notifier` suffix → provider name is `activeCricketGameNotifierProvider`)
- [ ] Family parameter: `build(String gameId)` — provider keyed per game
- [ ] Return type: `Future<ActiveCricketGameState?>` — returns `null` when `gameId` not found

### `build(String gameId)`
- [ ] Calls `gameRepositoryProvider.getGame(gameId)` — returns `null` → notifier state is `null`
- [ ] Calls `gameRepositoryProvider.getCompetitors(gameId)` to load competitors
- [ ] Calls `gameEventRepositoryProvider.getEventsForGame(gameId)` to load event log
- [ ] Reconstructs live `GameState` by replaying all events through `cricketEngineProvider.apply()` starting from `GameState.initial(game, competitors)`
- [ ] Wraps result in `ActiveCricketGameState(gameState: gs)` (both pending IDs `null`)
- [ ] Uses `ref.read(...)` (not `ref.watch`) inside `build()` for all repository/provider accesses — one-time load

### `processDart(String segment)`
- [ ] Returns early if `state.value == null`
- [ ] Builds `DartThrow` internally from segment + current `GameState` context (UUID generated inside notifier)
- [ ] Sets `state = const AsyncValue.loading()` before the async operation
- [ ] Uses `AsyncValue.guard()` wrapping `processCricketDartUseCaseProvider.execute()`
- [ ] **Leg detection**: sets `pendingLegWinnerId` to the current competitor's `competitorId` when `newGs.currentLegIndex > oldLegIndex && !newGs.isComplete`
- [ ] **Game detection**: sets `pendingGameWinnerId` to `newGs.winnerCompetitorId` when `newGs.isComplete`
- [ ] No bust detection — cricket never busts

### `undoDart()`
- [ ] Returns early if `state.value == null`
- [ ] Sets `state = const AsyncValue.loading()` before the async operation
- [ ] Uses `AsyncValue.guard()` wrapping `undoCricketLastDartUseCaseProvider.execute(current.gameState)`
- [ ] Returns `ActiveCricketGameState(gameState: newGs)` with both pending IDs cleared to `null`

### Dismiss methods
- [ ] `void dismissLegModal()` — clears `pendingLegWinnerId` to `null` via `state.whenData(...).copyWith(...)`, no async
- [ ] `void dismissGameModal()` — clears `pendingGameWinnerId` to `null` via `state.whenData(...).copyWith(...)`, no async
- [ ] No `dismissBust()` method — not applicable to cricket

### Tests — `test/features/game/presentation/providers/active_cricket_game_notifier_test.dart`
- [ ] File created with `@GenerateMocks` for `GameRepository`, `GameEventRepository`, `DartThrowRepository`
- [ ] Test: `build` returns `null` when `getGame` returns `null`
- [ ] Test: `build` replays events and returns correct `ActiveCricketGameState`
- [ ] Test: `processDart` updates `gameState` in returned state
- [ ] Test: `processDart` sets `pendingLegWinnerId` when a leg completes
- [ ] Test: `processDart` sets `pendingGameWinnerId` when game is complete
- [ ] Test: `undoDart` updates `gameState` and clears both pending IDs
- [ ] Test: `dismissLegModal` clears `pendingLegWinnerId` without affecting `pendingGameWinnerId`
- [ ] Test: `dismissGameModal` clears `pendingGameWinnerId` without affecting `pendingLegWinnerId`

---

## Files

- `lib/features/game/presentation/state/active_cricket_game_state.dart` — **to create**
- `lib/features/game/presentation/state/active_cricket_game_state.freezed.dart` — generated
- `lib/features/game/presentation/providers/active_cricket_game_provider.dart` — **to create**
- `lib/features/game/presentation/providers/active_cricket_game_provider.g.dart` — generated
- `test/features/game/presentation/providers/active_cricket_game_notifier_test.dart` — **to create**
- `test/features/game/presentation/providers/active_cricket_game_notifier_test.mocks.dart` — generated

---

## Implementation Notes

- The `DartThrow` fields to populate inside `processDart` are identical to `ActiveGameNotifier`:
  - `dartId`: `const Uuid().v4()`
  - `gameId`: from `gs.gameId`
  - `competitorId`: current competitor's `competitorId`
  - `playerId`: first entry of `competitor.playerIds`
  - `turnNumber`: `gs.currentLegIndex`
  - `dartNumber`: `gs.dartsThrownInTurn + 1`
  - `segment`: the `segment` parameter
  - `score`: `Segment.parse(segment).scoreValue`
- Leg detection compares `newGs.currentLegIndex > oldLegIndex` — same logic as X01 notifier.
- `pendingLegWinnerId` and `pendingGameWinnerId` are competitor IDs (UUIDs); the board page resolves display names from `gameState.competitors`.
- Spec references: `docs/STATE_MANAGEMENT.md` §"AsyncNotifier Patterns", `docs/GAME-EVENT-SPECIFICATIONS.md`, `docs/games/cricket.transitions.md`.

---
