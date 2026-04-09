#!/bin/bash

set -e

echo "Cloning solyto/selfhosted..."
git clone --depth 1 https://github.com/solyto/selfhosted.git solyto
cd solyto
rm -f LICENSE README.md

echo ""
echo "Configure domains and email for TLS certificates:"
read -rp "  API domain   (e.g. api.yourdomain.com): " API_DOMAIN
read -rp "  App domain   (e.g. app.yourdomain.com): " APP_DOMAIN
read -rp "  DAV domain   (e.g. dav.yourdomain.com): " DAV_DOMAIN
read -rp "  ACME email   (e.g. you@yourdomain.com): " ACME_EMAIL

sed -i \
    -e "s|^API_DOMAIN=.*|API_DOMAIN=${API_DOMAIN}|" \
    -e "s|^APP_DOMAIN=.*|APP_DOMAIN=${APP_DOMAIN}|" \
    -e "s|^DAV_DOMAIN=.*|DAV_DOMAIN=${DAV_DOMAIN}|" \
    -e "s|^ACME_EMAIL=.*|ACME_EMAIL=${ACME_EMAIL}|" \
    .env

echo ""

SECRETS_DIR="./secrets"
mkdir -p "$SECRETS_DIR"

generate_password() {
    openssl rand -base64 24 | tr -d '\n'
}

write_secret() {
    local name="$1"
    local value="$2"
    local file="$SECRETS_DIR/$name"
    if [ ! -f "$file" ]; then
        printf '%s' "$value" > "$file"
        echo "  created:  secrets/$name"
    else
        echo "  skipped:  secrets/$name (already exists)"
    fi
}

write_empty() {
    local name="$1"
    local file="$SECRETS_DIR/$name"
    if [ ! -f "$file" ]; then
        touch "$file"
        echo "  created:  secrets/$name (empty)"
    else
        echo "  skipped:  secrets/$name (already exists)"
    fi
}

echo "Setting up secrets..."

# Generate shared values so db_user/mariadb_user and db_password/mariadb_password match
DB_USER="solyto"
DB_PASSWORD="$(generate_password)"
DAV_DB_USER="solyto_dav"
DAV_DB_PASSWORD="$(generate_password)"

write_secret "app_key"               "base64:$(openssl rand -base64 32 | tr -d '\n')"
write_secret "db_user"               "$DB_USER"
write_secret "db_password"           "$DB_PASSWORD"
write_secret "dav_db_user"           "$DAV_DB_USER"
write_secret "dav_db_password"       "$DAV_DB_PASSWORD"
write_secret "mariadb_user"          "$DB_USER"
write_secret "mariadb_password"      "$DB_PASSWORD"
write_secret "mariadb_root_password" "$(generate_password)"
write_secret "postgres_root_password" "$(generate_password)"

echo ""
echo "Setting up optional secrets (empty by default)..."

write_empty "solyto_bot_webhook_token"
write_empty "solyto_bot_telegram_token"
write_empty "hardcover_api_key"
write_empty "openai_api_key"
write_empty "mailgun_secret"
write_empty "vapid_public_key"
write_empty "vapid_private_key"
write_empty "bgg_api_key"

echo ""
echo "Done. Run: cd solyto && docker compose up -d"
