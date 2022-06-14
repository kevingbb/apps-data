<template>
  <div
    v-if="currentTutorial"
    class="edit-form"
  >
    <h4>Tutorial</h4>
    <form>
      <div class="form-group">
        <label for="title">Title</label>
        <input
          id="title"
          v-model="currentTutorial.title"
          type="text"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="description">Description</label>
        <input
          id="description"
          v-model="currentTutorial.description"
          type="text"
          class="form-control"
        >
      </div>

      <div class="form-group">
        <label><strong>Status:</strong></label>
        {{ currentTutorial.published ? "Published" : "Pending" }}
      </div>
    </form>

    <button
      v-if="currentTutorial.published"
      class="badge bg-primary mr-2"
      @click="updatePublished(false)"
    >
      UnPublish
    </button>
    <button
      v-else
      class="badge bg-primary mr-2"
      @click="updatePublished(true)"
    >
      Publish
    </button>

    <button
      class="badge bg-danger mr-2"
      @click="deleteTutorial"
    >
      Delete
    </button>

    <button
      type="submit"
      class="badge bg-success"
      @click="updateTutorial"
    >
      Update
    </button>
    <p>{{ message }}</p>
  </div>

  <div v-else>
    <br>
    <p>Please click on a Tutorial...</p>
  </div>
</template>

<script>
import TutorialDataService from "../services/TutorialDataService";

export default {
  name: "DetailTutorial",
  data() {
    return {
      currentTutorial: null,
      message: ''
    };
  },
  mounted() {
    this.message = '';
    this.getTutorial(this.$route.params.id);
  },
  methods: {
    getTutorial(id) {
      TutorialDataService.get(id)
        .then(response => {
          this.currentTutorial = response.data;
          console.log(response.data);
        })
        .catch(e => {
          console.log(e);
        });
    },

    updatePublished(status) {
      var data = {
        id: this.currentTutorial.id,
        title: this.currentTutorial.title,
        description: this.currentTutorial.description,
        published: status
      };

      TutorialDataService.update(this.currentTutorial.id, data)
        .then(response => {
          console.log(response.data);
          this.currentTutorial.published = status;
          this.message = 'The status was updated successfully!';
        })
        .catch(e => {
          console.log(e);
        });
    },

    updateTutorial() {
      TutorialDataService.update(this.currentTutorial.id, this.currentTutorial)
        .then(response => {
          console.log(response.data);
          this.message = 'The tutorial was updated successfully!';
        })
        .catch(e => {
          console.log(e);
        });
    },

    deleteTutorial() {
      TutorialDataService.delete(this.currentTutorial.id)
        .then(response => {
          console.log(response.data);
          this.$router.push({ name: "tutorials" });
        })
        .catch(e => {
          console.log(e);
        });
    }
  }
};
</script>

<style>
  .edit-form {
    max-width: 300px;
    margin: auto;
  }
</style>
