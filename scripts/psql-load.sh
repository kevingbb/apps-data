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

# Setup Inventory Database
# List Databases
\l
# List Tables, Views, Sequences
\d
# Create New DB
CREATE DATABASE cnainventory;
\c cnainventory
# Create Table
CREATE TABLE inventory (
id serial PRIMARY KEY, 
name VARCHAR(50), 
quantity INTEGER,
    date DATE NOT NULL DEFAULT NOW()::date
);
# Verify Table
\dt
# Insert Sample Data
INSERT INTO inventory (id, name, quantity) VALUES (1, 'yogurt', 200);
INSERT INTO inventory (id, name, quantity) VALUES (2, 'milk', 100);
# Check Sample Data
SELECT * FROM inventory;
# Quit
\quit

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
