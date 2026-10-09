const jwt = require("jsonwebtoken");
const db = require("../db");

async function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ error: "Authentication required." });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, {
      algorithms: ["HS256"],
    });

    // Re-check account state and role in the database, so deactivated users
    // cannot continue using an otherwise unexpired token.
    const result = await db.query(
      `SELECT id, email, full_name, role, is_active
       FROM users WHERE id = $1 LIMIT 1`,
      [payload.sub]
    );

    if (result.rowCount === 0 || !result.rows[0].is_active) {
      return res.status(401).json({ error: "Account is unavailable." });
    }

    req.user = result.rows[0];
    next();
  } catch (error) {
    if (error.name === "JsonWebTokenError" || error.name === "TokenExpiredError") {
      return res.status(401).json({ error: "Invalid or expired token." });
    }
    next(error);
  }
}

module.exports = requireAuth;
