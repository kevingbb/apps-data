
# Provisioning

## Credits 
This app was refactored from its original code which can be found here -> (https://www.bezkoder.com/vue-node-express-postgresql/)

## Deploy AKS Cluster 

```bash
##Define variables 
LOCATION=eastus # Location 
AKS_NAME=nodeapp
RG=$AKS_NAME-$LOCATION
AKS_VNET_NAME=$AKS_NAME-vnet # The VNET where AKS will reside
AKS_CLUSTER_NAME=$AKS_NAME-cluster # name of the cluster
AKS_VNET_CIDR=172.16.0.0/16
AKS_NODES_SUBNET_NAME=$AKS_NAME-subnet # the AKS nodes subnet
AKS_NODES_SUBNET_PREFIX=172.16.0.0/24
NETWORK_PLUGIN=azure
NETWORK_POLICY=calico
IDENTITY_NAME=$AKS_NAME`date +"%d%m%y"`
NODE_COUNT=3
NODES_SKU=Standard_D8d_v5
K8S_VERSION=$(az aks get-versions  -l $LOCATION --query 'orchestrators[-1].orchestratorVersion' -o tsv)
LOG_WORKSPACE_NAME=nodeapp-aks
```

##Create RG
```bash
az group create --name $RG --location $LOCATION
```

##Create VNET and Subnet for AKS 
```bash
az network vnet create \
  --name $AKS_VNET_NAME \
  --resource-group $RG \
  --location $LOCATION \
  --address-prefix $AKS_VNET_CIDR \
  --subnet-name $AKS_NODES_SUBNET_NAME \
  --subnet-prefix $AKS_NODES_SUBNET_PREFIX
```

##Create identity for the cluster 
```
az identity create --name $IDENTITY_NAME --resource-group $RG
#Get identity ID and Client ID 
IDENTITY_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RG --query id -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RG --query clientId -o tsv)

#get the RG ID
RG_ID=$(az group show -n $RG  --query id -o tsv)

#get the vnet ID
VNETID=$(az network vnet show -g $RG --name $AKS_VNET_NAME --query id -o tsv)


## assign permissions to the identity 
#Assign SP Permission to VNET and RG 
az role assignment create --assignee $IDENTITY_CLIENT_ID --scope $RG_ID --role Contributor
#Assign SP Permission to VNET
az role assignment create --assignee $IDENTITY_CLIENT_ID --scope $VNETID --role Contributor

#Validate Role Assignment
az role assignment list --assignee $IDENTITY_CLIENT_ID --all -o table


#get the subnet id 
AKS_VNET_SUBNET_ID=$(az network vnet subnet show --name $AKS_NODES_SUBNET_NAME -g $RG --vnet-name $AKS_VNET_NAME --query "id" -o tsv)
```

##Create Log Analytics Workspace 
```bash
az monitor log-analytics workspace create \
--resource-group $RG \
--workspace-name $LOG_WORKSPACE_NAME


#get workspace ID 
LOG_WORKSPACE_ID=$(az monitor log-analytics workspace show -g $RG -n $LOG_WORKSPACE_NAME --query id -o tsv)
```

##Deploy the cluster 
```bash
az aks create \
-g $RG \
-n $AKS_CLUSTER_NAME \
-l $LOCATION \
--node-count $NODE_COUNT \
--node-vm-size $NODES_SKU \
--network-plugin $NETWORK_PLUGIN \
--network-policy $NETWORK_POLICY \
--kubernetes-version $K8S_VERSION \
--generate-ssh-keys \
--vnet-subnet-id $AKS_VNET_SUBNET_ID \
--enable-addons monitoring \
--workspace-resource-id $LOG_WORKSPACE_ID \
--kubernetes-version $K8S_VERSION \
--zones 1 2 3 \
--enable-managed-identity \
--assign-identity $IDENTITY_ID \
--assign-kubelet-identity $IDENTITY_ID


### get the credentials 
az aks get-credentials -n $AKS_CLUSTER_NAME -g $RG



### test

#get nodes
kubectl get nodes  

#verify nodes spread across AZs
kubectl describe nodes | grep -i topology.disk.csi.azure.com/zone

                    topology.disk.csi.azure.com/zone=westeurope-1
                    topology.disk.csi.azure.com/zone=westeurope-2
                    topology.disk.csi.azure.com/zone=westeurope-3

```


##Create Azure Container Registry and attach it to the cluster 
```bash
### Define variable 
ACR_NAME=nodecr$LOCATION

### Create ACR 
az acr create \
--resource-group $RG \
--name $ACR_NAME \
--sku Basic

### get the login server 
ACR_LOGIN_SERVER=$(az acr show -n $ACR_NAME -g $RG --query loginServer --output tsv)

### attach ACR to AKS 
az aks update \
-n $AKS_CLUSTER_NAME \
-g $RG \
--attach-acr $ACR_NAME
```

## Database Provisioning
We will have 2 options here, Option1 is PostgreSQL and Option2 is MySQL, choose based on your desired DB engine.


### [Option 1] Deploy Azure PostgreSQL flexible server 


##Create subnet for postgresql 
```bash
#Define variables 
POSTGRES_SUBNET_NAME=postgres-subnet
POSTGRES_SUBNET_PREFIX=172.16.1.0/24

#create subnet
az network vnet subnet create \
  --name $POSTGRES_SUBNET_NAME \
  --resource-group $RG \
  --vnet-name $AKS_VNET_NAME   \
  --address-prefix $POSTGRES_SUBNET_PREFIX

#get subnet ID 
POSTGRES_SUBNET_ID=$(az network vnet subnet show --name $POSTGRES_SUBNET_NAME -g $RG --vnet-name $AKS_VNET_NAME --query "id" -o tsv)
```

##Provision a single node Postgresql DB using Flexible Server
```bash
#### Define variable 
P_DB_NAME=nodepg
DB_SKU=Standard_D4ds_v4
STORAGE_SIZE=128
ADMIN_USER=moadmin
ADMIN_PASS=Postgres123$

#### Deploy DB

az postgres flexible-server create \
--resource-group $RG \
--name $P_DB_NAME \
--sku-name $DB_SKU \
--storage-size $STORAGE_SIZE \
--subnet $POSTGRES_SUBNET_ID \
--location $LOCATION \
--admin-user $ADMIN_USER \
--admin-pass $ADMIN_PASS \
--yes 

#### Enable diagnostics logs

#get DB and workspace ID 
P_DB_ID=$(az postgres flexible-server show -n $P_DB_NAME -g $RG --query id -o tsv)


#create diagnostics logs 
az monitor diagnostic-settings create  \
--name postgres-diagnostics \
--resource $P_DB_ID \
--logs    '[{"category": "PostgreSQLLogs","enabled": true}]' \
--metrics '[{"category": "AllMetrics","enabled": true}]' \
--workspace $LOG_WORKSPACE_ID

#show settings
az monitor diagnostic-settings show \
--resource $P_DB_ID \
--name postgres-diagnostics


#get the AZ where the DB is
P_DB_ZONE=$(az postgres flexible-server show -n $P_DB_NAME -g $RG --query availabilityZone -o tsv)
#the above command just gives us the number, we need the full name as in region-number
P_DB_ZONE=$LOCATION-$P_DB_ZONE
```


##Create database and insert some data 
```bash
##Get Database FQDN so we can connect 
DB_FQDN=$(az postgres flexible-server show -n $P_DB_NAME -g $RG --query fullyQualifiedDomainName -o tsv)

##Connect to DB using PSQL client and create the "tutorials" database

kubectl run psql --image tmaier/postgresql-client -i --rm --\
 postgresql://$ADMIN_USER:$ADMIN_PASS@$DB_FQDN/postgres <<EOF
CREATE DATABASE tutorials;
\l
\quit
EOF

##Bonus
##If you want to connect to the database and run some commands on your own
kubectl run -it --rm psql --image tmaier/postgresql-client -- postgresql://$ADMIN_USER:$ADMIN_PASS@$DB_FQDN/postgres 
```


## [Option 2] Deploy A single node Azure MySQL flexible server 


##Create subnet for postgresql 
```bash
#Define variables 
MYSQL_SUBNET_NAME=mysql-subnet
MYSQL_SUBNET_PREFIX=172.16.2.0/24

#create subnet
az network vnet subnet create \
  --name $MYSQL_SUBNET_NAME \
  --resource-group $RG \
  --vnet-name $AKS_VNET_NAME   \
  --address-prefix $MYSQL_SUBNET_PREFIX

#get subnet ID 
MYSQL_SUBNET_ID=$(az network vnet subnet show --name $MYSQL_SUBNET_NAME -g $RG --vnet-name $AKS_VNET_NAME --query "id" -o tsv)

### Provision a single PG DB

#### Define variable 
DB_NAME=nodemysql
DB_SKU=Standard_D4ds_v4
STORAGE_SIZE=128
ADMIN_USER=moadmin
ADMIN_PASS=Mysql123$
```

##Deploy DB
```bash
az mysql flexible-server create \
--resource-group $RG \
--name $DB_NAME \
--sku-name $DB_SKU \
--storage-size $STORAGE_SIZE \
--subnet $MYSQL_SUBNET_ID \
--location $LOCATION \
--admin-user $ADMIN_USER \
--admin-pass $ADMIN_PASS \
--tier GeneralPurpose \
--yes 

#### Enable diagnostics logs

#get DB and workspace ID 
DB_ID=$(az mysql flexible-server show -n $DB_NAME -g $RG --query id -o tsv)


#create diagnostics logs 
az monitor diagnostic-settings create  \
--name mysql-diagnostics \
--resource $DB_ID \
--logs    '[{"category": "MySqlSlowLogs","enabled": true}]' \
--metrics '[{"category": "AllMetrics","enabled": true}]' \
--workspace $LOG_WORKSPACE_ID

#show settings
az monitor diagnostic-settings show \
--resource $DB_ID \
--name mysql-diagnostics


#get the AZ where the DB is
DB_ZONE=$(az mysql flexible-server show -n $DB_NAME -g $RG --query availabilityZone -o tsv)
#the above command just gives us the number, we need the full name as in region-number
DB_ZONE=$LOCATION-$DB_ZONE






### create DB and insert some data 

##Get Database FQDN so we can connect 
DB_FQDN=$(az mysql flexible-server show -n $DB_NAME -g $RG --query fullyQualifiedDomainName -o tsv)

##Connect to DB using mysql-client and create the "tutorials" database

kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never --\
  mysql -u $ADMIN_USER -p $ADMIN_PASS -h $DB_FQDN <<EOF
CREATE DATABASE tutorials;
SHOW DATABASES;
EOF
```

## Build and Push the Application to Azure Container Registry
```bash
# Build and Push the API App
cd /apps/api
az acr build --registry $ACR_NAME --image appsdata/api:v1 --file Dockerfile .
# Build and Push the UI App 
cd /apps/ui
az acr build --registry $ACR_NAME --image appsdata/ui:v1 --file Dockerfile .
```


**Follow to next section [Single Availability Zone Deployment](1-singleaz.md)
