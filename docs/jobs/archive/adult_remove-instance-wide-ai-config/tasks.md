# Tasks: remove instance-wide AI config

Branch verified: worktree HEAD is `refs/heads/feature/adult_remove-instance-wide-ai-config`, which matches `brief.md`.

## TASK-1: Remove the AI secret from `compose.yml`
- **Description:** In the `api` service, delete the `AI_API_KEY_FILE: /run/secrets/ai_api_key` env entry (line ~87) and the `- ai_api_key` entry under `secrets:` (line ~107). Then delete the top-level `ai_api_key:` / `file: ./secrets/ai_api_key` definition (lines ~338–339).
- **Files:** `compose.yml`
- **Dependencies:** none
- **Risk:** low. These are three small deletions, and no other service references `ai_api_key`. Verify with `docker compose config` (with stub secret files present) or a grep afterwards to confirm the YAML is still valid.

## TASK-2: Stop `setup.sh` from creating the AI secret
- **Description:** Delete the line `write_empty "ai_api_key"` (line ~88) in the optional-secrets section of `setup.sh`.
- **Files:** `setup.sh`
- **Dependencies:** none (ship it together with TASK-1 so compose doesn't reference a secret that is no longer created)
- **Risk:** low. It is a single-line deletion in a list of independent calls.

## TASK-3: Remove the `# AI (library recommendations)` block from `.env`
- **Description:** Delete the `# AI (library recommendations)` comment and the `AI_BASE_URL` / `AI_MODEL` lines from `.env`.
- **Files:** `.env`
- **Dependencies:** none
- **Risk:** low as an edit, but the scope is **unclear** (see below).
- **⚠ Unclear:** `/workspace/.env` is **empty** in this worktree as I read it. It has no AI block, and it also lacks the `API_DOMAIN`/`APP_DOMAIN`/… keys that `setup.sh` `sed`s into it, so it looks like the file is not being shown with its real committed contents. The developer should check `git show HEAD:.env` (or `git diff`) before editing. If the committed `.env` really has no AI block, this task is a no-op and should be reported as such. The developer must not recreate or otherwise change `.env`.

## TASK-4: Update the AI section of `README.md`
- **Description:** Remove the `├── ai_api_key` line from the `secrets/` tree (line ~103). Replace the "AI API Key (`ai_api_key`) …" bullet (line ~147) with a short note that music/book AI recommendations are now configured per user in the app (plugin settings), so no instance-level secret or `.env` values are needed. Optionally add one sentence saying existing installs can delete `secrets/ai_api_key`, and that leaving it in place is harmless (this comes from the brief's Notes).
- **Files:** `README.md`
- **Dependencies:** none
- **Risk:** low. It is a docs-only change. Keep the note short and don't document the plugin UI, which is out of scope.

## TASK-5 (pre-ship check, not a code change): Confirm the API release is tagged
- **Description:** Before merging or releasing, confirm that a tagged solyto/api release (and the `solyto/api-php` image) contains `597ce36` (plus `618c1b8` and `cea37f0`). Self-hosters pinning an older `SOLYTO_VERSION` would still run an API that reads `AI_API_KEY_FILE`. This probably only disables AI recommendations rather than crashing, but that is unverified from this repo.
- **Files:** none in this repo; may affect release notes or any recommended `SOLYTO_VERSION` value
- **Dependencies:** should gate shipping TASK-1–4
- **Risk:** medium. This can't be verified from this repository, and a human needs to confirm the tag exists.

## Notes
- I found no other references to `ai_api_key`, `AI_BASE_URL` or `AI_MODEL` outside `docs/` (the backlog item `docs/backlog/remove-instance-ai-config.md` mirrors the brief; whether to delete or close it is not in the brief, so leave it alone unless asked).
