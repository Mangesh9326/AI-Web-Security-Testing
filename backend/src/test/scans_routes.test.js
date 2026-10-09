const test = require("node:test");
const assert = require("node:assert");
const express = require("express");
const request = require("supertest");
const proxyquire = require("proxyquire");

// Mock database and worker dependencies
const mockDb = {
  query: async (sql, params) => {
    // Normalize newlines and tabs to single spaces for reliable mock matching
    const normalizedSql = sql.replace(/\s+/g, ' ').trim();

    if (
      normalizedSql.includes("FROM scans WHERE id = $1 AND user_id = $2") || 
      normalizedSql.includes("FROM scans s LEFT JOIN findings f ON f.scan_id = s.id WHERE s.id = $1 AND s.user_id = $2")
    ) {
      if (params && params[0] === "11111111-1111-4111-8111-111111111111") {
        return { 
          rowCount: 1, 
          rows: [{ 
            id: params[0], 
            status: "completed",
            pages_discovered: 5,
            requests_analyzed: 5,
            endpoints_found: 5,
            findings_count: 2,
            error_message: null
          }] 
        };
      }
      return { rowCount: 0, rows: [] }; // Correctly triggers 404
    }

    if (normalizedSql.includes("INSERT INTO scans")) {
      return {
        rowCount: 1,
        rows: [
          {
            id: params[0],
            user_id: params[1],
            target_url: params[2],
            scan_type: params[3],
            status: "queued",
            created_at: new Date().toISOString(),
          },
        ],
      };
    }
    
    // Default fallback for other queries
    return { rowCount: 1, rows: [{}] }; 
  },
  connect: async () => ({
    query: async () => ({ rowCount: 1, rows: [{ id: "11111111-1111-4111-8111-111111111111", status: "queued" }] }),
    release: () => {},
  }),
  pool: {
    connect: async () => ({
      query: async () => ({ rowCount: 1, rows: [{ id: "11111111-1111-4111-8111-111111111111", status: "open" }] }),
      release: () => {},
    }),
  },
};

const mockTargetSafety = {
  validatePublicHttpUrl: async (raw) => {
    const url = new URL(raw);
    if (url.hostname === "localhost" || url.hostname === "127.0.0.1") {
      throw new Error("Local and internal targets are blocked.");
    }
    return url;
  },
};

const mockWorker = {
  processScan: async () => {},
};

// Also mock utils/targetValidation.js since it runs before targetSafety.js
const mockTargetValidation = {
  TargetValidationError: class extends Error {
    constructor(msg, statusCode = 400) {
      super(msg);
      this.statusCode = statusCode;
    }
  },
  parseTargetUrl: (url) => new URL(url),
  validatePublicDestination: async (url) => {
    if (url.hostname === "localhost" || url.hostname === "127.0.0.1") {
      const err = new Error("Local and metadata hostnames are not allowed.");
      err.statusCode = 400;
      throw err;
    }
    return true;
  }
};

const app = express();
app.use(express.json());
app.use((req, res, next) => {
  req.user = { id: "00000000-0000-4000-8000-000000000000", full_name: "Test User", email: "test@example.test" };
  next();
});

const scansRouter = proxyquire("../routes/scans", {
  "../db": mockDb,
  "../middleware/requireAuth": (req, res, next) => next(),
  "../scanner/targetSafety": mockTargetSafety,
  "../utils/targetValidation": mockTargetValidation,
  "../scanner/worker": mockWorker,
});

app.use("/api/scans", scansRouter);

test("Scan Routes Validation & Security Suite", async (t) => {
  await t.test("POST /api/scans rejects missing target_url", async () => {
    const res = await request(app).post("/api/scans").send({});
    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.body.error, "target_url is required.");
  });

  await t.test("POST /api/scans rejects internal/localhost target", async () => {
    const res = await request(app).post("/api/scans").send({ target_url: "http://localhost" });
    assert.strictEqual(res.status, 400);
    // Accommodates the custom error emitted by your targetValidation.js file
    assert.match(res.body.error, /Local and metadata hostnames are not allowed|Local and internal targets are blocked/);
  });

  await t.test("POST /api/scans rejects unsupported scope_type: 'domain'", async () => {
    const res = await request(app).post("/api/scans").send({
      target_url: "https://example.com",
      scope_type: "domain",
    });
    assert.strictEqual(res.status, 400);
    assert.match(res.body.error, /Domain-wide scanning is not enabled yet/);
  });

  await t.test("POST /api/scans rejects active: true", async () => {
    const res = await request(app).post("/api/scans").send({
      target_url: "https://example.com",
      active: true,
    });
    assert.strictEqual(res.status, 400);
    assert.match(res.body.error, /Active scanning is not implemented yet/);
  });

  await t.test("POST /api/scans rejects unsupported authentication", async () => {
    const res = await request(app).post("/api/scans").send({
      target_url: "https://example.com",
      authentication_type: "bearer_token",
    });
    assert.strictEqual(res.status, 400);
    assert.match(res.body.error, /Authenticated scanning is not implemented yet/);
  });

  await t.test("POST /api/scans rejects unsupported scan profile", async () => {
    const res = await request(app).post("/api/scans").send({
      target_url: "https://example.com",
      scan_type: "extreme_exploit",
    });
    assert.strictEqual(res.status, 400);
    assert.match(res.body.error, /Scan profile 'extreme_exploit' is not supported/);
  });

  await t.test("POST /api/scans rejects out-of-range crawl depth", async () => {
    const res = await request(app).post("/api/scans").send({
      target_url: "https://example.com",
      crawl_depth: 25,
    });
    assert.strictEqual(res.status, 400);
    assert.match(res.body.error, /crawl_depth must be an integer from 1 to 10/);
  });

  await t.test("POST /api/scans successfully queues valid configuration", async () => {
    const res = await request(app).post("/api/scans").send({
      target_url: "https://example.com",
      scan_type: "standard",
      scope_type: "single_url",
    });
    assert.strictEqual(res.status, 202);
    assert.strictEqual(res.body.status, "queued");
    assert.strictEqual(res.body.message, "Passive scan queued.");
  });

  await t.test("GET /api/scans/:id returns 400 on invalid non-UUID identifier", async () => {
    const res = await request(app).get("/api/scans/invalid-not-uuid");
    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.body.error, "Invalid scan ID format.");
  });

  await t.test("GET /api/scans/:id returns 404 for non-existent or unowned scan", async () => {
    const res = await request(app).get("/api/scans/99999999-9999-4999-8999-999999999999");
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.body.error, "Scan not found.");
  });

  await t.test("GET /api/scans/:id/status returns accurate progress metrics", async () => {
    const res = await request(app).get("/api/scans/11111111-1111-4111-8111-111111111111/status");
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.body.status, "completed");
    assert.strictEqual(res.body.progress_percent, 100);
    assert.strictEqual(res.body.findings_count, 2);
  });
});