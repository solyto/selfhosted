# Verdict: document new optional API env vars

id: friendly
reviewer: @reviewer
date: 2026-10-14

## Review

Base: `main` (there is no `.manigot/manigot.json`). Reviewed `git diff main...HEAD`.
Branch `feature/friendly_document-new-optional-api-env-vars` matches brief.md.
Outside the job directory, the only file changed is `README.md` (+33/−2).
`.env` is unchanged (`git diff main...HEAD -- .env` is empty; I read the
committed blob with `git show HEAD:.env`).

TASK-1: PASS
notes: README.md l.201–219 adds the new step "8. Configure API guards (optional)".
It covers everything tasks.md asks for:
- HTTP 426 for logged-in requests from older apps, and that login and the health
  check aren't affected (Q3 neutral wording).
- Empty or unset turns the check off, and this is the default.
- Requests without `X-Client-Version` are always allowed.
- Versions are compared numerically (`1.0.9` < `1.0.10`).
- The example value is `1.0.15` (Q2).
- It includes the lock-out warning.

"Start" and "Create first user" are renumbered to 9 and 10, so steps 1–10 run
without gaps. Nothing else in the repo refers to the old step numbers.

TASK-2: PASS
notes: README.md l.221–230. The threshold is described as per user per minute
(default 300) and the cooldown as per user, in seconds (default 3600). Both
defaults match the upstream values in tasks.md. It says that requests are never
blocked or slowed down, and that each alert writes a line to
`storage/logs/traffic.log` with the user ID, count and route. It says that push
alerts go only via ntfy, which this repo doesn't set up yet. It doesn't claim
mail or Telegram. No defaults were changed.

TASK-3: FAIL (not done; blocked by the sandbox, handed off to the owner)
notes: The owner answered Q1 with A (commented-out vars in `.env`), so this task is
in scope and the brief ("Expose ... in `.env` and `README.md`") requires it. The
branch has no `.env` change. `git show HEAD:.env` l.31–36 still goes straight from
`EMAIL_CONFIRMATION=true` to `# Versions`. The developer couldn't make the change
because `.env` is masked in the sandbox, and wrote the exact block plus commit
steps in implementation.md ("TASK-3: manual step for the owner"). I checked the
proposed block: it only adds lines, every var is commented out (no default gets
pinned), and the wording matches the README.

Scope: nothing outside tasks.md changed. The `session.log` and `tokens.json` files
in the job directory are tooling artifacts.

## Security

None. This is a docs-only change. The README warns about locking users out
with `MIN_CLIENT_VERSION` and doesn't promise admin notifications that aren't set up.

## Overall

NEEDS WORK

Blocker, which a human has to do outside the agent sandbox:
1. Apply the TASK-3 `.env` block exactly as written in implementation.md (after
   `EMAIL_CONFIRMATION=true`, before `# Versions`). Check with `git diff .env`
   that only lines were added, and commit it on this branch as
   `[friendly] TASK-3: add commented-out API guard vars to .env`.
   Once that commit is on the branch, TASK-1–3 are all done and this can be
   approved without another code review.
