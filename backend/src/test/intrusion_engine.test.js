const test = require("node:test");
const assert = require("node:assert");
const { evaluateEventRules } = require("../scanner/rules");
const { buildCorrelationKey } = require("../scanner/intrusionEngine");

test("Phase 3: Intrusion Detection Engine Rules", async (t) => {
  await t.test("Benign traffic does not trigger security rules", () => {
    const event = {
      endpoint: "/products/view?category=electronics&page=2",
      method: "GET",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    };
    const matches = evaluateEventRules(event);
    assert.strictEqual(matches.length, 0);
  });

  await t.test("SQL Injection: Detects UNION SELECT attempts", () => {
    const event = {
      endpoint: "/api/users?id=-1%20UNION%20SELECT%20username,password%20FROM%20users--",
      method: "GET"
    };
    const matches = evaluateEventRules(event);
    assert.ok(matches.length > 0);
    assert.strictEqual(matches[0].classification, "SQL Injection");
    assert.strictEqual(matches[0].severity, "critical");
    assert.ok(matches[0].confidence >= 0.9);
  });

  await t.test("SQL Injection: Detects Boolean Injection patterns", () => {
    const event = {
      endpoint: "/search?q=' OR 1=1--",
      method: "GET"
    };
    const matches = evaluateEventRules(event);
    assert.ok(matches.length > 0);
    assert.strictEqual(matches[0].classification, "SQL Injection");
  });

  await t.test("XSS: Detects inline event handlers & script tags", () => {
    const event = {
      endpoint: "/comment?msg=<script>alert(document.cookie)</script>",
      method: "POST"
    };
    const matches = evaluateEventRules(event);
    assert.ok(matches.length > 0);
    assert.strictEqual(matches[0].classification, "Cross-Site Scripting");
    assert.strictEqual(matches[0].severity, "high");
  });

  await t.test("Path Traversal: Detects directory traversal attempts", () => {
    const event = {
      endpoint: "/download?file=../../../../etc/passwd",
      method: "GET"
    };
    const matches = evaluateEventRules(event);
    assert.ok(matches.length > 0);
    assert.strictEqual(matches[0].classification, "Path Traversal");
  });

  await t.test("Reconnaissance: Detects sensitive probe paths (.env / phpinfo)", () => {
    const event = {
      endpoint: "/.env",
      method: "GET"
    };
    const matches = evaluateEventRules(event);
    assert.ok(matches.length > 0);
    assert.strictEqual(matches[0].classification, "Reconnaissance");
    assert.strictEqual(matches[0].severity, "low");
  });

  await t.test("Protocol Abuse: Flags unexpected methods (TRACE)", () => {
    const event = {
      endpoint: "/login",
      method: "TRACE"
    };
    const matches = evaluateEventRules(event);
    assert.ok(matches.some((m) => m.classification === "Protocol Abuse"));
  });

  await t.test("Correlation Key: Deterministically groups query-variant attacks", () => {
    const scanId = "123e4567-e89b-12d3-a456-426614174000";
    const ruleId = "RULE-SQLI-001";
    const key1 = buildCorrelationKey(scanId, ruleId, "192.168.1.5", "/search?q=1%20OR%201=1");
    const key2 = buildCorrelationKey(scanId, ruleId, "192.168.1.5", "/search?q=2%20OR%201=1");

    assert.strictEqual(key1, key2);
  });
});