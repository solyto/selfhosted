# Brief: document new optional API env vars

type: feature
id: friendly
branch: feature/friendly_document-new-optional-api-env-vars
date: 2026-10-14
author: Leander Muskalla

## What

Expose the new optional settings from solyto/api in `.env` and `README.md`:

- `MIN_CLIENT_VERSION` (`c5f3b99`): authenticated requests whose
  `X-Client-Version` header is below this version get a 426. Requests without
  the header are always allowed. Empty/unset turns the check off.
- `API_TRAFFIC_ALERT_THRESHOLD` (default `300`) and
  `API_TRAFFIC_ALERT_COOLDOWN` (default `3600` seconds) (`fb9b5d1`): alert
  admins when a single user sends too many API requests.

## Why

All three have safe defaults, so nothing breaks without them. But
self-hosters can't tune them if they don't know they exist.

## Decisions

- Undecided: add them to `.env` (commented out or with defaults), or only
  mention them in `README.md`.

## Out of scope

- Changing defaults.

## Notes

- Not verified: whether traffic alerts go out via ntfy (they likely use the
  new admin notifications, see `ntfy-notifications.md`). The API also logs
  them to `storage/logs/traffic.log`. Check before documenting.
