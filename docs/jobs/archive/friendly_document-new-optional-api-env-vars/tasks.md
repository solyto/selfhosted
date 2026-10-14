# Tasks: document new optional API env vars

id: friendly
analyst: @analyst
date: 2026-10-14

<!-- Produced by @analyst from brief.md. -->

## Context checked before planning

- Branch: worktree HEAD is `refs/heads/feature/friendly_document-new-optional-api-env-vars`,
  which matches `brief.md`.
- Upstream API behaviour, read from the GitHub commits on solyto/api:
  - **`c5f3b99` (`MIN_CLIENT_VERSION`):** read as `app.min_client_version`, default `null`.
    Unset or empty turns the check off. Header `X-Client-Version` is compared with
    `version_compare(header, min, '<')`, so `1.0.9 < 1.0.10`. Rejection is HTTP 426
    "Please update the app." with `meta.min_client_version`. A missing or invalid header
    is allowed. The check only applies to routes behind `auth:sanctum`; `health` and
    `auth/login` are not affected. It runs *before* auth, so an outdated client with a
    bad token gets 426, not 401.
  - **`fb9b5d1` (`API_TRAFFIC_ALERT_THRESHOLD` = 300, `API_TRAFFIC_ALERT_COOLDOWN` = 3600 s):**
    - Counts are per user, over a 60-second window, for authenticated requests only.
    - The middleware only observes. It never blocks or slows a request.
    - The threshold is requests **per minute** per user. The brief doesn't say this.
    - Alerts go out **only via ntfy** (`NtfyChannel`; no mail or Telegram). Each alert
      also writes one warning line to `storage/logs/traffic.log` with `user_id`,
      `count` and `route`.
    - The cooldown is per user.
- **ntfy is not wired up in this repo yet.** `compose.yml` has no `NTFY_*` vars or
  secrets, and that work is a separate backlog item (`docs/backlog/ntfy-notifications.md`).
  Until it lands, self-hosters only get the `traffic.log` line, not a push alert. The
  docs must not promise admin notifications.
- **Sandbox caveat for `.env`:** in the agent sandbox, `/workspace/.env` is masked
  (0 bytes, a `/dev/null` mount; see `docs/reports/email-confirmation-default.md` and
  the archived jobs). An agent cannot read or edit the real committed `.env` here.
  Any `.env` edit has to be made outside the sandbox or by a human.

## Open questions (need owner input)

1. **Q1 (brief: "Undecided"):** should the vars go into `.env`, or only into the
   README? If into `.env`, should they be commented out or set to their defaults?
   This blocks TASK-3 only.
   - Analyst suggestion, not a decision: add them commented out. Then `.env`
     shows they exist but doesn't pin defaults. That fits "out of scope: changing
     defaults", because a value in `.env` would override future upstream default
     changes.
2. **Q2:** what version string does `solyto/app` send in `X-Client-Version`? It may
   match `SOLYTO_VERSION`. The `PATTERN` regex isn't in the diff. The README example
   needs a realistic value and a warning: setting it above the deployed `app`
   version would lock out every user of the current app. Not verified.
3. **Q3:** should the README say that `auth/logout`, `refresh` etc. are also blocked
   below the minimum? The upstream commit lists this as an open point for its owner.
   I suggest documenting today's behaviour only: "requests to logged-in endpoints".

## Task breakdown

TASK-1: Add a README section for `MIN_CLIENT_VERSION`. Cover what it does (426 for
        logged-in requests whose `X-Client-Version` is below the minimum). Say that
        requests without the header are always allowed, that empty/unset means off
        (the default), and give an example value. Also warn about locking out users
        when it is set above the deployed app version.
     files: README.md (Setup section; suggest a new optional step after
            "7. Configure security (optional)", e.g. "8. Configure API guards
            (optional)", and renumber "Start" / "Create first user" to 9 / 10)
     depends: none (the example value depends on Q2; use a neutral placeholder
              like `1.2.0` if Q2 isn't answered)
     risk: low — docs only, but wrong wording could lead an operator to lock out
           clients, so keep the lock-out warning.

TASK-2: In the same README section, document `API_TRAFFIC_ALERT_THRESHOLD`
        (default `300` requests per user **per minute**) and
        `API_TRAFFIC_ALERT_COOLDOWN` (default `3600` seconds, per user). Say that
        requests are never blocked, and that each alert is written to
        `storage/logs/traffic.log`. Say that push alerts need ntfy, which this repo
        doesn't wire up yet. Do not claim the alerts arrive via mail or Telegram.
     files: README.md
     depends: TASK-1 (same section, avoids conflicting edits and renumbering twice)
     risk: low — docs only; the main risk is over-promising notifications, which is
           covered above.

TASK-3: **BLOCKED on Q1. Do not implement until the owner decides.** Add the three
        vars to `.env` in their own block next to the existing Security block (the
        committed `.env` has `PASSWORD_MIN_LENGTH` / `PASSWORD_UNCOMPROMISED` /
        `EMAIL_CONFIRMATION` around lines 32–34). Use the format decided in Q1, with a
        one-line comment per var, and don't change any default values.
     files: .env
     depends: Q1 answered; TASK-1/TASK-2 (keep wording consistent)
     risk: medium — the file is masked in the agent sandbox, so it can't be edited
           or verified there, and setting values (instead of commenting them out)
           would pin defaults on existing installs.

## Out of scope (from brief, plus what I noticed)

- Changing any default.
- Wiring up ntfy in `compose.yml` / `setup.sh` / `.env`. That is
  `docs/backlog/ntfy-notifications.md`. When that job lands, the TASK-2 sentence
  "ntfy is not wired up yet" needs updating; the developer should note this as a
  follow-up.
- `compose.yml` and `setup.sh`: no changes needed. All three are plain env vars that
  reach `api`/`queue` through `env_file: .env`, with no secrets involved.

## Verification

- TASK-1/2: read the rendered README Markdown (no browser needed). Check that the
  step numbering is still continuous and that the defaults match the upstream ones
  above.
- TASK-3: `git diff .env` outside the sandbox. Only additions are allowed, and
  existing lines must not change.
