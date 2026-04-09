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
| `nginx`    | `solyto/api-nginx` | Web server / reverse proxy for the API |
| `php`      | `solyto/api-php`   | Laravel PHP-FPM application            |
| `dav`      | `solyto/api-php`   | WebDAV service (separate PHP config)   |
| `queue`    | `solyto/api-php`   | Laravel queue worker                   |
| `app`      | `solyto/app`       | Frontend app (port 3000)               |
| `mariadb`  | `mariadb`          | Primary database for the API           |
| `postgres` | `postgres`         | Database for the DAV service           |
| `redis`    | `redis`            | Cache and queue backend                |

## 

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
  
  - OpenAI API Key: if you want music / book recommendations via a lean LLM call
  
  - Mailgun Secret: if you need email functionality
  
  - Vapid Keys: if you want to use solyto as a Progressive Web App with Push Notifications
  
  - BGG API Key: if you want to import games from boardgamesgeek

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

**5. Create first user**

```php
docker exec -it solyto-api php artisan app:user:create
```

*Please note: if you changed the project name via `.env`, please do also adjust the container name in this command.*

## ## Networks

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

## Running with a reverse proxy

**Traefik**

If you are running solyto behind a Traefik reverse proxy, just add normal Traefik labels to the default containers. Example for the API container:

```yml
labels:
      - traefik.enable=true
      - traefik.docker.network=web
      - traefik.http.routers.${PROJECT_NAME}.entrypoints=websecure
      - traefik.http.routers.${PROJECT_NAME}.rule=Host(`api.yourdomain.com`) || Host(`dav.yourdomain.com`)
      - traefik.http.routers.${PROJECT_NAME}.tls=true
      - traefik.http.routers.${PROJECT_NAME}.tls.certresolver=leresolver
      - traefik.http.services.${PROJECT_NAME}.loadbalancer.server.port=${LISTEN_PORT}
```

**Caddy**

If you are running solyto behind a Caddy reverse proxy, make sure to redirect to the correct ports in `etc/caddy/Caddyfile`. Example:

```
api.yourdomain.com {
    reverse_proxy 10.0.1.8:80
}

dav.yourdomain.com {
    reverse_proxy 10.0.1.8:80
}

app.yourdomain.com {
    reverse_proxy 10.0.1.8:3000
}
```

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
