# Multi Availability Zone Deployment with Preference for one AZ

##Create namespace 
```
APP_NAMESPACE=nodeapp-mazp
kubectl create namespace $APP_NAMESPACE
```

## Create secret 
Depending on your database engine of choice, choose option 1 (PostgreSQL) or option 2 MySQL

### Option 1 PostgreSQL 

```bash
kubectl create secret --namespace $APP_NAMESPACE generic db-connection \
  --from-literal=APP_HOST=$DB_FQDN \
  --from-literal=APP_USER=$ADMIN_USER \
  --from-literal=APP_PASSWORD=$ADMIN_PASS \
  --from-literal=APP_DB='tutorials' \
  --from-literal=DB_PORT='5432' \
  --from-literal=SSL_ENABLED=true \
  --from-literal=APP_DIALECT=postgres
```
### Option 2 MySQL 
```bash
kubectl create secret --namespace $APP_NAMESPACE generic db-connection \
  --from-literal=APP_HOST=$DB_FQDN \
  --from-literal=APP_USER=$ADMIN_USER \
  --from-literal=APP_PASSWORD=$ADMIN_PASS \
  --from-literal=APP_DB='tutorials' \
  --from-literal=DB_PORT='3306' \
  --from-literal=SSL_ENABLED=false \
  --from-literal=APP_DIALECT=mysql
```

#verify secret 
```bash
kubectl get secrets db-connection -n $APP_NAMESPACE -o yaml  
```


## Deploy Application to Kubernetes

```bash
##Define Variables
DATE=$(date +%Y%m%d)
PREFIX="multiazpappsdata"
MULTIAZP_API_DNS="${PREFIX}${DATE}api" #we make use of the new AKS DNS lables feature 
MULTIAZP_UI_DNS="${PREFIX}${DATE}ui" #we make use of the new AKS DNS lables feature 
API_APP_NAME="${PREFIX}-api"
UI_APP_NAME="${PREFIX}-ui"
```

##Deploy the API APP 
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: ${APP_NAMESPACE}
  labels:
    app: ${API_APP_NAME}
    environment: dev
  name: ${API_APP_NAME}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${API_APP_NAME}
      environment: dev
  template:
    metadata:
      labels:
        app: ${API_APP_NAME}
        environment: dev
    spec:
      affinity: 
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                - ${DB_ZONE}
      containers:
      - image: ${ACR_NAME}.azurecr.io/appsdata/api:v1
        name: ${API_APP_NAME}
        imagePullPolicy: Always
        env:
        - name: APP_HOST
          valueFrom:
            secretKeyRef:
              name: db-connection
              key: APP_HOST
        - name: APP_USER
          valueFrom:
            secretKeyRef:
              name: db-connection
              key: APP_USER        
        - name: APP_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-connection
              key: APP_PASSWORD
        - name: APP_DB
          valueFrom:
            secretKeyRef:
              name: db-connection
              key: APP_DB
        - name: DB_PORT
          valueFrom:
            secretKeyRef:
              name: db-connection
              key: DB_PORT               
        - name: APP_DIALECT
          valueFrom:
            secretKeyRef:
              name: db-connection
              key: APP_DIALECT
        - name: SSL_ENABLED
          valueFrom:
            secretKeyRef:
              name: db-connection
              key: SSL_ENABLED
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
---
apiVersion: v1
kind: Service
metadata:
  namespace: ${APP_NAMESPACE}
  labels:
    app: ${API_APP_NAME}
    environment: dev
  name: ${API_APP_NAME}-svc
  annotations:
    service.beta.kubernetes.io/azure-dns-label-name: ${MULTIAZP_API_DNS}
spec:
  type: LoadBalancer
  ports:
  - name: "http"
    protocol: TCP
    port: 80
    targetPort: 8080
  selector:
    app: ${API_APP_NAME}
    environment: dev
EOF
```

##Deploy the UI App 
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: ${APP_NAMESPACE}
  name: config
data:
  config.js: |-
      const config = (() => {
          return {
            "VUE_APP_APIURL": "http://${MULTIAZP_API_DNS}.${LOCATION}.cloudapp.azure.com/api/",
          };
        })();
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: ${APP_NAMESPACE}
  labels:
    app: ${UI_APP_NAME}
    environment: dev
  name: ${UI_APP_NAME}
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ${UI_APP_NAME}
      environment: dev
  template:
    metadata:
      labels:
        app: ${UI_APP_NAME}
        environment: dev
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - ${API_APP_NAME}
            topologyKey: topology.kubernetes.io/zone
      containers:
      - image: ${ACR_NAME}.azurecr.io/appsdata/ui:v1
        name: ${UI_APP_NAME}
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
  namespace: ${APP_NAMESPACE}
  labels:
    app: ${UI_APP_NAME}
    environment: dev
  name: ${UI_APP_NAME}-svc
  annotations:
    service.beta.kubernetes.io/azure-dns-label-name: ${MULTIAZP_UI_DNS}
spec:
  type: LoadBalancer
  ports:
  - name: "http"
    protocol: TCP
    port: 80
    targetPort: 80
  selector:
    app: ${UI_APP_NAME}
    environment: dev
EOF
```

## verify the deployment and services 
```bash
kubectl -n $APP_NAMESPACE get pods 

kubectl -n $APP_NAMESPACE get service

#verify the app landed in the correct AZ 

kubectl -n $APP_NAMESPACE get pods -o wide
```


## Verify the app 

##Check the API APP 
```bash
#get all tutorials 
curl http://$MULTIAZP_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/
#add a tutorial 
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"title":"ThirdOne","description":"This is the third one.","published":"false"}' \
  http://$MULTIAZP_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/

#verify again 
curl http://$MULTIAZP_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/
```
##Check the UI app 
Open a browser and head to (replace the variable with its value) http://$MULTIAZP_UI_DNS.$LOCATION.cloudapp.azure.com

## Performance test the app 
We will use Azure Load Testing 

[Insert screenshot here ]


## simulate AZ failure and observe 

#Open another terminal and and run the below command 
```
while true;do curl -I http://$MULTIAZP_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/ 2>/dev/null | head -n 1 | cut -d$' ' -f2;  done
```

#Remove the node where the application is 
```bash
kubectl get nodes 

kubectl cordon aks-nodepool1-33800249-vmss000001
kubectl drain aks-nodepool1-33800249-vmss000001 --delete-emptydir-data --ignore-daemonsets
kubectl -n nodeapp-mazp get pods -o wide 
```

You should see limited to no failure in the application as the pods are moving to a different availability zone 
##Uncordon the node 
```bash
kubectl uncordon aks-nodepool1-33800249-vmss000001
```

## clean up 
```bash
kubectl delete namespace $APP_NAMESPACE 
```
