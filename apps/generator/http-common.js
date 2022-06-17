const axios = require("axios");

const http = axios.create({
  baseURL: process.env.VUE_APP_APIURL || "http://localhost:8080/api",
  headers: {
    "Content-type": "application/json"
  }
});

exports.http = http;
