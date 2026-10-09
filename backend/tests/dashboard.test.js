const test = require("node:test");
const assert = require("node:assert");
const express = require("express");
const request = require("supertest");
const proxyquire = require("proxyquire");

const mockDb = {
  query: async (sql, params) => {
    const normalized = sql.replace(/\s+/g, ' ').trim();
    if (normalized.includes("total_scans")) {
      return {
        rows: [{
          total_scans: 10,
          completed_scans: 5,
          running_scans: 2,
          failed_scans: 3
        }]
      };
    }
    if (normalized.includes("total_findings")) {
      return {
        rows: [{
          total_findings: 100,
          critical_high_findings: 20,
          open_findings: 50,
          critical_findings: 5,
          high_findings: 15,
          medium_findings: 40,
          low_findings: 40
        }]
      };
    }
    return { rows: [] };
  }
};

const mockWorker = {
  processScan: async () => {},
  getScanProgress: () => ({ status: "completed" })
};

const scansRouter = proxyquire("../src/routes/scans", {
  "../db": mockDb,
  "../scanner/worker": mockWorker,
  "../middleware/requireAuth": (req, res, next) => next()
});

const app = express();
app.use(express.json());
app.use((req, res, next) => {
  req.user = { id: "user-1" };
  next();
});
app.use("/api/scans", scansRouter);

test("Dashboard Metrics Endpoint", async (t) => {
  await t.test("Returns aggregated scan and finding statistics", async () => {
    const res = await request(app).get("/api/scans/dashboard/metrics");
    assert.strictEqual(res.statusCode, 200);
    assert.deepStrictEqual(res.body, {
      scans: {
        total_scans: 10,
        completed_scans: 5,
        running_scans: 2,
        failed_scans: 3
      },
      findings: {
        total_findings: 100,
        critical_high_findings: 20,
        open_findings: 50,
        critical_findings: 5,
        high_findings: 15,
        medium_findings: 40,
        low_findings: 40
      }
    });
  });
});
