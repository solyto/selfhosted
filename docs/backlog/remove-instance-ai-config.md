# Backlog: remove instance-wide AI config

created: 2026-10-14

## What

Remove the instance-level AI settings, since solyto/api now runs AI on each
user's plugin config (`597ce36`, together with `618c1b8` and `cea37f0`):

- `compose.yml`: remove `AI_API_KEY_FILE` and the `ai_api_key` secret from
  `api`, and the top-level `ai_api_key` secret definition.
- `setup.sh`: remove `write_empty "ai_api_key"`.
- `.env`: remove the `# AI (library recommendations)` block (`AI_BASE_URL`,
  `AI_MODEL`).
- `README.md`: remove `ai_api_key` from the secrets tree and replace the
  "AI API Key" paragraph with a short note that AI recommendations are now
  configured per user in the app.

## Why

`config/services.php` no longer has an `ai` block, so the secret and env vars
are dead. Keeping them suggests to self-hosters that they still do something.

## Decisions

- Only remove what the API no longer reads; no new env vars replace it.

## Out of scope

- Documenting the per-user plugin UI in detail.

## Notes

- Existing installs can delete `secrets/ai_api_key` after updating; leaving it
  in place is harmless.
- Check whether the API release containing `597ce36` is tagged before
  shipping this, so `SOLYTO_VERSION` pins don't break.
