
# Apps and Data Sample

This is an Apps + Data sample application based on the following links:

* https://www.bezkoder.com/vue-node-express-postgresql/

## Local Setup

1. Open in Codespaces or as a DevContainer in VS Code
2. Look at scripts/psql-load.sh to Create localhost "Tutorials" Database
3. Start API on http://localhost:8080

```bash
cd apps/api
npm install
npm run start
```

4. Start UI on http://localhost:8081

```bash
cd ../ui
npm install
npm run serve
```

5. Open http://localhost:8081 and Test App

## Content 
* [Provisioning](0-provisioning.md)
* [Single Availability Zone Deployment](1-singleaz.md)
* [Multi Availability Zones Deployment](2-multiaz.md)
* [Multi Availability Zones Deployment with Preference ](3-multiazp.md)
* [Use Connection Pooling](4-connection_pooling.md)
* [Add Caching](5-cache.md)
* [Pagination](6-pagination.md)
* [Scaling](7-scaling.md)
* [Add Authentication](8-Authentication.md)
* [Observability](9-observability.md)
* [Benchmarking](10-pgbench.md)