const { describe, it } = require("node:test");
const assert = require("node:assert");
const { parseTargetUrl, validatePublicDestination } = require("../src/utils/targetValidation.js");
const { validatePublicHttpUrl } = require("../src/scanner/targetSafety.js");

describe("Target Validation & SSRF Protection", () => {
  it("Blocks local and internal-network scan targets in production mode", async () => {
    process.env.ALLOW_LOCAL_TARGET_SCANNING = "false";

    // Test parseTargetUrl
    assert.throws(() => parseTargetUrl("http://localhost"), /Local and metadata hostnames are not allowed/);
    assert.throws(() => parseTargetUrl("http://localhost:3000/#/"), /Local and metadata hostnames are not allowed/);
    
    // IP validation happens during validatePublicDestination
    const parsedIp = parseTargetUrl("http://127.0.0.1");
    await assert.rejects(() => validatePublicDestination(parsedIp), /Targets resolving to private or reserved IP addresses are blocked/);
    
    // Test targetSafety.js
    await assert.rejects(() => validatePublicHttpUrl("http://localhost"), /Local and internal targets are blocked/);
    await assert.rejects(() => validatePublicHttpUrl("http://127.0.0.1"), /Private, loopback, or reserved IP targets are blocked/);
  });

  it("Blocks cloud metadata targets unconditionally", async () => {
    process.env.ALLOW_LOCAL_TARGET_SCANNING = "true";
    
    assert.throws(() => parseTargetUrl("http://metadata.google.internal"), /Local and metadata hostnames are not allowed/);
    await assert.rejects(() => validatePublicHttpUrl("http://169.254.169.254"), /Private, loopback, or reserved IP targets are blocked/);
  });

  it("Allows ordinary local frontend/API access explicitly in dev mode", async () => {
    process.env.ALLOW_LOCAL_TARGET_SCANNING = "true";

    const parsed = parseTargetUrl("http://localhost:3000/#/");
    assert.strictEqual(parsed.href, "http://localhost:3000/");

    const parsedIp = parseTargetUrl("http://127.0.0.1:8000/api");
    const addresses = await validatePublicDestination(parsedIp);
    assert.deepStrictEqual(addresses, ["127.0.0.1"]);
    
    // Test targetSafety.js allowing it
    const safeParsed = await validatePublicHttpUrl("http://localhost:3000/#/");
    assert.strictEqual(safeParsed.href, "http://localhost:3000/");
  });
});
