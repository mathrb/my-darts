# TICKET-040: CricketMarkIndicatorWidget

**Status:** Todo
**Epic:** EPIC-006 — Cricket Game

---

## Description

Build `CricketMarkIndicatorWidget`, a pure `StatelessWidget` that renders one cricket cell's current mark state (0–3 marks). It is a leaf widget with no provider access and no business logic — it takes a single `marks` integer and renders the appropriate visual indicator. Used inside `CricketGridWidget` (TICKET-041) for every cell in the cricket board grid.

---

## Acceptance Criteria

- [ ] `lib/features/game/presentation/widgets/cricket_mark_indicator_widget.dart` exists
- [ ] Class is a `StatelessWidget` — no `ConsumerWidget`, no providers
- [ ] Constructor:
  ```dart
  const CricketMarkIndicatorWidget({required int marks, super.key});
  ```
- [ ] `marks` is clamped to the range `[0, 3]` before rendering — values below 0 render as 0, values above 3 render as 3
- [ ] **0 marks** → renders `"–"` (em-dash or en-dash; a visually clear empty indicator)
- [ ] **1 mark** → renders `"/"` (single forward slash; visually distinct from the 0 state)
- [ ] **2 marks** → renders `"X"` (two lines crossing; letter X in appropriate font weight)
- [ ] **3 marks (closed)** → renders a circled X (e.g. `"⊗"` Unicode character, or a custom paint/stack of an outlined circle with an X inside); visually clearly distinguishable from 2 marks
- [ ] Each state uses appropriate sizing — the indicator should be readable at the cell size used by `CricketGridWidget`
- [ ] No hardcoded colours that conflict with the app's theme; use `Theme.of(context)` tokens or `DefaultTextStyle` for text colour

---

## Files

- `lib/features/game/presentation/widgets/cricket_mark_indicator_widget.dart` — **to create**

---

## Implementation Notes

- The four states (0–3) map to the standard darts cricket scoreboard notation used in physical chalk scoreboards.
- The circled X for 3 marks can be implemented with:
  - Unicode `⊗` (U+2297 CIRCLED TIMES) rendered in a `Text` widget, or
  - A `Stack` of a `Container` with circular border + a centred `Text('X')`, or
  - `CustomPaint` for pixel-perfect control
  - Choose whichever approach is cleanest; the character must be clearly legible at small sizes.
- Font weight for `"X"` (2 marks) should be `FontWeight.bold` to distinguish it from `"/"` at a glance.
- The widget will be embedded inside a cell in `CricketGridWidget`; do not set a fixed size inside this widget — let the parent control sizing via `SizedBox` or `Expanded`.
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Cricket Board — Mark Indicator".

---
