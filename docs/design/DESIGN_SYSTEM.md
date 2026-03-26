# Design System — my-darts

**Theme name:** Dual-Tone Performance Framework
**Last updated:** 2026-03-23
**Status:** Active specification

---

## 1. Overview & Creative North Star

The "Creative North Star" of this design system is **Technical Kineticism**.

This is a "two-speed" experience designed to mirror the psychology of a darts player: the surgical, high-adrenaline focus of the throw (Match Mode) and the calm, analytical reflection of the clubhouse (Admin/Nav Mode). We break the "template" look by oscillating between aggressive, sharp-edged brutalism and soft, high-end editorial layouts.

- **Match Boards:** "Brutalist Precision." Zero-radius corners, high-contrast neon accents, and oversized typography that feels like a broadcast scoreboard.
- **Admin/Nav:** "Soft Luxury." 16px+ radii, generous whitespace, and tonal layering that feels like a premium Swiss watch application.

### P1 — The No-Line Rule
Standard 1px borders are strictly prohibited for sectioning. To define boundaries:
- **Tonal Shifts:** Place a `surfaceContainerLow` card against a `surface` background.
- **Negative Space:** Use the Spacing Scale (`spacing-8` to `spacing-12`) to create structural "voids" that act as invisible dividers.

### P2 — Sharp / Soft Hybrid
Only use `radiusNone` (0dp) in Match Board components. Use `radiusXLarge` (24dp) or `radiusFull` (pill) for everything in Admin/Nav. Avoid the "uncanny valley" of 4px or 8px corners.

### P3 — State is Always Visible
The active player, current score, darts thrown this turn, and remaining outs are always on screen during play. Status is conveyed by color and position — never by icon alone.

---

## 2. Color Tokens

### 2.1 Palette

The palette is rooted in `surface` (#0c0e10), providing a deep, obsidian base that allows the neon `primaryContainer` (#00FFAB) to vibrate with intensity.

| Token | Hex | Usage |
|---|---|---|
| `surface` | `#0c0e10` | App scaffold background — Level 0 base |
| `surfaceDim` | `#0a0c0e` | Match Mode deepest background |
| `surfaceContainerLowest` | `#0a0c0e` | Most inset / Match Mode dark cells |
| `surfaceContainerLow` | `#111416` | Level-1 sections |
| `surfaceContainer` | `#171a1c` | Level-2 interactive cards |
| `surfaceContainerHigh` | `#1e2124` | Intermediate elevation |
| `surfaceContainerHighest` | `#242729` | Score input buttons (Match Mode) |
| `surfaceBright` | `#292c30` | Level-3 popovers / floating elements |
| `primary` | `#afffd1` | Primary action text / icons |
| `onPrimary` | `#002112` | Text on `primary` backgrounds |
| `primaryContainer` | `#00ffab` | Brand neon — CTA fills, active player accent |
| `onPrimaryContainer` | `#002112` | Text on `primaryContainer` |
| `onPrimaryFixed` | `#002112` | Text on any neon fill — 8.9:1 contrast |
| `primaryFixed` | `#00ffab` | Admin primary button fill |
| `primaryFixedDim` | `#00e297` | Hover / pressed neon state |
| `primaryDim` | `#00cc88` | Graph gradient stroke end |
| `onSurface` | `#eeeef0` | Primary body text and icons |
| `onSurfaceVariant` | `#8f9193` | Secondary labels, metadata, placeholder text |
| `outlineVariant` | `#46484a` | Ghost border at 20% opacity only — see No-Line Rule |
| `outline` | `#46484a` | Structural outlines when required |
| `error` | `#cf6679` | Bust indicator, validation errors |
| `onError` | `#000000` | Text on error-colored backgrounds |
| `errorContainer` | `#370b0a` | Bust snackbar background, error cards |
| `onErrorContainer` | `#ffcdd2` | Text inside error container |
| `scrim` | `#000000` | Modal backdrop at 80% opacity + 20px backdrop-blur |

### 2.2 Surface Hierarchy & Nesting

Treat the UI as physical layers of "Obsidian Glass."

| Level | Token | Hex | Role |
|---|---|---|---|
| **0 — Base** | `surface` | `#0c0e10` | Global scaffold background |
| **1 — Sections** | `surfaceContainerLow` | `#111416` | Distinct content zones / sections |
| **2 — Cards** | `surfaceContainer` | `#171a1c` | Interactive cards, inputs |
| **3 — Popovers** | `surfaceBright` | `#292c30` | Floating elements, modals |

`surfaceContainerHigh` and `surfaceContainerHighest` sit between Level 2 and Level 3 and are used for score input buttons (Match) and axis ticks (graphs) respectively. `surfaceContainerLowest` sits below Level 0 — reserved for the deepest Match Mode backgrounds.

### 2.3 Glass & Gradient Rule

For CTAs and hero moments, move beyond flat hex codes. Apply a **15% linear gradient** from `primary` (`#afffd1`) to `primaryContainer` (`#00ffab`) at a **135° angle**. This adds a "lithium-ion" glow to gameplay elements.

For overlays: use `scrim` (`#000000`) at **80% opacity** + **20px backdrop-blur**.

### 2.4 The "Ghost Border" Fallback

If contrast is required for accessibility, use a "Ghost Border": `outlineVariant` (`#46484a`) at **20% opacity**. Never use 100% opacity.

### 2.5 Semantic Aliases (game-specific)

| Token | Resolves to | Meaning |
|---|---|---|
| `activePlayerBg` | `surfaceContainerLow` (`#111416`) | Panel background tint for active player |
| `inactiveScore` | `outlineVariant` (`#46484a`) | Score numeral for non-active players |
| `cricketClosed` | `primaryContainer` (`#00ffab`) | Cricket number closed indicator |
| `win` | `primary` (`#afffd1`) | Win banner, end-game highlight |
| `winContainer` | `surfaceContainerLow` (`#111416`) | Win screen card background |

---

## 3. Typography Tokens

### 3.1 Font Families

| Family | Weight used | Source | Purpose |
|---|---|---|---|
| **Space Grotesk** | Medium (500), Bold (700) | `google_fonts` | Display, headlines, labels — geometric, technical ("Oche Precision") |
| **Inter** | Regular (400), SemiBold (600) | `google_fonts` | Body text, titles — neutral clarity for admin / data density |

Fallback stack: `system-ui, sans-serif`

### 3.2 Type Scale

| Token | Family | Weight | Size | Line height | Letter spacing | Usage |
|---|---|---|---|---|---|---|
| `display-lg` | Space Grotesk | Medium (500) | 3.5rem / 56px | 1.1 | -0.02em | Live scores in Match Mode, hero numerals |
| `headline-md` | Space Grotesk | Bold (700) | 1.75rem / 28px | 1.2 | 0 | Screen titles. Match Mode: ALL CAPS + `tracking-tighter` |
| `title-md` | Inter | SemiBold (600) | 1.125rem / 18px | 1.4 | 0 | Subsection labels, player names in scoreboard |
| `body-md` | Inter | Regular (400) | 0.875rem / 14px | 1.5 | 0 | All administrative data, list descriptions |
| `label-md` | Space Grotesk | Bold (700) | 0.75rem / 12px | 1.3 | 0.05em | Button text, chips, tab labels — ALL CAPS |
| `label-sm` | Space Grotesk | Bold (700) | 0.6875rem / 11px | 1.45 | 0.05em | Over-line text above a headline. Use `primaryFixed` color to ground the technical feel. |

**Game-specific score tokens:**

| Token | Family | Weight | Size | Usage |
|---|---|---|---|---|
| `textScoreActive` | Space Grotesk | Bold (700) | 80px | Active player score |
| `textScoreInactive` | Space Grotesk | Bold (700) | 56px | Inactive player scores |
| `textScoreMedium` | Space Grotesk | Bold (700) | 48px | Post-game summary, leaderboard top |
| `textScoreSmall` | Space Grotesk | Bold (700) | 36px | History list scores, stat cards |
| `textSegmentButton` | Inter | SemiBold (600) | 18px | Dart segment grid button numbers |
| `textMultiplierLabel` | Inter | Medium (500) | 11px | "DBL" / "TRP" labels on segment buttons |

### 3.3 Usage Rules

- `headline-md` in Match Mode must use ALL CAPS and `tracking-tighter` (`letter-spacing: -0.02em`). Apply via `toUpperCase()` on the string — do not rely on CSS `text-transform`.
- `title-md` (player names in scoreboard) must also render in ALL CAPS.
- `label-md` is the correct token for all interactive control labels — buttons, chips, tab labels.
- `label-sm` in `primaryFixed` color is used for "over-line" text (small text above a headline).
- Minimum rendered size is 11px. Never go below this.
- Score numerals must never truncate or wrap. Constrain the container width, not the text size.
- Never mix Space Grotesk and Inter within the same UI element (e.g. a single label line).

---

## 4. Spacing Scale

Base unit: **4dp**

| Token | Value | Usage |
|---|---|---|
| `space1` | 4dp | Minimum internal padding — icon gap, tight chip padding |
| `space2` | 8dp | Compact padding — list tile vertical padding, small gaps |
| `space3` | 12dp | No-divider gap between list items (replaces 1px lines) |
| `space4` | 16dp | Standard content padding (horizontal page margin) |
| `space5` | 20dp | Card internal padding (top/bottom) |
| `space6` | 24dp | Section spacing within a screen |
| `space8` | 32dp | Section headers below previous content |
| `space10` | 40dp | Large visual break between major layout regions |
| `space12` | 48dp | Empty state illustration margin |
| `space16` | 64dp | Bottom padding for scrollable content above nav bar |

**Asymmetric spacing (Admin screens):** Use `spacing-16` (64dp / 3.5rem) for top padding and `spacing-8` (32dp) for sides to create a "gallery" feel.

**Page horizontal margin:** `space4` (16dp) on both sides.
**Bottom safe area:** All scrollable content must include `space16` (64dp) bottom padding.

---

## 5. Elevation & Depth

### Tonal Layering (Admin views)

Avoid shadows in Admin views. Instead, stack `surfaceContainerLowest` components inside `surfaceContainerHigh` regions to create an "inset" look. Hierarchy is expressed through tonal stepping alone — never through drop shadows or borders.

### Ambient Shadows (Match Mode modals)

For floating Match Mode modals, use an "Aura Shadow":
- **Color:** `onSurface` (`#eeeef0`) at **6% opacity**
- **Blur:** 40px–60px
- **Spread:** -10px

This mimics the soft glow of a dartboard spotlight rather than a digital drop shadow.

### The "Ghost Border" Fallback

If contrast is required for accessibility on a floating element, use a "Ghost Border": `outlineVariant` (`#46484a`) at **20% opacity**. Never use 100% opacity.

---

## 6. Shape Tokens

### Dual-Mode Radius System

| Token | Value | Context | Notes |
|---|---|---|---|
| `radiusNone` | 0dp | **Match Boards only** | Score inputs, active player cards, progress bar ends |
| `radiusLarge` | 16dp | Admin cards, stats cards | Standard "Soft Luxury" card radius |
| `radiusXLarge` | 24dp | Admin primary buttons | Large CTA feel |
| `radiusFull` | 9999dp | Selection chips, pill buttons | Fully rounded |

**Rule:** Only use `radiusNone` in Match Board components. Use `radiusLarge` / `radiusXLarge` / `radiusFull` for everything in Admin/Nav. Never use 4dp or 8dp — these are the "uncanny valley" of corner radii.

---

## 7. Components

### 7.1 Match-Speed Components (Brutalist Precision)

*Designed for high-contrast, peripheral-vision readability.*

**Score Input Buttons**
- Border-radius: `radiusNone` (0dp)
- Background: `surfaceContainerHighest` (`#242729`)
- Text: `primary` (`#afffd1`)
- No shadow

**Active Player Card**
- Border-radius: `radiusNone` (0dp)
- Left edge: 4dp solid `primaryContainer` (`#00ffab`) — "strike bar"
- Background: `activePlayerBg` (`surfaceContainerLow` / `#111416`)

**The "Oche" Progress Bar**
- Height: 2px line across the top of the Match Board
- Color: `primaryContainer` (`#00ffab`)
- No rounded ends (`radiusNone`)
- Animation: linear fill only

### 7.2 Admin-Speed Components (Soft Luxury)

*Designed for tactile comfort and high-end feel.*

**Primary Action Button**
- Border-radius: `radiusFull` (pill) or `radiusXLarge` (24dp)
- Background: `primaryFixed` (`#00ffab`) — or glass/gradient variant (see §2.3)
- Text: `onPrimaryFixed` (`#002112`) — `label-md`, ALL CAPS
- Padding: 14dp vertical, 24dp horizontal
- No shadow

**Stats Cards**
- Border-radius: `radiusLarge` (16dp)
- Background: `surfaceContainerLow` (`#111416`)
- No borders — tonal background provides hierarchy

**Selection Chips**
- Border-radius: `radiusFull` (pill)
- Unselected: `surfaceContainerHighest` background, `onSurfaceVariant` text
- Selected: `primaryContainer` background, `onPrimaryContainer` text

**Secondary Button**
- Background: transparent
- Border: Ghost Border — `outlineVariant` at 20% opacity
- Text: `onSurface` (`#eeeef0`) — `label-md`, ALL CAPS
- Border-radius: `radiusXLarge` (24dp)
- Padding: 14dp vertical, 24dp horizontal

**Input Fields**
- Background: `surfaceContainerLow` (`#111416`)
- Border-radius: `radiusLarge` (16dp) in admin; `radiusNone` in match
- Focus indicator: 2dp bottom bar in `primary` (`#afffd1`) expanding from center
- Label: `label-sm` — Space Grotesk Bold, ALL CAPS — at 60% opacity (unfocused), 100% (focused)

### 7.3 Performance Graph

- Plot area: `surfaceContainerLow` background
- Trend line: gradient stroke from `primary` (`#afffd1`) to `primaryDim` (`#00cc88`)
- No grid lines — use `surfaceContainerHigh` for axis ticks only

### 7.4 Overlays & Modals

- Backdrop: `scrim` (`#000000`) at **80% opacity** + **20px backdrop-blur**
- Sheet / dialog surface: `surfaceBright` (`#292c30`)
- Border-radius: `radiusXLarge` (24dp) for admin modals; `radiusNone` for match modals
- Entry animation: slide up 200ms `easeOut`; dismiss: slide down 200ms `easeIn`
- Aura Shadow applied (see §5 Elevation & Depth)

---

## 8. Do's and Don'ts

### Do

- **Asymmetric Spacing (Admin):** Use `spacing-16` for top padding and `spacing-8` for sides for a "gallery" feel.
- **Sharp/Soft Hybrid:** Only use `radiusNone` in the Match Board. Use `radiusXLarge` / `radiusFull` for everything else.
- **Typographic Hierarchy:** Use `label-sm` in `primaryFixed` color for over-line text to ground the technical feel.
- **No-Line Separation:** Replace dividers with a 12dp gap (`space3`) or a subtle `surface` → `surfaceContainerLow` tonal shift.
- Apply `primaryContainer` (`#00ffab`) as the single brand neon accent.
- Use the ghost border (`outlineVariant` at 20% opacity) only when tone alone cannot provide a boundary.
- Use the 4dp `primaryContainer` strike bar on the left edge of a card for "active" / "selected" state.

### Don't

- **No 1px Lines:** Never use a line to separate list items. Use a 12dp gap or a tonal surface shift.
- **No Pure Black:** Avoid `#000000` except for `surfaceContainerLowest` in Match Mode. Use `surface` (`#0c0e10`) as the main canvas to maintain depth.
- **No Standard Radii:** Avoid the "uncanny valley" of 4dp or 8dp corners. Stick to the extremes: `radiusNone` (Match) or `radiusLarge` / `radiusXLarge` / `radiusFull` (Admin).
- Don't use `primaryContainer` (`#00ffab`) as text color on dark backgrounds — pair it with `onPrimaryContainer` (`#002112`) on neon fills.
- Don't use `outlineVariant` at full (100%) opacity.
- Don't add shadows beyond the Aura Shadow spec (§5).
- Don't mix Space Grotesk and Inter within the same UI element.

---

## 9. Minimum Tap Target Rules

**Absolute minimum:** 48×48dp for any interactive element.

| Element | Minimum touch target | Recommended visual size |
|---|---|---|
| Segment cell — 3-cell bar (Practice 3-button types, Cricket input) | 56dp height × ⅓ row width | 56dp height |
| Segment cell — 10-column grid (X01, Catch-40, Checkout Practice) | 48dp height × ~39dp width | 48dp height; width = screen width ÷ 10 |
| Undo / correction button | 48×48dp | 44×36dp visual, 48dp touch |
| Chip / filter pill | 48dp height × auto width | 36dp visual height |
| Player row in selection list | 56dp height | 56dp |
| Bottom sheet drag handle | 48×48dp centered tap area | 4×32dp visual bar |
| Dialog action button | 48dp height | 40dp visual |
| FAB (start game) | 56×56dp | 56×56dp |

**Game board special rules:**

**3-cell bar:** cells expand to one-third of available width. Minimum 56dp height. No exception.

**10-column contiguous grid** (X01 Board, Catch-40, Checkout Practice): 10 cells per row keeps all 20 numbers in 2 rows per tier. On a 390dp device this yields ~39dp cell widths — an **accepted exception** because cells are densely packed with no gaps, and minimum cell height is 48dp. Every cell must carry a full `semanticsLabel`.

---

## 10. Interactive States

### 9.1 Pressed State

Ripple color: `onSurface` at 12% opacity. No scale transforms — avoid "pop" animations during rapid dart entry.

**Kinetic Shift:** Primary buttons offset **2px up and 2px right** on press. Background shifts to `primaryFixedDim` (`#00e297`).

### 9.2 Focused State (keyboard / accessibility)

2dp outline in `primaryContainer` (`#00ffab`) with 2dp offset. Never use the browser default outline style.

### 9.3 Disabled State

- Opacity: 38% on the element's normal foreground color.
- Background: `surfaceContainerHighest`.
- No ripple. Always include a `Tooltip` explaining why disabled.

### 9.4 Active Player Highlight

Active player panel:
- Left border: 4dp solid `primaryContainer` (`#00ffab`)
- Background: `activePlayerBg` (`surfaceContainerLow` / `#111416`)
- Score numeral: `textScoreActive` in `primary` (`#afffd1`)
- Player name: `title-md` in `onSurface`, ALL CAPS

All other player panels:
- No left border
- Background: `surface`
- Score numeral: `textScoreInactive` in `inactiveScore` (`outlineVariant`)
- Player name: `title-md` in `onSurface` at 60% opacity

### 9.5 Bust Feedback

1. Snackbar: `errorContainer` background, `onErrorContainer` text, "BUST" in `headline-md`.
2. Auto-dismisses after 2 seconds.
3. Active player panel flashes `error` left border once (300ms in, 500ms hold, 300ms out).
4. No full-screen overlay — scoreboard remains readable throughout.

### 9.6 Win State

1. Full-screen win banner slides up from bottom (covers game board).
2. Winner name in `display-lg`, `win` color.
3. Two actions: "Post-Game Summary" (primary) and "Play Again" (secondary).

### 9.7 Loading State

Centered `CircularProgressIndicator` in `primary`. Sits on `surface`. List skeletons (shimmer placeholders) for history list initial load.

---

## 11. Animation Guidelines

- **Duration:** 200ms for micro-interactions. 350ms for page transitions and panel expansions.
- **Easing:** `easeInOut` for symmetric animations. `easeOut` entering. `easeIn` leaving.
- **Score update:** Counter rolldown (250ms, linear) for active player score only. Inactive scores update instantly.
- **No decorative animations** during active gameplay. No particles, confetti, or idle animations.
- **Respect `MediaQuery.disableAnimations`.** All transitions collapse to instant when reduced motion is on.

---

## 12. Iconography

Use `material_symbols_outlined` (weight 300, opticalSize 24) for all icons.

| Icon | Usage |
|---|---|
| `sports_bar` or custom dartboard SVG | App icon, home page hero |
| `undo` | Undo last dart |
| `person` | Player |
| `leaderboard` | Statistics / leaderboard |
| `history` | Game history |
| `settings` | Settings |
| `add` | New player, add action |
| `edit` | Edit player |
| `delete` | Delete player (destructive — error tint) |
| `check_circle` | Checkout success, win |
| `error` | Bust, validation error |
| `arrow_back` | Navigation back |
| `close` | Dismiss dialog |
| `filter_list` | History filter |
| `expand_more` | Expandable sections |

All icons at 24dp visual size, 48dp touch target. Icon-only buttons must have a `Tooltip`.

---

## 13. Accessibility

- **Contrast ratios:** All text/background combinations meet WCAG 2.1 AA (4.5:1 body, 3:1 large text ≥18sp Bold).
- **Primary neon fill:** `primaryContainer` (`#00ffab`) must only carry text in `onPrimaryContainer` (`#002112`) — 8.9:1 contrast.
- **Score numerals** at 56px+ meet large-text threshold. `inactiveScore` (`outlineVariant` `#46484a`) on `surface` (`#0c0e10`) ≈ 3.5:1 — meets AA for large text. Active score (`primary` `#afffd1` on `surface`) = high contrast.
- **Semantic labels:** All `IconButton` and image elements include `semanticsLabel`.
- **Screen reader order:** Scoreboard panels announced in turn order (active player first). Segment grid announces as "Single [number]", "Double [number]", "Triple [number]".
- **Text scaling:** Layouts must not break at 1.4×. Score numerals may clip at 2.0× — accepted given sport context.

---

## 14. Implementation Files (Code Phase)

| File | Purpose |
|---|---|
| `lib/core/utils/app_colors.dart` | `AppColors` — all color token constants (dark-first) |
| `lib/core/utils/app_text_styles.dart` | `AppTextStyles` — Space Grotesk (display/headlines/labels) + Inter (body/titles) |
| `lib/core/utils/app_theme.dart` | `AppTheme.light()` / `AppTheme.dark()` — dark obsidian scheme; radius tokens (`radiusNone`, `radiusLarge`, `radiusXLarge`, `radiusFull`) |
| `lib/app/app.dart` | Default `themeMode` set to `ThemeMode.dark` |
