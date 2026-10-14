# Verdict: Fix setup.sh for all OSes

id: plus
reviewer: @reviewer
date: 2026-10-14

## Review

Reviewed `git diff main...HEAD` on `feature/plus_fix-setup-sh-for-all-oses`
(`.manigot/manigot.json` is missing, so the base defaults to `main`). The only
non-job-doc changes are `setup.sh` (+6/-1), `README.md` (+2) and an empty
`docs/CLAUDE.md` (see notes).

TASK-1: PASS
notes: `setup.sh:5-8` defines `SOLYTO_UID="${SOLYTO_UID:-33}"` /
`SOLYTO_GID="${SOLYTO_GID:-33}"` near the top, with a comment explaining why the
IDs are numeric. `setup.sh:16` now runs `chown -R "${SOLYTO_UID}:${SOLYTO_GID}" storage/`.
The values are quoted, and the variables are set before the `cd solyto`, so env
overrides work. This is the same as before on Debian/Ubuntu hosts, and it removes
the host-user lookup that failed on Arch, Fedora and macOS. UID 33 has not been
checked against the image with Docker. But the reporter's working Arch fix
(`chown -R 33:33`) is real-world evidence that it is correct, and the env
override covers any difference.

TASK-2: NOT IMPLEMENTED (correctly deferred)
notes: tasks.md says this task "needs human confirmation before implementing".
The session ran unattended, so skipping it was the right call, and
implementation.md says so. This is not a failure of this job. A human still
needs to decide whether to approve it in a follow-up.

TASK-3: PASS
notes: `README.md:58` adds a note under "Install script". It says storage/ is
chowned to 33:33 (container www-data) no matter which users exist on the host,
that this needs root / `sudo bash`, how to override with `SOLYTO_UID`/`SOLYTO_GID`
(`sudo VAR=… bash` is valid sudo syntax), and the manual fix command. The wording
matches the current behaviour (the script stops if chown fails, because TASK-2
was not done).

Scope: nothing changed outside the tasks except an empty `docs/CLAUDE.md`. It
came from the automated `[plus] chore: commit all` commit (1d83f07), not from
the developer's task commits, and it does not affect behaviour. It is not
mentioned in implementation.md, so it may be worth removing during squash, but
it does not block merging.

## Security

Not run. The change only swaps a user name for numeric IDs from env vars. The
values are quoted, and an operator who sets their own env vars gains nothing new.

## Overall

APPROVED

No blocking changes are required. Before merging, a human should still decide on
the deferred TASK-2 (sudo/warn fallback), either now or in a follow-up job.
