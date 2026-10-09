import React, { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  PieChart, Pie, Cell, Tooltip as RechartsTooltip, ResponsiveContainer, Legend
} from 'recharts';
import api, { apiError } from '../services/api';

const Reports = () => {
  const navigate = useNavigate();
  const [scans, setScans] = useState([]);
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadReportData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [scansRes, findingsRes] = await Promise.allSettled([
        api.get('/scans'),
        api.get('/findings'),
      ]);
      if (scansRes.status === 'fulfilled') {
        setScans(Array.isArray(scansRes.value.data) ? scansRes.value.data : scansRes.value.data?.items || []);
      }
      if (findingsRes.status === 'fulfilled') {
        setFindings(Array.isArray(findingsRes.value.data) ? findingsRes.value.data : findingsRes.value.data?.items || []);
      }
    } catch (err) {
      setError(apiError(err, 'Unable to load report data.'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadReportData();
  }, [loadReportData]);

  const countSev = (s) => findings.filter((f) => (f.severity || '').toLowerCase() === s).length;

  const severityData = [
    { name: 'Critical', value: countSev('critical'), color: '#dc2626', action: 'Immediate Remediation' },
    { name: 'High', value: countSev('high'), color: '#ea580c', action: 'High Priority' },
    { name: 'Medium', value: countSev('medium'), color: '#eab308', action: 'Scheduled Review' },
    { name: 'Low', value: countSev('low'), color: '#16a34a', action: 'Best Practice Hardening' },
  ];

  // Export findings & scan summary to CSV
  const handleExportCSV = () => {
    const headers = ['ID', 'Title', 'Category', 'Severity', 'CVSS', 'Status', 'Detected_At'];
    const rows = findings.map((f) => [
      f.id,
      `"${(f.title || f.name || '').replace(/"/g, '""')}"`,
      `"${(f.vulnerability_type || '').replace(/"/g, '""')}"`,
      f.severity || '',
      f.cvss_score ?? '',
      f.status || 'open',
      f.detected_at || '',
    ]);
    const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `ai-websectest-report-${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div style={{ maxWidth: '100%', overflowX: 'hidden' }}>
      {/* Header */}
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
          <p className="page-label">SECURITY / REPORTS</p>
          <h1 style={{ margin: '0 0 6px 0' }}>Security Assessment Reports</h1>
          <p className="page-description">
            Consolidated risk summaries, scan statistics, and exportable vulnerability reports.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
          <button
            onClick={() => navigate('/scan-history')}
            style={secondaryBtnStyle}
          >
            Scan History
          </button>
          <button
            onClick={handleExportCSV}
            disabled={findings.length === 0}
            style={secondaryBtnStyle}
          >
            ↓ Export CSV
          </button>
          <button
            onClick={() => window.print()}
            style={primaryBtnStyle}
          >
            🖨 Print / Save PDF
          </button>
        </div>
      </div>

      {error && (
        <div style={{ padding: '12px 16px', backgroundColor: '#fef2f2', border: '1px solid #fecaca', color: '#991b1b', borderRadius: '8px', marginBottom: '20px', fontSize: '14px' }}>
          ⚠ {error}
        </div>
      )}

      {/* KPI Row */}
      <section
        className="stats-grid"
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))',
          gap: '16px',
          marginBottom: '24px',
        }}
      >
        <div className="stat-card" style={{ borderTop: '3px solid #09090b' }}>
          <p>Total Scans</p>
          <h2>{scans.length}</h2>
        </div>
        <div className="stat-card" style={{ borderTop: '3px solid #3f3f46' }}>
          <p>Total Findings</p>
          <h2>{findings.length}</h2>
        </div>
        <div className="stat-card" style={{ borderTop: '3px solid #dc2626' }}>
          <p>Critical</p>
          <h2 style={{ color: '#dc2626' }}>{severityData[0].value}</h2>
        </div>
        <div className="stat-card" style={{ borderTop: '3px solid #ea580c' }}>
          <p>High</p>
          <h2 style={{ color: '#ea580c' }}>{severityData[1].value}</h2>
        </div>
        <div className="stat-card" style={{ borderTop: '3px solid #eab308' }}>
          <p>Medium & Low</p>
          <h2>{severityData[2].value + severityData[3].value}</h2>
        </div>
      </section>

      {/* Middle Grid */}
      <section style={{ display: 'flex', flexWrap: 'wrap', gap: '20px', marginBottom: '24px' }}>
        <div className="dashboard-card" style={{ flex: '1 1 360px', minWidth: 0 }}>
          <div className="card-header">
            <div>
              <h3>Risk Prioritization Summary</h3>
              <p>Counts by severity level</p>
            </div>
          </div>
          <div style={{ width: '100%', overflowX: 'auto' }}>
            <div className="table-row table-header" style={{ gridTemplateColumns: '1fr 1fr 2fr', padding: '10px', backgroundColor: '#fafafa' }}>
              <span>Severity</span>
              <span>Count</span>
              <span>Recommended Action</span>
            </div>
            {severityData.map((item, idx) => (
              <div className="table-row" key={idx} style={{ gridTemplateColumns: '1fr 1fr 2fr', padding: '10px' }}>
                <span style={{ fontWeight: 700, color: item.color }}>{item.name}</span>
                <span style={{ fontWeight: 600 }}>{item.value}</span>
                <span style={{ color: '#52525b', fontSize: '13px' }}>{item.action}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="dashboard-card" style={{ flex: '1 1 320px', minWidth: 0 }}>
          <div className="card-header">
            <div>
              <h3>Severity Distribution</h3>
              <p>Visual proportion of recorded findings</p>
            </div>
          </div>
          {findings.length > 0 ? (
            <div style={{ height: '250px', width: '100%' }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={severityData} cx="50%" cy="50%" innerRadius={55} outerRadius={85} paddingAngle={4} dataKey="value">
                    {severityData.map((entry, idx) => (
                      <Cell key={`cell-${idx}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip />
                  <Legend verticalAlign="bottom" height={32} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          ) : (
            <div style={{ height: '220px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#71717a', fontSize: '13.5px' }}>
              No findings available to chart.
            </div>
          )}
        </div>
      </section>

      {/* Scan Reports List */}
      <section className="dashboard-card findings-card">
        <div className="card-header">
          <div>
            <h3>Scan Assessment Reports ({scans.length})</h3>
            <p>Select any scan below to view its full assessment report.</p>
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '32px', textAlign: 'center', color: '#52525b' }}>Loading reports...</div>
        ) : scans.length > 0 ? (
          <div className="table-placeholder" style={{ overflowX: 'auto' }}>
            <div style={{ minWidth: '650px' }}>
              <div className="table-row table-header" style={{ gridTemplateColumns: '1fr 2.5fr 1.5fr 1fr 1.5fr 1fr' }}>
                <span>Report ID</span>
                <span>Target URL</span>
                <span>Scan Type</span>
                <span>Status</span>
                <span>Scan Date</span>
                <span>Action</span>
              </div>
              {scans.map((scan) => (
                <div className="table-row" key={scan.id} style={{ gridTemplateColumns: '1fr 2.5fr 1.5fr 1fr 1.5fr 1fr', alignItems: 'center' }}>
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
                    <button
                      onClick={() => navigate(`/scan/${scan.id}`)}
                      style={{
                        padding: '6px 12px',
                        borderRadius: '6px',
                        backgroundColor: '#09090b',
                        color: '#ffffff',
                        border: 'none',
                        fontSize: '12px',
                        fontWeight: 600,
                        cursor: 'pointer',
                      }}
                    >
                      Open Report
                    </button>
                  </span>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div style={{ padding: '32px', textAlign: 'center', color: '#71717a', fontSize: '14px' }}>
            No scan reports available yet. Run a security scan to generate an assessment report.
          </div>
        )}
      </section>
    </div>
  );
};

const primaryBtnStyle = {
  padding: '10px 16px',
  borderRadius: '8px',
  backgroundColor: '#09090b',
  color: '#ffffff',
  border: '1px solid #09090b',
  fontSize: '13px',
  fontWeight: 600,
  cursor: 'pointer',
};

const secondaryBtnStyle = {
  padding: '10px 16px',
  borderRadius: '8px',
  backgroundColor: '#ffffff',
  color: '#09090b',
  border: '1px solid #d4d4d8',
  fontSize: '13px',
  fontWeight: 600,
  cursor: 'pointer',
};

export default Reports;