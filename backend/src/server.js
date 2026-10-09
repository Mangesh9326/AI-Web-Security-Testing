require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const db = require("./db");
const authRoutes = require("./routes/auth");
const scanRoutes = require("./routes/scans");
const intrusuionRoute = require('./routes/intrusion');

const app = express();
const port = Number(process.env.PORT || 5000);

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is required. Copy .env.example to .env and configure it.");
}
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
  throw new Error("JWT_SECRET must be configured with at least 32 characters.");
}

const allowedOrigin = process.env.FRONTEND_ORIGIN || "http://localhost:5173";
app.use(helmet());
app.use(cors({
  origin: allowedOrigin,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));
app.use(express.json({ limit: "20kb" }));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: "draft-7",
  legacyHeaders: false,
  message: { error: "Too many authentication attempts. Try again later." },
});

app.get("/api/health", async (req, res, next) => {
  try {
    await db.query("SELECT 1");
    res.json({ status: "ok", database: "connected" });
  } catch (error) {
    next(error);
  }
});

app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/scans", scanRoutes);
app.use("/api/intrusion", intrusuionRoute);
app.use("/api/profile", require("./routes/profile"));

app.use((req, res) => {
  res.status(404).json({ error: "Route not found." });
});

app.use((error, req, res, next) => {
  // Keep internal SQL errors and secrets out of client responses.
  console.error("API error:", error.message);
  if (res.headersSent) return next(error);
  res.status(500).json({ error: "Internal server error." });
});

async function start() {
  await db.query("SELECT 1");
  app.listen(port, () => {
    console.log(`AI-WebSecTest API listening on http://localhost:${port}`);
  });
}

start().catch((error) => {
  console.error("Could not start API. Check PostgreSQL and DATABASE_URL:", error.message);
  process.exit(1);
});

process.on("SIGINT", async () => {
  await db.pool.end();
  process.exit(0);
});
process.on("SIGTERM", async () => {
  await db.pool.end();
  process.exit(0);
});
