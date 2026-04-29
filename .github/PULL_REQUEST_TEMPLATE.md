<!-- Thanks for contributing! Keep this PR focused on a single concern. -->

## Summary

<!-- 1-3 sentences describing what changed and why. -->

## Related issue

<!-- "Closes #123" or "Refs #123". Required unless this is a one-line fix. -->

## Test plan

<!-- How did you verify this works? -->

- [ ] `flutter analyze` passes locally
- [ ] `flutter test` passes locally
- [ ] Manually tested on …  <!-- web / Android / iOS — at least one -->

## Checklist

- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] If schema or repository code changed: both the sqflite and drift implementations are in sync, and tests pass on both
- [ ] If a new game event type was added: documented in `docs/GAME-EVENT-SPECIFICATIONS.md`
- [ ] If statistics logic changed: both statistics repositories (sqflite + drift) and `ComputeLegStatsUseCase` were updated together
- [ ] No statistics persisted to the database (statistics are projections only)
- [ ] No `domain/` layer file imports `flutter`, `drift`, `sqflite`, or `dio`

## Screenshots (UI changes only)

<!-- Drag in before/after screenshots or screen recordings. -->
