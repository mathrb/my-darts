# TICKET-053: ProcessPracticeDartUseCase + Provider Wiring

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `ProcessPracticeDartUseCase` — the use case that drives all five practice engine types. It follows the same event choreography as `ProcessCricketDartUseCase` but without bust handling. Wire all five engine providers and their corresponding use-case providers in `database_provider.dart`. Also wire `undoPracticeDartUseCaseProvider` (reusing the existing `UndoLastDartUseCase`).

Depends on: TICKET-045 (ATC engine), TICKET-047 (Bob's 27 engine), TICKET-049 (Shanghai engine), TICKET-051 (Catch 40 engine), TICKET-052 (Checkout Practice engine).

---

## Acceptance Criteria

### `ProcessPracticeDartUseCase` — `lib/features/game/domain/usecases/process_practice_dart_use_case.dart`
- [ ] File exists; class named `ProcessPracticeDartUseCase`
- [ ] Constructor parameters: `GameRepository gameRepository`, `GameEventRepository gameEventRepository`, `DartThrowRepository dartThrowRepository`, `GameEngine engine`
- [ ] Single public method: `Future<GameState> execute(GameState currentState, DartThrow dart)`
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`

### Event choreography inside `execute()`
- [ ] Builds a `DartThrown` event from `dart` and appends it via `gameEventRepository.appendEvent()`
- [ ] Calls `engine.apply(currentState, dartThrownEvent)` to get `newState`
- [ ] Inserts the dart throw via `dartThrowRepository.insertDart(dart)`
- [ ] If `newState.currentLegIndex > currentState.currentLegIndex` AND `!newState.isComplete`: appends `LegCompleted` event, applies it via `engine.apply()`
- [ ] If `newState.isComplete`: appends `GameCompleted` event, applies via `engine.apply()`; calls `gameRepository.updateGameStatus(gameId, completed: true)`
- [ ] Returns the final `GameState` after all events applied
- [ ] No bust path — practice engines never produce bust states

### Provider wiring — `lib/core/persistence/database_provider.dart`

Engine providers:
- [ ] `aroundTheClockEngineProvider` — `keepAlive: true`; returns `StatelessAroundTheClockEngine()`
- [ ] `bobs27EngineProvider` — `keepAlive: true`; returns `StatelessBobs27Engine()`
- [ ] `shanghaiEngineProvider` — `keepAlive: true`; returns `StatelessShanghaiEngine()`
- [ ] `catch40EngineProvider` — `keepAlive: true`; returns `StatelessCatch40Engine()`
- [ ] `checkoutPracticeEngineProvider` — `keepAlive: true`; returns `StatelessCheckoutPracticeEngine()`

`ProcessPracticeDartUseCase` providers (one per engine):
- [ ] `processAroundTheClockDartUseCaseProvider` — `keepAlive: true`; constructs `ProcessPracticeDartUseCase` with `aroundTheClockEngineProvider`
- [ ] `processBobs27DartUseCaseProvider` — `keepAlive: true`; constructs with `bobs27EngineProvider`
- [ ] `processShanghaiDartUseCaseProvider` — `keepAlive: true`; constructs with `shanghaiEngineProvider`
- [ ] `processCatch40DartUseCaseProvider` — `keepAlive: true`; constructs with `catch40EngineProvider`
- [ ] `processCheckoutPracticeDartUseCaseProvider` — `keepAlive: true`; constructs with `checkoutPracticeEngineProvider`

Undo providers:
- [ ] `undoPracticeAroundTheClockLastDartUseCaseProvider` — `keepAlive: true`; constructs `UndoLastDartUseCase` with `aroundTheClockEngineProvider`
- [ ] `undoPracticeBobs27LastDartUseCaseProvider` — `keepAlive: true`; constructs `UndoLastDartUseCase` with `bobs27EngineProvider`
- [ ] `undoPracticeShanghaiLastDartUseCaseProvider` — `keepAlive: true`; constructs `UndoLastDartUseCase` with `shanghaiEngineProvider`
- [ ] `undoPracticeCatch40LastDartUseCaseProvider` — `keepAlive: true`; constructs `UndoLastDartUseCase` with `catch40EngineProvider`
- [ ] `undoPracticeCheckoutPracticeLastDartUseCaseProvider` — `keepAlive: true`; constructs `UndoLastDartUseCase` with `checkoutPracticeEngineProvider`

### Checkout practice — explicit exit provider
- [ ] `endCheckoutPracticeUseCaseProvider` — `keepAlive: true`; a thin use case or direct use of `gameRepository.updateGameStatus` that emits `GameCompleted` event and marks game as complete (see TICKET-052 — the engine never auto-completes)

---

## Files

- `lib/features/game/domain/usecases/process_practice_dart_use_case.dart` — **to create**
- `lib/core/persistence/database_provider.dart` — **to update**

---

## Implementation Notes

- The choreography is nearly identical to `ProcessCricketDartUseCase` in `lib/features/game/domain/usecases/process_cricket_dart_use_case.dart`. Read it carefully before implementing.
- The single `ProcessPracticeDartUseCase` class works for all five practice engines because it takes `GameEngine` as a constructor parameter — the injected engine determines behaviour.
- The undo use case (`UndoLastDartUseCase`) already exists from TICKET-027. It also takes a `GameEngine` constructor parameter, so it simply needs to be instantiated with each practice engine.
- For checkout practice, the "explicit exit" use case should emit a `GameCompleted` event with `winnerCompetitorId = null` and call `gameRepository.updateGameStatus(gameId, completed: true)`. Keep this minimal.
- Spec references: `docs/STATE_MANAGEMENT.md` §"Provider wiring", `docs/GAME-EVENT-SPECIFICATIONS.md`, `docs/REPOSITORY_INTERFACES.md`.

---
