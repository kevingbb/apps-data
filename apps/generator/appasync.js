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

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Set Timer Interval
timerInterval = process.env.TIMER_INTERVAL || 2000

async function startLoop () {
  while(true) {
    let tutorialDataService = new TutorialDataService()
    let id = null
    let title = null

    // Random string generator routines.
    // let random = Math.random()
    // console.log(random)
    // console.log(random.toString(36))
    // console.log((random + 1).toString(36).substring(7))
    // console.log((random + 1).toString(36).substring(2))
    // console.log(random.toString(36).slice(2, 7))
    // console.log(random.toString(36).replace(/[^a-z]+/g, '').substr(0, 10))
    // console.log(new Array(5).join().replace(/(.|$)/g, function(){return ((Math.random()*36)|0).toString(36)[Math.random()<.5?"toString":"toUpperCase"]();}))
    // console.log(new Array(10).join().replace(/(.|$)/g, function(){return ((Math.random()*36)|0).toString(36)[Math.random()<.5?"toString":"toUpperCase"]();}))

    // Create New Record
    try {
      let createData = {
        title: "Title" + new Array(5).join().replace(/(.|$)/g, function(){return ((Math.random()*36)|0).toString(36)[Math.random()<.5?"toString":"toUpperCase"]();}),
        description: "Description" + new Array(20).join().replace(/(.|$)/g, function(){return ((Math.random()*36)|0).toString(36)[Math.random()<.5?"toString":"toUpperCase"]();})
      }
      const response = await tutorialDataService.create(createData)
      id = response.data.id
      title = response.data.title
      console.log('CREATE OPERATION - ' + new Date() + ' - ID: ' + id)
    }
    catch(error) {
      console.error('CREATE ERROR - ' + new Date() + ' - ' + error.message)
    }

    // Read Created Record
    try {
      const response = await tutorialDataService.get(id)
      const { title } = response.data
      console.log('READ   OPERATION - ' + new Date() + ' - ID: ' + id + ' - Title: ' + title)
    }
    catch(error) {
      console.error('READ   ERROR - ' + new Date() + ' - ' + error.message)
    }
    
    // Search Existing Records
    try {
      let params = {}
      params["title"] = title
      params["page"] = 0
      params["size"] = 3
    
      const response = await tutorialDataService.getAll(params)
      const { totalItems, totalPages } = response.data
      console.log('SEARCH OPERATION - ' + new Date() + ' - Total Items: ' + totalItems + ' - Total Pages: ' + totalPages)
    }
    catch(error) {
      console.error('SEARCH ERROR - ' + new Date() + ' - ' + error.message)
    }

    await sleep(timerInterval)
  }
}

// Execute function based on Timer Interval
startLoop()
