const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // For a local PostgreSQL database, SSL is usually unnecessary.
  // Configure SSL explicitly for your hosted database if required.
});

pool.on("error", (error) => {
  console.error("Unexpected PostgreSQL pool error:", error.message);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
