const test = require("node:test");
const assert = require("node:assert");
const { analyzeResponse } = require("../scanner/passiveChecks");

// Mock Fetch Response Object
const createMockResponse = (headersObj) => ({
  headers: {
    get: (name) => headersObj[name.toLowerCase()] || null
  }
});

test("Phase 6: Passive Security Checks", async (t) => {
  await t.test("Secure Response returns 0 findings", () => {
    const res = createMockResponse({
      "strict-transport-security": "max-age=31536000",
      "content-security-policy": "default-src 'self'",
      "x-content-type-options": "nosniff",
      "referrer-policy": "strict-origin-when-cross-origin",
      "set-cookie": "session=xyz; Secure; HttpOnly; SameSite=Strict"
    });
    
    const findings = analyzeResponse("https://example.com", res);
    assert.strictEqual(findings.length, 0);
  });

  await t.test("Missing Security Headers accurately reported", () => {
    const res = createMockResponse({}); // Empty headers
    
    const findings = analyzeResponse("https://example.com", res);
    
    // Expect 4 missing headers (HSTS, CSP, XCTO, Referrer-Policy)
    assert.strictEqual(findings.length, 4);
    assert.ok(findings.some(f => f.title.includes("Content-Security-Policy")));
    assert.ok(findings.some(f => f.title.includes("Strict-Transport-Security")));
    assert.strictEqual(findings[0].vulnerability_type, "security_headers");
  });

  await t.test("HTTP targets do not require HSTS", () => {
    const res = createMockResponse({}); 
    const findings = analyzeResponse("http://example.com", res);
    
    // Should NOT include HSTS finding because it's HTTP
    assert.strictEqual(findings.some(f => f.title.includes("HSTS")), false);
  });

  await t.test("Insecure Cookie Parsing redacts values", () => {
    const res = createMockResponse({
      "set-cookie": "secret_session_token=super_secret_value123; path=/"
    });
    
    const findings = analyzeResponse("https://example.com", res);
    
    // Should flag Missing Secure, Missing HttpOnly, Missing SameSite
    assert.strictEqual(findings.length, 7); // 4 header alerts + 3 cookie alerts
    
    const cookieFindings = findings.filter(f => f.vulnerability_type === "security_misconfiguration");
    assert.strictEqual(cookieFindings.length, 3);
    
    // Validate Evidence contains NO secrets
    const evidenceStr = JSON.stringify(cookieFindings[0].evidence);
    assert.ok(evidenceStr.includes("secret_session_token"));
    assert.strictEqual(evidenceStr.includes("super_secret_value123"), false); // Secret must not be logged
  });

  await t.test("Information Disclosure Detection", () => {
    const res = createMockResponse({
      "server": "nginx/1.18.0",
      "x-powered-by": "Express",
      // Include required secure headers to isolate findings
      "strict-transport-security": "max-age=31536000",
      "content-security-policy": "default-src 'self'",
      "x-content-type-options": "nosniff",
      "referrer-policy": "strict-origin-when-cross-origin"
    });
    
    const findings = analyzeResponse("https://example.com", res);
    
    assert.strictEqual(findings.length, 2);
    assert.strictEqual(findings[0].vulnerability_type, "information_disclosure");
    assert.strictEqual(findings[0].ai_confidence, 0.85); // Nginx version might be spoofed
    assert.strictEqual(findings[1].ai_confidence, 1.0);  // X-Powered-By is explicitly declared
  });
});