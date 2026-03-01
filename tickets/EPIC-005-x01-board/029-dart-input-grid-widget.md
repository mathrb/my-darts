# TICKET-029: DartInputGridWidget

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

Build the dart segment input grid — the primary input surface for the X01 board. This is a pure `StatelessWidget` with no provider access; it receives a callback and an enabled flag, and emits canonical segment strings upward. The `X01BoardPage` (TICKET-033) wires the callback to `notifier.processDart`.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/widgets/dart_input_grid_widget.dart` exists
- [ ] Class is a `StatelessWidget` — no `ConsumerWidget`, no providers
- [ ] Constructor:
  ```dart
  const DartInputGridWidget({
    required void Function(String segment) onSegmentTapped,
    bool enabled = true,
    super.key,
  });
  ```
- [ ] **Special row** (3 equal-width buttons): `MISS` → emits `'MISS'`; `BULL 25` → emits `'SB'`; `BULL 50` → emits `'DB'`
- [ ] **Singles row**: buttons for 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 (dartboard order) — emits `'20'`…`'1'`
- [ ] **Doubles row**: same 20-number sequence — emits `'D20'`…`'D1'`; a visual indicator (e.g. double dot `··` below label) distinguishes this row from singles
- [ ] **Triples row**: same sequence — emits `'T20'`…`'T1'`; visual indicator (e.g. triple dot `···`)
- [ ] All 43 possible segments representable: `MISS`, `SB`, `DB`, singles 1–20, doubles D1–D20, triples T1–T20
- [ ] `enabled = false` → all buttons are non-interactive (`onPressed: null` or equivalent); visual style indicates disabled state
- [ ] `enabled = true` → tapping any button fires `onSegmentTapped` with the correct canonical string
- [ ] No segment strings hard-coded outside the widget's own mapping — use dartboard order list: `[20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]`

---

## Files

- `lib/features/game/presentation/widgets/dart_input_grid_widget.dart` — **to create**

---

## Implementation Notes

- Numbers must follow dartboard order (`[20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]`), not ascending numeric order — this matches player muscle memory.
- Use a `Wrap` or `GridView` for the numeric rows so the layout adapts to narrow screens without overflow.
- Row labelling: a small text label above each row indicating S / D / T (or a dot indicator below each button) is sufficient; match the style from `docs/UI_SCREEN_FLOWS_V3_FINAL.md` X01 board section.
- Buttons in the doubles and triples rows should visually communicate their multiplier without the prefix letter cluttering the button face (e.g. show just `"20"` with dots below, not `"D20"`).
- Segment format reference: `AGENTS.md` §"Segment Format Convention".
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"X01 Board — Input Grid".

---
