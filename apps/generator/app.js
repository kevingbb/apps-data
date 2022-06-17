const { http } = require('./http-common.js');

class TutorialDataService {
  getAll(params) {
    return http.get("/tutorials", {params});
  }

  get(id) {
    return http.get(`/tutorials/${id}`);
  }

  create(data) {
    return http.post("/tutorials", data);
  }

  update(id, data) {
    return http.put(`/tutorials/${id}`, data);
  }

  delete(id) {
    return http.delete(`/tutorials/${id}`);
  }

  deleteAll() {
    return http.delete(`/tutorials`);
  }

  findByTitle(title) {
    return http.get(`/tutorials?title=${title}`);
  }
}

function startLoop () {
  let tutorialDataService = new TutorialDataService()
  let id = null

  // Create New Record
  let createData = {
    title: "Title10000",
    description: "Description10000"
  }
  tutorialDataService.create(createData)
    .then(function (response) {
      id = response.data.id
      console.log('CREATE OPERATION - ' + new Date() + ' - ID: ' + id)
    })
    .catch(function(error) {
      console.error('CREATE ERROR - ' + error.message)
    })
      .then(function(){
        // Read Created Record
        tutorialDataService.get(id)
          .then(function(response) {
            const { title } = response.data
            console.log('READ   OPERATION - ' + new Date() + ' - ID: ' + id + ' - Title: ' + title)
          })
          .catch(function(error) {
            console.error('READ ERROR - ' + error.message)
          })
      })
        .finally(function(){
          // Search Existing Records
          let params = {}
          params["title"] = ""
          params["page"] = 0
          params["size"] = 3
    
          tutorialDataService.getAll(params)
            .then(function(response) {
              const { totalItems, totalPages } = response.data
              console.log('SEARCH OPERATION - ' + new Date() + ' - Total Items: ' + totalItems + ' - Total Pages: ' + totalPages)
            })
            .catch(function(error) {
              console.error('SEARCH ERROR - ' + error.message)
            })
        })
}

timerInterval = process.env.TIMER_INTERVAL || 2000

setInterval(startLoop, timerInterval)
