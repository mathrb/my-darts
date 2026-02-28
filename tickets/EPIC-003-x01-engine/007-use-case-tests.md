# TICKET-017: Use Case Tests

**Status:** Done
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Write the missing `CreateGameUseCase` test file and expand `ProcessDartUseCase` tests to cover leg-completion and game-completion paths. All tests use mock repositories — no real database or Flutter runtime required.

---

## Acceptance Criteria

- [x] `test/features/game/domain/usecases/create_game_use_case_test.dart` is created (file does not exist)
- [x] `CreateGameUseCase` tests cover:
  - [x] Valid config produces a `Game` entity with the correct `gameId`, `startingScore`, `legsToWin`, in/out strategy
  - [x] `GameCreated` event is appended before `TurnStarted` event
  - [x] `TurnStarted` payload: `turnIndex == 0`, `legIndex == 0`, `competitorId` matches the first competitor
  - [x] Invalid `startingScore` (e.g. 100) throws `ValidationException`
  - [x] Invalid `legsToWin` (0 or negative) throws `ValidationException`
  - [x] Empty `competitors` list throws `ValidationException`
  - [x] `GameRepository.createGame` is called exactly once
  - [x] `GameEventRepository.appendEvent` is called exactly twice (once per opening event)
- [x] `test/features/game/domain/usecases/process_dart_use_case_test.dart` is expanded to cover:
  - [x] Normal dart (no turn end): only `DartThrown` is appended; `GameRepository` not mutated
  - [x] Turn-ending dart (3rd dart, non-bust, non-checkout): `DartThrown` → `TurnEnded` → `TurnStarted` in order
  - [x] Bust dart: `DartThrown` (with bust=true) → `TurnEnded`; score reset confirmed in returned state
  - [x] Leg-completing dart: `DartThrown` → `TurnEnded` → `LegCompleted` → `TurnStarted` (first player of new leg)
  - [x] Game-completing dart: `DartThrown` → `TurnEnded` → `LegCompleted` → `GameCompleted`; no `TurnStarted` appended
  - [x] Call on completed game throws `GameAlreadyCompleteException`
  - [x] `engine.isValid` returning false causes early return with no persistence side effects

---

## Files

- `test/features/game/domain/usecases/create_game_use_case_test.dart` — **to create** (file does not exist)
- `test/features/game/domain/usecases/process_dart_use_case_test.dart` — to expand (leg/game completion paths missing)
- `test/features/game/domain/usecases/process_dart_use_case_test.mocks.dart` — regenerate after adding new mocks if needed

---

## Implementation Notes

- Use `mockito` (`@GenerateMocks`) for `GameRepository`, `GameEventRepository`, `DartThrowRepository`, and `GameEngine`. Regenerate mocks with `dart run build_runner build --delete-conflicting-outputs` after adding new `@GenerateMocks` annotations.
- Use `verify(mock.method(...)).called(N)` to assert call counts and ordering. Use `verifyInOrder([...])` to assert the event append sequence.
- `CreateGameUseCase` tests do not need a real `GameEngine` — the use case does not invoke the engine.
- `ProcessDartUseCase` tests mock `GameEngine.isValid` and `GameEngine.apply` to return controlled `EngineResult` values so each path (normal / bust / leg-complete / game-complete) can be tested in isolation.
- Do not use `ProviderContainer` here — these are use-case unit tests, not notifier tests. Instantiate the use cases directly with mock constructor arguments.
- Refer to `docs/GAME-EVENT-SPECIFICATIONS.md` for expected payload shapes when asserting `appendEvent` arguments.

---

## Implementation Summary

All 37 tests pass (27 for `CreateGameUseCase`, 10 for `ProcessDartUseCase`).

- `create_game_use_case_test.dart`: Uses `MockGameRepository` and `MockGameEventRepository` (mockito). Tests cover happy path, event ordering, payload shapes, `localSequence` assignment, strategy/score/legsToWin validation, and empty-competitors guard.
- `process_dart_use_case_test.dart`: Uses `MockGameRepository`, `MockGameEventRepository`, and `MockDartThrowRepository`. Uses the real `StatelessX01Engine` to drive all code paths (single dart, turn end, bust, leg checkout, game checkout). `verifyInOrder` confirms dart is persisted before events; sequence numbers are asserted to be strictly ascending.
