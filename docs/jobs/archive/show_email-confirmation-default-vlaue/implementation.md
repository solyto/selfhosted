# Implementation: EMAIL_CONFIRMATION  default vlaue

id: show
developer: @developer
date: 2026-10-14

## Summary

Wrote a report that answers the brief's question ("Should EMAIL_CONFIRMATION
default to false?"). It recommends defaulting to `false`, together with clearer
README/`.env` docs. No configuration was changed.

## Changes

TASK-1: Read-only fact gathering from `.env` (committed version), `README.md`,
`compose.yml`, `setup.sh` and git history. Nothing to commit. The facts are in
section 1 of the report, and application behaviour I couldn't verify is listed
separately in section 2. Checked the "empty .env" discrepancy: in the sandbox,
`.env` is a `/dev/null` character device mounted over the real file. That is
an artifact of the environment, not a real change, and it was left untouched.

TASK-2: Added `docs/reports/email-confirmation-default.md`. It covers current
state, the problem, options A–D with pros/cons (including security/abuse), the
recommendation and open questions Q1–Q5 for the app maintainers.

## Known issues / follow-ups

- Follow-up (needs decision): set `EMAIL_CONFIRMATION=false` in `.env` and
  `README.md:198`, and add a note in README sections 6/7 that confirmation
  requires working mail.
- Optional: have `setup.sh` ask about mail; support generic SMTP (needs changes
  in `compose.yml` and the application image).
- `git status` shows `.env` as modified only because of the sandbox
  `/dev/null` mount. It can't be committed and isn't part of this job.
