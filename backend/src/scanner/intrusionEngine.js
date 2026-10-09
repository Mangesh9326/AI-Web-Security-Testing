const db = require("../db");
const { evaluateEventRules } = require("./rules");

/**
 * Builds a deterministic correlation key to deduplicate and group related events.
 */
function buildCorrelationKey(scanId, ruleId, sourceIp, endpoint) {
  const pathOnly = endpoint.split("?")[0].slice(0, 80);
  const ip = sourceIp || "unknown_ip";
  return `${scanId}:${ruleId}:${ip}:${pathOnly}`;
}

/**
 * Processes a single traffic event through the detection engine,
 * updates the traffic log record, and creates or updates aggregated alerts.
 * @param {Object} event - The ingested traffic event record.
 * @param {Object} client - Optional PostgreSQL client for transactional consistency.
 */
async function processEvent(event, client = null) {
  const queryClient = client || db;
  const matches = evaluateEventRules(event);

  if (matches.length === 0) {
    await queryClient.query(
      `UPDATE traffic_logs
       SET classification = 'benign', confidence = 0.95, severity = 'info'
       WHERE id = $1`,
      [event.id]
    );
    return { evaluated: true, alertsCreated: 0 };
  }

  const severityRank = { critical: 5, high: 4, medium: 3, low: 2, info: 1 };
  let primaryMatch = matches[0];
  for (const match of matches) {
    if ((severityRank[match.severity] || 0) > (severityRank[primaryMatch.severity] || 0)) {
      primaryMatch = match;
    }
  }

  await queryClient.query(
    `UPDATE traffic_logs
     SET classification = $1, confidence = $2, severity = $3,
         evidence = jsonb_set(COALESCE(evidence, '{}'::jsonb), '{detection_matches}', $4::jsonb)
     WHERE id = $5`,
    [
      primaryMatch.classification,
      primaryMatch.confidence,
      primaryMatch.severity,
      JSON.stringify(matches),
      event.id
    ]
  );

  let alertsCreated = 0;
  for (const match of matches) {
    const correlationKey = buildCorrelationKey(
      event.scan_id,
      match.ruleId,
      event.source_ip,
      event.endpoint
    );

    const existingAlert = await queryClient.query(
      `SELECT id, occurrence_count 
       FROM alerts
       WHERE correlation_key = $1
         AND status IN ('new', 'investigating')
         AND last_seen_at >= (NOW() - INTERVAL '2 hours')
       LIMIT 1`,
      [correlationKey]
    );

    if (existingAlert.rowCount > 0) {
      await queryClient.query(
        `UPDATE alerts
         SET occurrence_count = occurrence_count + 1,
             last_seen_at = NOW(),
             evidence = $1::jsonb
         WHERE id = $2`,
        [JSON.stringify(match.evidence), existingAlert.rows[0].id]
      );
    } else {
      const newAlert = await queryClient.query(
        `INSERT INTO alerts (
           scan_id, traffic_log_id, correlation_key, rule_id, classification,
           severity, confidence, source_ip, endpoint, http_method,
           status, occurrence_count, description, evidence, first_seen_at, last_seen_at
         ) VALUES (
           $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'new', 1, $11, $12::jsonb, NOW(), NOW()
         )
         RETURNING id`,
        [
          event.scan_id,
          event.id,
          correlationKey,
          match.ruleId,
          match.classification,
          match.severity,
          match.confidence,
          event.source_ip,
          event.endpoint,
          event.method,
          match.reason,
          JSON.stringify(match.evidence)
        ]
      );

      // Create initial audit trail entry
      await queryClient.query(
        `INSERT INTO alert_audit_logs (alert_id, user_id, action, new_value, metadata)
         VALUES ($1, NULL, 'alert_created', 'new', $2::jsonb)`,
        [
          newAlert.rows[0].id,
          JSON.stringify({ rule_id: match.ruleId, classification: match.classification, severity: match.severity })
        ]
      );

      alertsCreated++;
    }
  }

  return { evaluated: true, matches: matches.length, alertsCreated };
}

module.exports = {
  processEvent,
  buildCorrelationKey
};