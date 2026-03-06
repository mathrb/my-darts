# TICKET-052: StatelessCheckoutPracticeEngine

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `StatelessCheckoutPracticeEngine`, a pure-function game engine for the 170 Checkout Practice drill. The drill cycles through standard checkout routes from the 170-checkout table. The player attempts each checkout using 2–3 darts; success is detected when all required segments are hit in order within the allocated darts. The drill has no win/lose condition — it runs until the player explicitly exits.

Also wire the Checkout Practice case in `GameEngineFactory`.

Depends on: TICKET-044 (practice model additions — `currentTarget`, `practiceAttempts`, `practiceSuccesses` on `CompetitorState`; `CheckoutPracticeGameConfig` with `randomOrder`).

---

## Acceptance Criteria

### Checkout table constant
- [ ] A constant list of standard checkout routes is embedded in the engine file (or a companion constants file)
- [ ] Table covers all standard finishes from 170 down to 2 (the full 170-checkout table)
- [ ] Each entry: `{finish: int, route: List<String>}` — route is an ordered list of segments in canonical format (e.g., `{finish: 170, route: ['T20', 'T20', 'DB']}`)
- [ ] Table is `const` and not parsed at runtime

### Engine class
- [ ] `lib/features/game/domain/engines/stateless_checkout_practice_engine.dart` exists and implements `GameEngine`
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Reads `randomOrder` from `CheckoutPracticeGameConfig` embedded in `GameState`
- [ ] Reads current checkout finish from `CompetitorState.currentTarget`

### Checkout sequence
- [ ] Sequential mode (`randomOrder == false`): present checkouts in descending order (170, 167, 164, …, 2)
- [ ] Random mode (`randomOrder == true`): shuffle checkout order once at `GameState.initial()` time (seed not required; a fixed pseudo-random order is acceptable for determinism in tests)
- [ ] `currentTarget` holds the current checkout value being practiced

### Event routing — `apply(GameState state, GameEvent event)`
- [ ] `GameCreated` → returns state unchanged
- [ ] `TurnStarted` → sets `dartsThrownInTurn = 0`; does not reset the checkout route progress tracker (allows partial route carry-over within a single attempt)
- [ ] `DartThrown` → checks each dart against the expected next segment in the checkout route; increments `dartsThrownInTurn`; checks for success or bust
- [ ] `TurnEnded` → increments `practiceAttempts`; if current attempt was not a success → advance to next checkout; resets attempt progress
- [ ] `GameCompleted` → sets `isComplete = true` (fired only on explicit exit, not by engine internally)

### Success detection (within DartThrown)
- [ ] Maintain an index into the current checkout route (e.g., a transient field `routeProgress: int` on `CompetitorState`)
- [ ] Each dart must match `route[routeProgress]` (canonical segment string, exact match)
- [ ] On correct dart: `routeProgress += 1`; if `routeProgress == route.length`: success detected
- [ ] On success: `practiceSuccesses += 1`; advance to next checkout; reset `routeProgress = 0`; do not end the turn (player may throw remaining darts — they simply score 0)
- [ ] On incorrect dart: the attempt fails immediately; advance to next checkout; reset `routeProgress = 0`; increment `practiceAttempts` on this turn's end
- [ ] `MISS` is always an incorrect dart for any checkout route position

### Explicit exit
- [ ] The engine does NOT emit `GameCompleted` internally — only the use case layer calls it when the player taps "End Drill"
- [ ] The engine ignores any `GameCompleted` event it receives — just returns state with `isComplete = true`

### `isValid(GameState state, GameEvent event)`
- [ ] Returns `false` if `state.isComplete`
- [ ] Returns `false` if event is `DartThrown` and `dartsThrownInTurn >= 3`
- [ ] Returns `false` if event is `TurnStarted` while turn already active
- [ ] Returns `true` for all other valid events

### GameEngineFactory
- [ ] `lib/features/game/domain/engines/game_engine_factory.dart` updated to return `StatelessCheckoutPracticeEngine()` for `GameType.checkoutPractice`

---

## Files

- `lib/features/game/domain/engines/stateless_checkout_practice_engine.dart` — **to create**
- `lib/features/game/domain/engines/game_engine_factory.dart` — **to update**

---

## Implementation Notes

- The 170-checkout table is a well-known fixed set. Include it as a `const List<Map<String, Object>>` or a typed `const List<CheckoutRoute>` record. Minimally cover the most common finishes (170, 167, 164, 161, 160, 158, 157, 156, 155, 154, 153, 152, 151, 150 … down to 2). The table does not need to be exhaustive if memory is a concern — focus on finishes 40–170.
- This is the most complex engine in EPIC-007 due to route progress tracking. Plan for a `routeProgress` integer on `CompetitorState` (added in TICKET-044 if needed, or add as a follow-on to that ticket).
- The "explicit exit" design means the UI notifier calls a separate `endDrill()` method that emits `GameCompleted` via the use case, rather than the engine ever auto-completing. This is intentional and differs from other practice engines.
- Success/failure on a dart happens within `DartThrown.apply()`. The `TurnEnded` event is only responsible for bookkeeping (incrementing attempts, rotating checkout). Keep this distinction clean.
- Spec references: `EPIC-007-practice-modes.md` §"170 Checkout Practice", `docs/GAME-EVENT-SPECIFICATIONS.md`.

---
