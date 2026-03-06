# TICKET-054: ActivePracticeState + ActivePracticeNotifier

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Define `ActivePracticeState` (a `@freezed` presentation-layer wrapper) and implement `ActivePracticeNotifier` (a family `AsyncNotifier` keyed by `gameId`). Mirrors `ActiveCricketGameNotifier` from EPIC-006 but adapted for practice modes: no bust, no leg pending ID (all practice modes have 1 leg), and selects the correct use-case provider based on `gameState.gameType`.

Depends on: TICKET-053 (use case + provider wiring for all five practice engines).

---

## Acceptance Criteria

### `ActivePracticeState` — `lib/features/game/presentation/state/active_practice_state.dart`
- [ ] File exists and is `@freezed`
- [ ] Single variant constructor:
  ```dart
  const factory ActivePracticeState({
    required GameState gameState,
    String? pendingGameWinnerId,
  }) = _ActivePracticeState;
  ```
- [ ] No `showBust` field — practice modes never bust
- [ ] No `pendingLegWinnerId` — all practice modes have exactly 1 leg
- [ ] No imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Code generation (`build_runner`) produces `.freezed.dart` without errors

### `ActivePracticeNotifier` — `lib/features/game/presentation/providers/active_practice_provider.dart`
- [ ] `@riverpod` annotation; Riverpod strips `Notifier` suffix → provider name is `activePracticeProvider`
- [ ] Family parameter: `build(String gameId)` — provider keyed per game
- [ ] Return type: `Future<ActivePracticeState?>` — returns `null` when `gameId` not found

### `build(String gameId)`
- [ ] Calls `gameRepositoryProvider.getGame(gameId)` — returns `null` → notifier state is `null`
- [ ] Calls `gameRepositoryProvider.getCompetitors(gameId)` to load competitors
- [ ] Calls `gameEventRepositoryProvider.getEventsForGame(gameId)` to load event log
- [ ] Selects the correct engine based on `game.gameType` (maps to correct engine provider)
- [ ] Reconstructs live `GameState` by replaying all events through `engine.apply()` starting from `GameState.initial(game, competitors)`
- [ ] Wraps result in `ActivePracticeState(gameState: gs)` with `pendingGameWinnerId = null`
- [ ] Uses `ref.read(...)` (not `ref.watch`) inside `build()` — one-time load

### `processDart(String segment)`
- [ ] Returns early if `state.value == null`
- [ ] Builds `DartThrow` from segment + current `GameState` context (UUID generated inside notifier)
- [ ] Sets `state = const AsyncValue.loading()` before async operation
- [ ] Selects correct `processPracticeDartUseCaseProvider` based on `gs.gameType`
- [ ] Uses `AsyncValue.guard()` wrapping use case `execute()`
- [ ] Sets `pendingGameWinnerId` to `newGs.winnerCompetitorId` when `newGs.isComplete`
- [ ] No bust detection — practice never busts

### `undoDart()`
- [ ] Returns early if `state.value == null`
- [ ] Sets `state = const AsyncValue.loading()` before async operation
- [ ] Selects correct `undoPracticeLastDartUseCaseProvider` based on `gs.gameType`
- [ ] Uses `AsyncValue.guard()` wrapping undo use case `execute()`
- [ ] Returns `ActivePracticeState(gameState: newGs)` with `pendingGameWinnerId = null`

### `dismissGameModal()`
- [ ] Clears `pendingGameWinnerId` to `null` via `state.whenData(...).copyWith(...)`, no async

### `endDrill()` — checkout practice only
- [ ] Returns early if `state.value == null` or `gs.gameType != GameType.checkoutPractice`
- [ ] Calls `endCheckoutPracticeUseCaseProvider` to emit `GameCompleted`
- [ ] Sets `pendingGameWinnerId = null` (no winner in checkout practice)
- [ ] Sets `state` to reflect `isComplete = true`

### Tests — `test/features/game/presentation/providers/active_practice_notifier_test.dart`
- [ ] File created with `@GenerateMocks` for `GameRepository`, `GameEventRepository`, `DartThrowRepository`
- [ ] Test: `build` returns `null` when `getGame` returns `null`
- [ ] Test: `build` replays events and returns correct `ActivePracticeState`
- [ ] Test: `processDart` updates `gameState` in returned state (ATC engine test)
- [ ] Test: `processDart` sets `pendingGameWinnerId` when game is complete
- [ ] Test: `undoDart` updates `gameState` and clears `pendingGameWinnerId`
- [ ] Test: `dismissGameModal` clears `pendingGameWinnerId`
- [ ] Test: selecting Bob's 27 engine when `gameType == GameType.bobs27`
- [ ] Test: selecting Shanghai engine when `gameType == GameType.shanghai`

---

## Files

- `lib/features/game/presentation/state/active_practice_state.dart` — **to create**
- `lib/features/game/presentation/state/active_practice_state.freezed.dart` — generated
- `lib/features/game/presentation/providers/active_practice_provider.dart` — **to create**
- `lib/features/game/presentation/providers/active_practice_provider.g.dart` — generated
- `test/features/game/presentation/providers/active_practice_notifier_test.dart` — **to create**
- `test/features/game/presentation/providers/active_practice_notifier_test.mocks.dart` — generated

---

## Implementation Notes

- Engine/use-case selection within `processDart` and `undoDart`: use a `switch` on `gs.gameType` to select the correct provider. Avoid dynamic dispatch through a map — the `switch` is explicit and exhaustive.
- The `DartThrow` fields to populate inside `processDart` are identical to `ActiveCricketGameNotifier`:
  - `dartId`: `const Uuid().v4()`
  - `gameId`: from `gs.gameId`
  - `competitorId`: current competitor's `competitorId`
  - `playerId`: first entry of `competitor.playerIds`
  - `turnNumber`: `gs.currentLegIndex`
  - `dartNumber`: `gs.dartsThrownInTurn + 1`
  - `segment`: the `segment` parameter
  - `score`: `Segment.parse(segment).scoreValue`
- `pendingGameWinnerId` may be `null` (for drill-complete games with no winner) even when `isComplete == true` — the board page must handle this case gracefully.
- Spec references: `docs/STATE_MANAGEMENT.md` §"AsyncNotifier Patterns", `docs/GAME-EVENT-SPECIFICATIONS.md`.

---
