# Backlog: ntfy notifications for instance admins

created: 2026-10-14

## What

Wire up the ntfy admin notifications added in solyto/api (`337a3e1`) for
self-hosters:

- `compose.yml`: top-level secrets `ntfy_topic` and `ntfy_token`. On `api` and
  `queue`, add `NTFY_TOPIC_FILE=/run/secrets/ntfy_topic`,
  `NTFY_TOKEN_FILE=/run/secrets/ntfy_token` and the service-level `secrets:`
  entries.
- `setup.sh`: add `write_empty "ntfy_topic"` and `write_empty "ntfy_token"` to
  the optional secrets.
- `.env`: `NTFY_URL=` (empty) in its own block.
- `README.md`: list `ntfy_topic` and `ntfy_token` under optional secrets and
  note that ntfy is off unless URL and topic are both set.

## Why

The API now reads `NTFY_URL` from env and `NTFY_TOPIC` / `NTFY_TOKEN` via
`DockerSecretHelper`. Without these changes self-hosters can't enable it.

## Decisions

- Secrets go on `api` and `queue` only (`api` evaluates `via()`, `queue`
  sends). `dav`, `nginx` and `imgproxy` need nothing.
- No defaults and no fallback to ntfy.sh: an instance makes no outbound call
  unless the operator sets URL and topic.

## Out of scope

- Any change to the API itself.

## Notes

- The `write_empty` entries are required: compose fails on a missing secret
  file. An empty file is fine, the API checks with `filled()`.
- Existing installs need to create the two secret files manually (or rerun the
  relevant part of `setup.sh`) before pulling the new `compose.yml`.
