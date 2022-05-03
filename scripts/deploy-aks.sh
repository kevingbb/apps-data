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
AKS_NAME=akskh0120220411
# And for ACR (Assuming Already Created)
ACR_RG=akskh01-rg
ACR_NAME=akskh01acr
# Load Balancer DNS Names
API_DNS="${PREFIX}${DATE}api"
UI_DNS="${PREFIX}${DATE}ui"

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
  --sku-name Standard_B1ms \
  --tier Burstable \
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
az acr login -n $ACR_NAME
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
# First the API
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  labels:
    app: appsdata-api
    environment: dev
  name: appsdata-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: appsdata-api
      environment: dev
  template:
    metadata:
      labels:
        app: appsdata-api
        environment: dev
    spec:
      containers:
      - image: ${ACR_NAME}.azurecr.io/appsdata/api:v1
        name: appsdata-api
        imagePullPolicy: Always
        env:
        - name: APP_HOST
          value: ${PGNAME}.postgres.database.azure.com
        - name: APP_USER
          value: myadmin
        - name: APP_PASSWORD
          value: ${PG_PASSWORD}
        - name: APP_DB
          value: tutorials
        - name: APP_DIALECT
          value: postgres
        ports:
        - name: http
          containerPort: 8080
        resources:
          requests:
            memory: "250Mi"
            cpu: "250m"
          limits:
            memory: "250Mi"
            cpu: "250m"
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  labels:
    app: appsdata-api
    environment: dev
  name: appsdata-api-svc
  annotations:
    service.beta.kubernetes.io/azure-dns-label-name: ${API_DNS}
spec:
  type: LoadBalancer
  ports:
  - name: "http"
    protocol: TCP
    port: 80
    targetPort: 8080
  selector:
    app: appsdata-api
    environment: dev
EOF
# Second the UI
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: config
data:
  config.js: |-
      const config = (() => {
          return {
            "VUE_APP_APIURL": "http://${API_DNS}.westeurope.cloudapp.azure.com/api/",
          };
        })();
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: default
  labels:
    app: appsdata-ui
    environment: dev
  name: appsdata-ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: appsdata-ui
      environment: dev
  template:
    metadata:
      labels:
        app: appsdata-ui
        environment: dev
    spec:
      containers:
      - image: ${ACR_NAME}.azurecr.io/appsdata/ui:v1
        name: appsdata-ui
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 80
        resources:
          requests:
            memory: "250Mi"
            cpu: "250m"
          limits:
            memory: "250Mi"
            cpu: "250m"
        volumeMounts:
        - name: config-js
          mountPath: /usr/share/nginx/html/config.js
          subPath: config.js
      restartPolicy: Always
      volumes:
      - name: config-js
        configMap:
          name: config
          items:
            - key: config.js
              path: config.js
---
apiVersion: v1
kind: Service
metadata:
  namespace: default
  labels:
    app: appsdata-ui
    environment: dev
  name: appsdata-ui-svc
  annotations:
    service.beta.kubernetes.io/azure-dns-label-name: ${UI_DNS}
spec:
  type: LoadBalancer
  ports:
  - name: "http"
    protocol: TCP
    port: 80
    targetPort: 80
  selector:
    app: appsdata-ui
    environment: dev
EOF
# Or Manually Manipulate Values in Files
cd /workspace/scripts
k apply -f api.yaml
k apply -f ui.yaml

# Test AKS Deployed App
# First API
# Get
curl http://${API_DNS}.westeurope.cloudapp.azure.com/api/tutorials/
# Add
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"id":1,"title":"FirstOne","description":"This is the first one.","published":"false"}' \
  http://${API_DNS}.westeurope.cloudapp.azure.com/api/tutorials/
# Update
curl --header "Content-Type: application/json" \
  --request PUT \
  --data '{"id":1,"title":"FirstOneEdited","description":"This is the first one.","published":"true"}' \
  http://${API_DNS}.westeurope.cloudapp.azure.com/api/tutorials/1
curl http://${API_DNS}.westeurope.cloudapp.azure.com/api/tutorials/1
# Second UI
echo "http://${UI_DNS}.westeurope.cloudapp.azure.com"
