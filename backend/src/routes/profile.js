const express = require("express");
const router = express.Router();
const db = require("../db");
const requireAuth = require("../middleware/requireAuth");

router.use(requireAuth);

router.get("/", async (req, res, next) => {
  try {
    const result = await db.query(
      "SELECT id, email, full_name, role, is_active, created_at, last_login_at FROM users WHERE id = $1",
      [req.user.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "User profile not found." });
    }

    res.json({ profile: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

router.put("/", async (req, res, next) => {
  try {
    const { fullName, email } = req.body;
    
    // Basic validation
    if (!email || !email.includes('@')) {
      return res.status(400).json({ error: "A valid email is required." });
    }

    // Check if email is already taken by another user
    const emailCheck = await db.query(
      "SELECT id FROM users WHERE email = $1 AND id != $2",
      [email.toLowerCase().trim(), req.user.id]
    );

    if (emailCheck.rowCount > 0) {
      return res.status(409).json({ error: "Email is already in use by another account." });
    }

    const result = await db.query(
      "UPDATE users SET full_name = $1, email = $2 WHERE id = $3 RETURNING id, email, full_name, role",
      [fullName?.trim() || null, email.toLowerCase().trim(), req.user.id]
    );

    res.json({ message: "Profile updated successfully.", profile: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
