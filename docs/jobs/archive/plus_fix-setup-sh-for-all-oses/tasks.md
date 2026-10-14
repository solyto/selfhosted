# Tasks: Fix setup.sh for all OSes

id: plus
analyst: @analyst
date: 2026-10-14

<!-- Produced by @analyst from brief.md. -->

## Context (what the code actually does)

- `setup.sh:11` runs `chown -R www-data:www-data storage/` on the **host**.
  The name `www-data` is looked up in the host's `/etc/passwd`. Debian/Ubuntu
  have it (UID/GID 33). Arch, Fedora, Alpine hosts and macOS do not, or use a
  different UID. Under `set -e`, a failing `chown` stops the whole script.
- `compose.yml` runs `api`, `dav` and `queue` (image `solyto/api-php`) with
  `user: www-data`. That name is looked up **inside the container**, so what
  the bind mount `./storage/` really needs is the container's numeric
  UID/GID, whatever the host OS is.
- The reported fix (`chown -R 33:33`) worked on Arch. That strongly suggests
  `solyto/api-php` is Debian-based (official `php:*-fpm` → www-data = 33;
  Alpine would be 82). I could not confirm the base image from Docker Hub
  metadata, so the developer/reviewer should confirm it, for example with
  `docker run --rm --entrypoint id solyto/api-php:latest www-data` on any
  machine with Docker.
- `nginx` (user `nginx`) and `imgproxy` (`:ro`) also mount `./storage/`, but
  they only need read access. The default directory mode (755) already gives
  them that, so this job does not change them.
- The README install path is `curl … | bash`, with no `sudo` mentioned.
  `chown` to any UID other than your own needs root, so this can also fail
  on Debian for non-root users. See TASK-2.

## Task breakdown

TASK-1: Replace the name-based `chown -R www-data:www-data storage/` with a numeric UID/GID that matches `www-data` in the `solyto/api-php` image. Define it once near the top of `setup.sh` as a variable (default `33`, overridable via env such as `SOLYTO_UID`/`SOLYTO_GID`), and add a one-line comment explaining why it is numeric.
  files: setup.sh
  depends: none
  risk: low — same effect on Debian/Ubuntu hosts (www-data is already 33 there), and it removes the dependency on a host user; the only risk is if the image is not actually UID 33, so confirm that first (see Context).

TASK-2 (needs human confirmation before implementing): Make the ownership step not abort the script when it isn't running as root. If `$EUID` ≠ 0, use `sudo chown` if `sudo` is available. Otherwise print a clear warning with the exact manual command (`sudo chown -R 33:33 solyto/storage`) and continue.
  files: setup.sh
  depends: TASK-1
  risk: medium — it changes failure behaviour (warn vs. abort), and with `curl | bash` a `sudo` password prompt has to read from `/dev/tty`, as the existing `read` calls already do.

TASK-3: Add a short note to the README install section saying that `storage/` is owned by UID/GID 33 (www-data inside the containers), that the script may need root/sudo for this, and how to override or fix it manually.
  files: README.md
  depends: TASK-1 (and TASK-2 if it is approved)
  risk: low — documentation only.

## Open questions / unclear scope (not turned into tasks)

1. **Other non-portable parts of setup.sh.** "All OSes" may mean more than
   the chown. `sed -i -e …` (setup.sh:20-25) is GNU-only. On macOS/BSD,
   `-i` takes the next argument as a backup suffix, so it will misbehave or
   leave a `.env-e` file. If macOS hosts are in scope, a follow-up task could
   swap it for a portable form (e.g. `sed -i.bak … && rm .env.bak`). I left
   it out because the brief only describes the chown failure.
2. **Detecting the UID dynamically** (e.g.
   `docker run --rm --entrypoint id solyto/api-php:$SOLYTO_VERSION -u www-data`)
   would always be correct, but it pulls the image during setup and needs
   Docker access in the script. I suggest hardcoding with an env override
   (TASK-1) unless the image's UID is expected to change.
3. **Base image confirmation.** Someone with Docker access should confirm
   that `www-data` in `solyto/api-php` is 33:33 before TASK-1 is merged.
