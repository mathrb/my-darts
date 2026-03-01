# TICKET-027: undoLastDartUseCaseProvider

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

`UndoLastDartUseCase` already exists in the domain layer but has no Riverpod provider wired in `lib/core/persistence/database_provider.dart`. Add the missing `keepAlive` provider so `ActiveGameNotifier` (TICKET-028) can resolve it via `ref.read`. This is the only file change in this ticket.

---

## Acceptance Criteria

- [ ] `undoLastDartUseCaseProvider` is added to `lib/core/persistence/database_provider.dart`
- [ ] Provider is annotated `@Riverpod(keepAlive: true)`
- [ ] Wires the same four dependencies as `processDartUseCaseProvider`:
  - `ref.watch(gameRepositoryProvider)`
  - `ref.watch(gameEventRepositoryProvider)`
  - `ref.watch(dartThrowRepositoryProvider)`
  - `ref.watch(x01EngineProvider)`
- [ ] Import for `UndoLastDartUseCase` added to `database_provider.dart`
- [ ] `build_runner` regenerates `database_provider.g.dart` without errors
- [ ] All existing tests (301) still pass

---

## Files

- `lib/core/persistence/database_provider.dart` — **to modify** (append provider)
- `lib/core/persistence/database_provider.g.dart` — regenerated

---

## Implementation Notes

- Place the new provider directly after `processDartUseCaseProvider` in the file for readability.
- Do not change the signatures or wiring of any existing providers.
- The import path for `UndoLastDartUseCase` is `package:my_darts/features/game/domain/usecases/undo_last_dart_use_case.dart` (verify the exact path matches the existing file).
- Spec references: `docs/REPOSITORY_INTERFACES.md` §"Repository Providers", `docs/STATE_MANAGEMENT.md` §"Provider Conventions".

---
