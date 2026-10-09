/**
 * Passive Response Analyzer
 * Analyzes HTTP responses for missing security headers, insecure cookie attributes,
 * and information disclosure. Does NOT send active payloads.
 */
function analyzeResponse(url, response) {
  const findings = [];
  const headers = response.headers;

  // Helper to safely extract headers regardless of the fetch implementation
  const getHeader = (name) => {
    if (!headers) return null;
    if (typeof headers.get === "function") return headers.get(name);
    return headers[name.toLowerCase()] || null;
  };

  const add = (type, title, severity, description, remediation, evidence = {}, confidence = 1.0) => {
    findings.push({
      vulnerability_type: type,
      title,
      severity,
      description,
      affected_url: url,
      evidence,
      remediation,
      ai_confidence: confidence 
    });
  };

  const isHttps = url.startsWith("https://");

  // ==========================================
  // 1. Security Headers (Defense-in-Depth)
  // ==========================================
  if (isHttps && !getHeader("strict-transport-security")) {
    add(
      "security_headers", 
      "Missing Strict-Transport-Security (HSTS) Header", 
      "low",
      "The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.",
      "Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.", 
      { missing_header: "Strict-Transport-Security" }, 
      1.0
    );
  }
  
  if (!getHeader("content-security-policy")) {
    add(
      "security_headers", 
      "Missing Content-Security-Policy (CSP) Header", 
      "low",
      "The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).",
      "Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.", 
      { missing_header: "Content-Security-Policy" }, 
      1.0
    );
  }

  if (!getHeader("x-content-type-options")) {
    add(
      "security_headers", 
      "Missing X-Content-Type-Options Header", 
      "info",
      "The response does not set 'X-Content-Type-Options: nosniff', potentially allowing browsers to perform unexpected MIME-type sniffing.",
      "Add the 'X-Content-Type-Options: nosniff' header to all HTTP responses.", 
      { missing_header: "X-Content-Type-Options" }, 
      1.0
    );
  }

  if (!getHeader("referrer-policy")) {
    add(
      "security_headers", 
      "Missing Referrer-Policy Header", 
      "info",
      "The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.",
      "Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.", 
      { missing_header: "Referrer-Policy" }, 
      1.0
    );
  }

  // ==========================================
  // 2. Cookie Security Misconfigurations
  // ==========================================
  const setCookieHeader = getHeader("set-cookie");
  if (setCookieHeader) {
    // Handle both string arrays (Node fetch) and comma-separated strings securely
    const cookieStrings = Array.isArray(setCookieHeader)
      ? setCookieHeader
      : setCookieHeader.split(/,(?=\s*[^;,]+=)/);

    for (const cookieStr of cookieStrings) {
      if (!cookieStr || typeof cookieStr !== "string") continue;
      
      const parts = cookieStr.split(";");
      const nameValuePair = parts[0].trim();
      const cookieName = nameValuePair.split("=")[0].trim() || "unnamed";
      const lowerCookieStr = cookieStr.toLowerCase();

      // IMPORTANT: Cookie values are explicitly excluded from evidence to prevent secret logging.
      if (isHttps && !lowerCookieStr.includes("secure")) {
        add(
          "security_misconfiguration", 
          `Insecure Cookie Attribute: ${cookieName}`, 
          "low",
          "A cookie was set over HTTPS but lacks the 'Secure' attribute, meaning the browser could transmit it over an insecure HTTP connection if downgraded.",
          "Ensure the 'Secure' flag is set on all cookies.",
          { cookie_name: cookieName }, 
          1.0
        );
      }

      if (!lowerCookieStr.includes("httponly")) {
        add(
          "security_misconfiguration", 
          `Missing HttpOnly Cookie Attribute: ${cookieName}`, 
          "low",
          "A cookie lacks the 'HttpOnly' attribute, making it accessible to client-side JavaScript and increasing the impact of potential XSS attacks.",
          "Ensure the 'HttpOnly' flag is set for session and authentication cookies.",
          { cookie_name: cookieName }, 
          1.0
        );
      }

      if (!lowerCookieStr.includes("samesite")) {
        add(
          "security_misconfiguration", 
          `Missing SameSite Cookie Attribute: ${cookieName}`, 
          "info",
          "A cookie lacks the 'SameSite' attribute, which removes a layer of defense against Cross-Site Request Forgery (CSRF).",
          "Configure the 'SameSite' attribute to 'Lax' or 'Strict' depending on cross-domain requirements.",
          { cookie_name: cookieName }, 
          1.0
        );
      }
    }
  }

  // ==========================================
  // 3. Information Disclosure
  // ==========================================
  const serverHeader = getHeader("server");
  if (serverHeader && /\d/.test(serverHeader)) {
    add(
      "information_disclosure", 
      "Server Version Disclosure", 
      "info",
      "The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.",
      "Configure the web server to omit version numbers or mask the Server header.", 
      { server_header: serverHeader }, 
      0.85 // 0.85 confidence because some versions are deliberately spoofed by WAFs
    );
  }

  const poweredByHeader = getHeader("x-powered-by");
  if (poweredByHeader) {
    add(
      "information_disclosure", 
      "Technology Stack Disclosure", 
      "info",
      "The response includes an 'X-Powered-By' header, revealing the underlying application framework.",
      "Disable or remove the 'X-Powered-By' header in the application framework configuration.", 
      { x_powered_by: poweredByHeader }, 
      1.0
    );
  }

  return findings;
}

module.exports = { analyzeResponse };