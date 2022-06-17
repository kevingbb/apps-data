const dbConfig = require("../config/db.config.js");

const Sequelize = require("sequelize");
const sequelize = new Sequelize(dbConfig.DB, dbConfig.USER, dbConfig.PASSWORD, {
  host: dbConfig.HOST,
  port: dbConfig.DB_PORT,
  dialect: dbConfig.dialect,
  dialectOptions: {
    ssl: dbConfig.SSL_ENABLED,
    logging: (...msg) => console.log(msg)
  },
  pool: {
    max: dbConfig.pool.max,
    min: dbConfig.pool.min,
    acquire: dbConfig.pool.acquire,
    idle: dbConfig.pool.idle
  },
  retry: {
    match: [
      Sequelize.ConnectionError,
      Sequelize.ConnectionTimedOutError,
      Sequelize.ConnectionRefusedError,
      Sequelize.DatabaseError,
      Sequelize.TimeoutError
    ],
    max: 3, // maximum amount of tries
    timeout: 10000, // throw if no response or error within millisecond timeout
    backoffBase: 3000, // Initial backoff duration in ms. Default: 100
    backoffExponent: 1.5 // Exponent to increase backoff each try. Default: 1.1
  }
});

const db = {};

db.Sequelize = Sequelize;
db.sequelize = sequelize;

db.tutorials = require("./tutorial.model.js")(sequelize, Sequelize);

module.exports = db;
