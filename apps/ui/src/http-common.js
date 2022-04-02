import axios from "axios";

export default axios.create({
  baseURL: config.VUE_APP_APIURL,
  headers: {
    "Content-type": "application/json"
  }
});
