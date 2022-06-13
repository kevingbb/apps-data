# Single Availability Zone Deployment 

#Create namespace 
```bash
APP_NAMESPACE=nodeapp-single
kubectl create namespace $APP_NAMESPACE
```



## Create secret 
Depending on your database engine of choice, choose option 1 (PostgreSQL) or option 2 MySQL

## Option 1 PostgreSQL 

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
## Option 2 MySQL 
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

##Define variables 
```bash
DATE=$(date +%Y%m%d)
PREFIX="singleappsdata"
SINGLE_API_DNS="${PREFIX}${DATE}api" #we make use of the new AKS DNS lables feature 
SINGLE_UI_DNS="${PREFIX}${DATE}ui" #we make use of the new AKS DNS lables feature 
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
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
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
    service.beta.kubernetes.io/azure-dns-label-name: ${SINGLE_API_DNS}
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

##Now deploy the UI
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
            "VUE_APP_APIURL": "http://${SINGLE_API_DNS}.${LOCATION}.cloudapp.azure.com/api/",
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
    service.beta.kubernetes.io/azure-dns-label-name: ${SINGLE_UI_DNS}
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

## Verify the deployment and the service 

##Verify the app landed in the correct AZ (you should see one node only)
```bash
kubectl -n $APP_NAMESPACE get pods -o wide
NAME                                  READY   STATUS    RESTARTS   AGE   IP            NODE                                NOMINATED NODE   READINESS GATES
singleappsdata-api-5df6b9b79c-4kckx   1/1     Running   0          84s   172.16.0.13   aks-nodepool1-18451697-vmss000000   <none>           <none>
singleappsdata-api-5df6b9b79c-8b4jw   1/1     Running   0          84s   172.16.0.11   aks-nodepool1-18451697-vmss000000   <none>           <none>
singleappsdata-api-5df6b9b79c-d96j9   1/1     Running   0          84s   172.16.0.28   aks-nodepool1-18451697-vmss000000   <none>           <none>
singleappsdata-ui-77976c67bc-8j5kh    1/1     Running   0          37s   172.16.0.18   aks-nodepool1-18451697-vmss000000   <none>           <none>
singleappsdata-ui-77976c67bc-cccpx    1/1     Running   0          37s   172.16.0.20   aks-nodepool1-18451697-vmss000000   <none>           <none>
singleappsdata-ui-77976c67bc-msslm    1/1     Running   0          37s   172.16.0.27   aks-nodepool1-18451697-vmss000000   <none>           <none>

#check which zone the node is in 
kubectl describe nodes aks-nodepool1-18451697-vmss000000 | grep -i topology.kubernetes.io/zone
                    topology.kubernetes.io/zone=eastus-1

#check if the services were created successfully
kubectl -n $APP_NAMESPACE get service
NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
singleappsdata-api-svc   LoadBalancer   10.0.186.70    20.50.31.207   80:30004/TCP   4m38s
singleappsdata-ui-svc    LoadBalancer   10.0.249.149   51.138.45.95   80:32271/TCP   2m50s
```


## Check the app 

### Check the API APP 
#get all tutorials, you should receive an empty response 
```bash
curl http://$SINGLE_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/

#add a tutorial 
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{"title":"testtest","description":"This is the third one.","published":"false"}' \
  http://$SINGLE_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/

#verify again, you should see the tutorial that you just added 
curl http://$SINGLE_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/
```
### Check the UI app 
#Open a browser and head to (replace the variable with its value) http://$SINGLE_UI_DNS.$LOCATION.cloudapp.azure.com or for convenience run the below command and copy-paste in the browser 
```bash
echo http://$SINGLE_UI_DNS.$LOCATION.cloudapp.azure.com
```



## Performance test the app 
We will use Azure Load Testing 

[Insert screenshot here ]



## clean up
```bash 
kubectl delete namespace $APP_NAMESPACE
```

**Follow to next section [Multi Availability Zones Deployment](2-multiaz.md)