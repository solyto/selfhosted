# Verdict: EMAIL_CONFIRMATION  default vlaue

id: show
reviewer: @reviewer
date: 2026-10-14

## Review

Base: `main` (no `.manigot/manigot.json`). Reviewed `git diff main...HEAD`.

TASK-1: PASS
notes: Read-only task, nothing to commit. I re-checked every cited fact against
the committed files and they are accurate:
- `git show HEAD:.env` l.32-34: `PASSWORD_MIN_LENGTH=12`, `PASSWORD_UNCOMPROMISED=true`,
  `EMAIL_CONFIRMATION=true`. l.75-77: `MAILGUN_DOMAIN=`, `MAIL_FROM_ADDRESS=`,
  `MAIL_FROM_NAME=` are empty. No `MAIL_MAILER`. Commit `ba762d2` matches.
- README l.149 (Mailgun secret "if you need email functionality"), l.181-189
  (mail optional, Mailgun only), l.191-199 (security flags), l.207-211 (`users:create`).
- compose.yml l.90/180 (`MAILGUN_SECRET_FILE` only), l.340-341, l.159 (`--tries=3`),
  `public` network on both services.
- setup.sh l.19-30 (asks only for domains and the ACME email), l.90 (empty `mailgun_secret`).
The `.env` discrepancy was looked into and explained (a sandbox `/dev/null` mount),
and the file was left untouched, as tasks.md asked.

TASK-2: PASS
notes: `docs/reports/email-confirmation-default.md` covers everything tasks.md
asks for: current state (§1), the problem, options A–D with pros/cons including
security/abuse (§3), a recommendation (§4), and open questions Q1–Q5 (§5).
Application behaviour that can't be checked from this repo is kept apart from
the facts (§2) and is labelled as assumptions. Nothing is stated as fact that
the repo can't back up. No config, README or `.env` changes were made, which
matches the out-of-scope section.

Scope note: the diff also adds an empty `docs/CLAUDE.md` (0 bytes, created
17:32 UTC during the analyst session and swept in by the auto-commit `be48cfa
[show] chore: commit all`). It isn't in tasks.md or implementation.md. It looks
like a tooling/session artifact rather than developer work. It has no runtime
impact, so I'm not counting it as a blocker, but whoever runs `mg done` should
confirm it's meant to land on `main`, or drop it.

## Security

None. Documentation-only change. The report discusses the security trade-off
of `false` (unverified addresses, abuse on open-registration instances) fairly.

## Overall

APPROVED

No blockers. The report answers the brief's question with a sourced, accurate
recommendation and clearly marked open questions.
