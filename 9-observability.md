# Add Observability to App

Adding observability to an application will help with troubleshooting issues and identifying potential bottlenecks as the application scales.

## Add Application Insights

##add app insights to api
```bash
cd apps/api
npm install applicationinsights --save
```

```javascript
// apps/api/server.js
const appInsights = require("applicationinsights");
// Set APPLICATIONINSIGHTS_CONNECTION_STRING environment variable in order to not have to pass it via setup("<connection_string>").
appInsights.setup()
    .setAutoDependencyCorrelation(true)
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true, true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectConsole(true)
    .setUseDiskRetryCaching(true)
    .setSendLiveMetrics(false)
    .setDistributedTracingMode(appInsights.DistributedTracingModes.AI);
    // Provide a CloudRole name.
appInsights.defaultClient.context.tags[appInsights.defaultClient.context.keys.cloudRole] = "AppsDataAPI"
appInsights.start();
```

##add app insights to ui
```bash
cd apps/ui
npm install @microsoft/applicationinsights-web --save
```

```javascript
// apps/ui/public/config.js
const config = (() => {
    return {
      "VUE_APP_APIURL": "http://localhost:8080/api",
      "APPLICATIONINSIGHTS_CONNECTION_STRING": "<<CONNECTION_STRING_GOES_HERE>>"
    };
  }
)();
```

```javascript
// apps/ui/src/main.js

...

// Add Application Insights
import { ApplicationInsights } from '@microsoft/applicationinsights-web'
const appInsights = new ApplicationInsights({
    config: {
        connectionString: config.APPLICATIONINSIGHTS_CONNECTION_STRING,
        enableCorsCorrelation: true,
        distributedTracingMode: ApplicationInsights.AI_AND_W3C,
        enableRequestHeaderTracking: true,
        enableResponseHeaderTracking: true,
        enableAutoRouteTracking: true
    }
});
appInsights.loadAppInsights();
appInsights.addTelemetryInitializer((telemetryItem) => {
    telemetryItem.tags['ai.cloud.role'] = 'AppsDataUI';
});
appInsights.trackPageView(); // Manually call trackPageView to establish the current user/session/pageview

...
```
