<p align="center">
  <img src="https://raw.githubusercontent.com/solyto/assets/main/solyto_logo.png" />
</p>

solyto is a free, private, all-in-one personal management app — covering your todos, contacts, calendar, notes, news, music and book library in one place, with one login, and one coherent interface. No annoying AI features, no tracking, no subscriptions, no bullshit. Use it on the web, install it as a PWA, or self-host it entirely on your own infrastructure. Built out of frustration with bloated tools, fragmented self-hosted stacks, and services that keep adding things you never asked for.

# 

# selfhosted

You can use solyto for free at [solyto.app](https://solyto.app). If you want to be fully in control, feel free to selfhost it. This repositories provides all necessary files and setup instructions.

## 

## Prerequisites

You can host solyto on almost anything, be it through a compose stack with locally built images or through a compose stack utilizing our pre-built dockerhub images.

**Software Requirements**

The only thing your server needs is docker & docker compose. The rest is done inside the containers automatically.

**Hardware Requirements**

Solyto is relatively light in resource usage. You should be able to run it on a Raspberry Pi no problem. Any other VPS, cloud server or root server will be more than fine.

## 

## Services

| Service    | Image              | Description                            |
| ---------- | ------------------ | -------------------------------------- |
| `traefik`  | `traefik`          | Reverse proxy, TLS termination         |
| `nginx`    | `solyto/api-nginx` | Web server / reverse proxy for the API |
| `api`      | `solyto/api-php`   | Laravel PHP-FPM application            |
| `dav`      | `solyto/api-php`   | WebDAV service (separate PHP config)   |
| `queue`    | `solyto/api-php`   | Laravel queue worker                   |
| `app`      | `solyto/app`       | Frontend app                           |
| `mariadb`  | `mariadb`          | Primary database for the API           |
| `postgres` | `postgres`         | Database for the DAV service           |
| `redis`    | `redis`            | Cache and queue backend                |

## 

## Setup

You have two options regarding setup. Either go through steps manually or run our one-step-install script.

### Install script

```
curl -fsSL "https://raw.githubusercontent.com/solyto/selfhosted/main/setup.sh?$(date +%s)" | bash
```

Run this command to run the install script. It will clone all relevant files to solyto/, ask you for your domains and set everything up. After doing this, all you have to do is `cd` into solyto/ and run `make start` or `docker compose up -d`.

### Do things manually

**1. Copy relevant files from this repository to your server**

All you need is:

- .env

- compose.yml

- init-dav.sh (to initiate the Postgres database)

- Makefile (if you want shortcuts for managing your stack)

**2. Configure your domains**

Edit `.env` and fill in your domains and an email address for Let's Encrypt:

```env
API_DOMAIN=api.yourdomain.com
APP_DOMAIN=app.yourdomain.com
DAV_DOMAIN=dav.yourdomain.com
ACME_EMAIL=you@yourdomain.com
```

**3. Create secrets**

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
├── ai_api_key
├── mailgun_secret
├── vapid_public_key
├── vapid_private_key
└── bgg_api_key
```

Each file should contain just the secret value, no trailing newline. Example:

```sh
echo -n "your-secret-value" > secrets/db_password
```

<u>Required vs optional secrets</u>

- To use most of solytos functionality, you need these secrets:
  
  - app_key
  
  - db_user
  
  - db_password
  
  - dav_db_user
  
  - dav_db_password
  
  - mariadb_user
  
  - mariadb_password
  
  - mariadb_root_password
  
  - postgres_root_password

- The rest are optional for certain functionality:
  
  - Solyto Bot tokens: if you want Telegram integration (sending notifications to users, pasting links to the bot to add it to the users link library, etc.)
  
  - Hardcover API Key: if you want to be able to import books from Hardcover directly
  
  - AI API Key (`ai_api_key`): if you want music / book recommendations. Works with OpenAI or any OpenAI-compatible provider (e.g. IONOS AI Model Hub). Set `AI_BASE_URL` and `AI_MODEL` in `.env` to point at your preferred provider. This is the only AI feature solyto has. We have looked at others, but didn't find them to be useful. We are also trying to replace the AI recommendations with something more sophisticated and AI-less.
  
  - Mailgun Secret: if you need email functionality
  
  - Vapid Keys: if you want to use solyto as a Progressive Web App with Push Notifications
  
  - BGG API Key: if you want to import games from boardgamesgeek

**4. Configure mail (optional)**

Set the Mailgun values in `.env` if you want outgoing email:

```env
MAILGUN_DOMAIN=mg.yourdomain.com
MAIL_FROM_ADDRESS=hello@yourdomain.com
MAIL_FROM_NAME=Solyto
```

**5. Start**

```sh
docker compose up -d
```

**6. Create first user**

```sh
docker exec -it solyto-api php artisan app:user:create
```

*Please note: if you changed the project name via `.env`, please do also adjust the container name in this command.*

## Networks

The compose file uses three networks to limit service exposure:

- `api` — internal only, nginx and PHP talk here
- `db` — internal only, app services connect to the databases here
- `public` — externally reachable, for services that need outside connectivity

## Storage

The `./storage/` directory is mounted into nginx, php, dav, and queue so they all share the same filesystem for uploads and generated files.

## Backups

If you want to regularly backup your data, there are 3 components to it: the MariaDB database, the Postgres database and your local file storage containing album covers, book covers, etc.

We recommend using restic to automatically backup to a SFTP storage or server of your choice. Have a look at our example backup script.

```#!/bin/bash
#!/bin/bash
set -e

REPO="sftp:USER@HOST:data"
PASSWORD_FILE="/etc/restic/repo.key"
SQL_API="/tmp/api.sql"
SQL_DAV="/tmp/dav.sql"

echo "Dumping MariaDB..."
docker exec db-mariadb mariadb-dump -u root -p"$(cat /home/db/secrets/mariadb_root_password)" \
  --databases api --add-drop-database --routines --triggers --single-transaction \
  > "$SQL_API"
echo "MariaDB done."

echo "Dumping PostgreSQL..."
docker exec -e PGPASSWORD="$(cat /home/db/secrets/postgres_root_password)" db-postgres \
  pg_dump -U postgres --clean --create --if-exists dav \
  > "$SQL_DAV"
echo "PostgreSQL done."

echo "Running restic backup..."
restic -r "$REPO" backup "$SQL_API" "$SQL_DAV" /home/api/storage \
  --exclude="/home/api/storage/framework/cache" \
  --exclude="/home/api/storage/framework/sessions" \
  --exclude="/home/api/storage/framework/views" \
  --password-file "$PASSWORD_FILE"
echo "Backup done."

echo "Cleaning up..."
rm -f "$SQL_API" "$SQL_DAV"

echo "Pruning old snapshots..."
restic -r "$REPO" forget --keep-last 7 --prune \
  --password-file "$PASSWORD_FILE"

echo "All done."
```

## Running with an external reverse proxy

Traefik is included in the stack and handles routing and TLS automatically. If you prefer to use your own reverse proxy (e.g. Caddy), remove the `traefik` service from `compose.yml` and point your proxy at the internal ports directly:

- API: `8080`
- DAV: `8081`
- App: `3000`

Example Caddyfile:

```
api.yourdomain.com {
    reverse_proxy localhost:8080
}

dav.yourdomain.com {
    reverse_proxy localhost:8081
}

app.yourdomain.com {
    reverse_proxy localhost:3000
}
```

If you use an external reverse proxy, set `TRUSTED_PROXIES` in `.env` to your proxy's IP address. This ensures rate limiting works correctly and clients are identified by their real IP rather than the proxy's IP.

## Updates

If you run our dockerhub images, just pull the newest image and restart the stack. All necessary migrations will be run automatically.

## Downgrades

We do not yet have a verifiable downgrade strategy. However, all that needs to be done is to rollback previous Laravel Eloquent migrations. We will be releasing all migrations that need to be rolled back with each Dockerhub image release.

We are working on an automated procedure for this.

## Support

If you need any help setting your instance up, let us know. We are happy to help.

[Discord](https://discord.gg/JbNPJHG6)

---

## Licensing

Solyto is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.en.html) (AGPL-3.0).

You are free to use, modify, and self-host this software. If you distribute it or run it as a network service, you must make your source code available under the same license.
