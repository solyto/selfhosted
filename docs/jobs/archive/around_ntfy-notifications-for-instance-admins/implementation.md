# Implementation: ntfy notifications for instance admins

id: around
developer: @developer
date: 2026-10-14

## Summary

Added the plumbing self-hosters need for the ntfy admin notifications from solyto/api `337a3e1`. That covers the compose secrets and env vars on `api` and `queue`, empty secret files from `setup.sh`, and README docs. The `.env` change (TASK-3) could not be made in this sandbox and has to be applied by hand (see below).

## Changes

TASK-1: `compose.yml`: added top-level secrets `ntfy_topic` / `ntfy_token` (`file: ./secrets/ntfy_*`). Added `NTFY_TOPIC_FILE` / `NTFY_TOKEN_FILE` (`/run/secrets/ntfy_*`) to the `environment:` of `api` and `queue`, plus matching service-level `secrets:` entries. `dav`, `nginx`, `imgproxy` and the others are unchanged. Verification: no Docker and no YAML parser were available in the sandbox, so `docker compose config` was not run. I checked the diff by hand: the indentation matches the neighbouring entries, and both service-level secrets have top-level definitions.

TASK-2: `setup.sh`: added `write_empty "ntfy_topic"` and `write_empty "ntfy_token"` after `bgg_api_key` in the optional-secrets block. `bash -n setup.sh` passes.

TASK-3: **Not done (skipped as the plan says).** `/workspace/.env` is still a `/dev/null` character device in this sandbox (`crw-rw-rw- 1,3`), so edits are discarded and it can't be committed. A human should add this block to `.env` outside the sandbox, after the `# Image processing` block (the committed `.env` has `IMAGE_DRIVER=intervention` followed by two blank lines, then `# Telegram bot`):

```
# ntfy (admin notifications)
# Base URL of your ntfy server. Leave empty to disable ntfy.
NTFY_URL=
```

TASK-4: `README.md`: added `ntfy_topic` / `ntfy_token` (marked optional) to the secrets file tree. Also added a bullet to the optional-secrets list covering what they are for, `NTFY_URL` in `.env`, `ntfy_token` only being needed for protected topics, and that ntfy is off unless both `NTFY_URL` and `ntfy_topic` are set, with no default server and no outbound calls otherwise.

## Known issues / follow-ups

- TASK-3 `.env` block above needs to be applied manually.
- **Breaking for existing installs:** `docker compose up` will fail until `secrets/ntfy_topic` and `secrets/ntfy_token` exist (e.g. `touch secrets/ntfy_topic secrets/ntfy_token`). The README "Updates" section doesn't mention this. A human should decide whether to add an upgrade note (open question 1 in tasks.md).
- I couldn't confirm the exact `NTFY_URL` format (base URL vs. including the topic) from this repo. The README and the suggested `.env` comment assume a server base URL, which fits the topic coming from a separate secret. Worth checking against solyto/api `337a3e1`.
- `compose.yml` not checked with `docker compose config` (no Docker in the sandbox).
