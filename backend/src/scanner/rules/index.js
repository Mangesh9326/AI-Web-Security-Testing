// Bounded normalization helper to safely decode URI components
function safeDecode(str) {
  if (typeof str !== "string") return "";
  try {
    return decodeURIComponent(str.replace(/\+/g, " "));
  } catch {
    return str;
  }
}

// 1. SQL Injection Signatures
const SQLI_PATTERNS = [
  { pattern: /(?:\bunion\b\s+(?:all\s+)?select\b)/i, reason: "UNION SELECT statement detected", confidence: 0.95 },
  { pattern: /(?:--|#|\/\*).*$/i, reason: "SQL comment delimiter detected", confidence: 0.70 },
  { pattern: /(?:\b(?:and|or)\b\s+[\d'"]+\s*=\s*[\d'"]+)/i, reason: "Tautological boolean injection pattern (e.g., OR 1=1)", confidence: 0.90 },
  { pattern: /(?:\b(?:exec|execute)\s*\(?\s*(?:xp_cmdshell|sp_executesql)\b)/i, reason: "Dangerous SQL procedure invocation", confidence: 0.98 },
  { pattern: /(?:\bwaitfor\s+delay\b|\bsleep\s*\(\s*\d+\s*\)|\bbenchmark\s*\(\s*\d+)/i, reason: "Time-based blind SQL injection signature", confidence: 0.92 }
];

// 2. Cross-Site Scripting (XSS) Signatures
const XSS_PATTERNS = [
  { pattern: /<\s*script[^>]*>/i, reason: "Explicit HTML <script> tag injection", confidence: 0.95 },
  { pattern: /\bjavascript:\s*[\w\W]+/i, reason: "JavaScript URI pseudo-protocol execution attempt", confidence: 0.90 },
  { pattern: /<\s*(?:iframe|object|embed|svg|img|body)\b[^>]*?\bon(?:error|load|mouseover|click)\s*=/i, reason: "Inline DOM event handler payload", confidence: 0.92 },
  { pattern: /(?:document\.(?:cookie|location|domain)|window\.location)\b/i, reason: "DOM property access payload targeting session context", confidence: 0.85 }
];

// 3. Path Traversal Signatures
const TRAVERSAL_PATTERNS = [
  { pattern: /(?:\.\.[\/\\]|\.\.%2f|\.\.%5c)/i, reason: "Directory traversal character sequence (../)", confidence: 0.88 },
  { pattern: /(?:\/etc\/(?:passwd|shadow|hosts)|\/windows\/win\.ini|\/boot\.ini)/i, reason: "Targeting sensitive operating system system files", confidence: 0.98 },
  // FIXED: Required traversal characters before .env or .git/config to separate from basic recon
  { pattern: /(?:WEB-INF[\/\\]web\.xml|\.\.[\/\\]+(?:\.env|\.git\/config))/i, reason: "Targeting application configuration secrets or SCM metadata", confidence: 0.95 }
];

// 4. Reconnaissance & Sensitive Endpoint Probing
const RECON_PATHS = [
  { pattern: /^\/(?:phpinfo|info)\.php/i, reason: "PHP environment diagnostic probe", confidence: 0.85 },
  { pattern: /^\/(?:wp-admin|wp-login\.php|administrator|phpmyadmin)/i, reason: "Common CMS/Database administrative gateway discovery probe", confidence: 0.75 },
  { pattern: /^\/(?:\.env|\.git|\.aws|\.docker)/i, reason: "Hidden file or secret directory reconnaissance", confidence: 0.90 },
  { pattern: /^\/(?:actuator\/health|server-status|elmah\.axd)/i, reason: "Framework debug/status endpoint probe", confidence: 0.80 }
];

// Suspicious HTTP Methods
const SUSPICIOUS_METHODS = ["TRACE", "TRACK", "DEBUG", "CONNECT"];

/**
 * Evaluates an individual traffic event against deterministic security rules.
 * @param {Object} event - The traffic log event object.
 * @returns {Array} List of matched detections.
 */
function evaluateEventRules(event) {
  const matches = [];
  const endpoint = typeof event.endpoint === "string" ? event.endpoint : "";
  const method = typeof event.method === "string" ? event.method.toUpperCase() : "GET";
  const userAgent = typeof event.user_agent === "string" ? event.user_agent : "";

  // Normalization pass
  const decodedEndpoint = safeDecode(endpoint);
  const targetText = `${endpoint} ${decodedEndpoint} ${JSON.stringify(event.evidence || {})}`;

  // Evaluate SQL Injection
  for (const rule of SQLI_PATTERNS) {
    if (rule.pattern.test(targetText)) {
      matches.push({
        ruleId: "RULE-SQLI-001",
        classification: "SQL Injection",
        severity: rule.confidence >= 0.9 ? "critical" : "high",
        confidence: rule.confidence,
        reason: rule.reason,
        evidence: { matchedPattern: rule.pattern.toString(), matchedContext: endpoint.slice(0, 150) }
      });
      break; 
    }
  }

  // Evaluate XSS
  for (const rule of XSS_PATTERNS) {
    if (rule.pattern.test(targetText)) {
      matches.push({
        ruleId: "RULE-XSS-001",
        classification: "Cross-Site Scripting",
        severity: "high",
        confidence: rule.confidence,
        reason: rule.reason,
        evidence: { matchedPattern: rule.pattern.toString(), matchedContext: endpoint.slice(0, 150) }
      });
      break;
    }
  }

  // Evaluate Path Traversal
  for (const rule of TRAVERSAL_PATTERNS) {
    if (rule.pattern.test(targetText)) {
      matches.push({
        ruleId: "RULE-TRAVERSAL-001",
        classification: "Path Traversal",
        severity: rule.confidence >= 0.95 ? "high" : "medium",
        confidence: rule.confidence,
        reason: rule.reason,
        evidence: { matchedPattern: rule.pattern.toString(), matchedContext: endpoint.slice(0, 150) }
      });
      break;
    }
  }

  // Evaluate HTTP Reconnaissance
  for (const rule of RECON_PATHS) {
    if (rule.pattern.test(decodedEndpoint)) {
      matches.push({
        ruleId: "RULE-RECON-001",
        classification: "Reconnaissance",
        severity: "low",
        confidence: rule.confidence,
        reason: rule.reason,
        evidence: { matchedEndpoint: endpoint }
      });
      break;
    }
  }

  // Evaluate Suspicious HTTP Methods
  if (SUSPICIOUS_METHODS.includes(method)) {
    matches.push({
      ruleId: "RULE-METHOD-001",
      classification: "Protocol Abuse",
      severity: "medium",
      confidence: 0.85,
      reason: `Anomalous or disabled HTTP method encountered: ${method}`,
      evidence: { method, endpoint }
    });
  }

  // Evaluate Suspicious Scanner User-Agents
  if (/sqlmap|nikto|nmap|acunetix|masscan|zgrab/i.test(userAgent)) {
    matches.push({
      ruleId: "RULE-SCANNER-UA-001",
      classification: "Automated Attack Tool",
      severity: "medium",
      confidence: 0.90,
      reason: "Known vulnerability scanning tool user-agent string detected",
      evidence: { userAgent: userAgent.slice(0, 100) }
    });
  }

  return matches;
}

module.exports = {
  evaluateEventRules,
  safeDecode
};