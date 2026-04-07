# 170 Checkout Practice – Game Rules & State Transitions

**Status:** Authoritative (engine + server validation)

---

## 1. Overview

The 170 Checkout Practice game is a solo drill where the player starts at 170 and tries to reach 0 using standard X01 double-out rules. The goal is to practice executing the 170 checkout sequence from a full dart input grid. The drill ends when the player successfully checks out or manually ends the session.

---

## 2. Setup

| Parameter | Value |
|---|---|
| Players | 1 (solo drill) |
| Darts per turn | Up to 3 (turn ends early on checkout or bust) |
| Starting score | 170 |
| Out rule | Double-out |
| End condition | Checkout (score reaches 0 on a double) OR player taps "End Drill" |

There is no "in" strategy — the player is always "in" from the first dart.

---

## 3. State Model

### Per Session

* `score` — current score; starts at 170
* `darts_thrown` — total dart throws recorded across all turns
* `game_complete` — boolean

### Per Turn

* `turn_active` — boolean
* `turn_start_score` — score at the moment TurnStarted fired (used for bust revert)
* `darts_thrown_in_turn` ∈ {0, 1, 2, 3}

---

## 4. Turn Transitions

### TurnStarted

Precondition: `turn_active == false`

```
turn_start_score = score
darts_thrown_in_turn = 0
turn_active = true
```

### DartThrown

Preconditions: `turn_active == true`, `darts_thrown_in_turn < 3`, `game_complete == false`

```
dart_value = segment_value(dart)    // e.g. T20 = 60, DB = 50, MISS = 0
new_score = score - dart_value
```

**Checkout** — `new_score == 0` AND dart is a double (D1–D20 or DB):

```
score = 0
darts_thrown += 1
darts_thrown_in_turn += 1
→ emit TurnEnded
→ emit GameCompleted(winner = competitor)
```

**Bust** — `new_score < 0`, OR `new_score == 1`, OR (`new_score == 0` AND dart is NOT a double):

```
score = turn_start_score            // revert
turn_active = false
→ emit TurnEnded                    // turn ends immediately; remaining darts forfeited
```

> Note: a busted dart does **not** increment `darts_thrown` or `darts_thrown_in_turn`.

**Normal** — `new_score > 1`:

```
score = new_score
darts_thrown += 1
darts_thrown_in_turn += 1

if darts_thrown_in_turn == 3:
    → emit TurnEnded
```

### TurnEnded

```
turn_active = false
darts_thrown_in_turn = 0
```

---

## 5. End Conditions

| Condition | Result |
|---|---|
| `score == 0` on a double | `GameCompleted` emitted; player is the winner |
| Player taps "End Drill" | `GameCompleted` emitted; no winner |

---

## 6. Scoring / Statistics

Stats are shown at the end of the drill.

| Metric | Definition |
|---|---|
| Darts thrown | Total dart throws recorded (`darts_thrown`). Only counts darts that were **not** busted. |
| Checkout score | The score at the **start of the finishing turn** (`turn_start_score` when `GameCompleted` fires on a checkout). Indicates the checkout value the player actually executed. |

> Example: player reaches 40 before the final turn, then checks out D20. Checkout score = 40; darts thrown = total across all turns.

Stats are computed as projections from events; never stored pre-calculated.

---

## 7. Invalid States

| Situation | Handling |
|---|---|
| `DartThrown` when `turn_active == false` | Rejected |
| `DartThrown` when `darts_thrown_in_turn == 3` | Rejected |
| `DartThrown` when `game_complete == true` | Rejected |
| `TurnStarted` when `turn_active == true` | Rejected |
| `TurnStarted` when `game_complete == true` | Rejected |
