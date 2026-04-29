# Security Policy

## Supported versions

Only the latest commit on `main` (and the most recent tagged release, if any)
receives security fixes. Older versions are not maintained — please upgrade
before reporting issues.

## Reporting a vulnerability

**Do not open public issues for security bugs.**

Please report vulnerabilities privately through GitHub's private vulnerability
reporting:

1. Go to the **Security** tab of this repository.
2. Click **Report a vulnerability**.
3. Provide a description, reproduction steps, and the affected version /
   commit.

This creates a private thread visible only to maintainers, so the issue can be
triaged and fixed before any public disclosure.

## What to expect

This is a solo-maintained open-source project, so triage is best-effort —
there is no formal response SLA. I will acknowledge reports as soon as I am
able and work in the open from there. Coordinated disclosure is appreciated:
please give me a reasonable window to ship a fix before publishing details.

## Scope

In scope:

- The Flutter app (`lib/`, `test/`)
- Build / CI configuration (`.github/workflows/`, `tools/`)
- Local persistence (sqflite, drift web)
- Crash reporting integration (Sentry)

Out of scope:

- Vulnerabilities in upstream dependencies — please report those to the
  respective projects (Flutter SDK, sqflite, drift, sentry-dart, etc.). I'll
  pick up fixes once they're released upstream, tracked via Dependabot.
- Self-hosted backends sketched in `docs/BACKEND_INTEGRATION.md` — that
  integration is not implemented in this repository.
