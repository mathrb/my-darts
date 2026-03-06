# TICKET-049: StatelessShanghaiEngine

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `StatelessShanghaiEngine`, a pure-function game engine for the Shanghai practice drill. Each of the `totalRounds` rounds (default 7) targets a specific number. Score accumulates from darts hitting the round's target number. A "Shanghai" — hitting single, double, AND triple of the round number in a single 3-dart turn — triggers an instant win. Highest score after all rounds wins; single-player drill completes with no winner if no Shanghai achieved.

Also wire the Shanghai case in `GameEngineFactory`.

Depends on: TICKET-044 (practice model additions — `shanghaiTotalRounds` on `GameState`, `practiceRound` on `CompetitorState`).

---

## Acceptance Criteria

### Engine class
- [ ] `lib/features/game/domain/engines/stateless_shanghai_engine.dart` exists and implements `GameEngine`
- [ ] Zero imports of `package:flutter`, `package:sqflite`, `package:drift`, `package:dio`
- [ ] Reads total rounds from `GameState.shanghaiTotalRounds`
- [ ] Reads current round from `CompetitorState.practiceRound` (1-based)

### Event routing — `apply(GameState state, GameEvent event)`
- [ ] `GameCreated` → returns state unchanged
- [ ] `TurnStarted` → sets `dartsThrownInTurn = 0`
- [ ] `DartThrown` → full scoring logic (see below); increments `dartsThrownInTurn`; on 3rd dart: checks Shanghai and round end conditions
- [ ] `TurnEnded` → rotates competitor (single-player: no-op on index); resets `dartsThrownInTurn = 0`; increments `practiceRound`
- [ ] `GameCompleted` → sets `isComplete = true`, sets `winnerCompetitorId`

### Scoring per dart (DartThrown)
- [ ] Round target is the round number: round 1 target = 1, round 2 target = 2, …
- [ ] Dart hits target number (any multiplier on `segmentNumber == practiceRound`):
  - Single → `score += practiceRound × 1`
  - Double → `score += practiceRound × 2`
  - Triple → `score += practiceRound × 3`
- [ ] Dart does NOT hit target number (wrong number, MISS, Bull): `score += 0`
- [ ] Score accumulates across the turn; all 3 darts are always thrown (no early turn end unless Shanghai)

### Shanghai instant win condition
- [ ] Detected after the 3rd dart of a turn
- [ ] Shanghai requires all three of the following to be hit in a single turn: single of round number (`'{n}'`), double of round number (`'D{n}'`), triple of round number (`'T{n}'`)
- [ ] Order does not matter — hitting S, T, D in any order still counts
- [ ] If Shanghai detected: emit `GameCompleted` immediately with current competitor as winner (`winnerCompetitorId = competitorId`)
- [ ] If NOT Shanghai after 3 darts: check if final round complete; otherwise continue to next round

### End condition — final round
- [ ] After the 3rd dart of round `shanghaiTotalRounds` and no Shanghai: emit `GameCompleted`
- [ ] Single-player: `winnerCompetitorId = null` (drill complete — no competitive winner)
- [ ] Multi-player: `winnerCompetitorId` = competitor with highest score; if tied, the one who scored last (last to complete final round) wins

### `isValid(GameState state, GameEvent event)`
- [ ] Returns `false` if `state.isComplete`
- [ ] Returns `false` if event is `DartThrown` and `dartsThrownInTurn >= 3`
- [ ] Returns `false` if event is `TurnStarted` while turn already active
- [ ] Returns `true` for all other valid events

### GameEngineFactory
- [ ] `lib/features/game/domain/engines/game_engine_factory.dart` updated to return `StatelessShanghaiEngine()` for `GameType.shanghai`

---

## Files

- `lib/features/game/domain/engines/stateless_shanghai_engine.dart` — **to create**
- `lib/features/game/domain/engines/game_engine_factory.dart` — **to update**

---

## Implementation Notes

- Shanghai detection requires tracking which multiplier types were hit for the current round's target within a single turn. Consider a transient set stored in `CompetitorState` (e.g., `practiceHitsThisTurn: Set<int>` for multiplier values hit) or derive from `GameState.currentTurnSegments` — whichever is consistent with how Bob's 27 engine tracks per-turn accumulation (coordinate with TICKET-047 implementor).
- `practiceRound` increments at `TurnEnded`, not `DartThrown`. The 3rd dart triggers Shanghai check first, then `TurnEnded` increments the round.
- For single-player drills (the primary use case), the "multi-player tie" resolution is not exercised — still implement for completeness.
- Segment parsing for hit detection: extract number from `'T7'` → number=7, multiplier=3; from `'D7'` → number=7, multiplier=2; from `'7'` → number=7, multiplier=1.
- Bull (`'SB'`/`'DB'`) is not a valid target for any round 1–7; treat as non-scoring.
- Spec references: `EPIC-007-practice-modes.md` §"Shanghai", `docs/GAME-EVENT-SPECIFICATIONS.md`.

---
