## Summary

Documented the three new optional solyto/api settings (`MIN_CLIENT_VERSION`,
`API_TRAFFIC_ALERT_THRESHOLD`, `API_TRAFFIC_ALERT_COOLDOWN`) in a new README
setup step, "8. Configure API guards (optional)". Owner decisions: Q1 = A
(commented out in `.env`), Q2 = example value `1.0.15`, Q3 = neutral wording
("logged-in endpoints", login and health check not affected).

`.env` is masked in the agent sandbox (a `/dev/null` mount), so TASK-3 can't be
done by an agent. The exact change is written down below for the owner to apply.

## Changes

TASK-1: `README.md`: added step 8, "Configure API guards (optional)", with a
"Minimum app version" part: HTTP 426 for logged-in requests from older apps,
login and health check not affected, empty/unset = off (the default), requests
without `X-Client-Version` are always allowed, numeric version comparison, and a
lock-out warning. Example value `1.0.15`. Renumbered "Start" and "Create first
user" to 9 and 10.

TASK-2: `README.md`: added a "Traffic alerts" part to the same step. Threshold is
requests per user per minute (default 300), cooldown is per user in seconds
(default 3600), requests are never blocked, each alert writes a line to
`storage/logs/traffic.log`, and push alerts need ntfy, which this repo doesn't
set up yet.

TASK-3: **manual step for the owner** (not done by an agent, because `.env` is
masked in the sandbox). In `.env`, add this block directly after the
`# Security` block (after `EMAIL_CONFIRMATION=true`, before `# Versions`),
with a blank line before and after it:

```env
# API guards (optional, leave commented out to use the API defaults)
# MIN_CLIENT_VERSION=1.0.15          # empty/unset = off; older apps get HTTP 426 on logged-in requests
# API_TRAFFIC_ALERT_THRESHOLD=300    # requests per user per minute before an alert is logged
# API_TRAFFIC_ALERT_COOLDOWN=3600    # seconds before the same user can trigger another alert
```

Then check it and commit it:

```sh
git diff .env          # only the 4 added lines plus a blank line; no existing line changed
git add .env
git commit -m "[friendly] TASK-3: add commented-out API guard vars to .env"
```

## Known issues / follow-ups

- solyto/api (not this repo): exempt `auth/logout` and token refresh from the
  `MIN_CLIENT_VERSION` check, so outdated clients can still sign out (owner
  confirmed this is wanted). The README wording stays correct either way.
- When `docs/backlog/ntfy-notifications.md` lands, update the README sentence
  "This repository doesn't set up ntfy yet…" in step 8 ("Traffic alerts").
- `git add -A` fails in the sandbox ("cannot hash .env") because of the masked
  `.env`, so commits in this job used explicit paths.
