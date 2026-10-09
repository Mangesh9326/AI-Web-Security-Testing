const { describe, it } = require("node:test");
const assert = require("node:assert");
const { isUrlInScope } = require("../src/scanner/worker.js");

describe("isUrlInScope Domain Scoping Rules", () => {
  it("Enforces single_url strictly within origin path boundary", () => {
    const start = "https://example.com/app/docs/";
    
    // In scope
    assert.strictEqual(isUrlInScope("https://example.com/app/docs/page1", start, "single_url"), true);
    assert.strictEqual(isUrlInScope("https://example.com/app/docs/", start, "single_url"), true);
    
    // Out of scope (path doesn't match)
    assert.strictEqual(isUrlInScope("https://example.com/app/", start, "single_url"), false);
    assert.strictEqual(isUrlInScope("https://example.com/", start, "single_url"), false);
    
    // Out of scope (host/port/protocol)
    assert.strictEqual(isUrlInScope("http://example.com/app/docs/", start, "single_url"), false);
    assert.strictEqual(isUrlInScope("https://sub.example.com/app/docs/", start, "single_url"), false);
  });

  it("Enforces domain scope across entire exact hostname and port, but blocks subdomains and deceptive hosts", () => {
    const start = "https://example.com/app/docs/";
    
    // In scope (any path on exact host/port/protocol)
    assert.strictEqual(isUrlInScope("https://example.com/app/docs/page1", start, "domain"), true);
    assert.strictEqual(isUrlInScope("https://example.com/", start, "domain"), true);
    assert.strictEqual(isUrlInScope("https://example.com/totally/different", start, "domain"), true);
    
    // Out of scope (subdomains)
    assert.strictEqual(isUrlInScope("https://sub.example.com/", start, "domain"), false);
    
    // Out of scope (deceptive suffixes)
    assert.strictEqual(isUrlInScope("https://example.com.attacker.com/", start, "domain"), false);
    
    // Out of scope (protocol/port mismatch)
    assert.strictEqual(isUrlInScope("http://example.com/", start, "domain"), false);
    assert.strictEqual(isUrlInScope("https://example.com:8443/", start, "domain"), false);
  });
});
