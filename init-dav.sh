#!/bin/bash
set -e

DAV_DB_USER=$(cat /run/secrets/dav_db_user)
DAV_DB_PASSWORD=$(cat /run/secrets/dav_db_password)

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER ${DAV_DB_USER} WITH PASSWORD '${DAV_DB_PASSWORD}';
    CREATE DATABASE ${DAV_DB_DATABASE} OWNER ${DAV_DB_USER};
EOSQL
