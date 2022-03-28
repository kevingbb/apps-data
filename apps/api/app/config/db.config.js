module.exports = {
  HOST: process.env.APP_HOST || "localhost",
  USER: process.env.APP_USER || "postgres",
  PASSWORD: process.env.APP_PASSWORD || "postgres",
  DB: process.env.APP_DB || "tutorials",
  dialect: process.env.APP_DIALECT || "postgres",
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
};
