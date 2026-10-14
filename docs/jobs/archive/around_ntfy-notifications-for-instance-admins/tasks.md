# Tasks: ntfy notifications for instance admins

id: around
analyst: @analyst
date: 2026-10-14

<!-- Produced by @analyst from brief.md. -->

## Findings from reading the repo (input for the developer)

- Branch checked: the worktree HEAD is `feature/around_ntfy-notifications-for-instance-admins`,
  which matches the brief.
- `compose.yml`:
  - `api` sets `*_FILE` env vars in its `environment:` map (l.78-94) and lists its
    service secrets at l.98-114. The last entries are `IMGPROXY_SALT_FILE` / `imgproxy_salt`.
  - `queue` follows the same pattern: env vars at l.169-182, secrets at l.186-199.
  - The top-level `secrets:` block is at l.317-353. Every entry has the form
    `name:\n    file: ./secrets/name`.
  - `api` and `queue` both use `env_file: ".env"`, so a new `NTFY_URL` in `.env` gets
    to both containers without any `environment:` entry. **Don't** add `NTFY_URL` to
    compose (the brief doesn't ask for it).
- `setup.sh`: the optional secrets are the `write_empty` calls at l.83-93, and the last
  one is `bgg_api_key`.
- `README.md`: the secrets file tree is at l.89-111, with inline `# optional` comments on
  some entries. The "Required vs optional secrets" bullet list is at l.141-157.
- **`.env` can't be edited in this sandbox.** `/workspace/.env` reads as 0 bytes.
  Earlier jobs (`docs/jobs/archive/show_…/implementation.md`,
  `docs/jobs/archive/plus_…/implementation.md`) found that it is a `/dev/null` character
  device mounted over the real file, and git reports it as "modified / unsupported file
  type". Upstream `.env` has blocks separated by blank lines, e.g. AI (~l.69-73),
  Mail (~l.75-78), Image driver (~l.80-81), Telegram debug (~l.84-85). See TASK-3 for how
  to handle this.

## Task breakdown

TASK-1: In `compose.yml`, add top-level secrets `ntfy_topic` and `ntfy_token` (`file: ./secrets/ntfy_topic` / `./secrets/ntfy_token`). Add `NTFY_TOPIC_FILE: /run/secrets/ntfy_topic` and `NTFY_TOKEN_FILE: /run/secrets/ntfy_token` to the `environment:` of **`api` and `queue` only**, plus `ntfy_topic` / `ntfy_token` to those two services' `secrets:` lists.
     files: compose.yml
     depends: none
     risk: medium — a typo or a service-level secret with no top-level definition stops the whole stack from starting, and existing installs without the two secret files will fail on `docker compose up` (expected per the brief, see TASK-2/4). Verify: if Docker is available, run `docker compose config` with stub `secrets/ntfy_*` files; otherwise at least parse the YAML. Confirm that `dav`, `nginx` and `imgproxy` are unchanged.
     note: do all three parts in one change. Splitting them would leave compose.yml invalid in between.

TASK-2: In `setup.sh`, add `write_empty "ntfy_topic"` and `write_empty "ntfy_token"` to the optional-secrets block (after `write_empty "bgg_api_key"`, l.93).
     files: setup.sh
     depends: none (logically pairs with TASK-1: without it, fresh installs fail on the new compose secrets)
     risk: low — two extra lines that use an existing idempotent helper. Verify with `bash -n setup.sh`.

TASK-3: In `.env`, add `NTFY_URL=` (empty, no default) in its own block, i.e. separated by blank lines, ideally with a short comment header matching the style of the neighbouring blocks.
     files: .env
     depends: none
     risk: high (process, not code) — in this sandbox `.env` is a `/dev/null` mount, so edits are silently discarded and the real file can't be committed from here. The developer should first check this (`test -c .env` / `git status`). If it is still masked, **don't** try workarounds such as writing blobs to the git index by hand. Skip the task and record in implementation.md the exact block a human should add outside the sandbox. Don't commit `.env` either way unless it is a real, readable file with the full upstream content plus the new block.

TASK-4: In `README.md`, add `ntfy_topic` and `ntfy_token` to the secrets file tree (l.89-111, marked `# optional`) and add a bullet to the optional-secrets list (l.141-157). The bullet should cover what they are for (admin notifications via ntfy), that `NTFY_URL` is set in `.env`, and that ntfy is **off unless both `NTFY_URL` and `ntfy_topic` are set**, with no default server and no outbound calls otherwise. `ntfy_token` is optional (for protected topics).
     files: README.md
     depends: TASK-1, TASK-3 (names must match what was actually added)
     risk: low — docs only. The one risk is describing app behaviour this repo can't verify (see open questions), so stick to what the brief states.

## Open questions / unclear scope (not tasks, don't do these without a decision)

1. **Upgrade note for existing installs.** The brief notes that existing installs must
   create `secrets/ntfy_topic` and `secrets/ntfy_token` before pulling the new
   `compose.yml`, or the stack won't start. The README "Updates" section (l.298-300)
   currently says "just pull the newest image and restart". The brief doesn't ask for a
   README change here, so it isn't a task. A human should decide whether to add a
   one-line upgrade note, since this is a breaking change for current self-hosters.
2. **Format of `NTFY_URL`.** It isn't clear from this repo whether `NTFY_URL` is the
   server base URL (e.g. `https://ntfy.example.com`) or includes the topic, or which
   events trigger notifications. That lives in solyto/api `337a3e1`. The README should not
   claim specifics beyond "ntfy server URL" unless the developer can confirm them from
   that commit.
3. The `.env` mount issue (TASK-3) needs a human to apply that one-line change outside
   the sandbox.
