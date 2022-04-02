#!/bin/bash

PGNAME=localhost
PG_ADMIN=postgres

# Connect to Local PostgreSQL Running in Docker Container
psql --version
psql --host="${PGNAME}" --port=5432 \
  --username="${PG_ADMIN}" \
  --dbname=postgres

# Connect to PostgreSQL DB with CLI or Docker
# Try with psql CLI
psql --host="${PGNAME}.postgres.database.azure.com" --port=5432 \
  --username="${PG_ADMIN}" \
  --dbname=postgres
# Connect to Default 'postgre' DB
docker run -it --rm postgres:13.4 psql --host="${PGNAME}.postgres.database.azure.com" --port=5432 \
  --username="${PG_ADMIN}" \
  --dbname=postgres

# Setup Tutorials Database
# List Databases
\l
# List Tables, Views, Sequences
\d
# Create New DB
CREATE DATABASE tutorials;
\c tutorials
# Run API App to Generate Tables + Data
# Check for Tables + Data
SELECT * FROM tutorials;
# Quit
\quit
