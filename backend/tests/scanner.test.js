const { describe, it } = require("node:test");
const assert = require("node:assert");
const proxyquire = require("proxyquire");

describe("Scanner Worker Regression Tests", () => {
  it("A reachable HTML page with several internal links produces multiple discovered endpoints", async () => {
    let endpointsCount = 0;
    const dbMock = {
      query: async (q, params) => {
        if (q.includes("status FROM scans")) return { rowCount: 1, rows: [{ status: "queued" }] };
        if (q.includes("UPDATE scans SET status")) return { rowCount: 1, rows: [{ id: "123" }] };
        if (q.includes("INSERT INTO scan_endpoints")) {
          endpointsCount++;
          return { rowCount: 1 };
        }
        if (q.includes("UPDATE scan_endpoints")) return { rowCount: 1 };
        if (q.includes("traffic_logs")) return { rowCount: 1, rows: [{ id: 1 }] };
        if (q.includes("SELECT f.id, f.status")) return { rowCount: 0 };
        return { rowCount: 1, rows: [] };
      }
    };

    const fetchMock = async (url) => {
      const html = '<a href="http://example.com/about">About</a><a href="/contact">Contact</a>';
      return {
        status: 200,
        headers: { get: (name) => name === "content-type" ? "text/html" : null },
        body: (async function* () {
          yield Buffer.from(html);
        })()
      };
    };

    const worker = proxyquire("../src/scanner/worker.js", {
      "../db": dbMock,
      "./targetSafety": { validatePublicHttpUrl: async (u) => new URL(u) },
      "./intrusionEngine": { processEvent: async () => {} }
    });

    global.fetch = fetchMock;

    const scan = {
      id: "123",
      target_url: "http://example.com",
      scan_config: { max_pages: 5, spider: true, scope_type: "domain" },
      user_id: "abc"
    };

    await worker.processScan(scan);
    // 1 start url + 2 discovered links = 3 endpoints
    assert.strictEqual(endpointsCount, 3);
  });

  it("A failed initial request cannot be presented as a successful crawl", async () => {
    let statusFailed = false;
    let endpointFailed = false;

    const dbMock = {
      query: async (q, params) => {
        if (q.includes("status FROM scans")) return { rowCount: 1, rows: [{ status: "queued" }] };
        if (q.includes("UPDATE scans SET status = 'failed'")) {
          statusFailed = true;
          return { rowCount: 1, rows: [{ id: "123" }] };
        }
        if (q.includes("UPDATE scans SET status")) return { rowCount: 1, rows: [{ id: "123" }] };
        if (q.includes("UPDATE scan_endpoints") && params.includes("failed")) {
          endpointFailed = true;
        }
        return { rowCount: 1, rows: [] };
      }
    };

    const worker = proxyquire("../src/scanner/worker.js", {
      "../db": dbMock,
      "./targetSafety": { validatePublicHttpUrl: async (u) => new URL(u) },
      "./intrusionEngine": { processEvent: async () => {} }
    });

    global.fetch = async () => {
      throw Object.assign(new Error("Connection timeout"), { code: "ETIMEDOUT" });
    };

    const scan = {
      id: "fail-test",
      target_url: "http://example.com",
      scan_config: { max_pages: 1 },
      user_id: "abc"
    };

    await worker.processScan(scan);
    assert.strictEqual(statusFailed, true, "Scan must be marked as failed");
    assert.strictEqual(endpointFailed, true, "Endpoint must be marked as failed");
  });
});
