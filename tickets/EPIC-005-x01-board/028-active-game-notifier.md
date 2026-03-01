# TICKET-028: Rebuild ActiveGameNotifier

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

The existing `ActiveGameNotifier` stub in `lib/features/game/presentation/providers/active_game_provider.dart` is a placeholder that does not match the required API. Fully rewrite it as a family-parameterized `AsyncNotifier` that loads game state by `gameId`, processes dart throws, supports undo, and manages the three UI overlay flags defined in `ActiveGameState` (TICKET-026).

Depends on: TICKET-026 (`ActiveGameState`), TICKET-027 (`undoLastDartUseCaseProvider`).

---

## Acceptance Criteria

### Provider shape
- [ ] `@riverpod` annotation on `ActiveGameNotifier` (Riverpod strips `Notifier` suffix → provider name is `activeGameNotifierProvider`)
- [ ] Family parameter: `build(String gameId)` — provider keyed per game
- [ ] Return type: `Future<ActiveGameState?>`  — returns `null` when `gameId` not found in repository

### `build(String gameId)`
- [ ] Calls `gameRepositoryProvider.getGame(gameId)` — returns `null` → notifier state is `null`
- [ ] Calls `gameRepositoryProvider.getCompetitors(gameId)` to load competitors
- [ ] Calls `gameEventRepositoryProvider.getEventsForGame(gameId)` to load event log
- [ ] Reconstructs live `GameState` by replaying all events through `x01EngineProvider.apply()` starting from `GameState.initial(game, competitors)`
- [ ] Wraps result in `ActiveGameState(gameState: gs)` (overlays all default off)

### `processDart(String segment)`
- [ ] Returns early if `state.value == null`
- [ ] Builds `DartThrow` internally from segment + current `GameState` context (UUID generated inside notifier, not passed in from widget)
- [ ] Sets `state = const AsyncValue.loading()` before the async operation
- [ ] Uses `AsyncValue.guard()` for the `processDartUseCaseProvider.execute()` call
- [ ] **Bust detection**: `showBust = true` when the turn advances (current competitor index changes) AND the active competitor's score is unchanged after the dart — i.e. the engine performed a bust rollback
- [ ] **Leg detection**: `pendingLegWinnerId` set to current competitor's `competitorId` when `newGs.currentLegIndex > oldLegIndex` AND `!newGs.isComplete`
- [ ] **Game detection**: `pendingGameWinnerId` set to `newGs.winnerCompetitorId` when `newGs.isComplete`

### `undoDart()`
- [ ] Returns early if `state.value == null`
- [ ] Sets `state = const AsyncValue.loading()` before the async operation
- [ ] Uses `AsyncValue.guard()` wrapping `undoLastDartUseCaseProvider.execute(current.gameState)`
- [ ] Returns `ActiveGameState(gameState: newGs)` with all overlays reset to defaults

### Dismiss methods
- [ ] `void dismissBust()` — clears `showBust` flag via `copyWith`, no async
- [ ] `void dismissLegModal()` — clears `pendingLegWinnerId` to `null` via `copyWith`, no async
- [ ] `void dismissGameModal()` — clears `pendingGameWinnerId` to `null` via `copyWith`, no async
- [ ] All three use `state.whenData(...)` pattern to safely mutate only on data state

### Tests — `test/features/game/presentation/providers/active_game_notifier_test.dart`
- [ ] File created with `@GenerateMocks` for `GameRepository`, `GameEventRepository`, `DartThrowRepository`
- [ ] Test: `build` returns `null` when `getGame` returns `null`
- [ ] Test: `build` replays events and returns correct `ActiveGameState`
- [ ] Test: `processDart` updates `gameState` in returned state
- [ ] Test: `processDart` sets `showBust: true` on a bust scenario
- [ ] Test: `processDart` sets `pendingLegWinnerId` when a leg completes
- [ ] Test: `processDart` sets `pendingGameWinnerId` when game is complete
- [ ] Test: `undoDart` updates `gameState` and clears all overlays
- [ ] Test: `dismissBust` sets `showBust` to `false` without affecting other fields
- [ ] Test: `dismissLegModal` clears `pendingLegWinnerId` without affecting other fields
- [ ] Test: `dismissGameModal` clears `pendingGameWinnerId` without affecting other fields

---

## Files

- `lib/features/game/presentation/providers/active_game_provider.dart` — **full rewrite**
- `lib/features/game/presentation/providers/active_game_provider.g.dart` — regenerated
- `test/features/game/presentation/providers/active_game_notifier_test.dart` — **to create**
- `test/features/game/presentation/providers/active_game_notifier_test.mocks.dart` — generated

---

## Implementation Notes

- `DartThrow` fields to populate inside `processDart`:
  - `dartId`: `const Uuid().v4()` — import `package:uuid/uuid.dart`
  - `gameId`: from `gs.gameId`
  - `competitorId`: `competitor.competitorId`
  - `playerId`: first entry of `competitor.playerIds` (or a sentinel if empty)
  - `turnNumber`: `gs.currentLegIndex`
  - `dartNumber`: `gs.dartsThrownInTurn + 1`
  - `segment`: the `segment` parameter
  - `score`: `Segment.parse(segment).scoreValue`
- Bust detection relies on the engine having rolled back the score on bust. After calling `processDartUseCaseProvider`, compare `newGs.competitors[oldTurnIndex].score == gs.competitors[oldTurnIndex].score` (score unchanged) AND `newGs.currentTurnIndex != gs.currentTurnIndex` (turn advanced). Both conditions together indicate a bust.
- Use `ref.read(...)` inside `build()` (not `ref.watch`) for all repository accesses — this is a one-time load, not a reactive subscription.
- Spec references: `docs/STATE_MANAGEMENT.md` §"AsyncNotifier Patterns", `docs/GAME-EVENT-SPECIFICATIONS.md`, `docs/games/x01.transitions.md` §"Bust".

---
