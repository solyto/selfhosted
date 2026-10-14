# Verdict: remove instance-wide AI config

id: adult
reviewer: reviewer agent
date: 2026-10-14

## Review

Base: `main` (`.manigot/manigot.json` not present, so I used the default). Branch verified: `feature/adult_remove-instance-wide-ai-config`.
I reviewed `git diff main...HEAD`. Outside `docs/jobs/…`, only `compose.yml` (−4), `setup.sh` (−1) and `README.md` (+1/−2) changed. Nothing changed that the tasks didn't cover. `git grep` outside `docs/` finds no `ai_api_key` / `AI_BASE_URL` / `AI_MODEL` references except the new README note.

This is a re-review. The previous verdict (e987912) was NEEDS WORK only because TASK-3 (`.env`) wasn't done. Since then, commit c76183b, authored by the brief's author (Leander Muskalla), records a human decision to keep `.env` unchanged and rewords the README to match. I'm treating that as an authorised scope change to the brief, not as a missing requirement.

TASK-1: PASS
notes: `compose.yml` removes `AI_API_KEY_FILE` (api env), `- ai_api_key` (api secrets) and the top-level `ai_api_key:` / `file:` definition. These are pure deletions, and indentation and neighbouring entries are intact.

TASK-2: PASS
notes: `setup.sh` removes `write_empty "ai_api_key"`, and nothing else changed.

TASK-3: PASS (dropped by human decision)
notes: The committed `.env` (lines 68–72) still has the `# AI (library recommendations)` block, as decided in c76183b. The README now says that `AI_BASE_URL`/`AI_MODEL` in `.env` are no longer read and are ignored, so the docs no longer contradict the shipped `.env`.

TASK-4: PASS
notes: `README.md` removes `├── ai_api_key` from the secrets tree and replaces the "AI API Key" bullet with a short per-user note. The note also says that deleting `secrets/ai_api_key` is optional and that leaving the `.env` vars in place does nothing. It doesn't document the plugin UI, so it stays in scope.

TASK-5: N/A for code review (pre-ship check)
notes: This repo can't confirm that a tagged solyto/api release / `solyto/api-php` image contains `597ce36`, `618c1b8` and `cea37f0`. A human should confirm this before release (the brief's Notes). It doesn't block merging this branch's code.

## Overall

APPROVED

Must change before merge: nothing.
