const dbConfig = require("../config/db.config.js");

const Sequelize = require("sequelize");
const sequelize = new Sequelize(dbConfig.DB, dbConfig.USER, dbConfig.PASSWORD, {
  host: dbConfig.HOST,
  port: dbConfig.DB_PORT,
  dialect: dbConfig.dialect,
  dialectOptions: {
    ssl: dbConfig.SSL_ENABLED,
    logging: (...msg) => console.log(msg),
    retry: {
      match: [
        Sequelize.ConnectionError,
        Sequelize.ConnectionTimedOutError,
        Sequelize.TimeoutError
      ],
      max: 3, // maximum amount of tries
      timeout: 10000, // throw if no response or error within millisecond timeout
      backoffBase: 1000, // Initial backoff duration in ms. Default: 100
      backoffExponent: 1.5 // Exponent to increase backoff each try. Default: 1.1
    }
  },
  pool: {
    max: dbConfig.pool.max,
    min: dbConfig.pool.min,
    acquire: dbConfig.pool.acquire,
    idle: dbConfig.pool.idle
  }
});

const db = {};

db.Sequelize = Sequelize;
db.sequelize = sequelize;

console.log(sequelize);

db.tutorials = require("./tutorial.model.js")(sequelize, Sequelize);

module.exports = db;
