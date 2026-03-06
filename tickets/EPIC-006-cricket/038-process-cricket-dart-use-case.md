# TICKET-038: ProcessCricketDartUseCase + Provider Wiring

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Implement `ProcessCricketDartUseCase`, the domain-layer use case that records a single cricket dart throw. It mirrors `ProcessDartUseCase` (used by X01) but is adapted for cricket: no bust-path logic, no score rollback. Wire it into `database_provider.dart` alongside a `cricketEngineProvider` and an `undoCricketLastDartUseCaseProvider` that uses the cricket engine for replay.

Depends on: TICKET-036 (`StatelessCricketEngine`).

---

## Acceptance Criteria

### ProcessCricketDartUseCase
- [ ] `lib/features/game/domain/usecases/process_cricket_dart_use_case.dart` exists
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Constructor takes four injected dependencies:
  ```dart
  ProcessCricketDartUseCase(
    GameRepository gameRepository,
    GameEventRepository gameEventRepository,
    DartThrowRepository dartThrowRepository,
    StatelessCricketEngine engine,
  );
  ```
- [ ] Single public method `Future<GameState> execute(GameState currentState, DartThrow dart)`:
  1. Validates the dart via `engine.isValid(currentState, DartThrown event)`; throws `ValidationException` if invalid
  2. Appends a `DartThrown` event via `gameEventRepository.appendEvent()`
  3. Persists the `DartThrow` via `dartThrowRepository.insertDart(dart)`
  4. Applies the event to get `newState = engine.apply(currentState, dartThrownEvent)`
  5. If `newState.dartsThrownInTurn == 3` (or equivalent turn-end condition), appends a `TurnEnded` event and applies it
  6. If a leg completes (`newState.currentLegIndex > currentState.currentLegIndex && !newState.isComplete`), appends `LegCompleted` + `TurnStarted` events and applies them in sequence
  7. If `newState.isComplete`, appends a `GameCompleted` event and applies it
  8. Updates the game's `gameStateJson` via `gameRepository.updateGameState(newState)`
  9. Returns the final `GameState`
- [ ] **No bust path**: never appends a bust-rollback event; never rolls back score; cricket engine determines scoring directly
- [ ] All repository exceptions propagate — do not catch or swallow them

### Provider wiring in `database_provider.dart`
- [ ] `cricketEngineProvider` added:
  ```dart
  @Riverpod(keepAlive: true)
  StatelessCricketEngine cricketEngine(Ref ref) => StatelessCricketEngine();
  ```
- [ ] `processCricketDartUseCaseProvider` added:
  ```dart
  @Riverpod(keepAlive: true)
  ProcessCricketDartUseCase processCricketDartUseCase(Ref ref) =>
      ProcessCricketDartUseCase(
        ref.watch(gameRepositoryProvider),
        ref.watch(gameEventRepositoryProvider),
        ref.watch(dartThrowRepositoryProvider),
        ref.watch(cricketEngineProvider),
      );
  ```
- [ ] `undoCricketLastDartUseCaseProvider` added (reuses existing `UndoLastDartUseCase` with the cricket engine):
  ```dart
  @Riverpod(keepAlive: true)
  UndoLastDartUseCase undoCricketLastDartUseCase(Ref ref) =>
      UndoLastDartUseCase(
        ref.watch(gameEventRepositoryProvider),
        ref.watch(dartThrowRepositoryProvider),
        ref.watch(gameRepositoryProvider),
        ref.watch(cricketEngineProvider),
      );
  ```
- [ ] Code generation (`build_runner`) produces updated `.g.dart` without errors

---

## Files

- `lib/features/game/domain/usecases/process_cricket_dart_use_case.dart` — **to create**
- `lib/core/persistence/database_provider.dart` — **to update**
- `lib/core/persistence/database_provider.g.dart` — regenerated

---

## Implementation Notes

- The event choreography (DartThrown → TurnEnded → LegCompleted + TurnStarted / GameCompleted) must follow `docs/GAME-EVENT-SPECIFICATIONS.md` exactly — same as `ProcessDartUseCase`.
- Cricket never produces a bust, so there is no bust event to append and no score rollback. Do not add any bust-related branches to this use case.
- Turn-end trigger: check `newState.dartsThrownInTurn == 3` after applying `DartThrown`. The cricket engine does not auto-rotate turns; the use case is responsible for appending `TurnEnded`.
- Leg complete trigger: compare `newState.currentLegIndex > currentState.currentLegIndex`. Append `LegCompleted` first, then `TurnStarted` for the new leg.
- Game complete trigger: check `newState.isComplete` after all other event applications.
- Spec references: `docs/GAME-EVENT-SPECIFICATIONS.md`, `docs/REPOSITORY_INTERFACES.md`, `docs/games/cricket.transitions.md` §"Event Choreography", `docs/STATE_MANAGEMENT.md` §"Use Cases".

---
