const test = require("node:test");
const assert = require("node:assert");

// Isolated validation logic representing the worker's failure determination
function isScanCompletedSuccessfully(requestsAnalyzed, checkTerminalStatusResult) {
  if (checkTerminalStatusResult === "cancelled") return "cancelled";
  
  if (requestsAnalyzed === 0) {
    throw new Error("Target unreachable: Zero HTTP requests completed successfully.");
  }
  
  return "completed";
}

test("Scanner Worker: Execution Edge Cases", async (t) => {
  await t.test("Scan fails if zero requests successfully executed", () => {
    // 0 analyzed means the startUrl threw an exception (e.g. DNS failure)
    assert.throws(() => isScanCompletedSuccessfully(0, false), /Target unreachable/);
  });

  await t.test("Scan completes if at least one request successfully analyzed", () => {
    // Even if 99 failed, if 1 succeeded, we process those findings.
    assert.strictEqual(isScanCompletedSuccessfully(1, false), "completed");
  });

  await t.test("Scan respects cancellation despite successful requests", () => {
    assert.strictEqual(isScanCompletedSuccessfully(10, "cancelled"), "cancelled");
  });
});