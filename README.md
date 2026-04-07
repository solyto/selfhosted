# solyto — self-hosted

Docker Compose setup for running the Solyto stack.

## Services

| Service | Image | Description |
|---------|-------|-------------|
| `nginx` | `solyto/api-nginx` | Web server / reverse proxy for the API |
| `php` | `solyto/api-php` | Laravel PHP-FPM application |
| `dav` | `solyto/api-php` | WebDAV service (separate PHP config) |
| `queue` | `solyto/api-php` | Laravel queue worker |
| `app` | `solyto/app` | Frontend app (port 3000) |
| `mariadb` | `mariadb` | Primary database for the API |
| `postgres` | `postgres` | Database for the DAV service |
| `redis` | `redis` | Cache and queue backend |

## Setup

**1. Configure your domains**

Edit `.env` and fill in your domains:

```env
API_DOMAIN=api.yourdomain.com
APP_DOMAIN=app.yourdomain.com
```

**2. Create secrets**

All secrets are read from files in `./secrets/`. Create the directory and populate each file:

```
secrets/
├── app_key
├── db_user
├── db_password
├── dav_db_user
├── dav_db_password
├── mariadb_user
├── mariadb_password
├── mariadb_root_password
├── postgres_root_password
├── solyto_bot_webhook_token
├── solyto_bot_telegram_token
├── hardcover_api_key
├── openai_api_key
├── mailgun_secret
├── vapid_public_key
├── vapid_private_key
└── bgg_api_key
```

Each file should contain just the secret value, no trailing newline. Example:

```sh
echo -n "your-secret-value" > secrets/db_password
```

**3. Configure mail (optional)**

Set the Mailgun values in `.env` if you want outgoing email:

```env
MAILGUN_DOMAIN=mg.yourdomain.com
MAIL_FROM_ADDRESS=hello@yourdomain.com
MAIL_FROM_NAME=Solyto
```

**4. Start**

```sh
docker compose up -d
```

## Networks

The compose file uses three networks to limit service exposure:

- `api` — internal only, nginx and PHP talk here
- `db` — internal only, app services connect to the databases here
- `public` — externally reachable, for services that need outside connectivity

## Storage

The `./storage/` directory is mounted into nginx, php, dav, and queue so they all share the same filesystem for uploads and generated files.
