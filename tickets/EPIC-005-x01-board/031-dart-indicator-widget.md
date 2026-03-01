# TICKET-031: DartIndicatorWidget

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

Build the three-dart-slot indicator strip shown between the score section and the input grid. Each slot represents one dart in the current turn. Thrown darts render as filled (with a dart icon or highlight); unthrown slots render as empty. This widget is a pure `StatelessWidget` with no provider access.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/widgets/dart_indicator_widget.dart` exists
- [ ] Class is a `StatelessWidget` — no `ConsumerWidget`, no providers
- [ ] Constructor:
  ```dart
  const DartIndicatorWidget({
    required int dartsThrown,
    super.key,
  });
  ```
- [ ] Renders exactly 3 slots in a `Row`
- [ ] Slots `0` through `dartsThrown - 1` render as **filled** (e.g. dart emoji `🎯`, filled icon, or highlighted dash)
- [ ] Slots `dartsThrown` through `2` render as **empty** (e.g. plain dash `────`, greyed-out icon)
- [ ] `dartsThrown` values 0, 1, 2, 3 all render correctly without assertion errors
- [ ] Pure `StatelessWidget`

---

## Files

- `lib/features/game/presentation/widgets/dart_indicator_widget.dart` — **to create**

---

## Implementation Notes

- `dartsThrown` is sourced from `GameState.dartsThrownInTurn`; the board page passes it directly.
- Assertion: `assert(dartsThrown >= 0 && dartsThrown <= 3)` is acceptable for debug builds.
- Visual style: three equally spaced containers in a `Row` with `MainAxisAlignment.spaceEvenly`. Filled slots use a distinct color or icon; empty slots use a muted/grey style.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"X01 Board — Dart Indicator".

---
