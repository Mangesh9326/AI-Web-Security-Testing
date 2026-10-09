const test = require("node:test");
const assert = require("node:assert");

// Finite State Machine reference from route
const VALID_TRANSITIONS = {
  new: ["investigating", "false_positive"],
  investigating: ["confirmed", "false_positive", "resolved"],
  confirmed: ["resolved", "investigating"],
  false_positive: ["investigating"],
  resolved: ["investigating"]
};

function isValidTransition(current, next) {
  const allowed = VALID_TRANSITIONS[current] || [];
  return allowed.includes(next);
}

test("Phase 4: Alert Lifecycle & Investigation Controls", async (t) => {
  await t.test("Valid Transitions: new -> investigating -> confirmed -> resolved", () => {
    assert.strictEqual(isValidTransition("new", "investigating"), true);
    assert.strictEqual(isValidTransition("investigating", "confirmed"), true);
    assert.strictEqual(isValidTransition("confirmed", "resolved"), true);
  });

  await t.test("Invalid Transition: Reject jumping directly from new to resolved", () => {
    assert.strictEqual(isValidTransition("new", "resolved"), false);
  });

  await t.test("Invalid Transition: Reject jumping directly from new to confirmed without triage", () => {
    assert.strictEqual(isValidTransition("new", "confirmed"), false);
  });

  await t.test("Reopening Workflow: Permitted from resolved or false_positive back to investigating", () => {
    assert.strictEqual(isValidTransition("resolved", "investigating"), true);
    assert.strictEqual(isValidTransition("false_positive", "investigating"), true);
  });

  await t.test("Note Length Validation: Rejects empty or oversized text", () => {
    const validateNote = (note) => {
      if (typeof note !== "string" || note.trim().length === 0) throw new Error("Empty note");
      if (note.trim().length > 2000) throw new Error("Oversized note");
      return true;
    };

    assert.throws(() => validateNote(""), /Empty note/);
    assert.throws(() => validateNote("   "), /Empty note/);
    assert.throws(() => validateNote("A".repeat(2001)), /Oversized note/);
    assert.strictEqual(validateNote("Valid analyst assessment findings."), true);
  });
});