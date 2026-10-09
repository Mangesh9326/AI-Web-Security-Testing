const { validatePublicHttpUrl } = require("./targetSafety");
const { analyzeResponse } = require("./passiveChecks");
const { processEvent } = require("./intrusionEngine");
const db = require("../db");
const crypto = require("node:crypto");

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Normalizes URL representation and removes fragment identifiers.
 */
function normalizePath(url) {
  const u = url instanceof URL ? new URL(url.href) : new URL(url);
  u.hash = "";
  return u.href;
}

/**
 * Returns effective port for standard and non-standard HTTP/HTTPS URLs.
 */
function getEffectivePort(url) {
  if (url.port) return url.port;
  return url.protocol === "https:" ? "443" : "80";
}

/**
 * Evaluates whether a candidate URL is within the authorized scope of startUrl.
 *
 * Scope definitions:
 * - single_url: exact same origin (protocol, host, port) as startUrl.
 * - domain: conservative same-host policy. Candidate must have the exact same
 *   hostname, protocol, and effective port as the target, but covers all paths across the domain.
 *   Subdomains and deceptive suffixes (e.g. example.com.attacker.test) are rejected.
 */
function isUrlInScope(candidateUrl, startUrl, scopeType = "single_url") {
  let candidate;
  let start;

  try {
    candidate = candidateUrl instanceof URL ? candidateUrl : new URL(candidateUrl);
    start = startUrl instanceof URL ? startUrl : new URL(startUrl);
  } catch {
    return false;
  }

  // Reject unsupported protocols
  if (!["http:", "https:"].includes(candidate.protocol) || !["http:", "https:"].includes(start.protocol)) {
    return false;
  }

  const candidateHost = candidate.hostname.toLowerCase().replace(/\.$/, "");
  const startHost = start.hostname.toLowerCase().replace(/\.$/, "");

  // Hostname must match exactly to prevent deceptive suffixes or cross-domain leaks
  if (candidateHost !== startHost) {
    return false;
  }

  // Enforce protocol and port boundary
  if (candidate.protocol !== start.protocol) {
    return false;
  }

  if (getEffectivePort(candidate) !== getEffectivePort(start)) {
    return false;
  }

  if (scopeType === "single_url") {
    return candidate.origin === start.origin;
  }

  if (scopeType === "domain") {
    return true;
  }

  return false;
}

/**
 * Extracts links from HTML attributes (href, src, action) resolved against baseUrl.
 */
function extractLinks(html, baseUrl) {
  const found = new Set();
  const pattern = /\b(?:href|src|action)\s*=\s*["']?([^"'\s>]+)["']?/gi;
  let match;

  while ((match = pattern.exec(html)) !== null) {
    try {
      const raw = match[1].trim();
      if (!raw || /^(?:javascript|mailto|tel|data|sms|ftp):/i.test(raw)) {
        continue;
      }
      const candidate = new URL(raw, baseUrl);
      if (["http:", "https:"].includes(candidate.protocol)) {
        candidate.hash = "";
        found.add(candidate.href);
      }
    } catch {
      // Ignore malformed links
    }
  }

  return [...found];
}

/**
 * Checks if a candidate URL matches any configured exclusion prefix.
 */
function pathExcluded(url, excludedPaths) {
  if (!Array.isArray(excludedPaths) || !excludedPaths.length) return false;
  return excludedPaths.some((path) => {
    if (typeof path !== "string" || !path.trim()) return false;
    try {
      const candidate = new URL(url);
      const cleanPath = path.trim().replace(/\*$/, "");
      return candidate.pathname.startsWith(cleanPath);
    } catch {
      return false;
    }
  });
}

/**
 * Executes an HTTP GET request with manual redirect validation and SSRF protection.
 */
async function fetchWithValidatedRedirects(initialUrl, startUrl, scopeType, config, signal) {
  let current = new URL(initialUrl);
  const maxRedirects = config.follow_redirects ? 5 : 0;

  for (let hop = 0; hop <= maxRedirects; hop++) {
    // 1. SSRF & destination validation on every hop
    await validatePublicHttpUrl(current.href);

    const headers = {
      "User-Agent": config.user_agent || "AI-WebSecTest-PassiveScanner/1.0",
      Accept: "text/html,application/xhtml+xml,*/*;q=0.8",
    };

    if (config.custom_headers && typeof config.custom_headers === "object") {
      for (const [key, value] of Object.entries(config.custom_headers)) {
        if (
          typeof key === "string" &&
          typeof value === "string" &&
          !/^(host|connection|content-length|transfer-encoding|cookie|authorization|proxy-authorization)$/i.test(key) &&
          key.length < 100 &&
          value.length < 1000
        ) {
          headers[key] = value;
        }
      }
    }

    const response = await fetch(current, {
      method: "GET",
      headers,
      redirect: "manual",
      signal,
    });

    if (![301, 302, 303, 307, 308].includes(response.status)) {
      return { response, finalUrl: current };
    }

    const location = response.headers.get("location");

    if (response.body) {
      await response.body.cancel().catch(() => {});
    }

    if (!location || hop === maxRedirects) {
      return { response, finalUrl: current };
    }

    const next = new URL(location, current);
    next.hash = "";

    // 2. Redirect boundary: do not follow out-of-scope destinations
    if (!isUrlInScope(next, startUrl, scopeType)) {
      return { response, finalUrl: current };
    }

    current = next;
  }

  return { response: null, finalUrl: current };
}

async function runPassiveScan(scan) {
  const config = typeof scan.scan_config === "string" ? JSON.parse(scan.scan_config) : (scan.scan_config || {});

  // Precedence: config.scope_type takes precedence, then scan.scope_type, defaulting to single_url
  const scopeType = (config.scope_type || scan.scope_type || "single_url").toLowerCase();

  const maxPages = Math.min(Math.max(Number(config.max_pages || 100), 1), 500);
  const maxDepth = Math.min(Math.max(Number(config.crawl_depth || 2), 1), 10);
  const delay = Math.min(Math.max(Number(config.request_delay_ms ?? 250), 100), 10000);
  const timeoutSeconds = Math.min(Math.max(Number(config.request_timeout_seconds || 20), 1), 60);

  const excludedPaths = Array.isArray(config.excluded_paths) ? config.excluded_paths : [];

  const startUrl = await validatePublicHttpUrl(scan.target_url);
  const normalizedStart = normalizePath(startUrl);

  const queue = [{ url: normalizedStart, depth: 0 }];
  const seen = new Set();
  const queued = new Set([normalizedStart]);
  const allFindings = [];

  await recordEndpoint(db, scan.id, {
    url: normalizedStart,
    method: "GET",
    type: "page",
    depth: 0,
    crawlStatus: "discovered",
  });

  let requestsAnalyzed = 0;

  async function checkTerminalStatus() {
    const result = await db.query("SELECT status FROM scans WHERE id = $1", [scan.id]);
    return !result.rowCount || ["cancelled", "completed", "failed"].includes(result.rows[0].status);
  }

  async function updateCounters() {
    await db.query(
      `UPDATE scans SET pages_discovered = $2, requests_analyzed = $3, endpoints_found = $4
       WHERE id = $1 AND status NOT IN ('cancelled', 'completed', 'failed')`,
      [scan.id, queued.size, requestsAnalyzed, queued.size],
    );
  }

  if (await checkTerminalStatus()) return;

  const started = await db.query(
    `UPDATE scans SET status = 'crawling', started_at = COALESCE(started_at, NOW())
     WHERE id = $1 AND status = 'queued' RETURNING id`,
    [scan.id],
  );

  if (!started.rowCount) return;

  while (queue.length && seen.size < maxPages) {
    if (await checkTerminalStatus()) return;

    const item = queue.shift();

    if (seen.has(item.url)) continue;

    if (pathExcluded(item.url, excludedPaths)) {
      await updateEndpointStatus(db, scan.id, item.url, "GET", "skipped", {
        errorMessage: "Path excluded by scan configuration",
      }).catch(() => {});
      continue;
    }

    let pageUrl;
    try {
      pageUrl = await validatePublicHttpUrl(item.url);
    } catch (err) {
      await updateEndpointStatus(db, scan.id, item.url, "GET", "failed", {
        errorMessage: err.message || "Target validation failed",
      }).catch(() => {});
      continue;
    }

    if (!isUrlInScope(pageUrl, startUrl, scopeType)) {
      await updateEndpointStatus(db, scan.id, item.url, "GET", "skipped", {
        errorMessage: "URL is out of permitted scan scope",
      }).catch(() => {});
      continue;
    }

    seen.add(item.url);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutSeconds * 1000);

    try {
      if (await checkTerminalStatus()) return;

      const { response, finalUrl } = await fetchWithValidatedRedirects(
        pageUrl.href,
        startUrl,
        scopeType,
        config,
        controller.signal,
      );

      if (!response) {
        throw new Error("No response received");
      }

      const finalHref = finalUrl.href;
      const contentType = response.headers.get("content-type") || "";

      // Traffic ingestion pipeline
      try {
        const trafficInsert = await db.query(
          `INSERT INTO traffic_logs 
            (scan_id, source_ip, method, endpoint, status_code, user_agent, classification, event_type, evidence, created_at)
           VALUES 
            ($1, $2, $3, $4, $5, $6, 'unclassified', 'http_request', $7::jsonb, NOW())
           RETURNING id, scan_id, source_ip, method, endpoint, status_code, user_agent, evidence`,
          [
            scan.id,
            "127.0.0.1",
            "GET",
            finalUrl.pathname + finalUrl.search,
            response.status,
            config.user_agent || "AI-WebSecTest-PassiveScanner/1.0",
            JSON.stringify({
              headers: {
                "content-type": contentType,
                server: response.headers.get("server") || "unknown",
              },
            }),
          ],
        );
        await processEvent(trafficInsert.rows[0]);
      } catch (ingestionError) {
        console.error("Traffic event ingestion failed during passive scan:", ingestionError);
      }

      // Passive analysis
      const findings = analyzeResponse(finalHref, response);
      allFindings.push(...findings);

      // Spidering & link extraction
      if (
        item.depth < maxDepth &&
        config.spider !== false &&
        /text\/html|application\/xhtml\+xml/i.test(contentType)
      ) {
        let html = "";
        let bytesRead = 0;
        const maxHtmlBytes = 1_000_000;

        if (response.body) {
          try {
            const decoder = new TextDecoder();
            for await (const chunk of response.body) {
              if (await checkTerminalStatus()) {
                await response.body.cancel?.().catch(() => {});
                return;
              }

              const remaining = maxHtmlBytes - bytesRead;
              const chunkData = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
              const toRead = chunkData.subarray(0, Math.min(remaining, chunkData.length));

              html += decoder.decode(toRead, { stream: true });
              bytesRead += toRead.byteLength;

              if (chunkData.length >= remaining) {
                await response.body.cancel?.().catch(() => {});
                break;
              }
            }
            html += decoder.decode();
          } catch (bodyError) {
            console.error("Warning: Partial body read error:", bodyError);
          }
        }

        const discoveredLinks = extractLinks(html, finalHref);

        for (const link of discoveredLinks) {
          const candidate = new URL(link);
          const endpointUrl = normalizePath(candidate);

          if (!isUrlInScope(candidate, startUrl, scopeType)) {
            continue;
          }

          if (seen.has(endpointUrl) || queued.has(endpointUrl)) {
            continue;
          }

          if (pathExcluded(endpointUrl, excludedPaths)) {
            await recordEndpoint(db, scan.id, {
              url: endpointUrl,
              method: "GET",
              type: "page",
              depth: item.depth + 1,
              discoveredFrom: finalHref,
              crawlStatus: "skipped",
            });
            queued.add(endpointUrl);
            continue;
          }

          if (queued.size < maxPages) {
            await recordEndpoint(db, scan.id, {
              url: endpointUrl,
              method: "GET",
              type: "page",
              depth: item.depth + 1,
              discoveredFrom: finalHref,
              crawlStatus: "discovered",
            });

            queue.push({ url: endpointUrl, depth: item.depth + 1 });
            queued.add(endpointUrl);
          }
        }
      } else {
        try {
          await response.body?.cancel?.();
        } catch {}
      }

      requestsAnalyzed++;
      await updateEndpointStatus(db, scan.id, item.url, "GET", "crawled", {
        statusCode: response.status,
        contentType,
      });
      await updateCounters();
    } catch (error) {
      if (await checkTerminalStatus()) return;

      let safeMsg = error.message || error.name || "request_error";
      let safeCode = error.code || null;
      if (error.cause) {
        safeMsg = error.cause.message || safeMsg;
        safeCode = error.cause.code || safeCode;
      }

      await updateEndpointStatus(db, scan.id, item.url, "GET", "failed", {
        errorMessage: safeCode ? `${safeCode}: ${safeMsg}` : safeMsg,
      }).catch(() => {});

      await db
        .query(
          `INSERT INTO activity_logs (user_id, scan_id, level, action, message, details)
           VALUES ($1, $2, 'warning', 'scan_request_failed', $3, $4::jsonb)`,
          [
            scan.user_id,
            scan.id,
            "A page could not be fetched during scanning.",
            JSON.stringify({ url: item.url, reason: safeCode || safeMsg }),
          ],
        )
        .catch(() => {});
        
      await updateCounters();
    } finally {
      clearTimeout(timeout);
    }

    if (queue.length && seen.size < maxPages) {
      await sleep(delay);
    }
  }

  if (requestsAnalyzed === 0) {
    throw new Error("Target unreachable: Zero HTTP requests completed successfully.");
  }

  if (await checkTerminalStatus()) return;

  const analyzing = await db.query(
    `UPDATE scans SET status = 'analyzing' WHERE id = $1 AND status = 'crawling' RETURNING id`,
    [scan.id],
  );

  if (!analyzing.rowCount) return;

  const uniqueFindings = [];
  const findingHashes = new Set();

  for (const finding of allFindings) {
    const hash = `${finding.vulnerability_type}|${finding.title}|${finding.affected_url}`;
    if (!findingHashes.has(hash)) {
      findingHashes.add(hash);
      uniqueFindings.push(finding);
    }
  }

  for (const finding of uniqueFindings) {
    if (await checkTerminalStatus()) return;

    const fingerprintString = `${finding.vulnerability_type}|${finding.title}|${finding.affected_url}`;
    const fingerprint = crypto.createHash("sha256").update(fingerprintString).digest("hex");

    const existing = await db.query(
      `SELECT f.id, f.status 
       FROM findings f 
       JOIN scans s ON f.scan_id = s.id 
       WHERE s.user_id = $1 AND s.target_url = $2 AND f.fingerprint = $3
       LIMIT 1`,
      [scan.user_id, scan.target_url, fingerprint],
    );

    if (existing.rowCount > 0) {
      const findingId = existing.rows[0].id;
      const currentStatus = existing.rows[0].status;
      const isReopened = ["resolved", "false_positive"].includes(currentStatus);

      await db.query(
        `UPDATE findings 
         SET scan_id = $1, 
             last_seen_at = NOW(), 
             updated_at = NOW(),
             status = CASE WHEN status IN ('resolved', 'false_positive') THEN 'open'::public.finding_status ELSE status END 
         WHERE id = $2`,
        [scan.id, findingId],
      );

      if (isReopened) {
        await db.query(
          `INSERT INTO finding_audit_logs (finding_id, user_id, action, previous_value, new_value, metadata) 
           VALUES ($1, NULL, 'finding_reopened', $2, 'open', $3::jsonb)`,
          [findingId, currentStatus, JSON.stringify({ reason: "Re-detected by scanner." })],
        );
      }
    } else {
      const newFinding = await db.query(
        `INSERT INTO findings
           (scan_id, vulnerability_type, title, description,
            severity, affected_url, evidence, remediation, ai_confidence, fingerprint, last_seen_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9, $10, NOW()) 
         RETURNING id`,
        [
          scan.id,
          finding.vulnerability_type,
          finding.title,
          finding.description,
          finding.severity,
          finding.affected_url,
          JSON.stringify(finding.evidence),
          finding.remediation,
          finding.ai_confidence,
          fingerprint,
        ],
      );

      await db.query(
        `INSERT INTO finding_audit_logs (finding_id, user_id, action, new_value, metadata) 
         VALUES ($1, NULL, 'finding_detected', 'open', '{}'::jsonb)`,
        [newFinding.rows[0].id],
      );
    }
  }

  const completed = await db.query(
    `UPDATE scans 
     SET status = 'completed', 
         completed_at = NOW(), 
         pages_discovered = $2,
         requests_analyzed = $3,
         endpoints_found = $2,
         findings_count = (SELECT COUNT(*) FROM findings WHERE scan_id = $1), 
         critical_count = (SELECT COUNT(*) FROM findings WHERE scan_id = $1 AND severity = 'critical'), 
         high_count = (SELECT COUNT(*) FROM findings WHERE scan_id = $1 AND severity = 'high') 
     WHERE id = $1 AND status = 'analyzing' 
     RETURNING id`,
    [scan.id, queued.size, requestsAnalyzed],
  );

  if (!completed.rowCount) return;

  await db.query(
    `INSERT INTO activity_logs (user_id, scan_id, level, action, message, details)
     VALUES ($1, $2, 'info', 'scan_completed', 'Passive scan completed.', $3::jsonb)`,
    [
      scan.user_id,
      scan.id,
      JSON.stringify({
        pages_discovered: queued.size,
        requests_analyzed: requestsAnalyzed,
        endpoints_found: queued.size,
        findings: uniqueFindings.length,
      }),
    ],
  );
}

async function markScanFailed(scan, error) {
  const message = String(error?.message || "Scan failed").slice(0, 1000);
  const reason = message.slice(0, 300);

  try {
    const result = await db.query(
      `UPDATE scans SET status = 'failed', completed_at = NOW(), error_message = $2
       WHERE id = $1 AND status NOT IN ('cancelled', 'completed', 'failed') RETURNING id`,
      [scan.id, message],
    );

    if (!result.rowCount) return;

    await db.query(
      `INSERT INTO activity_logs (user_id, scan_id, level, action, message, details)
       VALUES ($1, $2, 'error', 'scan_failed', 'Scan failed.', $3::jsonb)`,
      [scan.user_id, scan.id, JSON.stringify({ reason })],
    );
  } catch (loggingError) {
    console.error("Unable to record scan failure:", loggingError.message);
  }
}

async function processScan(scan) {
  try {
    await runPassiveScan(scan);
  } catch (error) {
    await markScanFailed(scan, error);
  }
}

async function recordEndpoint(db, scanId, endpoint) {
  const crawlStatus = endpoint.crawlStatus || "discovered";
  const result = await db.query(
    `INSERT INTO scan_endpoints (scan_id, url, http_method, endpoint_type, depth, discovered_from, crawl_status)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (scan_id, url, http_method) DO UPDATE
     SET crawl_status = CASE 
       WHEN scan_endpoints.crawl_status = 'discovered' AND EXCLUDED.crawl_status != 'discovered' THEN EXCLUDED.crawl_status 
       ELSE scan_endpoints.crawl_status 
     END
     RETURNING id`,
    [
      scanId,
      endpoint.url,
      endpoint.method || "GET",
      endpoint.type || "page",
      endpoint.depth ?? 0,
      endpoint.discoveredFrom || null,
      crawlStatus,
    ],
  );
  return result.rowCount > 0;
}

async function updateEndpointStatus(db, scanId, url, method, status, details = {}) {
  const allowed = new Set(["crawled", "failed", "skipped"]);
  if (!allowed.has(status)) throw new Error("Invalid endpoint crawl status.");

  await db.query(
    `UPDATE scan_endpoints
     SET crawl_status = $4,
         status_code = $5,
         content_type = $6,
         error_message = $7,
         crawled_at = CASE WHEN $4 = 'crawled' THEN NOW() ELSE crawled_at END
     WHERE scan_id = $1 AND url = $2 AND http_method = $3`,
    [
      scanId,
      url,
      method,
      status,
      details.statusCode ?? null,
      details.contentType ?? null,
      details.errorMessage ? String(details.errorMessage).slice(0, 300) : null,
    ],
  );
}

module.exports = {
  processScan,
  isUrlInScope,
  extractLinks,
  pathExcluded,
};