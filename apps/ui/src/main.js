import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import paginate from 'vuejs-paginate-next';
import 'bootstrap/dist/css/bootstrap.min.css'

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

const app = createApp(App)

// Register Paginate component globally
// eslint-disable-next-line
app.component('paginate', paginate)

// Register Router
app.use(router)

// Mount Vue Instance
app.mount('#app')
