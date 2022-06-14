import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
// import { BootstrapVue3 } from 'bootstrap-vue-3'
// import 'bootstrap'
import 'bootstrap/dist/css/bootstrap.min.css'
// import 'bootstrap/dist/css/bootstrap.css'
// import 'bootstrap-vue-3/dist/bootstrap-vue-3.css'

// createApp(App).use(BootstrapVue3)
// createApp(App).use(paginate)
createApp(App).use(router).mount('#app')
