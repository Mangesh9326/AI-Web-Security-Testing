const test = require("node:test");
const assert = require("node:assert");
const express = require("express");
const request = require("supertest");
const proxyquire = require("proxyquire");

// Mock API client and dependencies
const mockApi = {
  get: async (url, config) => {
    if (url === "/scans") {
      return { data: { scans: [{ id: "scan-1", target_url: "https://example.com" }] } };
    }
    if (url.includes("/endpoints")) {
      return { data: { scan_id: "scan-1", endpoints: [] } };
    }
    return { data: {} };
  },
  post: async (url, data) => {
    if (url === "/scans") {
      if (!data || !data.target_url) {
        const err = new Error("Request failed with status code 400");
        err.response = { status: 400, data: { error: "target_url is required." } };
        throw err;
      }
      return { data: { id: "123-uuid", status: "queued", target_url: data.target_url } };
    }
    if (url.includes("/cancel")) {
      return { data: { scan: { id: "123-uuid", status: "cancelled" } } };
    }
    return { data: {} };
  },
  patch: async (url, data) => {
    if (url.includes("/status")) {
      return { data: { message: "Finding status updated." } };
    }
    return { data: {} };
  }
};

const scanService = proxyquire("../services/scanService", {
  "./api": mockApi
});

test("scanService Integration Tests (Native Node Runner)", async (t) => {
  await t.test("createScan returns valid data when scan ID is returned", async () => {
    const result = await scanService.createScan({ target_url: "https://example.com" });
    assert.strictEqual(result.id, "123-uuid");
    assert.strictEqual(result.status, "queued");
  });

  await t.test("createScan throws if server response is missing scan ID", async () => {
    // Override post mock for this specific test case
    const originalPost = mockApi.post;
    mockApi.post = async () => ({ data: { status: "queued" } }); // Missing ID

    await assert.rejects(
      () => scanService.createScan({ target_url: "https://example.com" }),
      /Invalid response from server: Missing scan ID/
    );

    mockApi.post = originalPost; // restore
  });

  await t.test("getScans requests correct base route", async () => {
    const result = await scanService.getScans({ limit: 10 });
    assert.ok(result.scans);
    assert.strictEqual(result.scans.length, 1);
  });

  await t.test("updateFindingStatus maps status and notes correctly", async () => {
    const result = await scanService.updateFindingStatus("finding-1", "resolved", "Fixed upstream");
    assert.strictEqual(result.message, "Finding status updated.");
  });

  await t.test("cancelScan targets correct route", async () => {
    const result = await scanService.cancelScan("123-uuid");
    assert.strictEqual(result.scan.status, "cancelled");
  });
});