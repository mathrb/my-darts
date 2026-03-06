# TICKET-055: PracticeTargetDisplayWidget + PracticeInputButtonsWidget

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement two pure presentation widgets for the practice board UI:
- `PracticeTargetDisplayWidget`: displays the current target (adapted label per mode) plus a secondary metric (hit rate % or running score)
- `PracticeInputButtonsWidget`: shows the three multiplier buttons (S-{n}, D-{n}, T-{n}) and a MISS button; labels update to reflect the current target

Both widgets are pure `StatelessWidget`s — no Riverpod, no direct provider access. They receive callbacks and data from the parent `PracticeBoardPage`.

Depends on: TICKET-044 (practice model — `GameType` enum, `CompetitorState` fields for display).

---

## Acceptance Criteria

### `PracticeTargetDisplayWidget` — `lib/features/game/presentation/widgets/practice_target_display_widget.dart`
- [ ] File exists; class named `PracticeTargetDisplayWidget` extends `StatelessWidget`
- [ ] Constructor parameters:
  - `required GameType gameType`
  - `required int? currentTarget` — the number being targeted (null for modes that don't use it)
  - `required int practiceRound` — current round number (for display)
  - `required int totalRounds` — total rounds (for progress display)
  - `required int score` — running score
  - `required int practiceAttempts` — for checkout practice hit rate
  - `required int practiceSuccesses` — for checkout practice hit rate
- [ ] Target label adapts per game type:
  - `aroundTheClock`: displays `'{n}'` (e.g., `'7'`)
  - `bobs27`: displays `'D{n}'` (e.g., `'D7'`) — the required double
  - `shanghai`: displays `'{n}'` (e.g., `'7'`) — the round target number
  - `catch40`: displays the round target total from config (e.g., `'40'`) — shows the round's catch threshold
  - `checkoutPractice`: displays the checkout finish value (e.g., `'170'`)
- [ ] Secondary metric (below target label) adapts per game type:
  - `aroundTheClock`: `'Number {n} of {total}'`
  - `bobs27`: `'Score: {score}'`
  - `shanghai`: `'Score: {score} | Round {n}/{total}'`
  - `catch40`: `'Score: {score} | Round {n}/{total}'`
  - `checkoutPractice`: `'{successes}/{attempts}' + hit rate %` (e.g., `'5/12 — 42%'`)
- [ ] No imports of `package:riverpod`, `package:sqflite`, `package:drift`, `package:dio`

### `PracticeInputButtonsWidget` — `lib/features/game/presentation/widgets/practice_input_buttons_widget.dart`
- [ ] File exists; class named `PracticeInputButtonsWidget` extends `StatelessWidget`
- [ ] Constructor parameters:
  - `required GameType gameType`
  - `required int? currentTarget` — determines button labels
  - `required void Function(String segment) onDartThrown` — called with canonical segment string
  - `required bool enabled` — disables all buttons when false (e.g., turn complete, game over)
- [ ] Shows four buttons: Single, Double, Triple, MISS
- [ ] Button labels when `currentTarget != null`:
  - Single: `'S-{n}'` (e.g., `'S-7'`)
  - Double: `'D-{n}'` (e.g., `'D-7'`)
  - Triple: `'T-{n}'` (e.g., `'T-7'`)
  - MISS: `'MISS'`
- [ ] Button labels when `currentTarget == null`: show generic labels (`'S'`, `'D'`, `'T'`, `'MISS'`)
- [ ] Button tap fires `onDartThrown` with canonical segment:
  - Single tap → `onDartThrown('{n}')` (e.g., `'7'`)
  - Double tap → `onDartThrown('D{n}')` (e.g., `'D7'`)
  - Triple tap → `onDartThrown('T{n}')` (e.g., `'T7'`)
  - MISS tap → `onDartThrown('MISS')`
- [ ] Bob's 27 mode: Single and Triple buttons are visually de-emphasised (not disabled, just styled differently) to hint that only doubles score — but they remain tappable
- [ ] Buttons are disabled (not interactive) when `enabled == false`
- [ ] No imports of `package:riverpod`, `package:sqflite`, `package:drift`, `package:dio`

---

## Files

- `lib/features/game/presentation/widgets/practice_target_display_widget.dart` — **to create**
- `lib/features/game/presentation/widgets/practice_input_buttons_widget.dart` — **to create**

---

## Implementation Notes

- Both widgets should follow the same styling conventions as existing widgets in `lib/features/game/presentation/widgets/` (e.g., `CricketGridWidget`, `CricketScoreSidebarWidget`).
- Checkout practice hit rate %: if `practiceAttempts == 0`, display `'—'` instead of dividing by zero.
- For Bob's 27 de-emphasis: consider using a secondary colour or a reduced opacity on the Single and Triple buttons. Do not disable them — a player may deliberately throw non-doubles for strategic reasons or to test the engine.
- `currentTarget` being `null` in `PracticeInputButtonsWidget` should be a rare/fallback state. The board page should always know the current target.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Practice Board", `EPIC-007-practice-modes.md` §"Shared Practice Board UI".

---
