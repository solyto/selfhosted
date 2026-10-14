# Tasks: EMAIL_CONFIRMATION  default vlaue

id: show
analyst: @analyst
date: 2026-10-14

<!-- Produced by @analyst from brief.md. -->

## Scope

The brief asks a question ("Should we make this false?") and asks for a **report in
`docs/reports/`**. It does not ask for the default to be changed. So the job delivers
a written report with a recommendation. Actually changing the default is only listed
below as a possible follow-up, and it stays out of scope until a human decides.

## Findings from reading the repo (input for the developer)

- `README.md:191-199` ("7. Configure security (optional)") documents
  `EMAIL_CONFIRMATION=true` next to `PASSWORD_MIN_LENGTH=12` and
  `PASSWORD_UNCOMPROMISED=true`.
- Upstream `.env` (github.com/solyto/selfhosted, `main`) ships
  `EMAIL_CONFIRMATION=true` and leaves `MAILGUN_DOMAIN=`, `MAIL_FROM_ADDRESS=` and
  `MAIL_FROM_NAME=` empty. So on a fresh install, confirmation is on but mail is
  not set up.
- **Discrepancy:** in this worktree, `/workspace/.env` is **empty** (0 bytes), which
  doesn't match upstream. The developer should check this (git status/diff) and note
  it in the report. Don't "fix" it as part of this job.
- Mailgun is the only mail transport wired up: `compose.yml` passes only
  `MAILGUN_SECRET_FILE` to `api` (l.90) and `queue` (l.180). `setup.sh:90`
  creates an empty `mailgun_secret`. README section 6 calls mail "optional".
- `setup.sh` never asks about mail or `EMAIL_CONFIRMATION`.
- First user is created via the CLI (`docker exec -it solyto-api so users:create`,
  README l.207-211).
- **Unclear / not in this repo:** what the app actually does with
  `EMAIL_CONFIRMATION` lives in the `solyto/api-php` / `solyto/app` images, not in
  this repo. From here I can't tell whether (a) self-registration exists, (b)
  `users:create` skips confirmation, (c) unconfirmed users get locked out or just
  see a banner, or (d) the app falls back to something (e.g. the `log` mailer) when
  Mailgun is empty. The report must mark these as open questions/assumptions and
  must not state them as fact.

## Task breakdown

TASK-1: Collect the facts the report needs (where the default is set, which mail transports are supported, what happens with confirmation on and mail not configured), and keep verified facts separate from open questions.
     files: README.md, .env (and upstream .env), compose.yml, setup.sh — read-only
     depends: none
     risk: low — read-only; the main risk is stating application behaviour that this repo can't verify.

TASK-2: Write the report `docs/reports/email-confirmation-default.md`. Cover: current state, the problem (Mailgun-only, mail optional and empty by default → users may never get a confirmation email), options (keep `true`; default to `false`; keep `true` but document/warn more clearly; tie it to whether mail is configured), pros and cons including security/abuse trade-offs, a recommendation, and open questions for the application maintainers.
     files: docs/reports/email-confirmation-default.md (new; `docs/reports/` does not exist yet)
     depends: TASK-1
     risk: low — new documentation file only; no runtime impact.

## Out of scope (possible follow-up, needs a human decision after the report)

- Changing the default to `EMAIL_CONFIRMATION=false` in `.env` and `README.md:198`,
  and/or adding a note in README sections 6/7 that confirmation requires working mail.
  Don't do this in this job: the brief only asks for a report.
- Supporting mail transports other than Mailgun (e.g. generic SMTP). That would need
  changes in `compose.yml` and very likely in the application image.
