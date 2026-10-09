const test = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');

test('Crawler link extraction handles fragments and attributes correctly', (t) => {
  const fileContent = fs.readFileSync('./src/scanner/worker.js', 'utf8');
  
  // Capture ONLY the body of the function, stopping precisely after its return statement
  const extractLinksRegex = /function extractLinks\(html, baseUrl\) \{([\s\S]*?return \[\.\.\.found\];)\n\}/;
  const match = fileContent.match(extractLinksRegex);
  
  if (!match) {
    assert.fail('Could not locate extractLinks in worker.js');
  }

  // Create an isolated function instance using just the cleanly extracted body
  const extractLinks = new Function('html', 'baseUrl', match[1]);

  const html = `
    <a href="https://example.com/page?test=1#section1">Absolute with Hash</a>
    <img src="/image.png" />
    <link href='https://example.com/styles.css#minified' />
    <a href="javascript:alert(1)">XSS</a>
    <a href="https://external.com/page">External</a>
  `;

  const links = extractLinks(html, 'https://example.com');
  
  // Validates: Fragment removal, relative URL resolution, protocol filtering
  assert.ok(links.includes('https://example.com/page?test=1'));
  assert.ok(links.includes('https://example.com/image.png'));
  assert.ok(links.includes('https://example.com/styles.css'));
  assert.strictEqual(links.includes('javascript:alert(1)'), false);
});