const express = require("express");
const { randomUUID } = require("node:crypto");
const db = require("../db");
const requireAuth = require("../middleware/requireAuth");
const { validatePublicHttpUrl } = require("../scanner/targetSafety");
const { processScan } = require("../scanner/worker");

// Optional target validation utilities (if present in the project)
let targetValidation = {};
try {
  targetValidation = require("../utils/targetValidation");
} catch {
  // Gracefully fallback to targetSafety
}
const { TargetValidationError, parseTargetUrl, validatePublicDestination } = targetValidation;

const router = express.Router();
router.use(requireAuth);

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
function isValidUUID(id) {
  return typeof id === "string" && UUID_REGEX.test(id);
}

const supportedProfiles = new Set(["quick", "standard", "passive", "api"]);
const allowedChecks = new Set([
  "sql_injection",
  "xss",
  "csrf",
  "security_headers",
  "authentication",
  "authorization",
  "ssl_tls",
  "information_disclosure",
  "sensitive_data_exposure",
  "security_misconfiguration",
]);

function boundedInt(value, fallback, min, max, fieldName = "Value") {
  const v = value ?? fallback;
  const n = Number(v);
  if (!Number.isInteger(n) || n < min || n > max) {
    throw new Error(`${fieldName} must be an integer from ${min} to${max}.`);
  }
  return n;
}

function parseConfig(body) {
  if (body.scan_type !== undefined && !supportedProfiles.has(body.scan_type)) {
    throw new Error(
      `Scan profile '${body.scan_type}' is not supported. Supported profiles are: ${Array.from(supportedProfiles).join(", ")}.`,
    );
  }
  const profile = body.scan_type || "standard";

  const scopeType = body.scope_type ?? "single_url";
  if (scopeType !== "single_url" && scopeType !== "domain") {
    throw new Error("Invalid scope_type. Select single_url or domain.");
  }

  if (body.security_checks !== undefined && !Array.isArray(body.security_checks)) {
    throw new Error("Security checks must be an array.");
  }
  const checks = Array.isArray(body.security_checks) ? body.security_checks : ["security_headers"];
  if (!checks.length || checks.some((c) => !allowedChecks.has(c))) {
    throw new Error("Choose at least one supported security check.");
  }

  if (body.active === true) {
    throw new Error("Active scanning is not implemented yet. Disable active testing; passive scanning is available.");
  }

  if (
    body.authorization_confirmed !== undefined &&
    typeof body.authorization_confirmed !== "boolean"
  ) {
    throw new Error("authorization_confirmed must be a boolean.");
  }

  const authType = body.authentication_type ?? "none";
  if (authType !== "none") {
    throw new Error("Authenticated scanning is not implemented yet. Select No authentication.");
  }

  if (body.excluded_paths !== undefined && !Array.isArray(body.excluded_paths)) {
    throw new Error("Excluded paths must be an array of at most 100 paths beginning with /.");
  }
  const excluded = Array.isArray(body.excluded_paths) ? body.excluded_paths : [];
  if (
    excluded.length > 100 ||
    excluded.some((p) => typeof p !== "string" || p.length > 300 || !p.startsWith("/"))
  ) {
    throw new Error("Excluded paths must be an array of at most 100 paths beginning with /.");
  }

  if (body.custom_headers !== undefined && (typeof body.custom_headers !== "object" || Array.isArray(body.custom_headers))) {
    throw new Error("Custom headers must be an object.");
  }
  const customHeaders =
    body.custom_headers && typeof body.custom_headers === "object" && !Array.isArray(body.custom_headers)
      ? body.custom_headers
      : {};

  if (Object.keys(customHeaders).length > 20) {
    throw new Error("A maximum of 20 custom headers is allowed.");
  }
  for (const [key, value] of Object.entries(customHeaders)) {
    if (
      !/^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/.test(key) ||
      typeof value !== "string" ||
      value.length > 1000
    ) {
      throw new Error("Custom headers contain an invalid name or value.");
    }
  }

  return {
    scan_type: profile,
    scope_type: scopeType,
    spider: body.spider !== false,
    passive: true,
    active: false,
    authorization_confirmed: body.authorization_confirmed === true,
    crawl_depth: boundedInt(
      body.crawl_depth,
      profile === "quick" ? 2 : 5,
      1,
      10,
      "crawl_depth",
    ),
    max_pages: boundedInt(
      body.max_pages,
      profile === "quick" ? 50 : 100,
      1,
      500,
      "max_pages",
    ),
    request_delay_ms: boundedInt(body.request_delay_ms, 250, 100, 10000, "request_delay_ms"),
    javascript_crawling: false,
    follow_redirects: body.follow_redirects !== false,
    security_checks: checks,
    excluded_paths: excluded,
    authentication_type: "none",
    request_timeout_seconds: boundedInt(
      body.request_timeout_seconds,
      20,
      1,
      60,
      "request_timeout_seconds",
    ),
    max_concurrent_requests: 1,
    user_agent: typeof body.user_agent === "string" ? body.user_agent.slice(0, 200) : "",
    custom_headers: customHeaders,
  };
}

// POST /api/scans
router.post("/", async (req, res, next) => {
  try {
    const rawTarget = typeof req.body?.target_url === "string" ? req.body.target_url.trim() : "";
    if (!rawTarget) {
      return res.status(400).json({ error: "target_url is required." });
    }

    let target;
    try {
      if (typeof parseTargetUrl === "function" && typeof validatePublicDestination === "function") {
        const parsedTarget = parseTargetUrl(rawTarget);
        await validatePublicDestination(parsedTarget);
        target = parsedTarget.href;
      }
      const validated = await validatePublicHttpUrl(target || rawTarget);
      target = validated.href;
    } catch (error) {
      if (typeof TargetValidationError !== "undefined" && error instanceof TargetValidationError) {
        return res.status(error.statusCode || 400).json({ error: error.message });
      }
      return res.status(400).json({ error: error.message || "Unable to validate the target URL." });
    }

    let config;
    try {
      config = parseConfig(req.body || {});
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }

    const id = randomUUID();
    const result = await db.query(
      `INSERT INTO scans
       (id, user_id, target_url, scan_type, status, scan_config,
        spider, passive, active, scope_type, authorization_confirmed,
        crawl_depth, max_pages, request_delay_ms, javascript_crawling,
        follow_redirects, security_checks, excluded_paths, authentication_type)
       VALUES ($1,$2,$3,$4,'queued',$5::jsonb,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16::jsonb,$17::jsonb,$18)
       RETURNING id, user_id, target_url, scan_type, status, scan_config, created_at`,
      [
        id,
        req.user.id,
        target,
        config.scan_type,
        JSON.stringify(config),
        config.spider,
        config.passive,
        config.active,
        config.scope_type,
        config.authorization_confirmed,
        config.crawl_depth,
        config.max_pages,
        config.request_delay_ms,
        config.javascript_crawling,
        config.follow_redirects,
        JSON.stringify(config.security_checks),
        JSON.stringify(config.excluded_paths),
        config.authentication_type,
      ],
    );

    await db
      .query(
        `INSERT INTO activity_logs (user_id, scan_id, level, action, message, details)
         VALUES ($1,$2,'info','scan_queued','Passive scan queued.',$3::jsonb)`,
        [req.user.id, id, JSON.stringify({ target_url: target, scan_type: config.scan_type })],
      )
      .catch(() => {});

    // Reliable background worker dispatch
    setImmediate(async () => {
      try {
        await processScan(result.rows[0]);
      } catch (workerError) {
        console.error("Worker processing failed for scan", id, workerError);
        try {
          await db.query(
            `UPDATE scans
             SET status = 'failed',
                 completed_at = NOW(),
                 error_message = $2
             WHERE id = $1 AND status NOT IN ('completed', 'failed', 'cancelled')`,
            [id, String(workerError?.message || "Worker processing failed").slice(0, 1000)],
          );
          await db.query(
            `INSERT INTO activity_logs (user_id, scan_id, level, action, message, details)
             VALUES ($1, $2, 'error', 'scan_failed', 'Scan worker execution failed.', $3::jsonb)`,
            [req.user.id, id, JSON.stringify({ error: workerError?.message || "Worker failure" })],
          );
        } catch (dbErr) {
          console.error("Unable to record worker failure in database:", dbErr.message);
        }
      }
    });

    return res.status(202).json({ ...result.rows[0], message: "Passive scan queued." });
  } catch (error) {
    if (error.message && /target|URL|hostname|IP|resolve|private|public|HTTP/i.test(error.message)) {
      return res.status(400).json({ error: error.message });
    }
    next(error);
  }
});

// GET /api/scans
router.get("/", async (req, res, next) => {
  try {
    const limit = Math.min(Math.max(Number.parseInt(req.query.limit || "20", 10) || 20, 1), 100);
    const offset = Math.max(Number.parseInt(req.query.offset || "0", 10) || 0, 0);

    const result = await db.query(
      `SELECT id, target_url, scan_type, status, findings_count, critical_count, high_count,
              pages_discovered, requests_analyzed, endpoints_found, error_message,
              created_at, started_at, completed_at
       FROM scans
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.user.id, limit, offset],
    );
    res.json({ scans: result.rows });
  } catch (error) {
    next(error);
  }
});

// GET /api/scans/all/findings
router.get("/all/findings", async (req, res, next) => {
  try {
    const limit = Math.min(Math.max(Number.parseInt(req.query.limit || "1000", 10) || 1000, 1), 5000);
    const result = await db.query(
      `SELECT f.id, f.scan_id, f.vulnerability_type, f.title, f.description, f.severity, f.cvss_score,
              f.cwe_id, f.affected_url, f.parameter_name, f.evidence, f.remediation,
              f.status, f.ai_confidence, f.detected_at, f.created_at, s.target_url
       FROM findings f
       JOIN scans s ON f.scan_id = s.id
       WHERE s.user_id = $1
       ORDER BY
         CASE f.severity WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 ELSE 5 END,
         f.detected_at DESC
       LIMIT $2`,
      [req.user.id, limit],
    );
    res.json({ findings: result.rows });
  } catch (error) {
    next(error);
  }
});

// GET /api/scans/:id/coverage
router.get("/:id/coverage", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid scan ID format." });
    }

    const result = await db.query(
      `SELECT
         s.id,
         s.status,
         s.target_url,
         s.max_pages,
         s.crawl_depth,
         s.pages_discovered,
         s.requests_analyzed,
         s.endpoints_found,
         COUNT(e.id)::int AS tracked_endpoints,
         COUNT(e.id) FILTER (WHERE e.crawl_status = 'crawled')::int AS crawled_endpoints,
         COUNT(e.id) FILTER (WHERE e.crawl_status = 'failed')::int AS failed_endpoints,
         COUNT(e.id) FILTER (WHERE e.crawl_status = 'skipped')::int AS skipped_endpoints,
         COUNT(e.id) FILTER (WHERE e.crawl_status = 'discovered')::int AS pending_endpoints,
         COUNT(e.id) FILTER (WHERE e.endpoint_type = 'form')::int AS forms_discovered,
         COUNT(e.id) FILTER (WHERE e.endpoint_type = 'api')::int AS api_endpoints_discovered,
         COUNT(DISTINCT e.depth)::int AS depth_levels_visited
       FROM scans s
       LEFT JOIN scan_endpoints e ON e.scan_id = s.id
       WHERE s.id = $1 AND s.user_id = $2
       GROUP BY s.id`,
      [req.params.id, req.user.id],
    );

    if (!result.rowCount) {
      return res.status(404).json({ error: "Scan not found." });
    }

    const row = result.rows[0];
    const discovered = Number(row.tracked_endpoints);
    const crawled = Number(row.crawled_endpoints);

    res.json({
      scan_id: row.id,
      status: row.status,
      target_url: row.target_url,
      limits: {
        max_pages: row.max_pages,
        crawl_depth: row.crawl_depth,
      },
      metrics: {
        pages_discovered: row.pages_discovered,
        requests_analyzed: row.requests_analyzed,
        endpoints_found: row.endpoints_found,
        tracked_endpoints: discovered,
        crawled_endpoints: crawled,
        failed_endpoints: Number(row.failed_endpoints),
        skipped_endpoints: Number(row.skipped_endpoints),
        pending_endpoints: Number(row.pending_endpoints),
        forms_discovered: Number(row.forms_discovered),
        api_endpoints_discovered: Number(row.api_endpoints_discovered),
        depth_levels_visited: Number(row.depth_levels_visited),
        crawl_completion_percent: discovered === 0 ? 0 : Math.round((crawled / discovered) * 100),
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/scans/:id/endpoints
router.get("/:id/endpoints", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid scan ID format." });
    }

    const owned = await db.query(
      "SELECT id FROM scans WHERE id = $1 AND user_id = $2",
      [req.params.id, req.user.id],
    );

    if (!owned.rowCount) {
      return res.status(404).json({ error: "Scan not found." });
    }

    const limit = Math.min(Math.max(Number.parseInt(req.query.limit || "100", 10) || 100, 1), 500);
    const offset = Math.max(Number.parseInt(req.query.offset || "0", 10) || 0, 0);

    const status = req.query.status;
    const allowedStatuses = new Set(["discovered", "crawled", "failed", "skipped"]);
    if (status && !allowedStatuses.has(status)) {
      return res.status(400).json({ error: "Invalid endpoint status filter." });
    }

    const result = await db.query(
      `SELECT
         id, url, http_method, endpoint_type, depth,
         status_code, content_type, discovered_from,
         crawl_status, error_message, discovered_at, crawled_at
       FROM scan_endpoints
       WHERE scan_id = $1
         AND ($2::text IS NULL OR crawl_status = $2)
       ORDER BY depth ASC, discovered_at ASC, id ASC
       LIMIT $3 OFFSET $4`,
      [req.params.id, status || null, limit, offset],
    );

    res.json({
      scan_id: req.params.id,
      endpoints: result.rows,
      pagination: { limit, offset, returned: result.rowCount },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/scans/:id
router.get("/:id", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid scan ID format." });
    }

    const result = await db.query(
      `SELECT
         id, user_id, target_url, scan_type, status, scan_config,
         scope_type, spider, passive, active,
         authorization_confirmed, crawl_depth, max_pages,
         request_delay_ms, javascript_crawling, follow_redirects,
         security_checks, excluded_paths, authentication_type,
         findings_count, critical_count, high_count,
         pages_discovered, requests_analyzed, endpoints_found,
         error_message, created_at, started_at, completed_at
       FROM scans
       WHERE id = $1 AND user_id = $2`,
      [req.params.id, req.user.id],
    );

    if (!result.rowCount) {
      return res.status(404).json({ error: "Scan not found." });
    }

    res.json({ scan: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

// GET /api/scans/:id/findings
router.get("/:id/findings", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid scan ID format." });
    }

    const owned = await db.query(
      "SELECT id FROM scans WHERE id = $1 AND user_id = $2",
      [req.params.id, req.user.id],
    );
    if (!owned.rowCount) {
      return res.status(404).json({ error: "Scan not found." });
    }

    const result = await db.query(
      `SELECT id, scan_id, vulnerability_type, title, description, severity, cvss_score,
              cwe_id, affected_url, parameter_name, evidence, remediation,
              status, ai_confidence, detected_at, created_at
       FROM findings
       WHERE scan_id = $1
       ORDER BY
         CASE severity WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 ELSE 5 END,
         detected_at DESC`,
      [req.params.id],
    );
    res.json({ findings: result.rows });
  } catch (error) {
    next(error);
  }
});

// GET /api/scans/:id/status
router.get("/:id/status", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid scan ID format." });
    }

    const result = await db.query(
      `SELECT
         s.id,
         s.status,
         s.pages_discovered,
         s.requests_analyzed,
         s.endpoints_found,
         s.error_message,
         COUNT(f.id)::int AS findings_count
       FROM scans s
       LEFT JOIN findings f ON f.scan_id = s.id
       WHERE s.id = $1 AND s.user_id = $2
       GROUP BY s.id`,
      [req.params.id, req.user.id],
    );

    if (!result.rowCount) {
      return res.status(404).json({ error: "Scan not found." });
    }

    const scan = result.rows[0];
    const progressByStatus = {
      queued: 0,
      crawling: 20,
      passive: 55,
      active: 55,
      analyzing: 85,
      completed: 100,
      failed: 0,
      cancelled: 0,
    };

    res.json({
      id: scan.id,
      status: scan.status,
      progress_percent: progressByStatus[scan.status] ?? 0,
      pages_discovered: scan.pages_discovered ?? 0,
      requests_analyzed: scan.requests_analyzed ?? 0,
      endpoints_found: scan.endpoints_found ?? 0,
      findings_count: scan.findings_count ?? 0,
      error_message: scan.error_message,
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/scans/:id/cancel
router.post("/:id/cancel", async (req, res, next) => {
  if (!isValidUUID(req.params.id)) {
    return res.status(400).json({ error: "Invalid scan ID format." });
  }

  const client = await db.connect();
  try {
    await client.query("BEGIN");

    const result = await client.query(
      `SELECT id, status
       FROM scans
       WHERE id = $1 AND user_id = $2
       FOR UPDATE`,
      [req.params.id, req.user.id],
    );

    if (!result.rowCount) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "Scan not found." });
    }

    const current = result.rows[0];
    const cancellable = ["queued", "running", "crawling", "passive", "active", "analyzing"];

    if (!cancellable.includes(current.status)) {
      await client.query("ROLLBACK");
      return res.status(409).json({
        error: `Scan cannot be cancelled in status "${current.status}".`,
        status: current.status,
      });
    }

    const updated = await client.query(
      `UPDATE scans
       SET status = 'cancelled',
           completed_at = NOW(),
           updated_at = NOW()
       WHERE id = $1 AND user_id = $2
       RETURNING id, target_url, scan_type, status,
                 findings_count, created_at, started_at, completed_at`,
      [req.params.id, req.user.id],
    );

    await client.query("COMMIT");
    return res.json({ scan: updated.rows[0] });
  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    next(error);
  } finally {
    client.release();
  }
});

const VALID_FINDING_TRANSITIONS = {
  open: ["in_progress", "accepted_risk", "false_positive"],
  in_progress: ["resolved", "accepted_risk", "false_positive", "open"],
  resolved: ["open", "in_progress"],
  accepted_risk: ["open"],
  false_positive: ["open"],
};

// PATCH /api/scans/findings/:id/status
router.patch("/findings/:id/status", async (req, res, next) => {
  if (!isValidUUID(req.params.id)) {
    return res.status(400).json({ error: "Invalid finding ID format." });
  }

  const { status, notes } = req.body;
  const targetStatus = typeof status === "string" ? status.toLowerCase() : "";

  if (!Object.keys(VALID_FINDING_TRANSITIONS).includes(targetStatus)) {
    return res.status(400).json({
      error: `Invalid status. Must be one of: ${Object.keys(VALID_FINDING_TRANSITIONS).join(", ")}.`,
    });
  }

  const client = await db.pool.connect();
  try {
    await client.query("BEGIN");

    const findingRes = await client.query(
      `SELECT f.id, f.status
       FROM findings f
       JOIN scans s ON f.scan_id = s.id
       WHERE f.id = $1 AND s.user_id = $2
       FOR UPDATE OF f`,
      [req.params.id, req.user.id],
    );

    if (findingRes.rowCount === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ error: "Finding not found or unauthorized." });
    }

    const currentStatus = findingRes.rows[0].status;
    if (currentStatus === targetStatus) {
      await client.query("ROLLBACK");
      return res.status(400).json({ error: `Finding is already '${targetStatus}'.` });
    }

    const allowedNext = VALID_FINDING_TRANSITIONS[currentStatus] || [];
    if (!allowedNext.includes(targetStatus)) {
      await client.query("ROLLBACK");
      return res.status(400).json({
        error: `Invalid transition from '${currentStatus}' to '${targetStatus}'.`,
      });
    }

    await client.query(
      `UPDATE findings SET status = $1::public.finding_status, updated_at = NOW() WHERE id = $2`,
      [targetStatus, req.params.id],
    );

    await client.query(
      `INSERT INTO finding_audit_logs (finding_id, user_id, action, previous_value, new_value, metadata)
       VALUES ($1, $2, 'status_changed', $3, $4, $5::jsonb)`,
      [req.params.id, req.user.id, currentStatus, targetStatus, JSON.stringify({ note: notes || null })],
    );

    if (notes && typeof notes === "string" && notes.trim().length > 0) {
      await client.query(
        `INSERT INTO finding_notes (finding_id, author_id, note) VALUES ($1, $2, $3)`,
        [req.params.id, req.user.id, notes.trim().slice(0, 2000)],
      );
    }

    await client.query("COMMIT");
    res.json({ message: "Finding status updated." });
  } catch (error) {
    await client.query("ROLLBACK").catch(() => {});
    next(error);
  } finally {
    client.release();
  }
});

// GET /api/scans/findings/:id/notes
router.get("/findings/:id/notes", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid finding ID format." });
    }

    const notesRes = await db.query(
      `SELECT n.id, n.note, n.created_at, u.full_name AS author_name, u.email AS author_email
       FROM finding_notes n
       JOIN findings f ON n.finding_id = f.id
       JOIN scans s ON f.scan_id = s.id
       JOIN users u ON n.author_id = u.id
       WHERE f.id = $1 AND s.user_id = $2
       ORDER BY n.created_at ASC`,
      [req.params.id, req.user.id],
    );
    res.json({ notes: notesRes.rows });
  } catch (error) {
    next(error);
  }
});

// POST /api/scans/findings/:id/notes
router.post("/findings/:id/notes", async (req, res, next) => {
  if (!isValidUUID(req.params.id)) {
    return res.status(400).json({ error: "Invalid finding ID format." });
  }

  const { note } = req.body;
  if (!note || typeof note !== "string" || note.trim().length === 0) {
    return res.status(400).json({ error: "Note is required." });
  }

  try {
    const authCheck = await db.query(
      `SELECT f.id FROM findings f JOIN scans s ON f.scan_id = s.id WHERE f.id = $1 AND s.user_id = $2`,
      [req.params.id, req.user.id],
    );
    if (authCheck.rowCount === 0) {
      return res.status(404).json({ error: "Finding not found." });
    }

    const noteRes = await db.query(
      `INSERT INTO finding_notes (finding_id, author_id, note) VALUES ($1, $2, $3) RETURNING *`,
      [req.params.id, req.user.id, note.trim().slice(0, 2000)],
    );
    await db.query(
      `INSERT INTO finding_audit_logs (finding_id, user_id, action, new_value) VALUES ($1, $2, 'note_added', 'Note appended')`,
      [req.params.id, req.user.id],
    );

    res.status(201).json({
      note: {
        ...noteRes.rows[0],
        author_name: req.user.full_name,
        author_email: req.user.email,
      },
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/scans/findings/:id/history
router.get("/findings/:id/history", async (req, res, next) => {
  try {
    if (!isValidUUID(req.params.id)) {
      return res.status(400).json({ error: "Invalid finding ID format." });
    }

    const histRes = await db.query(
      `SELECT l.id, l.action, l.previous_value, l.new_value, l.created_at, COALESCE(u.full_name, 'System (Scanner)') AS actor_name
       FROM finding_audit_logs l
       JOIN findings f ON l.finding_id = f.id
       JOIN scans s ON f.scan_id = s.id
       LEFT JOIN users u ON l.user_id = u.id
       WHERE f.id = $1 AND s.user_id = $2
       ORDER BY l.created_at ASC`,
      [req.params.id, req.user.id],
    );
    res.json({ history: histRes.rows });
  } catch (error) {
    next(error);
  }
});

module.exports = router;