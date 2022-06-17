# build stage
FROM node:lts-alpine as base
ENV TIMER_INTERVAL 2000
ENV VUE_APP_APIURL "http://localhost:8080/api"
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN chown -R node /app
USER node
CMD ["node", "./appasync.js"]

