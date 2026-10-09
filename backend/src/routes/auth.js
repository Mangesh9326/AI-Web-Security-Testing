const express = require("express");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const db = require("../db");
const requireAuth = require("../middleware/requireAuth");

const router = express.Router();

function normalizeEmail(value) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function publicUser(row) {
  return {
    id: row.id,
    email: row.email,
    fullName: row.full_name,
    role: row.role,
    isActive: row.is_active,
    createdAt: row.created_at,
  };
}

function createToken(user) {
  return jwt.sign(
    { role: user.role },
    process.env.JWT_SECRET,
    {
      subject: user.id,
      expiresIn: process.env.JWT_EXPIRES_IN || "1h",
      algorithm: "HS256",
    }
  );
}

// POST /api/auth/register
// Public registration always receives the database's default "analyst" role.
// Never accept role or is_active from the client.
router.post("/register", async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = req.body?.password;
    const fullName =
      typeof req.body?.fullName === "string" ? req.body.fullName.trim() : null;

    if (!email || email.length > 320 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return res.status(400).json({ error: "Enter a valid email address." });
    }

    if (typeof password !== "string" || password.length < 12 || password.length > 72) {
      return res.status(400).json({
        error: "Password must be between 12 and 72 characters.",
      });
    }

    if (fullName && fullName.length > 200) {
      return res.status(400).json({ error: "Full name must be 200 characters or fewer." });
    }

    const rounds = Number.parseInt(process.env.BCRYPT_ROUNDS || "12", 10);
    const passwordHash = await bcrypt.hash(password, rounds);

    const result = await db.query(
      `INSERT INTO users (email, password_hash, full_name)
       VALUES ($1, $2, $3)
       RETURNING id, email, full_name, role, is_active, created_at`,
      [email, passwordHash, fullName || null]
    );

    const user = result.rows[0];
    const token = createToken(user);

    return res.status(201).json({
      message: "Registration successful.",
      token,
      user: publicUser(user),
    });
  } catch (error) {
    if (error.code === "23505") {
      return res.status(409).json({ error: "An account with this email already exists." });
    }
    next(error);
  }
});

// POST /api/auth/login
router.post("/login", async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = req.body?.password;

    if (!email || typeof password !== "string" || password.length > 72) {
      return res.status(400).json({ error: "Email and password are required." });
    }

    const result = await db.query(
      `SELECT id, email, password_hash, full_name, role, is_active, created_at
       FROM users WHERE lower(email) = lower($1) LIMIT 1`,
      [email]
    );

    // Same response for unknown email and wrong password to reduce account enumeration.
    if (result.rowCount === 0) {
      return res.status(401).json({ error: "Invalid email or password." });
    }

    const user = result.rows[0];
    const passwordMatches = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatches || !user.is_active) {
      return res.status(401).json({ error: "Invalid email or password." });
    }

    await db.query("UPDATE users SET last_login_at = NOW() WHERE id = $1", [user.id]);

    return res.json({
      message: "Login successful.",
      token: createToken(user),
      user: publicUser(user),
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/auth/me — send Authorization: Bearer <token>
router.get("/me", requireAuth, async (req, res) => {
  return res.json({ user: req.user });
});

// JWT logout is handled by deleting the token on the client.
// This endpoint provides a consistent API response; for immediate revocation,
// add a server-side token/session store.
router.post("/logout", requireAuth, (req, res) => {
  return res.json({ message: "Logged out. Remove the token from client storage." });
});

module.exports = router;
