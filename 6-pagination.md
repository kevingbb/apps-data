# Add Pagination to App

Adding pagination to an application can help reduce load on the database and improve overall application response time by only fetching a subset of the data that is needed.

## Add Pagination to API 

##add pagination to api
```javascript
// apps/api/app/models/tutorial.model.js

// Add methods for Pagination Calculations
const getPagination = (page, size) => {
  const limit = size ? +size : 3;
  const offset = page ? page * limit : 0;
  return { limit, offset };
};

const getPagingData = (data, page, limit) => {
  const { count: totalItems, rows: tutorials } = data;
  const currentPage = page ? +page : 0;
  const totalPages = Math.ceil(totalItems / limit);
  return { totalItems, tutorials, totalPages, currentPage };
};

...

// Retrieve all Tutorials from the database.
exports.findAll = (req, res) => {
  const { page, size, title } = req.query;
  var condition = title ? { title: { [Op.iLike]: `%${title}%` } } : null;
  // Calculate Pagination Values
  const { limit, offset } = getPagination(page, size);
  // Pass Pagination Values to findAndCountAll Method
  Tutorial.findAndCountAll({ where: condition, limit, offset })
    .then(data => {
      const response = getPagingData(data, page, limit);
      res.send(response);
    })
    .catch(err => {
      res.status(500).send({
        message:
          err.message || "Some error occurred while retrieving tutorials."
      });
    });
};

...

// find all published Tutorial
exports.findAllPublished = (req, res) => {
  const { page, size } = req.query;
  // Calculate Pagination Values
  const { limit, offset } = getPagination(page, size);
  // Pass Pagination Values to findAndCountAll Method
  Tutorial.findAndCountAll({ where: { published: true }, limit, offset })
    .then(data => {
      const response = getPagingData(data, page, limit);
      res.send(response);
    })
    .catch(err => {
      res.status(500).send({
        message:
          err.message || "Some error occurred while retrieving tutorials."
      });
    });
};
```

##test Pagination
```bash
curl http://$SINGLE_API_DNS.$LOCATION.cloudapp.azure.com/api/tutorials/?page=0&size=3
```

##add pagination to ui
```bash
npm install vuejs-paginate-next --save
```

```javascript
// apps/ui/src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
// Import for Pagination
import paginate from 'vuejs-paginate-next';
import 'bootstrap/dist/css/bootstrap.min.css'

const app = createApp(App)

// Register paginate component globally
// eslint-disable-next-line
app.component('paginate', paginate)

// Register Router
app.use(router)

// Mount Vue Instance
app.mount('#app')
```

```javascript
// apps/ui/src/services/TutorialDataService.js
...
  // Add params to database call
  getAll(params) {
    return http.get("/tutorials", {params});
  }

...
```

```javascript
// apps/ui/src/components/TutorialsList.vue
...
    <!-- Add 'paginate' component which was registered globally in main.js -->
    <div class="col-md-12">
      <div class="mb-3">
        Items per Page:
        <select
          v-model.number="pageSize"
          @change="handlePageSizeChange($event)"
        >
          <option
            v-for="size in pageSizes"
            :key="size"
            :value="size"
          >
            {{ size }}
          </option>
        </select>
      </div>
      <!-- Added paginate component-->
      <paginate
        v-model="page"
        :page-count="pageCount"
        :page-range="pageSize"
        :margin-pages="2"
        :click-handler="handlePageChange"
        :prev-text="'Prev'"
        :next-text="'Next'"
        :container-class="'pagination'"
        :page-class="'page-item'"
      />
    </div>
    <div class="col-md-6">
      <h4>Tutorials List</h4>
      <ul
        id="tutorials-list"
        class="list-group"
      >
        <li
          v-for="(tutorial, index) in tutorials"
          :key="index"
          class="list-group-item"
          :class="{ active: index == currentIndex }"
          @click="setActiveTutorial(tutorial, index)"
        >
          {{ tutorial.title }}
        </li>
      </ul>
      <button
        class="m-3 btn btn-sm btn-danger"
        @click="removeAllTutorials"
      >
        Remove All
      </button>
    </div>

...

<!-- Added properties to Page for Pagination. -->
export default {
  name: "TutorialsList",
  data() {
    return {
      tutorials: [],
      currentTutorial: null,
      currentIndex: -1,
      searchTitle: "",
      page: 1,
      count: 0,
      pageCount: 0,
      pageSize: 3,
      pageSizes: [3, 6, 9],
      title: "",
    };
  },

...
  
  <!-- Added methods to set Pagination parameters and pass through to TutorialDataService.js database calls. -->
  methods: {
    getRequestParams(searchTitle, page, pageSize) {
      let params = {};
      if (searchTitle) {
        params["title"] = searchTitle;
      }
      if (page) {
        params["page"] = page - 1;
      }
      if (pageSize) {
        params["size"] = pageSize;
      }
      return params;
    },
    retrieveTutorials() {
      const params = this.getRequestParams(
        this.searchTitle,
        this.page,
        this.pageSize
      );
      TutorialDataService.getAll(params)
        .then(response => {
          const { tutorials, totalItems, totalPages } = response.data;
          this.tutorials = tutorials;
          this.count = totalItems;
          this.pageCount = totalPages;
          console.log(response.data);
        })
        .catch(e => {
          console.log(e);
        });
    },
    handlePageChange(value) {
      this.page = value;
      this.currentTutorial = null;
      this.currentIndex = -1;
      this.retrieveTutorials();
    },
    handlePageSizeChange(event) {
      this.pageSize = parseInt(event.target.value);
      this.currentTutorial = null;
      this.currentIndex = -1;
      this.page = 1;
      this.retrieveTutorials();
    },
```