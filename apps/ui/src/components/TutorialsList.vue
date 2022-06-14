<template>
  <div class="list row">
    <div class="col-md-8">
      <div class="input-group mb-3">
        <input
          v-model="searchTitle"
          type="text"
          class="form-control"
          placeholder="Search by title"
          @keyup.enter="page = 1; currentTutorial = null; currentIndex = -1; retrieveTutorials();"
        >
        <div class="input-group-append">
          <button
            class="btn btn-outline-secondary"
            type="button"
            @click="page = 1; currentTutorial = null; currentIndex = -1; retrieveTutorials();"
          >
            Search
          </button>
        </div>
      </div>
    </div>
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
    <div class="col-md-6">
      <div v-if="currentTutorial">
        <h4>Tutorial</h4>
        <div>
          <label><strong>Title:</strong></label> {{ currentTutorial.title }}
        </div>
        <div>
          <label><strong>Description:</strong></label> {{ currentTutorial.description }}
        </div>
        <div>
          <label><strong>Status:</strong></label> {{ currentTutorial.published ? "Published" : "Pending" }}
        </div>
        <router-link
          :to="'/tutorials/' + currentTutorial.id"
          class="badge bg-warning"
        >
          Edit
        </router-link>
      </div>
      <div v-else>
        <br>
        <p>Please click on a Tutorial...</p>
      </div>
    </div>
  </div>
</template>

<script>
import TutorialDataService from "../services/TutorialDataService";

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
  mounted() {
    this.retrieveTutorials();
  },
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
    refreshList() {
      this.retrieveTutorials();
      this.currentTutorial = null;
      this.currentIndex = -1;
    },
    setActiveTutorial(tutorial, index) {
      this.currentTutorial = tutorial;
      this.currentIndex = tutorial ? index : -1;
    },
    removeAllTutorials() {
      TutorialDataService.deleteAll()
        .then(response => {
          console.log(response.data);
          this.refreshList();
        })
        .catch(e => {
          console.log(e);
        });
    },
  }
};
</script>

<style>
  .list {
    text-align: left;
    max-width: 750px;
    margin: auto;
  }
</style>
