# Verdict: ntfy notifications for instance admins

id: around
reviewer: @reviewer
date: 2026-10-14

## Review

Branch verified: `feature/around_ntfy-notifications-for-instance-admins`.
Base: `main` (no `.manigot/manigot.json` present). Reviewed `git diff main...HEAD`;
source changes are limited to `compose.yml`, `setup.sh`, `README.md` (plus job docs).
No out-of-scope changes.

TASK-1: PASS
notes: `compose.yml` — `NTFY_TOPIC_FILE`/`NTFY_TOKEN_FILE` added to `api` (l.95-96) and
`queue` (l.187-188) environment; `ntfy_topic`/`ntfy_token` added to the service-level
`secrets:` of `api` (l.117-118) and `queue` (l.206-207); top-level definitions at
l.362-365 with `file: ./secrets/ntfy_*`. Indentation matches neighbours. `dav`, `nginx`,
`imgproxy` untouched. `NTFY_URL` correctly not added to compose (comes via `env_file: .env`).
No YAML parser/Docker in the sandbox either, so `docker compose config` was not run; manual
inspection finds no structural issue.

TASK-2: PASS
notes: `setup.sh` l.94-95 — `write_empty "ntfy_topic"` / `write_empty "ntfy_token"` after
`bgg_api_key`. `bash -n setup.sh` passes.

TASK-3: NOT DONE (sandbox limitation, handled as planned)
notes: `/workspace/.env` is a `/dev/null` char device (`crw-rw-rw- 1,3`) in this sandbox,
so it cannot be edited or committed. The developer skipped it as tasks.md instructs and
recorded the exact block in implementation.md. No workaround was attempted, and `.env`
is not in the branch diff. Correct handling.

TASK-4: PASS
notes: `README.md` — `ntfy_topic`/`ntfy_token` added to the secrets tree marked optional,
with tree glyphs fixed (`tmdb_access_token` now `├──`). The optional-secrets bullet covers
the purpose, `NTFY_URL` in `.env`, the token being needed only for protected topics,
"off unless both `NTFY_URL` and `ntfy_topic` are set" and no default server/outbound
calls. This matches the brief. The link to ntfy.sh is the project homepage, not a default
server.

## Security

none (not run). The change adds no defaults and no outbound calls unless configured.

## Overall

APPROVED

The code and docs in this branch are complete and correct. Blocker before merge (needs a
human, can't be done in the agent sandbox): add the `.env` block from implementation.md
(TASK-3) to the real `.env`:

```
# ntfy (admin notifications)
# Base URL of your ntfy server. Leave empty to disable ntfy.
NTFY_URL=
```
