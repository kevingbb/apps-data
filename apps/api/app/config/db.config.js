module.exports = {
  HOST: process.env.APP_HOST || "localhost",
  USER: process.env.APP_USER || "postgres",
  PASSWORD: process.env.APP_PASSWORD || "postgres",
  DB: process.env.APP_DB || "tutorials",
  DB_PORT: process.env.DB_PORT || "5432",
  SSL_ENABLED: process.env.SSL_ENABLED || true,
  dialect: process.env.APP_DIALECT || "postgres",
  pool: {
    max: 10, //Maximum number of connection in pool
    min: 2, //Minimum number of connection in pool
    acquire: 30000,  //The maximum time, in milliseconds, that pool will try to get connection before throwing error
    idle: 10000, //The maximum time, in milliseconds, that pool will try to get connection before throwing error
    evict: 1000 //The time interval, in milliseconds, after which sequelize-pool will remove idle connections.
  }
};
