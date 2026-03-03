#!/bin/bash
set -e

# Create additional databases for Solid Cache, Queue, and Cable.
# This runs automatically on first PostgreSQL startup via docker-entrypoint-initdb.d.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE lighthouse_production_cache;
    CREATE DATABASE lighthouse_production_queue;
    CREATE DATABASE lighthouse_production_cable;
EOSQL
