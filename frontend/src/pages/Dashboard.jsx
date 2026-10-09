import React, { useEffect, useState, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  PieChart, Pie, Cell, Tooltip as RechartsTooltip, ResponsiveContainer, Legend,
  BarChart, Bar, XAxis, YAxis, CartesianGrid
} from 'recharts';
import api, { apiError } from '../services/api';
import { useAuth } from '../hooks/useAuth';

const Dashboard = () => {
  const auth = useAuth ? useAuth() : {};
  const navigate = useNavigate();

  const [scans, setScans] = useState([]);
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const fetchDashboardData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [scansRes, findingsRes] = await Promise.allSettled([
        api.get('/scans'),
        api.get('/findings'),
      ]);

      if (scansRes.status === 'fulfilled') {
        const scanList = Array.isArray(scansRes.value.data)
          ? scansRes.value.data
          : scansRes.value.data?.items || [];
        setScans(scanList);
      }

      if (findingsRes.status === 'fulfilled') {
        const findingList = Array.isArray(findingsRes.value.data)
          ? findingsRes.value.data
          : findingsRes.value.data?.items || [];
        setFindings(findingList);
      }
    } catch (err) {
      setError(apiError(err, 'Unable to load dashboard telemetry.'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchDashboardData();
  }, [fetchDashboardData]);

  // Compute real severity counts
  const countBySeverity = (level) =>
    findings.filter((f) => (f.severity || '').toLowerCase() === level.toLowerCase()).length;

  const criticalCount = countBySeverity('critical');
  const highCount = countBySeverity('high');
  const mediumCount = countBySeverity('medium');
  const lowCount = countBySeverity('low');

  const severityChartData = [
    { name: 'Critical', value: criticalCount, color: '#dc2626' },
    { name: 'High', value: highCount, color: '#ea580c' },
    { name: 'Medium', value: mediumCount, color: '#eab308' },
    { name: 'Low', value: lowCount, color: '#16a34a' },
  ];

  const scanStatusChartData = [
    {
      name: 'Completed',
      count: scans.filter((s) => (s.status || '').toLowerCase() === 'completed').length,
    },
    {
      name: 'Running / Pending',
      count: scans.filter((s) =>
        ['running', 'pending', 'in_progress', 'queued'].includes((s.status || '').toLowerCase())
      ).length,
    },
    {
      name: 'Failed',
      count: scans.filter((s) => (s.status || '').toLowerCase() === 'failed').length,
    },
  ];

  return (
    <div style={{ maxWidth: '100%', overflowX: 'hidden' }}>
      {/* 1. Header & Welcome */}
      <div
        className="page-header"
        style={{
          marginBottom: '24px',
          display: 'flex',
          flexWrap: 'wrap',
          gap: '16px',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <div>
          <p className="page-label">WORKSPACE / OVERVIEW</p>
          <h1 style={{ margin: '0 0 6px 0' }}>
            Welcome{auth?.user?.full_name ? `, ${auth.user.full_name}` : ''}
          </h1>
          <p className="page-description">
            Real-time overview of your authorized web application security scans and classified findings.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button
            onClick={fetchDashboardData}
            disabled={loading}
            style={{
              padding: '10px 16px',
              borderRadius: '8px',
              backgroundColor: '#ffffff',
              color: '#09090b',
              border: '1px solid #d4d4d8',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            {loading ? 'Refreshing...' : '↻ Refresh'}
          </button>
          <button
            onClick={() => navigate('/new-scan')}
            style={{
              padding: '10px 18px',
              borderRadius: '8px',
              backgroundColor: '#09090b',
              color: '#ffffff',
              border: '1px solid #09090b',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            + Start New Scan
          </button>
        </div>
      </div>

      {error && (
        <div style={{ padding: '12px 16px', backgroundColor: '#fef2f2', border: '1px solid #fecaca', color: '#991b1b', borderRadius: '8px', marginBottom: '20px', fontSize: '14px' }}>
          ⚠ {error}
        </div>
      )}

      {/* 2. KPI Cards */}
      <section
        className="stats-grid"
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '18px',
          marginBottom: '24px',
        }}
      >
        <div className="stat-card" style={{ borderTop: '3px solid #09090b' }}>
          <p>Total Scans</p>
          <h2>{scans.length}</h2>
          <span>Recorded in database</span>
        </div>
        <div className="stat-card" style={{ borderTop: '3px solid #3f3f46' }}>
          <p>Total Vulnerabilities</p>
          <h2>{findings.length}</h2>
          <span>Classified findings</span>
        </div>
        <div className="stat-card" style={{ borderTop: '3px solid #dc2626' }}>
          <p>Critical & High Risk</p>
          <h2 style={{ color: '#dc2626' }}>{criticalCount + highCount}</h2>
          <span>Priority remediation</span>
        </div>
        <div className="stat-card" style={{ borderTop: '3px solid #16a34a' }}>
          <p>Completed Scans</p>
          <h2 style={{ color: '#16a34a' }}>
            {scans.filter((s) => (s.status || '').toLowerCase() === 'completed').length}
          </h2>
          <span>Ready for reporting</span>
        </div>
      </section>

      {/* 3. Charts */}
      <section style={{ display: 'flex', flexWrap: 'wrap', gap: '20px', marginBottom: '24px' }}>
        {/* Vulnerability Severity Chart */}
        <div className="dashboard-card" style={{ flex: '1 1 340px', minWidth: 0 }}>
          <div className="card-header">
            <div>
              <h3>Vulnerability Severity Distribution</h3>
              <p>Breakdown of findings from backend database</p>
            </div>
          </div>
          {findings.length > 0 ? (
            <div style={{ height: '260px', width: '100%' }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={severityChartData}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={85}
                    paddingAngle={4}
                    dataKey="value"
                  >
                    {severityChartData.map((entry, idx) => (
                      <Cell key={`cell-${idx}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip />
                  <Legend verticalAlign="bottom" height={32} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div style={emptyChartStyle}>
              No vulnerabilities recorded yet. Run an authorized scan to populate severity metrics.
            </div>
          )}
        </div>

        {/* Scan Status Distribution Chart */}
        <div className="dashboard-card" style={{ flex: '1 1 400px', minWidth: 0 }}>
          <div className="card-header">
            <div>
              <h3>Scan Execution Overview</h3>
              <p>Status distribution of recorded security scans</p>
            </div>
          </div>
          {scans.length > 0 ? (
            <div style={{ height: '260px', width: '100%' }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={scanStatusChartData} margin={{ top: 16, right: 16, left: -16, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e4e4e7" />
                  <XAxis dataKey="name" tick={{ fontSize: 12, fill: '#52525b' }} />
                  <YAxis allowDecimals={false} tick={{ fontSize: 12, fill: '#52525b' }} />
                  <RechartsTooltip />
                  <Bar dataKey="count" name="Scans" fill="#09090b" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div style={emptyChartStyle}>
              No scan history found. Click &ldquo;Start New Scan&rdquo; to launch your first assessment.
            </div>
          )}
        </div>
      </section>

      {/* 4. Recent Scans Table */}
      <section className="dashboard-card findings-card" style={{ marginBottom: '24px' }}>
        <div className="card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h3>Recent Scan Activity</h3>
            <p>Latest security assessments executed in your workspace</p>
          </div>
          <Link to="/scan-history" style={{ fontSize: '13px', fontWeight: 600, color: '#09090b' }}>
            View All Scans →
          </Link>
        </div>

        {scans.length > 0 ? (
          <div className="table-placeholder" style={{ overflowX: 'auto' }}>
            <div style={{ minWidth: '650px' }}>
              <div className="table-row table-header" style={{ gridTemplateColumns: '1fr 2.5fr 1.5fr 1fr 1.5fr 1fr' }}>
                <span>Scan ID</span>
                <span>Target URL</span>
                <span>Scan Type</span>
                <span>Status</span>
                <span>Created</span>
                <span>Action</span>
              </div>
              {scans.slice(0, 5).map((scan) => (
                <div
                  className="table-row"
                  key={scan.id}
                  style={{ gridTemplateColumns: '1fr 2.5fr 1.5fr 1fr 1.5fr 1fr', alignItems: 'center' }}
                >
                  <span style={{ fontFamily: 'monospace', fontSize: '12px', color: '#52525b' }}>
                    {String(scan.id).slice(0, 8)}
                  </span>
                  <span style={{ fontWeight: 600, color: '#09090b', wordBreak: 'break-all' }}>
                    {scan.target_url || scan.target}
                  </span>
                  <span style={{ fontSize: '13px', color: '#3f3f46' }}>
                    {scan.scan_type || 'Web Application Scan'}
                  </span>
                  <span style={{ fontSize: '12px', fontWeight: 600, textTransform: 'capitalize' }}>
                    {scan.status || 'completed'}
                  </span>
                  <span style={{ fontSize: '12px', color: '#71717a' }}>
                    {scan.created_at ? new Date(scan.created_at).toLocaleDateString() : '—'}
                  </span>
                  <span>
                    <Link
                      to={`/scan/${scan.id}`}
                      style={{
                        padding: '5px 10px',
                        borderRadius: '6px',
                        border: '1px solid #d4d4d8',
                        fontSize: '12px',
                        fontWeight: 600,
                        color: '#09090b',
                        textDecoration: 'none',
                      }}
                    >
                      Details
                    </Link>
                  </span>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div style={{ padding: '28px', textAlign: 'center', color: '#71717a', fontSize: '14px' }}>
            No scans recorded yet.{' '}
            <Link to="/new-scan" style={{ color: '#09090b', fontWeight: 600 }}>
              Launch your first scan →
            </Link>
          </div>
        )}
      </section>

      {/* 5. Recent Findings Table */}
      <section className="dashboard-card findings-card">
        <div className="card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h3>Recent Security Findings</h3>
            <p>Latest vulnerabilities recorded in PostgreSQL</p>
          </div>
          <Link to="/vulnerabilities" style={{ fontSize: '13px', fontWeight: 600, color: '#09090b' }}>
            View All Findings →
          </Link>
        </div>

        {findings.length > 0 ? (
          <div className="table-placeholder" style={{ overflowX: 'auto' }}>
            <div style={{ minWidth: '650px' }}>
              <div className="table-row table-header" style={{ gridTemplateColumns: '2fr 1.5fr 1fr 1fr 1.5fr' }}>
                <span>Vulnerability</span>
                <span>Category / CWE</span>
                <span>Severity</span>
                <span>Status</span>
                <span>Detected</span>
              </div>
              {findings.slice(0, 5).map((f) => (
                <div
                  className="table-row"
                  key={f.id}
                  style={{ gridTemplateColumns: '2fr 1.5fr 1fr 1fr 1.5fr', alignItems: 'center' }}
                >
                  <span style={{ fontWeight: 600, color: '#09090b' }}>{f.title || f.name}</span>
                  <span style={{ fontSize: '13px', color: '#52525b' }}>
                    {f.vulnerability_type || 'Web Vulnerability'}
                    {f.cwe_id ? ` (${f.cwe_id})` : ''}
                  </span>
                  <span style={{ fontWeight: 700, textTransform: 'capitalize' }}>{f.severity}</span>
                  <span style={{ fontSize: '12px', textTransform: 'capitalize' }}>{f.status || 'open'}</span>
                  <span style={{ fontSize: '12px', color: '#71717a' }}>
                    {f.detected_at ? new Date(f.detected_at).toLocaleDateString() : '—'}
                  </span>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div style={{ padding: '28px', textAlign: 'center', color: '#71717a', fontSize: '14px' }}>
            No vulnerability findings in the database yet.
          </div>
        )}
      </section>
    </div>
  );
};

const emptyChartStyle = {
  height: '220px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  textAlign: 'center',
  padding: '20px',
  color: '#71717a',
  fontSize: '13.5px',
  backgroundColor: '#fafafa',
  borderRadius: '8px',
  border: '1px dashed #d4d4d8',
};

export default Dashboard;