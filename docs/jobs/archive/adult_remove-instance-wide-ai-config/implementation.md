# Implementation: remove instance-wide AI config

id: adult
date: 2026-10-14

## Summary

Removed the instance-level AI configuration that solyto/api no longer reads
(`compose.yml`, `setup.sh`, `README.md`). TASK-3 (`.env`) was dropped by
human decision: `.env` stays unchanged, and the README states that its
leftover AI vars are ignored.

## Changes

TASK-1: `compose.yml` — removed `AI_API_KEY_FILE` env entry and `- ai_api_key`
from the `api` service's `secrets:`, and the top-level `ai_api_key` secret
definition. Pure line deletions; no other `ai_api_key` references remain.
(`docker compose config` / a YAML parser aren't available in this sandbox, so
validation was by diff/grep only.)

TASK-2: `setup.sh` — removed `write_empty "ai_api_key"`. `bash -n` passes.

TASK-3: **dropped (human decision: no changes to `.env`).** The committed
`.env` keeps its `# AI (library recommendations)` block (`AI_BASE_URL=`,
`AI_MODEL=gpt-4o-mini`). Nothing in this repo or the current API reads them,
and they're harmless when passed through `env_file`. The README note (TASK-4)
was reworded so it no longer claims that no `.env` values exist, and now says
these two are ignored.

TASK-4: `README.md` — removed `├── ai_api_key` from the secrets tree and
replaced the "AI API Key" bullet with a short note that music/book AI
recommendations are configured per user in the app (plugin settings), plus
the note that existing installs can delete `secrets/ai_api_key`.

TASK-5: pre-ship check, not a code change — not verifiable from this repo.

## Known issues / follow-ups

- **TASK-5:** before shipping, confirm a tagged solyto/api release /
  `solyto/api-php` image includes `597ce36`, `618c1b8` and `cea37f0`.
- Because `.env` is masked, `git status` always shows it as modified and
  `git add -A` fails on it ("unsupported file type"). I staged files by path.
