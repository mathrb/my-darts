# TICKET-012: X01 Engine Implementation

**Status:** Done
**Epic:** EPIC-003 — X01 Game Engine

---

## Description

Implement `StatelessX01Engine` — the pure, side-effect-free engine that applies dart throws to X01 game state according to all transition tables in `docs/games/x01.transitions.md`.

---

## Acceptance Criteria

- [x] `StatelessX01Engine` implements `GameEngine` from `base_game_engine.dart`
- [x] Implements all transition rows from Tables A–L in `docs/games/x01.transitions.md`
- [x] In-strategy enforcement: straight-in, double-in, master-in (Table A / B)
- [x] Out-strategy enforcement: straight-out, double-out, master-out (Table C / D / E)
- [x] Bust handling: dart that takes score below zero is a bust; bust immediately ends the turn and resets score to pre-turn value (Table F)
- [x] Exact-zero-miss bust: dart that hits exactly zero without satisfying out-strategy is a bust
- [x] Bull handling: `'SB'` scores 25 (single), `'DB'` scores 50 and counts as a double for in/out validation (Table G)
- [x] Failed in-dart: dart is consumed (turn dart count increments) but does not score — turn continues (Table H)
- [x] Score floor: score may never go below zero; enforced before state is mutated
- [x] Multi-leg detection: `legsToWin` from game config; leg reset on leg completion; game completion when a player reaches `legsToWin`
- [x] `MISS` segment scores 0 and does not satisfy any strategy requirement
- [x] No Flutter, sqflite, drift, or dio imports — pure Dart domain only

---

## Files

- `lib/features/game/domain/engines/stateless_x01_engine.dart` — created

---

## Implementation Notes

- Engine receives `GameState` and a dart segment string in canonical format (e.g. `'T20'`, `'D16'`, `'SB'`, `'MISS'`). Never accept numeric codes.
- Bust resets `currentScore` for the active competitor back to the value it held at the start of the turn. The pre-turn score must be captured in `GameState` before the turn's first dart.
- `isValid` is called by `ProcessDartUseCase` before `apply`. If `isValid` returns false, the use case does not call `apply` and returns an error result.
- Resolved ambiguities from `docs/games/x01.transitions.md` that the engine must respect:
  1. Failed in-dart counts the dart (dart index increments) — it does not score but uses a dart slot.
  2. Bust ends the turn immediately after the busting dart — remaining dart slots in the turn are not consumed.
  3. Out validation occurs before the terminal dart count is applied.
  4. `'DB'` (double bull, 50) counts as a double for both in-strategy and out-strategy purposes.
  5. `'MISS'` does not trigger C/D/E strategy miss penalties — it simply consumes a dart and scores 0.
