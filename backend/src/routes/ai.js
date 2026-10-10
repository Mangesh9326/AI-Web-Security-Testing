const express = require("express");
const router = express.Router();
const db = require("../db");
const requireAuth = require("../middleware/requireAuth");
const groqService = require("../services/groqService");

router.use(requireAuth);

/**
 * POST /api/ai/vulnerability-analysis
 * Body: { findingId: UUID }
 */
router.post("/vulnerability-analysis", async (req, res, next) => {
  try {
    const { findingId } = req.body;
    
    if (!findingId) {
      return res.status(400).json({ error: "findingId is required." });
    }

    // Load finding and verify ownership
    const findingResult = await db.query(
      `SELECT f.*, s.target_url 
       FROM findings f 
       JOIN scans s ON f.scan_id = s.id 
       WHERE f.id = $1 AND s.user_id = $2`,
      [findingId, req.user.id]
    );

    if (findingResult.rowCount === 0) {
      return res.status(404).json({ error: "Finding not found or not accessible." });
    }

    const finding = findingResult.rows[0];
    const analysis = await groqService.analyzeVulnerability(finding);

    res.json({ analysis });
  } catch (error) {
    console.error("AI Vulnerability Analysis Error:", error.message);
    res.status(500).json({ error: "Failed to generate AI analysis. Check API configuration and limits." });
  }
});

/**
 * POST /api/ai/security-overview
 * Uses all findings from the user's scans
 */
router.post("/security-overview", async (req, res, next) => {
  try {
    const findingsResult = await db.query(
      `SELECT f.vulnerability_type, f.title, f.severity, f.affected_url, s.target_url 
       FROM findings f 
       JOIN scans s ON f.scan_id = s.id 
       WHERE s.user_id = $1
       ORDER BY f.detected_at DESC
       LIMIT 500`, // Bound total findings to prevent memory/token exhaustion
      [req.user.id]
    );

    if (findingsResult.rowCount === 0) {
      return res.status(400).json({ error: "No findings available for analysis." });
    }

    const overview = await groqService.generateSecurityOverview(findingsResult.rows);

    res.json({ overview });
  } catch (error) {
    console.error("AI Security Overview Error:", error.message);
    res.status(500).json({ error: "Failed to generate security overview. Check API configuration and limits." });
  }
});

/**
 * POST /api/ai/intrusion-analysis
 * Body: { alertId: UUID }
 */
router.post("/intrusion-analysis", async (req, res, next) => {
  try {
    const { alertId } = req.body;
    
    if (!alertId) {
      return res.status(400).json({ error: "alertId is required." });
    }

    // Load alert and verify ownership
    const alertResult = await db.query(
      `SELECT a.*, s.target_url 
       FROM alerts a 
       JOIN scans s ON a.scan_id = s.id 
       WHERE a.id = $1 AND s.user_id = $2`,
      [alertId, req.user.id]
    );

    if (alertResult.rowCount === 0) {
      return res.status(404).json({ error: "Alert not found or not accessible." });
    }

    const alert = alertResult.rows[0];
    const analysis = await groqService.analyzeIntrusionAlert(alert);

    res.json({ analysis });
  } catch (error) {
    console.error("AI Intrusion Analysis Error:", error.message);
    res.status(500).json({ error: "Failed to generate AI analysis. Check API configuration and limits." });
  }
});

/**
 * POST /api/ai/intrusion-overview
 */
router.post("/intrusion-overview", async (req, res, next) => {
  try {
    const alertsResult = await db.query(
      `SELECT a.classification, a.severity, a.confidence, a.source_ip, a.endpoint, s.target_url 
       FROM alerts a 
       JOIN scans s ON a.scan_id = s.id 
       WHERE s.user_id = $1
       ORDER BY a.first_seen_at DESC
       LIMIT 500`,
      [req.user.id]
    );

    if (alertsResult.rowCount === 0) {
      return res.status(400).json({ error: "No alerts available for analysis." });
    }

    const overview = await groqService.generateIntrusionOverview(alertsResult.rows);

    res.json({ overview });
  } catch (error) {
    console.error("AI Intrusion Overview Error:", error.message);
    res.status(500).json({ error: "Failed to generate SOC overview. Check API configuration and limits." });
  }
});

module.exports = router;
