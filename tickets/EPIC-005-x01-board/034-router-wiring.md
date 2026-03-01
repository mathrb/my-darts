# TICKET-034: Router Wiring

**Status:** Todo
**Epic:** EPIC-005 — X01 Game Board

---

## Description

Replace the placeholder `_x01BoardPage` builder in `lib/app/app_router.dart` with the real `X01BoardPage`. The route already exists from EPIC-004; only the builder implementation changes. This is the final integration step that makes the complete X01 game flow reachable end-to-end.

Depends on: TICKET-033 (`X01BoardPage`).

---

## Acceptance Criteria

- [ ] `lib/app/app_router.dart` imports `X01BoardPage` from `lib/features/game/presentation/pages/x01_board_page.dart`
- [ ] The `_x01BoardPage` builder (or equivalent inline builder for the X01 route) passes `gameId` from `GoRouterState.pathParameters['gameId']!` to `X01BoardPage`
- [ ] The placeholder `Scaffold` / `Center(child: Text('X01 Board — coming in EPIC-005'))` is removed
- [ ] No other route builders are changed
- [ ] `build_runner` regenerates without errors (if any generated router files exist)
- [ ] All existing tests (301 + TICKET-028 additions) still pass
- [ ] Manual smoke test: completing the game setup flow navigates to `/game/active/x01/<uuid>` and renders the `X01BoardPage` with a loading spinner followed by the game board

---

## Files

- `lib/app/app_router.dart` — **to modify** (replace stub builder + add import)

---

## Implementation Notes

- The path parameter name is `gameId` — confirm the exact parameter key against the existing route definition in `app_router.dart` before writing `s.pathParameters['gameId']!`.
- Use the null-assertion `!` only after confirming the route pattern guarantees the parameter is always present (it should be, as the route is `/game/active/x01/:gameId`).
- If the router uses a `GoRoute` with `builder:` (not `pageBuilder:`), the replacement is a one-liner:
  ```dart
  builder: (_, s) => X01BoardPage(gameId: s.pathParameters['gameId']!),
  ```
- Spec references: `docs/UI_SCREEN_FLOWS_V3_FINAL.md` §"Navigation and Routing".

---
