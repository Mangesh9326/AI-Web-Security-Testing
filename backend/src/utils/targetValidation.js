const dns = require('node:dns').promises;
const net = require('node:net');
const ipaddr = require('ipaddr.js');

const ALLOWED_PROTOCOLS = new Set(['http:', 'https:']);

class TargetValidationError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.name = 'TargetValidationError';
    this.statusCode = statusCode;
  }
}

/**
 * Normalize and validate a URL's syntax.
 */
function parseTargetUrl(input) {
  if (typeof input !== 'string' || input.trim().length === 0) {
    throw new TargetValidationError('A target URL is required.');
  }

  if (input.length > 2048) {
    throw new TargetValidationError('Target URL is too long.');
  }

  if (/[\u0000-\u0020\u007f\\]/.test(input)) {
    throw new TargetValidationError('Target URL contains whitespace or invalid characters.');
  }

  let url;
  try {
    url = new URL(input);
  } catch {
    throw new TargetValidationError('Target URL is invalid.');
  }

  if (!ALLOWED_PROTOCOLS.has(url.protocol)) {
    throw new TargetValidationError('Only HTTP and HTTPS targets are allowed.');
  }

  if (url.username || url.password) {
    throw new TargetValidationError('Credentials must not be embedded in the target URL.');
  }

  const port = url.port ? parseInt(url.port, 10) : (url.protocol === 'https:' ? 443 : 80);
  if (isNaN(port) || port <= 0 || port > 65535) {
    throw new TargetValidationError('Target URL contains an invalid port.');
  }

  if (!url.hostname) {
    throw new TargetValidationError('Target hostname is missing.');
  }

  const hostname = url.hostname.toLowerCase().replace(/\.$/, '');

  const isDevMode = process.env.ALLOW_LOCAL_TARGET_SCANNING === 'true';

  if (
    hostname.endsWith('.internal') ||
    hostname === 'metadata.google.internal'
  ) {
    throw new TargetValidationError('Local and metadata hostnames are not allowed.');
  }

  if (
    hostname === 'localhost' ||
    hostname.endsWith('.localhost') ||
    hostname.endsWith('.local')
  ) {
    if (!isDevMode) {
      throw new TargetValidationError('Local and metadata hostnames are not allowed.');
    }
  }

  if (hostname.includes('%')) {
    throw new TargetValidationError('IPv6 zone identifiers are not allowed.');
  }

  url.hostname = hostname;
  url.hash = '';

  return url;
}

/**
 * Return true only for globally routable unicast IP addresses.
 */
function isPublicIp(address, isDevMode = false) {
  if (net.isIP(address) === 0) return false;

  try {
    let parsed = ipaddr.parse(address);

    if (parsed.kind() === 'ipv6' && parsed.isIPv4MappedAddress()) {
      parsed = parsed.toIPv4Address();
    }
    
    if (parsed.range() === 'linkLocal') {
      return false;
    }

    const prohibited = [
      'private', 'loopback', 'multicast', 'broadcast',
      'carrierGradeNat', 'reserved', 'unspecified'
    ];
    
    if (isDevMode && parsed.range() === 'loopback') {
      return true;
    }

    return !prohibited.includes(parsed.range());
  } catch {
    return false;
  }
}

/**
 * Resolve a hostname and reject it if ANY returned address is non-public.
 */
async function validatePublicDestination(url) {
  const hostname = url.hostname.replace(/^\[|\]$/g, '');
  const isDevMode = process.env.ALLOW_LOCAL_TARGET_SCANNING === 'true';

  if (net.isIP(hostname)) {
    if (!isPublicIp(hostname, isDevMode)) {
      throw new TargetValidationError('Targets resolving to private or reserved IP addresses are blocked.');
    }
    return [hostname];
  }

  let records;
  try {
    records = await dns.lookup(hostname, { all: true, verbatim: true });
  } catch {
    throw new TargetValidationError('Target hostname could not be resolved.');
  }

  if (!records || !records.length) {
    throw new TargetValidationError('Target hostname did not resolve to an IP address.');
  }

  const addresses = [...new Set(records.map(record => record.address))];

  if (addresses.some(address => !isPublicIp(address, isDevMode))) {
    throw new TargetValidationError('Target hostname resolves to a private or reserved IP address.');
  }

  return addresses;
}

/**
 * Scope enforcement for both single_url and domain modes.
 */
function isWithinScope(candidate, approvedTarget, scopeType = 'single_url') {
  const url = candidate instanceof URL ? candidate : parseTargetUrl(candidate);
  const root = approvedTarget instanceof URL ? approvedTarget : parseTargetUrl(approvedTarget);

  const effectivePort = value => value.port || (value.protocol === 'https:' ? '443' : '80');

  const isSameOrigin = (
    url.protocol === root.protocol &&
    url.hostname === root.hostname &&
    effectivePort(url) === effectivePort(root)
  );

  if (!isSameOrigin) return false;

  if (scopeType === 'single_url') {
    return url.pathname.startsWith(root.pathname);
  }

  return true;
}

/**
 * Validate a discovered URL or redirect against an approved origin and scope,
 * then check its DNS/IP destination.
 */
async function validateScopedUrl(candidate, approvedTarget, scopeType = 'single_url') {
  const url = parseTargetUrl(candidate);

  if (!isWithinScope(url, approvedTarget, scopeType)) {
    throw new TargetValidationError('URL is outside the approved scan scope.', 403);
  }

  const addresses = await validatePublicDestination(url);

  return { url, addresses };
}

module.exports = {
  TargetValidationError,
  parseTargetUrl,
  isPublicIp,
  validatePublicDestination,
  isWithinScope,
  validateScopedUrl,
};