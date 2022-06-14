import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import paginate from 'vuejs-paginate-next';
import 'bootstrap/dist/css/bootstrap.min.css'

const app = createApp(App)

// Register Paginate component globally
// eslint-disable-next-line
app.component('paginate', paginate)

// Register Router
app.use(router)

// Mount Vue Instance
app.mount('#app')
