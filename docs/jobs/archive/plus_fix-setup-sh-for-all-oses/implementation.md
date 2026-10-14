# Implementation: Fix setup.sh for all OSes

id: plus
developer: @developer
date: 2026-10-14

## Summary

`setup.sh` no longer looks up the user name `www-data` on the host. It now
`chown`s `storage/` to a numeric UID/GID (default 33:33, which is www-data
inside the `solyto/api-php` containers). You can override it with `SOLYTO_UID` /
`SOLYTO_GID`. The README explains the ownership step and how to fix it by hand.
TASK-2 was **not** implemented because tasks.md marks it as needing human
confirmation, and this session ran unattended.

## Changes

TASK-1: `setup.sh` — added `SOLYTO_UID`/`SOLYTO_GID` (default 33, can be overridden from the
env) near the top, with a comment on why the IDs are numeric. Replaced
`chown -R www-data:www-data storage/` with `chown -R "${SOLYTO_UID}:${SOLYTO_GID}" storage/`.
Checked with `bash -n`.

TASK-2: skipped (needs human confirmation). It is about warning or using sudo
instead of stopping when not running as root.

TASK-3: `README.md` — added a note under "Install script": storage/ is owned by 33:33
(container www-data), you need root/`sudo bash`, how to use `SOLYTO_UID`/`SOLYTO_GID`,
and the manual `sudo chown -R 33:33 solyto/storage` fix. The wording matches the
current behaviour (the script stops if chown fails). Update it if TASK-2 is approved.

## Known issues / follow-ups

- Not yet confirmed that `www-data` in `solyto/api-php` is UID/GID 33. Docker was not
  available in this session. Please run
  `docker run --rm --entrypoint id solyto/api-php:latest www-data` before merging.
  (The Arch fix with 33:33 suggests it is.)
- TASK-2 is waiting for a decision.
- `sed -i -e …` in setup.sh only works with GNU sed and will break on macOS/BSD.
  This is open question 1 in tasks.md and was not in scope.
- The working tree shows `/workspace/.env` as modified, but git cannot hash it
  ("unsupported file type", probably a mount). It was not touched or committed.
