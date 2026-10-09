const express = require("express");
const db = require("../db");
const requireAuth = require("../middleware/requireAuth");
const { processEvent } = require("../scanner/intrusionEngine");

const router = express.Router();
router.use(requireAuth);

const isValidUUID = (id) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
const isValidIP = (ip) => typeof ip === "string" && /^[:.0-9a-fA-F]{2,45}$/.test(ip);

// Finite State Machine: Strict status transition rules
const VALID_TRANSITIONS = {
  new: ["investigating", "false_positive"],
  investigating: ["confirmed", "false_positive", "resolved"],
  confirmed: ["resolved", "investigating"],
  false_positive: ["investigating"],
  resolved: ["investigating"]
};

/**
 * POST /api/intrusion/events
 */
router.post("/events", async (req, res, next) => {
  const events = req.body.events;

  if (!Array.isArray(events) || events.length === 0) {
    return res.status(400).json({ error: "Payload must contain an 'events' array." });
  }
  if (events.length > 50) {
    return res.status(400).json({ error: "Batch size exceeds the maximum limit of 50 events." });
  }

  const uniqueScanIds = new Set();
  const sanitizedEvents = [];

  for (const ev of events) {
    if (!ev.scan_id || !isValidUUID(ev.scan_id)) {
      return res.status(400).json({ error: "Invalid or missing scan_id in one or more events." });
    }
    uniqueScanIds.add(ev.scan_id);

    sanitizedEvents.push({
      scan_id: ev.scan_id,
      source_ip: isValidIP(ev.source_ip) ? ev.source_ip : null,
      method: typeof ev.method === "string" ? ev.method.slice(0, 20).toUpperCase() : "UNKNOWN",
      endpoint: typeof ev.endpoint === "string" ? ev.endpoint.slice(0, 500) : "/",
      status_code: Number.isInteger(ev.status_code) && ev.status_code >= 100 && ev.status_code <= 599 ? ev.status_code : null,
      user_agent: typeof ev.user_agent === "string" ? ev.user_agent.slice(0, 1000) : null,
      event_type: typeof ev.event_type === "string" ? ev.event_type.slice(0, 50) : "http_request",
      evidence: typeof ev.evidence === "object" && ev.evidence !== null ? ev.evidence : {}
    });
  }

  try {
    const scanIdArray = Array.from(uniqueScanIds);
    const ownershipCheck = await db.query(
      `SELECT id FROM scans WHERE user_id = $1 AND id = ANY($2::uuid[])`,
      [req.user.id, scanIdArray]
    );

    if (ownershipCheck.rowCount !== scanIdArray.length) {
      return res.status(403).json({ error: "Unauthorized: One or more scan_ids do not belong to your account." });
    }

    const client = await db.pool.connect();
    let totalAlertsGenerated = 0;

    try {
      await client.query("BEGIN");

      for (const ev of sanitizedEvents) {
        const insertRes = await client.query(
          `INSERT INTO traffic_logs 
            (scan_id, source_ip, method, endpoint, status_code, user_agent, classification, event_type, evidence, created_at)
           VALUES 
            ($1, $2, $3, $4, $5, $6, 'unclassified', $7, $8::jsonb, NOW())
           RETURNING id, scan_id, source_ip, method, endpoint, status_code, user_agent, evidence`,
          [ev.scan_id, ev.source_ip, ev.method, ev.endpoint, ev.status_code, ev.user_agent, ev.event_type, JSON.stringify(ev.evidence)]
        );

        const evalResult = await processEvent(insertRes.rows[0], client);
        totalAlertsGenerated += evalResult.alertsCreated;
      }

      await client.query("COMMIT");
    } catch (txError) {
      await client.query("ROLLBACK");
      throw txError;
    } finally {
      client.release();
    }

    return res.status(201).json({
      message: "Events successfully ingested and evaluated.",
      count: sanitizedEvents.length,
      alertsGenerated: totalAlertsGenerated
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/intrusion/traffic
 */
router.get("/traffic", async (req, res, next) => {
  try {
    let limit = Number.parseInt(req.query.limit, 10);
    if (!Number.isInteger(limit) || limit <= 0) limit = 100;
    limit = Math.min(limit, 200);

    let cursor = null;
    if (req.query.cursor) {
      cursor = Number.parseInt(req.query.cursor, 10);
      if (!Number.isInteger(cursor) || cursor <= 0) {
        return res.status(400).json({ error: "Invalid cursor parameter." });
      }
    }

    const queryParams = [req.user.id, limit];
    let filterClauses = "";
    let paramIndex = 3;

    if (cursor) {
      filterClauses += ` AND t.id < $${paramIndex++}`;
      queryParams.push(cursor);
    }

    if (req.query.classification && typeof req.query.classification === "string" && req.query.classification !== "all") {
      filterClauses += ` AND t.classification = $${paramIndex++}`;
      queryParams.push(req.query.classification);
    }

    const result = await db.query(
      `SELECT t.id, t.source_ip, t.method, t.endpoint, t.status_code, t.user_agent, 
              t.classification, t.confidence, t.created_at, t.event_type, t.severity, t.evidence, s.target_url
       FROM traffic_logs t
       JOIN scans s ON t.scan_id = s.id
       WHERE s.user_id = $1 ${filterClauses}
       ORDER BY t.id DESC
       LIMIT $2`,
      queryParams
    );

    let nextCursor = null;
    if (result.rows.length === limit) {
      nextCursor = result.rows[result.rows.length - 1].id;
    }

    res.json({ logs: result.rows, nextCursor });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/intrusion/alerts
 */
router.get("/alerts", async (req, res, next) => {
  try {
    let limit = Number.parseInt(req.query.limit, 10);
    if (!Number.isInteger(limit) || limit <= 0) limit = 50;
    limit = Math.min(limit, 100);

    const queryParams = [req.user.id, limit];
    let filterClauses = "";
    let paramIndex = 3;

    if (req.query.severity && typeof req.query.severity === "string" && req.query.severity !== "all") {
      filterClauses += ` AND a.severity = $${paramIndex++}`;
      queryParams.push(req.query.severity.toLowerCase());
    }

    if (req.query.status && typeof req.query.status === "string" && req.query.status !== "all") {
      filterClauses += ` AND a.status = $${paramIndex++}::public.alert_status`;
      queryParams.push(req.query.status.toLowerCase());
    }

    if (req.query.assigned_to && isValidUUID(req.query.assigned_to)) {
      filterClauses += ` AND a.assigned_to = $${paramIndex++}`;
      queryParams.push(req.query.assigned_to);
    }

    const result = await db.query(
      `SELECT a.id, a.scan_id, a.rule_id, a.classification, a.severity, a.confidence,
              a.source_ip, a.endpoint, a.http_method, a.status, a.occurrence_count,
              a.description, a.evidence, a.first_seen_at, a.last_seen_at, a.assigned_to,
              u.full_name AS assigned_to_name, u.email AS assigned_to_email, s.target_url
       FROM alerts a
       JOIN scans s ON a.scan_id = s.id
       LEFT JOIN users u ON a.assigned_to = u.id
       WHERE s.user_id = $1 ${filterClauses}
       ORDER BY a.last_seen_at DESC
       LIMIT $2`,
      queryParams
    );

    res.json({ alerts: result.rows });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/intrusion/alerts/:id
 */
router.get("/alerts/:id", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid alert UUID." });
    }

    const result = await db.query(
      `SELECT a.*, u.full_name AS assigned_to_name, u.email AS assigned_to_email, s.target_url
       FROM alerts a
       JOIN scans s ON a.scan_id = s.id
       LEFT JOIN users u ON a.assigned_to = u.id
       WHERE a.id = $1 AND s.user_id = $2`,
      [req.params.id, req.user.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Alert not found." });
    }

    res.json({ alert: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/intrusion/alerts/:id/status
 * Enforces FSM lifecycle transitions and records an immutable audit log.
 */
router.patch("/alerts/:id/status", async (req, res, next) => {
  if (!isValidUUID(req.params.id)) {
    return res.status(400).json({ error: "Invalid alert UUID." });
  }

  const { status, note } = req.body;
  const targetStatus = typeof status === "string" ? status.toLowerCase() : "";

  if (!Object.keys(VALID_TRANSITIONS).includes(targetStatus)) {
    return res.status(400).json({ error: `Invalid status '${status}'. Must be one of: ${Object.keys(VALID_TRANSITIONS).join(", ")}` });
  }

  const client = await db.pool.connect();
  try {
    await client.query("BEGIN");

    // Lock and verify ownership
    const alertRes = await client.query(
      `SELECT a.id, a.status 
       FROM alerts a
       JOIN scans s ON a.scan_id = s.id
       WHERE a.id = $1 AND s.user_id = $2
       FOR UPDATE`,
      [req.params.id, req.user.id]
    );

    if (alertRes.rowCount === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "Alert not found or unauthorized." });
    }

    const currentStatus = alertRes.rows[0].status;

    if (currentStatus === targetStatus) {
      await client.query("ROLLBACK");
      return res.status(400).json({ error: `Alert is already in '${targetStatus}' status.` });
    }

    const allowedNext = VALID_TRANSITIONS[currentStatus] || [];
    if (!allowedNext.includes(targetStatus)) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        error: `Invalid status transition from '${currentStatus}' to '${targetStatus}'. Allowed transitions: ${allowedNext.join(", ")}`
      });
    }

    // Determine audit action
    const isReopen = targetStatus === "investigating" && ["resolved", "false_positive"].includes(currentStatus);
    const auditAction = isReopen ? "alert_reopened" : targetStatus === "resolved" ? "alert_resolved" : "status_changed";

    // Update alert status
    const updateRes = await client.query(
      `UPDATE alerts
       SET status = $1::public.alert_status,
           updated_at = NOW()
       WHERE id = $2
       RETURNING id, status, updated_at`,
      [targetStatus, req.params.id]
    );

    // Write audit trail
    await client.query(
      `INSERT INTO alert_audit_logs (alert_id, user_id, action, previous_value, new_value, metadata)
       VALUES ($1, $2, $3, $4, $5, $6::jsonb)`,
      [
        req.params.id,
        req.user.id,
        auditAction,
        currentStatus,
        targetStatus,
        JSON.stringify({ transition_reason: note || null })
      ]
    );

    // Optional inline note creation
    if (typeof note === "string" && note.trim().length > 0) {
      const trimmedNote = note.trim().slice(0, 2000);
      await client.query(
        `INSERT INTO alert_notes (alert_id, author_id, note)
         VALUES ($1, $2, $3)`,
        [req.params.id, req.user.id, trimmedNote]
      );
      await client.query(
        `INSERT INTO alert_audit_logs (alert_id, user_id, action, new_value, metadata)
         VALUES ($1, $2, 'note_added', $3, '{}'::jsonb)`,
        [req.params.id, req.user.id, trimmedNote.slice(0, 100)]
      );
    }

    await client.query("COMMIT");
    res.json({ message: "Status updated successfully.", alert: updateRes.rows[0] });
  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    next(error);
  } finally {
    client.release();
  }
});

/**
 * GET /api/intrusion/alerts/:id/notes
 * Retrieves the collaborative investigation notes thread.
 */
router.get("/alerts/:id/notes", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid alert UUID." });
    }

    const check = await db.query(
      `SELECT a.id FROM alerts a JOIN scans s ON a.scan_id = s.id WHERE a.id = $1 AND s.user_id = $2`,
      [req.params.id, req.user.id]
    );
    if (check.rowCount === 0) return res.status(404).json({ error: "Alert not found." });

    const notesRes = await db.query(
      `SELECT n.id, n.alert_id, n.note, n.created_at, n.author_id,
              u.full_name AS author_name, u.email AS author_email
       FROM alert_notes n
       JOIN users u ON n.author_id = u.id
       WHERE n.alert_id = $1
       ORDER BY n.created_at ASC`,
      [req.params.id]
    );

    res.json({ notes: notesRes.rows });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/intrusion/alerts/:id/notes
 * Adds an investigation note and records an audit log entry.
 */
router.post("/alerts/:id/notes", async (req, res, next) => {
  if (!isValidUUID(req.params.id)) {
    return res.status(400).json({ error: "Invalid alert UUID." });
  }

  const { note } = req.body;
  if (typeof note !== "string" || note.trim().length === 0) {
    return res.status(400).json({ error: "Note text is required and cannot be empty." });
  }
  if (note.trim().length > 2000) {
    return res.status(400).json({ error: "Note exceeds the maximum length of 2000 characters." });
  }

  const client = await db.pool.connect();
  try {
    await client.query("BEGIN");

    const check = await client.query(
      `SELECT a.id FROM alerts a JOIN scans s ON a.scan_id = s.id WHERE a.id = $1 AND s.user_id = $2`,
      [req.params.id, req.user.id]
    );
    if (check.rowCount === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "Alert not found or unauthorized." });
    }

    const trimmedNote = note.trim();
    const noteRes = await client.query(
      `INSERT INTO alert_notes (alert_id, author_id, note)
       VALUES ($1, $2, $3)
       RETURNING id, alert_id, note, created_at, author_id`,
      [req.params.id, req.user.id, trimmedNote]
    );

    await client.query(
      `INSERT INTO alert_audit_logs (alert_id, user_id, action, new_value, metadata)
       VALUES ($1, $2, 'note_added', $3, '{}'::jsonb)`,
      [req.params.id, req.user.id, trimmedNote.slice(0, 100)]
    );

    await client.query("COMMIT");
    res.status(201).json({
      message: "Note added successfully.",
      note: {
        ...noteRes.rows[0],
        author_name: req.user.full_name,
        author_email: req.user.email
      }
    });
  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    next(error);
  } finally {
    client.release();
  }
});

/**
 * GET /api/intrusion/alerts/:id/history
 * Retrieves the immutable audit trail for an alert.
 */
router.get("/alerts/:id/history", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid alert UUID." });
    }

    const check = await db.query(
      `SELECT a.id FROM alerts a JOIN scans s ON a.scan_id = s.id WHERE a.id = $1 AND s.user_id = $2`,
      [req.params.id, req.user.id]
    );
    if (check.rowCount === 0) return res.status(404).json({ error: "Alert not found." });

    const auditRes = await db.query(
      `SELECT l.id, l.alert_id, l.action, l.previous_value, l.new_value, l.metadata, l.created_at,
              COALESCE(u.full_name, 'System Rule Engine') AS actor_name,
              u.email AS actor_email
       FROM alert_audit_logs l
       LEFT JOIN users u ON l.user_id = u.id
       WHERE l.alert_id = $1
       ORDER BY l.created_at ASC`,
      [req.params.id]
    );

    res.json({ history: auditRes.rows });
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/intrusion/alerts/:id/assignment
 * Assigns or unassigns an investigator to an alert.
 */
router.patch("/alerts/:id/assignment", async (req, res, next) => {
  if (!isValidUUID(req.params.id)) {
    return res.status(400).json({ error: "Invalid alert UUID." });
  }

  const { assigned_to } = req.body;
  if (assigned_to !== null && !isValidUUID(assigned_to)) {
    return res.status(400).json({ error: "assigned_to must be a valid user UUID or null." });
  }

  const client = await db.pool.connect();
  try {
    await client.query("BEGIN");

    const alertCheck = await client.query(
      `SELECT a.id, a.assigned_to 
       FROM alerts a 
       JOIN scans s ON a.scan_id = s.id 
       WHERE a.id = $1 AND s.user_id = $2
       FOR UPDATE`,
      [req.params.id, req.user.id]
    );
    if (alertCheck.rowCount === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "Alert not found or unauthorized." });
    }

    let targetUserName = "Unassigned";
    if (assigned_to !== null) {
      const userCheck = await client.query(
        `SELECT id, full_name, email FROM users WHERE id = $1 AND is_active = true`,
        [assigned_to]
      );
      if (userCheck.rowCount === 0) {
        await client.query("ROLLBACK");
        return res.status(400).json({ error: "Assigned investigator does not exist or is inactive." });
      }
      targetUserName = userCheck.rows[0].full_name || userCheck.rows[0].email;
    }

    const previousAssignee = alertCheck.rows[0].assigned_to;
    await client.query(
      `UPDATE alerts
       SET assigned_to = $1, updated_at = NOW()
       WHERE id = $2`,
      [assigned_to, req.params.id]
    );

    const action = assigned_to === null ? "investigator_unassigned" : "investigator_assigned";
    await client.query(
      `INSERT INTO alert_audit_logs (alert_id, user_id, action, previous_value, new_value, metadata)
       VALUES ($1, $2, $3, $4, $5, $6::jsonb)`,
      [
        req.params.id,
        req.user.id,
        action,
        previousAssignee,
        assigned_to,
        JSON.stringify({ target_name: targetUserName })
      ]
    );

    await client.query("COMMIT");
    res.json({ message: "Investigator assignment updated successfully.", assigned_to });
  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    next(error);
  } finally {
    client.release();
  }
});

/**
 * GET /api/intrusion/investigators
 * Retrieves active investigators with safe display profiles.
 */
router.get("/investigators", async (req, res, next) => {
  try {
    const usersRes = await db.query(
      `SELECT id, full_name, email, role
       FROM users
       WHERE is_active = true
       ORDER BY full_name ASC`
    );
    res.json({ investigators: usersRes.rows });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/intrusion/metrics
 */
router.get("/metrics", async (req, res, next) => {
  try {
    const statsQuery = await db.query(
      `SELECT 
         COUNT(*)::int AS total_alerts,
         COUNT(*) FILTER (WHERE a.severity = 'critical')::int AS critical_alerts,
         COUNT(*) FILTER (WHERE a.severity = 'high')::int AS high_alerts,
         COUNT(*) FILTER (WHERE a.severity = 'medium')::int AS medium_alerts,
         COUNT(*) FILTER (WHERE a.severity = 'low')::int AS low_alerts,
         COUNT(*) FILTER (WHERE a.status = 'confirmed')::int AS confirmed_incidents
       FROM alerts a
       JOIN scans s ON a.scan_id = s.id
       WHERE s.user_id = $1`,
      [req.user.id]
    );

    res.json({ metrics: statsQuery.rows[0] });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/intrusion/reprocess
 */
router.post("/reprocess", async (req, res, next) => {
  try {
    const logs = await db.query(
      `SELECT t.id, t.scan_id, t.source_ip, t.method, t.endpoint, t.user_agent, t.evidence
       FROM traffic_logs t
       JOIN scans s ON t.scan_id = s.id
       WHERE s.user_id = $1
       ORDER BY t.id ASC
       LIMIT 100`,
      [req.user.id]
    );

    let reprocessed = 0;
    for (const log of logs.rows) {
      await processEvent(log);
      reprocessed++;
    }

    res.json({ message: `Successfully reprocessed ${reprocessed} events.` });
  } catch (error) {
    next(error);
  }
});

module.exports = router;