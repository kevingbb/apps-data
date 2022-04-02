#!/bin/bash

# Variables
PREFIX="appsdata"
RG="${PREFIX}-rg"
LOC="westeurope"
DATE=$(date +%Y%m%d)
NAME="${PREFIX}${DATE}"
# And A Couple Extra for PostgreSQL
PGNAME="${NAME}pgsqlsvr"
PG_ADMIN="myadmin"
PG_PASSWORD=""
# And for AKS (Assuming Already Created)
AKS_RG=akskh01-rg
AKS_NAME=akskh0120220318
# And for ACR (Assuming Already Created)
ACR_RG=akskh01-rg
ACR_NAME=akskh01acr

# Get AKS Credentials
az aks get-credentials -g $AKS_RG -n $AKS_NAME --admin
# Validate AKS Connectivty
alias k=kubectl
k get no
k get po -A
# Attach ACR to AKS
az aks update -g $AKS_RG -n $AKS_NAME --attach-acr $ACR_NAME

# Create PostgreSQL Resource Group
az group create --name $RG --location $LOC > /dev/null

# Create PostgreSQL Server
az postgres flexible-server create -g $RG -n $PGNAME -l $LOC \
  --admin-user $PG_ADMIN \
  --admin-password $PG_PASSWORD \
  --public-access 0.0.0.0 \
  --sku-name Standard_D2ds_v4 \
  --tier GeneralPurpose \
  --storage-size 32 \
  --version 13

# Get Details
az postgres flexible-server show -g $RG -n $PGNAME
# Get Parameters
az postgres flexible-server parameter list -g $RG --server-name $PGNAME
# Disable SSL - Avoids Downloading TLS Cert
az postgres flexible-server parameter set -g $RG --server-name $PGNAME --name require_secure_transport --value off
# Add Firewall Rule
az postgres flexible-server firewall-rule create -g $RG --name $PGNAME --rule-name AllowMyIP --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255

# Connect to PostgreSQL DB with CLI or Docker
# Try with psql CLI
psql --host="${PGNAME}.postgres.database.azure.com" --port=5432 \
  --username="${PG_ADMIN}" \
  --dbname=postgres
# OR Docker Container
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

# Build Container Image(s)
# API
cd /workspace/apps/api
az acr build --registry $ACR_NAME --image appsdata/api:v1 --file Dockerfile .
# UI
cd /workspace/apps/ui
az acr build --registry $ACR_NAME --image appsdata/ui:v1 --file Dockerfile .
# Test App
docker run -it -p 8080:80 --rm --name appsdata-api $ACR_NAME/appsdata/api:v2
docker run -it -p 8080:80 --rm --nameappsdata-ui $ACR_NAME/appsdata/ui:v2

# Deploy App to AKS
cd /workspace/scripts
k apply -f api.yaml
k apply -f ui.yaml

# Test AKS Deployed App
# Get
curl http://localhost:8080/inventory/
curl http://20.103.202.53/api/tutorials/
# Add
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"id":1,"title":"FirstOne","description":"This is the first one.","published":"false"}' \
  http://localhost:8080/inventory/
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"id":1,"title":"FirstOne","description":"This is the first one.","published":"false"}' \
  http://20.103.202.53/api/tutorials/
# Update
curl http://localhost:8080/inventory/1
curl --header "Content-Type: application/json" \
  --request PUT \
  --data '{"id":1,"title":"FirstOneEdited","description":"This is the first one.","published":"true"}' \
  http://localhost:8080/inventory/1
curl http://localhost:8080/inventory/1
