import React, { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { createScan } from '../services/scanService';
import { apiError } from '../services/api';

const profiles = {
  quick: {
    label: "Quick Scan",
    description: "Shallow crawling with passive checks.",
    depth: 2,
    pages: 50,
    active: false
  },
  standard: {
    label: "Standard Web Scan",
    description: "Balanced crawling and passive analysis.",
    depth: 5,
    pages: 100,
    active: false
  },
  passive: {
    label: "Passive Scan",
    description: "Non-invasive analysis only. Safest for production.",
    depth: 5,
    pages: 100,
    active: false
  }
};

const checks = [
  'sql_injection', 'xss', 'csrf', 'security_headers', 
  'authentication', 'authorization', 'ssl_tls', 
  'information_disclosure', 'sensitive_data_exposure', 'security_misconfiguration'
];

const labelFormat = (value) => value.replaceAll('_', ' ').replace(/\b\w/g, (c) => c.toUpperCase());

const defaults = {
  target_url: "",
  scan_type: "standard",
  scope_type: "single_url", // Hardcoded backend requirement
  excluded_paths: [],
  spider: true,
  passive: true,
  active: false, // Hardcoded backend requirement
  authorization_confirmed: false,
  crawl_depth: 5,
  max_pages: 100,
  request_delay_ms: 250,
  javascript_crawling: false,
  follow_redirects: true,
  security_checks: [
    "sql_injection",
    "xss",
    "csrf",
    "security_headers"
  ],
  authentication_type: "none", // Hardcoded backend requirement
  request_timeout_seconds: 20,
  max_concurrent_requests: 1, // Sequential only currently
  user_agent: "",
  custom_headers: {}
};

export default function NewScan() {
  const [form, setForm] = useState(defaults);
  const [exclusion, setExclusion] = useState('');
  const [headerKey, setHeaderKey] = useState('');
  const [headerValue, setHeaderValue] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [advanced, setAdvanced] = useState(false);
  const [previewMode, setPreviewMode] = useState(false);
  const navigate = useNavigate();

  const targetState = useMemo(() => {
    try {
      const url = new URL(form.target_url);
      return ['http:', 'https:'].includes(url.protocol) && url.hostname 
        ? { valid: true, msg: '✓ Valid HTTP/HTTPS target' } 
        : { valid: false, msg: '✕ Please enter a valid HTTP/HTTPS URL.' };
    } catch {
      return form.target_url ? { valid: false, msg: '✕ Please enter a valid HTTP/HTTPS URL.' } : null;
    }
  }, [form.target_url]);

  const set = (key, value) => setForm((old) => ({ ...old, [key]: value }));

  const chooseProfile = (scan_type) => {
    const profile = profiles[scan_type];
    setForm((old) => ({ 
      ...old, 
      scan_type, 
      crawl_depth: profile.depth, 
      max_pages: profile.pages, 
      active: false, // Forced to false due to backend constraints
      authorization_confirmed: false, 
      passive: true, 
      spider: true,
      scope_type: 'single_url', // Forced to single_url
      authentication_type: 'none' // Forced to none
    }));
  };

  const toggleCheck = (check) => set('security_checks', form.security_checks.includes(check) 
    ? form.security_checks.filter((item) => item !== check) 
    : [...form.security_checks, check]);

  const addHeader = () => {
    if (headerKey.trim() && headerValue.trim()) {
      set('custom_headers', { ...form.custom_headers, [headerKey.trim()]: headerValue.trim() });
      setHeaderKey('');
      setHeaderValue('');
    }
  };

  const removeHeader = (keyToRemove) => {
    const newHeaders = { ...form.custom_headers };
    delete newHeaders[keyToRemove];
    set('custom_headers', newHeaders);
  };

  const submit = async (event) => {
    event.preventDefault();
    setError('');

    if (!targetState?.valid) return setError('Please enter a valid HTTP/HTTPS URL.');
    if (!form.security_checks.length) return setError('Choose at least one security check.');

    // Build the strictly enforced payload
    const payload = { 
      ...form, 
      active: false, 
      scope_type: 'single_url', 
      authentication_type: 'none' 
    };

    if (previewMode) {
      alert(`PREVIEW MODE: Configuration validated successfully.\n\nTarget: ${payload.target_url}\nProfile: ${profiles[payload.scan_type].label}\nAuth: ${payload.authentication_type}\n\nNo actual scan was started.`);
      return;
    }

    setLoading(true);
    try {
      const scan = await createScan(payload); 
      if (scan && scan.id) {
        navigate(`/scan/${scan.id}`); 
      } else {
        setError('Server responded with success but missing scan ID.');
      }
    } catch (err) {
      setError(apiError(err, 'Unable to create scan. Ensure the target resolves properly.')); 
    } finally {
      setLoading(false);
    }
  };

  const Section = ({ title, desc, children }) => (
    <section className="scan-section">
      <h3 className="section-title">{title}</h3>
      {desc && <p className="section-desc">{desc}</p>}
      <div className="section-content">{children}</div>
    </section>
  );

  return (
    <div className="scan-container">
      <style>{`
        .scan-container { max-width: 1400px; margin: 0 auto; padding: 20px; font-family: system-ui, -apple-system, sans-serif; }
        .page-header { margin-bottom: 24px; }
        .page-label { font-size: 12px; font-weight: 600; color: #64748b; letter-spacing: 0.05em; margin-bottom: 4px; }
        .page-title { font-size: 28px; margin: 0 0 8px 0; color: #0f172a; }
        .page-description { color: #475569; margin: 0; }
        .grid-layout { display: grid; grid-template-columns: 1fr 350px; gap: 24px; align-items: start; }
        @media (max-width: 900px) { .grid-layout { grid-template-columns: 1fr; } }
        .card { background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
        .scan-section { border-bottom: 1px solid #f1f5f9; padding-bottom: 24px; margin-bottom: 24px; }
        .scan-section:last-child { border-bottom: none; padding-bottom: 0; margin-bottom: 0; }
        .section-title { font-size: 16px; margin: 0 0 4px 0; color: #1e293b; }
        .section-desc { font-size: 13px; color: #64748b; margin: 0 0 16px 0; }
        .form-group { display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; }
        .form-label { font-size: 14px; font-weight: 500; color: #334155; }
        .form-input, .form-select { padding: 10px 12px; border: 1px solid #cbd5e1; border-radius: 6px; font-size: 14px; width: 100%; box-sizing: border-box; }
        .form-input:focus, .form-select:focus { outline: none; border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59,130,246,0.1); }
        .form-input:disabled, .form-select:disabled { background-color: #f8fafc; color: #94a3b8; cursor: not-allowed; }
        .notice { background: #eff6ff; border-left: 4px solid #3b82f6; padding: 12px; border-radius: 4px; color: #1e40af; font-size: 13px; margin-top: 12px; }
        .warning-box { background: #fff7ed; border: 1px solid #fed7aa; padding: 16px; border-radius: 8px; color: #9a3412; margin-top: 16px; }
        .error-box { background: #fef2f2; border: 1px solid #fecaca; color: #b91c1c; padding: 12px; border-radius: 8px; margin-bottom: 20px; }
        .radio-group { display: flex; gap: 16px; margin-bottom: 12px; }
        .radio-label { display: flex; align-items: center; gap: 8px; font-size: 14px; cursor: pointer; }
        .radio-label.disabled { color: #94a3b8; cursor: not-allowed; }
        .flex-row { display: flex; gap: 8px; }
        .btn-secondary { padding: 10px 16px; background: #f1f5f9; border: 1px solid #cbd5e1; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500; }
        .btn-secondary:hover { background: #e2e8f0; }
        .btn-text { background: none; border: none; color: #2563eb; font-weight: 600; cursor: pointer; padding: 0; font-size: 14px; }
        .tag { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; background: #e0e7ff; color: #3730a3; border-radius: 16px; font-size: 12px; margin: 8px 8px 0 0; }
        .tag button { background: none; border: none; color: #3730a3; cursor: pointer; font-weight: bold; padding: 0; }
        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .checkbox-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }
        .checkbox-label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #475569; }
        .summary-panel { position: sticky; top: 24px; }
        .summary-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #f1f5f9; font-size: 13px; }
        .summary-row:last-of-type { border-bottom: none; }
        .status-badge { display: block; text-align: center; padding: 10px; border-radius: 6px; font-weight: 600; font-size: 13px; margin: 16px 0; }
        .status-passive { background: #f0fdf4; color: #166534; border: 1px solid #bbf7d0; }
        .btn-primary { width: 100%; padding: 12px; background: #0f172a; color: white; border: none; border-radius: 6px; font-weight: 600; font-size: 15px; cursor: pointer; transition: background 0.2s; }
        .btn-primary:hover { background: #1e293b; }
        .btn-primary:disabled { background: #94a3b8; cursor: not-allowed; }
        .toggle-preview { display: flex; align-items: center; gap: 8px; padding: 12px; background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 6px; margin-bottom: 16px; font-size: 13px; }
      `}</style>

      <div className="page-header">
        <p className="page-label">SCANNER / CONFIGURATION</p>
        <h1 className="page-title">New Security Scan</h1>
        <p className="page-description">Configure an authorized web-security assessment.</p>
      </div>

      <form onSubmit={submit} className="grid-layout">
        <div className="card">
          {error && <div className="error-box">⚠ {error}</div>}

          <Section title="Target Configuration" desc="Define the primary endpoint for this security scan.">
            <div className="form-group">
              <label className="form-label">Target URL</label>
              <input 
                className="form-input" required disabled={loading} 
                value={form.target_url} onChange={(e) => set('target_url', e.target.value)} 
                placeholder="https://example.com" 
              />
            </div>
            {targetState && (
              <p style={{ fontSize: '13px', marginTop: '-10px', color: targetState.valid ? '#166534' : '#b91c1c' }}>
                {targetState.msg}
              </p>
            )}
            <div className="notice">
              <strong>Authorization Required:</strong> This scanner is strictly intended for targets you are legally authorized to test.
            </div>
          </Section>

          <Section title="Scan Profile" desc="Select a pre-configured baseline for the scanner.">
            <select className="form-select" value={form.scan_type} disabled={loading} onChange={(e) => chooseProfile(e.target.value)}>
              {Object.entries(profiles).map(([key, value]) => (
                <option key={key} value={key}>{value.label} - {value.description}</option>
              ))}
            </select>
          </Section>

          <Section title="Target Scope" desc="Control how the crawler navigates the target structure.">
            <div className="radio-group">
              <label className="radio-label">
                <input type="radio" name="scope" checked={true} readOnly /> 
                Single URL only
              </label>
              <label className="radio-label disabled" title="Domain scanning is currently disabled pending backend support.">
                <input type="radio" name="scope" disabled /> 
                Entire domain (Coming Soon)
              </label>
            </div>
            <p className="section-desc" style={{ marginTop: '8px', color: '#64748b' }}>
              Note: The crawler will spider the site within the specified depth limit, but will strictly remain within the origin URL's path boundary.
            </p>
            
            <div className="form-group" style={{ marginTop: '12px' }}>
              <label className="form-label">Excluded Paths</label>
              <div className="flex-row">
                <input 
                  className="form-input" value={exclusion} 
                  onChange={(e) => setExclusion(e.target.value)} 
                  placeholder="e.g., /logout, /admin/*" 
                  disabled={loading}
                />
                <button type="button" className="btn-secondary" disabled={loading} onClick={() => { 
                  if (exclusion.trim() && !form.excluded_paths.includes(exclusion.trim())) { 
                    set('excluded_paths', [...form.excluded_paths, exclusion.trim()]); 
                    setExclusion(''); 
                  } 
                }}>Add</button>
              </div>
              <div>
                {form.excluded_paths.map((item) => (
                  <span className="tag" key={item}>
                    {item} <button type="button" disabled={loading} onClick={() => set('excluded_paths', form.excluded_paths.filter((value) => value !== item))}>×</button>
                  </span>
                ))}
              </div>
            </div>
          </Section>

          <Section title="Authentication" desc="Authentication configuration.">
            <select className="form-select" value="none" disabled>
              <option value="none">No Authentication (Passive Phase 1 limit)</option>
            </select>
            <p className="section-desc" style={{ marginTop: '8px', color: '#854d0e' }}>
              Authenticated scanning is currently disabled at the backend layer. All scans will proceed unauthenticated.
            </p>
          </Section>

          <Section title="Crawler Settings" desc="Configure structural limits to prevent infinite loops and manage load.">
            <div className="grid-2">
              <div className="form-group">
                <label className="form-label">Maximum Crawl Depth</label>
                <input className="form-input" type="number" min="1" max="10" value={form.crawl_depth} disabled={loading} onChange={(e) => set('crawl_depth', Number(e.target.value))} />
              </div>
              <div className="form-group">
                <label className="form-label">Maximum Pages</label>
                <input className="form-input" type="number" min="1" max="500" value={form.max_pages} disabled={loading} onChange={(e) => set('max_pages', Number(e.target.value))} />
              </div>
              <div className="form-group">
                <label className="form-label">Request Delay (ms)</label>
                <input className="form-input" type="number" min="100" max="10000" step="50" value={form.request_delay_ms} disabled={loading} onChange={(e) => set('request_delay_ms', Number(e.target.value))} />
              </div>
            </div>
            <div className="flex-row" style={{ marginTop: '12px', gap: '24px' }}>
              <label className="checkbox-label">
                <input type="checkbox" checked={form.follow_redirects} disabled={loading} onChange={(e) => set('follow_redirects', e.target.checked)} /> 
                Follow redirects
              </label>
            </div>
          </Section>

          <Section title="Security Checks" desc="Select specific vulnerability classes to evaluate.">
            <div className="checkbox-grid">
              {checks.map((check) => (
                <label className="checkbox-label" key={check}>
                  <input type="checkbox" disabled={loading} checked={form.security_checks.includes(check)} onChange={() => toggleCheck(check)} /> 
                  {labelFormat(check)}
                </label>
              ))}
            </div>
          </Section>

          <div style={{ marginTop: '24px' }}>
            <button type="button" className="btn-text" onClick={() => setAdvanced(!advanced)}>
              {advanced ? '− Hide Advanced Options' : '+ Show Advanced Options'}
            </button>
          </div>

          {advanced && (
            <div style={{ marginTop: '20px', padding: '20px', background: '#f8fafc', borderRadius: '8px' }}>
              <div className="grid-2">
                <div className="form-group">
                  <label className="form-label">Request Timeout (sec)</label>
                  <input className="form-input" type="number" min="1" max="60" value={form.request_timeout_seconds} disabled={loading} onChange={(e) => set('request_timeout_seconds', Number(e.target.value))} />
                </div>
                <div className="form-group">
                  <label className="form-label">Max Concurrent Requests</label>
                  <input className="form-input" type="number" value="1" disabled title="Currently locked to sequential requests." />
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Custom User-Agent</label>
                <input className="form-input" placeholder="Mozilla/5.0..." value={form.user_agent} disabled={loading} onChange={(e) => set('user_agent', e.target.value)} />
              </div>
              <div className="form-group">
                <label className="form-label">Custom Headers</label>
                <div className="flex-row">
                  <input className="form-input" placeholder="Header Key (e.g. X-Origin)" disabled={loading} value={headerKey} onChange={(e) => setHeaderKey(e.target.value)} />
                  <input className="form-input" placeholder="Value" value={headerValue} disabled={loading} onChange={(e) => setHeaderValue(e.target.value)} />
                  <button type="button" className="btn-secondary" disabled={loading} onClick={addHeader}>Add</button>
                </div>
                {Object.entries(form.custom_headers).length > 0 && (
                  <div style={{ marginTop: '12px' }}>
                    {Object.entries(form.custom_headers).map(([k, v]) => (
                      <span className="tag" key={k}>
                        {k}: {v} <button type="button" disabled={loading} onClick={() => removeHeader(k)}>×</button>
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        <aside className="card summary-panel">
          <h3 className="section-title" style={{ marginBottom: '16px' }}>Live Summary</h3>
          
          <div className="summary-row"><span>Target</span> <b>{form.target_url || 'Not specified'}</b></div>
          <div className="summary-row"><span>Profile</span> <b>{profiles[form.scan_type].label}</b></div>
          <div className="summary-row"><span>Scope</span> <b>Single URL boundary</b></div>
          <div className="summary-row"><span>Auth Method</span> <b>None</b></div>
          <div className="summary-row"><span>Max Pages / Depth</span> <b>{form.max_pages} / {form.crawl_depth}</b></div>
          <div className="summary-row"><span>Active Checks</span> <b>{form.security_checks.length} selected</b></div>
          <div className="summary-row"><span>Concurrency</span> <b>1 thread</b></div>
          <div className="summary-row">
            <span>Estimated Workload</span> 
            <b>{Math.max(1, Math.ceil(form.max_pages / 100))}–{Math.max(2, Math.ceil(form.max_pages / 40))} mins</b>
          </div>

          <div className="status-badge status-passive">
            ✓ Passive / Non-invasive configuration
          </div>

          <label className="toggle-preview">
            <input type="checkbox" checked={previewMode} disabled={loading} onChange={(e) => setPreviewMode(e.target.checked)} />
            <b>Dev Mode:</b> Preview Config Only (Skip API)
          </label>

          <button 
            disabled={loading || !targetState?.valid || form.security_checks.length === 0} 
            className="btn-primary" 
            type="submit"
          >
            {loading ? 'Queueing Security Scan...' : previewMode ? 'Preview Configuration' : 'Start Security Scan'}
          </button>
        </aside>
      </form>
    </div>
  );
}