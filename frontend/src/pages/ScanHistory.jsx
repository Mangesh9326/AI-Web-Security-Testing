import React, { useEffect, useState, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api, { apiError } from '../services/api';

const ScanHistory = () => {
  const navigate = useNavigate();
  const [scans, setScans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');

  const loadScans = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/scans');
      const list = Array.isArray(response.data) ? response.data : response.data?.items || [];
      setScans(list);
    } catch (err) {
      setError(apiError(err, 'Unable to load scan history from backend.'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadScans();
  }, [loadScans]);

  const filteredScans = scans.filter((scan) => {
    const target = (scan.target_url || scan.target || '').toLowerCase();
    const idStr = String(scan.id || '').toLowerCase();
    const matchesSearch =
      target.includes(searchTerm.toLowerCase()) || idStr.includes(searchTerm.toLowerCase());
    const matchesStatus =
      statusFilter === 'All' || (scan.status || '').toLowerCase() === statusFilter.toLowerCase();
    return matchesSearch && matchesStatus;
  });

  const getStatusBadge = (status) => {
    const s = (status || 'completed').toLowerCase();
    const map = {
      completed: { bg: '#f0fdf4', text: '#166534', border: '#bbf7d0' },
      running: { bg: '#eff6ff', text: '#1d4ed8', border: '#bfdbfe' },
      pending: { bg: '#fefce8', text: '#854d0e', border: '#fef08a' },
      failed: { bg: '#fef2f2', text: '#991b1b', border: '#fecaca' },
    };
    const style = map[s] || { bg: '#f4f4f5', text: '#3f3f46', border: '#e4e4e7' };
    return (
      <span
        style={{
          backgroundColor: style.bg,
          color: style.text,
          border: `1px solid ${style.border}`,
          padding: '4px 10px',
          borderRadius: '9999px',
          fontSize: '12px',
          fontWeight: 600,
          textTransform: 'capitalize',
        }}
      >
        {status || 'completed'}
      </span>
    );
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
          <p className="page-label">SECURITY / SCAN HISTORY</p>
          <h1 style={{ margin: '0 0 6px 0' }}>Scan History</h1>
          <p className="page-description">
            Review previous web application security assessments and inspect detailed scan reports.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={loadScans}
            style={{
              padding: '10px 14px',
              borderRadius: '8px',
              backgroundColor: '#ffffff',
              color: '#09090b',
              border: '1px solid #d4d4d8',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            ↻ Refresh
          </button>
          <button
            onClick={() => navigate('/new-scan')}
            style={{
              padding: '10px 16px',
              borderRadius: '8px',
              backgroundColor: '#09090b',
              color: '#ffffff',
              border: 'none',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            + New Scan
          </button>
        </div>
      </div>

      {/* Search & Filter Controls */}
      <section className="dashboard-card" style={{ marginBottom: '24px', padding: '16px' }}>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '16px', alignItems: 'center' }}>
          <div style={{ flex: '1 1 240px' }}>
            <input
              type="text"
              placeholder="Search by target URL or Scan ID..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{
                width: '100%',
                padding: '10px 14px',
                fontSize: '14px',
                borderRadius: '8px',
                border: '1px solid #d4d4d8',
                outline: 'none',
              }}
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            style={{
              padding: '10px 14px',
              fontSize: '14px',
              borderRadius: '8px',
              border: '1px solid #d4d4d8',
              backgroundColor: '#ffffff',
              cursor: 'pointer',
            }}
          >
            <option value="All">All Statuses</option>
            <option value="completed">Completed</option>
            <option value="running">Running</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
          </select>
        </div>
      </section>

      {error && (
        <div style={{ padding: '12px 16px', backgroundColor: '#fef2f2', border: '1px solid #fecaca', color: '#991b1b', borderRadius: '8px', marginBottom: '20px', fontSize: '14px' }}>
          ⚠ {error}
        </div>
      )}

      {/* Table */}
      <section className="dashboard-card findings-card">
        <div className="card-header">
          <div>
            <h3>Recorded Scans ({filteredScans.length})</h3>
            <p>Click &ldquo;View Details&rdquo; to inspect scan configuration and discovered vulnerabilities.</p>
          </div>
        </div>

        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#52525b' }}>
            Loading scan history...
          </div>
        ) : filteredScans.length > 0 ? (
          <div className="table-placeholder" style={{ overflowX: 'auto' }}>
            <div style={{ minWidth: '750px' }}>
              <div
                className="table-row table-header"
                style={{ gridTemplateColumns: '1fr 2.5fr 1.5fr 1fr 1fr 1.5fr 1fr' }}
              >
                <span>Scan ID</span>
                <span>Target URL</span>
                <span>Scan Type</span>
                <span>Status</span>
                <span>Findings</span>
                <span>Date & Time</span>
                <span>Action</span>
              </div>

              {filteredScans.map((scan) => (
                <div
                  className="table-row"
                  key={scan.id}
                  style={{
                    gridTemplateColumns: '1fr 2.5fr 1.5fr 1fr 1fr 1.5fr 1fr',
                    alignItems: 'center',
                  }}
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
                  <span>{getStatusBadge(scan.status)}</span>
                  <span style={{ fontWeight: 600 }}>
                    {scan.findings_count ?? scan.vulnerability_count ?? '—'}
                  </span>
                  <span style={{ fontSize: '12px', color: '#52525b' }}>
                    {scan.created_at ? new Date(scan.created_at).toLocaleString() : '—'}
                  </span>
                  <span>
                    <Link
                      to={`/scan/${scan.id}`}
                      style={{
                        padding: '6px 12px',
                        borderRadius: '6px',
                        backgroundColor: '#09090b',
                        color: '#ffffff',
                        fontSize: '12px',
                        fontWeight: 600,
                        textDecoration: 'none',
                        display: 'inline-block',
                      }}
                    >
                      View Details
                    </Link>
                  </span>
                </div>
              ))}
            </div>
          </div>
        ) : (
          <div style={{ padding: '40px 20px', textAlign: 'center', color: '#71717a', fontSize: '14px' }}>
            No scans match your current filters.
          </div>
        )}
      </section>
    </div>
  );
};

export default ScanHistory;