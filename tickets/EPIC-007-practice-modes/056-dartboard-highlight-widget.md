# TICKET-056: DartboardHighlightWidget

**Status:** Todo
**Epic:** EPIC-007 — Practice Modes

---

## Description

Implement `DartboardHighlightWidget` — a visual dartboard widget that highlights the current target segment with a glow or accent effect, while rendering all other segments dimly. This is a pure `StatelessWidget` with no provider or database dependencies.

Depends on: nothing (pure widget — no dependency on other EPIC-007 tickets).

---

## Acceptance Criteria

### Widget class
- [ ] `lib/features/game/presentation/widgets/dartboard_highlight_widget.dart` exists
- [ ] Class named `DartboardHighlightWidget` extends `StatelessWidget`
- [ ] Constructor parameters:
  - `required int? currentTarget` — the number to highlight (1–20, or null for Bull)
  - `required bool doublesOnly` — when true, highlight only the double ring for the target segment
- [ ] No imports of `package:riverpod`, `package:sqflite`, `package:drift`, `package:dio`

### Visual rendering
- [ ] Renders a dartboard with all 20 numbered segments + bull + outer bull rings
- [ ] When `currentTarget` is a number 1–20:
  - Highlights all three scoring areas for that number (single, double, triple rings) unless `doublesOnly`
  - `doublesOnly == true`: highlights only the double ring area for `currentTarget`
- [ ] When `currentTarget == null`: highlights bull area (both single bull and double bull rings)
- [ ] Non-highlighted segments are rendered at reduced opacity or in muted colours
- [ ] Highlighted segment is rendered in a bright or accent colour (consistent with the app's existing colour scheme)

### Implementation approach
- [ ] Prefer a `CustomPainter`-based approach if no existing dartboard asset is available
- [ ] Alternatively, use a simple grid-based visual representation (e.g., numbered cells arranged in a circle) that is aesthetically clean and fast to render
- [ ] The widget must not require network assets — everything is drawn or bundled locally
- [ ] Widget size is determined by parent layout constraints (no hardcoded size)

### Null safety
- [ ] Renders gracefully when `currentTarget == null` (highlights bull)
- [ ] Does not throw if `currentTarget` is outside 1–20 range — clamp or show neutral state

---

## Files

- `lib/features/game/presentation/widgets/dartboard_highlight_widget.dart` — **to create**

---

## Implementation Notes

- A full realistic dartboard SVG with full segment interaction would be ideal but is complex. An acceptable V1 is a simplified polar-segment layout using `CustomPainter` that clearly shows the 20 numbered sections and a centre bull, with highlighting on the active segment. Do not over-engineer — the board needs to be usable, not photorealistic.
- Dartboard segment layout: segments are arranged clockwise starting from the top: 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5. This is the standard darts clockface ordering.
- Ring order from centre outward: double bull (innermost), single bull, triple ring, single (large), double ring (outermost scored area), miss area.
- For `doublesOnly == true`, highlight only the outermost scored ring for the target segment.
- Spec references: `EPIC-007-practice-modes.md` §"Shared Practice Board UI" ("Visual dartboard highlight: the current target segment glows").

---
