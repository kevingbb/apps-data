# build stage
FROM node:lts-alpine as base
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "./server.js"]
