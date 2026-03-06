# TICKET-044: Practice Model Additions

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Extend the domain model layer to support all five practice game types. This covers adding missing `GameType` enum values, new `GameConfig` variants, new `CompetitorState` fields for practice tracking, and new `GameState` fields for engine dispatch. Run `build_runner` after all changes.

No engine logic here — this ticket only prepares the data model foundation that TICKET-045 through 057 build upon.

Depends on: nothing (first ticket in EPIC-007).

---

## Acceptance Criteria

### `GameType` enum — `lib/core/utils/constants.dart`
- [ ] `catch40` value added to `GameType` enum
- [ ] `bobs27` value added to `GameType` enum
- [ ] `checkoutPractice` value added to `GameType` enum
- [ ] Existing values (`aroundTheClock`, `shanghai`, x01 variants, cricket variants) unchanged

### `AroundTheClockGameConfig` — `lib/features/game/domain/models/game_config.dart`
- [ ] Field added: `@Default('standard') String variant` — valid values are `'standard'`, `'reverse'`, `'doublesOnly'`
- [ ] Existing field `startingPlayerId` preserved

### `ShanghaiGameConfig` — `lib/features/game/domain/models/game_config.dart`
- [ ] Field added: `@Default(7) int totalRounds`
- [ ] Existing field `startingPlayerId` preserved

### `GameConfig.catch40(...)` — `lib/features/game/domain/models/game_config.dart`
- [ ] New factory variant `catch40` added to the `GameConfig` sealed union
- [ ] Fields:
  - `required String startingPlayerId`
  - `@Default(8) int totalRounds`
  - `@Default([10, 15, 20, 25, 30, 35, 40, 45]) List<int> roundTargets`

### `GameConfig.bobs27(...)` — `lib/features/game/domain/models/game_config.dart`
- [ ] New factory variant `bobs27` added to the `GameConfig` sealed union
- [ ] Fields:
  - `required String startingPlayerId`
  - (No other configuration; all rules are fixed)

### `GameConfig.checkoutPractice(...)` — `lib/features/game/domain/models/game_config.dart`
- [ ] New factory variant `checkoutPractice` added to the `GameConfig` sealed union
- [ ] Fields:
  - `required String startingPlayerId`
  - `@Default(false) bool randomOrder`

### `CompetitorState` — `lib/features/game/domain/models/game_state.dart`
- [ ] Field added: `int? currentTarget` — current target segment value (null = not applicable)
- [ ] Field added: `@Default(1) int practiceRound` — current round number (1-based), used by Bob's 27, Shanghai, Catch40
- [ ] Field added: `@Default(0) int practiceAttempts` — total attempts in checkout practice
- [ ] Field added: `@Default(0) int practiceSuccesses` — successful checkouts in checkout practice
- [ ] Existing fields unchanged

### `GameState` — `lib/features/game/domain/models/game_state.dart`
- [ ] Field added: `@Default('standard') String aroundTheClockVariant` — engine dispatch for ATC variants
- [ ] Field added: `@Default(7) int shanghaiTotalRounds` — engine dispatch for Shanghai round count
- [ ] Existing fields unchanged

### `GameState.initial()` — `lib/features/game/domain/models/game_state.dart`
- [ ] When config is `AroundTheClockGameConfig`: sets `aroundTheClockVariant` from `config.variant`; sets each competitor's `currentTarget` to `1` (standard/doublesOnly) or `20` (reverse)
- [ ] When config is `ShanghaiGameConfig`: sets `shanghaiTotalRounds` from `config.totalRounds`; sets each competitor's `practiceRound` to `1`
- [ ] When config is `Catch40GameConfig`: sets each competitor's `practiceRound` to `1`
- [ ] When config is `Bobs27GameConfig`: sets each competitor's `score` to `27`; sets `practiceRound` to `1`
- [ ] When config is `CheckoutPracticeGameConfig`: sets each competitor's `currentTarget` per first checkout in sequence

### Code generation
- [ ] `dart run build_runner build --delete-conflicting-outputs` completes without errors
- [ ] All `.freezed.dart` and `.g.dart` files regenerated

---

## Files

- `lib/core/utils/constants.dart` — **to update** (add enum values)
- `lib/features/game/domain/models/game_config.dart` — **to update** (add fields + new variants)
- `lib/features/game/domain/models/game_state.dart` — **to update** (add fields + update `initial()`)
- `lib/features/game/domain/models/game_config.freezed.dart` — generated
- `lib/features/game/domain/models/game_state.freezed.dart` — generated

---

## Implementation Notes

- The `GameConfig` sealed union uses `@freezed` with multiple factory constructors. Add new variants with the same pattern as existing ones (e.g., `CricketGameConfig`).
- `CompetitorState` is part of `game_state.dart` — check the existing `@freezed` class definition before adding fields to ensure correct placement.
- `GameState.initial()` must read `config.gameType` (or pattern-match on the config type) to set the new variant/round fields. Follow the existing pattern for extracting `legsToWin` from `X01GameConfig`.
- Do not add any engine logic here. Target initialisation in `initial()` is limited to setting the starting value — advancement logic belongs in the engine.
- Spec references: `docs/DATA.md` (entity fields), `docs/games/around-the-clock.md` §"State Model", `EPIC-007-practice-modes.md`.

---
