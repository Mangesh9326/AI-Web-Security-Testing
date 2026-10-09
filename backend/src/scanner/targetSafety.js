"use strict";

const { URL } = require("node:url");
const dns = require("node:dns").promises;
const net = require("node:net");
const ipaddr = require("ipaddr.js");

/**
 * Returns true only for globally routable unicast IP addresses.
 * Rejects private, loopback, link-local, reserved, multicast,
 * unspecified, and other non-public address ranges.
 */
function isPublicIp(ipString, isDevMode = false) {
  try {
    if (typeof ipString !== "string" || !net.isIP(ipString)) {
      return false;
    }

    let parsedIp = ipaddr.parse(ipString);

    if (
      parsedIp.kind() === "ipv6" &&
      parsedIp.isIPv4MappedAddress()
    ) {
      parsedIp = parsedIp.toIPv4Address();
    }
    
    if (parsedIp.range() === "linkLocal") {
      return false;
    }

    const prohibited = [
      "private", "loopback", "multicast", "broadcast",
      "carrierGradeNat", "reserved", "unspecified"
    ];

    if (isDevMode && parsedIp.range() === "loopback") {
      return true;
    }

    return !prohibited.includes(parsedIp.range());
  } catch {
    return false;
  }
}

/**
 * Validates a URL and verifies that its destination resolves
 * exclusively to public IP addresses.
 *
 * IMPORTANT:
 * DNS validation alone does not prevent DNS rebinding. The HTTP
 * client must connect to a validated IP address, or use an
 * equivalent DNS-pinning strategy, while preserving TLS hostname
 * verification and the original Host header.
 */
async function validatePublicHttpUrl(raw) {
  let parsedUrl;

  try {
    if (typeof raw !== "string" || !raw.trim()) {
      throw new Error("A target URL is required.");
    }

    parsedUrl = new URL(raw);
  } catch {
    throw new Error("Invalid URL format.");
  }

  if (!["http:", "https:"].includes(parsedUrl.protocol)) {
    throw new Error(
      "Unsupported protocol. Only HTTP and HTTPS are allowed."
    );
  }

  if (parsedUrl.username || parsedUrl.password) {
    throw new Error(
      "Embedded credentials in URLs are not permitted."
    );
  }

  const hostname = parsedUrl.hostname
    .replace(/^\[|\]$/g, "")
    .toLowerCase()
    .replace(/\.$/, "");

  const isDevMode = process.env.ALLOW_LOCAL_TARGET_SCANNING === 'true';

  if (
    hostname.endsWith(".internal") ||
    hostname === "metadata.google.internal"
  ) {
    throw new Error("Local and internal targets are blocked.");
  }

  if (
    hostname === "localhost" ||
    hostname.endsWith(".localhost") ||
    hostname.endsWith(".local")
  ) {
    if (!isDevMode) {
      throw new Error("Local and internal targets are blocked.");
    }
  }

  parsedUrl.hash = "";

  if (net.isIP(hostname)) {
    if (!isPublicIp(hostname, isDevMode)) {
      throw new Error(
        "Private, loopback, or reserved IP targets are blocked."
      );
    }

    return parsedUrl;
  }

  let addresses;

  try {
    addresses = await dns.lookup(hostname, {
      all: true,
      verbatim: true,
    });
  } catch (error) {
    throw new Error(
      `DNS lookup failed for target hostname (${error.code || "DNS_ERROR"}).`
    );
  }

  if (!Array.isArray(addresses) || addresses.length === 0) {
    throw new Error("Target hostname resolved to no addresses.");
  }

  for (const record of addresses) {
    if (!isPublicIp(record.address, isDevMode)) {
      throw new Error(
        "Target hostname resolves to a private or non-public IP address."
      );
    }
  }

  return parsedUrl;
}

module.exports = {
  validatePublicHttpUrl,
  isPublicIp,
};