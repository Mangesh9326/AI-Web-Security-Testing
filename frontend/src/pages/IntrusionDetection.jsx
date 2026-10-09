import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip as RechartsTooltip
} from 'recharts';
import {
  getTrafficLogs, getAlerts, updateAlertStatus, getIntrusionMetrics,
  getAlertNotes, addAlertNote, getAlertHistory, updateAlertAssignment, getInvestigators
} from '../services/intrusionService';
import { apiError } from '../services/api';

const VALID_TRANSITIONS = {
  new: ['investigating', 'false_positive'],
  investigating: ['confirmed', 'false_positive', 'resolved'],
  confirmed: ['resolved', 'investigating'],
  false_positive: ['investigating'],
  resolved: ['investigating']
};

const IntrusionDetection = () => {
  const [activeTab, setActiveTab] = useState('alerts');
  const [alerts, setAlerts] = useState([]);
  const [logs, setLogs] = useState([]);
  const [metrics, setMetrics] = useState(null);
  const [investigators, setInvestigators] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [lastRefreshed, setLastRefreshed] = useState(null);

  // Filters
  const [websiteFilter, setWebsiteFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedAlertId, setExpandedAlertId] = useState(null);

  // Inspection Drawer State
  const [drawerTab, setDrawerTab] = useState('notes');
  const [notes, setNotes] = useState([]);
  const [history, setHistory] = useState([]);
  const [newNoteText, setNewNoteText] = useState('');
  const [submittingNote, setSubmittingNote] = useState(false);
  const [statusReason, setStatusReason] = useState('');

  // Prevent polling overlaps
  const pollingRef = useRef(null);

  const fetchData = useCallback(async (isRefresh = false, isBackgroundPoll = false) => {
    if (!isBackgroundPoll) {
      if (isRefresh) setRefreshing(true);
      else setLoading(true);
    }
    setError('');

    try {
      const [alertsRes, trafficRes, metricsRes, invRes] = await Promise.all([
        getAlerts({ limit: 500 }), // Get broader set for client-side filtering
        getTrafficLogs({ limit: 500 }),
        getIntrusionMetrics(),
        getInvestigators()
      ]);

      setAlerts(alertsRes?.alerts || []);
      setLogs(trafficRes?.logs || []);
      setMetrics(metricsRes?.metrics || null);
      setInvestigators(invRes?.investigators || []);
      setLastRefreshed(new Date());
    } catch (err) {
      if (!isBackgroundPoll) setError(apiError(err, 'Failed to fetch intrusion detection data from server.'));
    } finally {
      if (!isBackgroundPoll) {
        setLoading(false);
        setRefreshing(false);
      }
    }
  }, []);

  // Initial Fetch & Live Polling Hook
  useEffect(() => {
    fetchData();

    pollingRef.current = setInterval(() => {
      fetchData(false, true);
    }, 10000); // Live poll every 10 seconds

    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current);
    };
  }, [fetchData]);

  const loadAlertDetails = async (alertId) => {
    if (expandedAlertId === alertId) {
      setExpandedAlertId(null);
      return;
    }
    setExpandedAlertId(alertId);
    setStatusReason('');
    try {
      const [notesRes, historyRes] = await Promise.all([
        getAlertNotes(alertId),
        getAlertHistory(alertId)
      ]);
      setNotes(notesRes?.notes || []);
      setHistory(historyRes?.history || []);
    } catch (err) {
      console.error('Failed to load alert details:', err);
    }
  };

  const handleStatusChange = async (alertId, nextStatus) => {
    try {
      await updateAlertStatus(alertId, nextStatus, statusReason.trim() || null);
      setStatusReason('');
      fetchData(true);
      const [notesRes, historyRes] = await Promise.all([
        getAlertNotes(alertId),
        getAlertHistory(alertId)
      ]);
      setNotes(notesRes?.notes || []);
      setHistory(historyRes?.history || []);
    } catch (err) {
      alert(apiError(err, 'Failed to update alert status.'));
    }
  };

  const handleAssigneeChange = async (alertId, assignedTo) => {
    try {
      await updateAlertAssignment(alertId, assignedTo === '' ? null : assignedTo);
      fetchData(true);
      const historyRes = await getAlertHistory(alertId);
      setHistory(historyRes?.history || []);
    } catch (err) {
      alert(apiError(err, 'Failed to reassign investigator.'));
    }
  };

  const handleAddNote = async (e, alertId) => {
    e.preventDefault();
    if (!newNoteText.trim()) return;

    setSubmittingNote(true);
    try {
      const res = await addAlertNote(alertId, newNoteText.trim());
      setNotes(prev => [...prev, res.note]);
      setNewNoteText('');
      const historyRes = await getAlertHistory(alertId);
      setHistory(historyRes?.history || []);
    } catch (err) {
      alert(apiError(err, 'Failed to post investigation note.'));
    } finally {
      setSubmittingNote(false);
    }
  };

  // --- Dynamic Filtering Logic ---

  // Extract unique websites from both logs and alerts
  const uniqueWebsites = useMemo(() => {
    const urls = [...alerts.map(a => a.target_url), ...logs.map(l => l.target_url)].filter(Boolean);
    return Array.from(new Set(urls)).sort();
  }, [alerts, logs]);

  // Base filtered list bounded to the selected website
  const websiteFilteredAlerts = useMemo(() => {
    return alerts.filter(a => websiteFilter === 'all' || a.target_url === websiteFilter);
  }, [alerts, websiteFilter]);

  // Deep filtered list applying search and sub-filters
  const filteredAlerts = useMemo(() => {
    return websiteFilteredAlerts.filter((a) => {
      const q = searchTerm.trim().toLowerCase();
      const matchesSearch = !q ||
        a.rule_id.toLowerCase().includes(q) ||
        a.classification.toLowerCase().includes(q) ||
        (a.source_ip && a.source_ip.toLowerCase().includes(q)) ||
        a.endpoint.toLowerCase().includes(q);
      
      const matchesSeverity = severityFilter === 'all' || a.severity === severityFilter;
      const matchesStatus = statusFilter === 'all' || a.status === statusFilter;

      return matchesSearch && matchesSeverity && matchesStatus;
    });
  }, [websiteFilteredAlerts, searchTerm, severityFilter, statusFilter]);

  const filteredLogs = useMemo(() => {
    return logs.filter(l => websiteFilter === 'all' || l.target_url === websiteFilter);
  }, [logs, websiteFilter]);

  // Aggregate Metrics depending on scope
  const stats = useMemo(() => {
    // If viewing all, use backend exact totals. If filtered, sum up the active view.
    if (websiteFilter === 'all' && metrics) {
      return {
        total: metrics.total_alerts,
        critical: metrics.critical_alerts,
        high: metrics.high_alerts,
        confirmed: metrics.confirmed_incidents
      };
    }
    return {
      total: websiteFilteredAlerts.length,
      critical: websiteFilteredAlerts.filter(a => a.severity === 'critical').length,
      high: websiteFilteredAlerts.filter(a => a.severity === 'high').length,
      confirmed: websiteFilteredAlerts.filter(a => a.status === 'confirmed').length
    };
  }, [metrics, websiteFilter, websiteFilteredAlerts]);

  // Chart: Alert Categories
  const categoryChartData = useMemo(() => {
    const counts = {};
    websiteFilteredAlerts.forEach((a) => {
      counts[a.classification] = (counts[a.classification] || 0) + (a.occurrence_count || 1);
    });
    const colors = ['#dc2626', '#ea580c', '#eab308', '#8b5cf6', '#3b82f6'];
    return Object.entries(counts).map(([name, value], idx) => ({
      name, value, color: colors[idx % colors.length]
    }));
  }, [websiteFilteredAlerts]);

  const getSeverityBadge = (severity) => {
    const map = {
      critical: { bg: '#fef2f2', text: '#dc2626', border: '#fecaca' },
      high: { bg: '#fff7ed', text: '#ea580c', border: '#fed7aa' },
      medium: { bg: '#fefce8', text: '#ca8a04', border: '#fef08a' },
      low: { bg: '#f0fdf4', text: '#16a34a', border: '#bbf7d0' },
      info: { bg: '#f8fafc', text: '#64748b', border: '#e2e8f0' }
    };
    const s = map[severity?.toLowerCase()] || map.info;
    return (
      <span style={{ backgroundColor: s.bg, color: s.text, border: `1px solid ${s.border}`, padding: '2px 8px', borderRadius: '4px', fontSize: '11px', fontWeight: 700, textTransform: 'uppercase' }}>
        {severity}
      </span>
    );
  };

  const getStatusBadge = (status) => {
    const map = {
      new: { bg: '#eff6ff', text: '#2563eb' },
      investigating: { bg: '#fefce8', text: '#ca8a04' },
      confirmed: { bg: '#fef2f2', text: '#dc2626' },
      resolved: { bg: '#f0fdf4', text: '#16a34a' },
      false_positive: { bg: '#f1f5f9', text: '#475569' }
    };
    const s = map[status] || { bg: '#f1f5f9', text: '#475569' };
    return (
      <span style={{ backgroundColor: s.bg, color: s.text, padding: '2px 8px', borderRadius: '4px', fontSize: '11px', fontWeight: 600, textTransform: 'capitalize' }}>
        {status.replace('_', ' ')}
      </span>
    );
  };

  return (
    <div style={{ maxWidth: '100%', overflowX: 'hidden' }}>
      {/* Header */}
      <div className="page-header" style={{ marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <p className="page-label">SECURITY / INCIDENT RESPONSE</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px', flexWrap: 'wrap' }}>
            <h1 style={{ margin: 0 }}>Incident Management & Triage</h1>
            <span style={{ backgroundColor: '#f0fdf4', color: '#166534', padding: '4px 10px', borderRadius: '9999px', fontSize: '12px', fontWeight: 'bold', border: '1px solid #bbf7d0' }}>
              Phase 5: Live Pipeline Linked
            </span>
          </div>
          <p className="page-description" style={{ marginBottom: '4px' }}>Investigate alerts, assign incident responders, collaborate with notes, and maintain an immutable audit trail.</p>
          {lastRefreshed && (
            <p style={{ fontSize: '12px', color: '#94a3b8', margin: 0, fontWeight: 500 }}>
              Live Polling Active — Last sync: {lastRefreshed.toLocaleTimeString()}
            </p>
          )}
        </div>
        <button
          onClick={() => fetchData(true)}
          disabled={loading || refreshing}
          style={{ padding: '8px 16px', backgroundColor: '#fff', border: '1px solid #d1d5db', borderRadius: '6px', cursor: 'pointer', fontWeight: 600 }}
        >
          {refreshing ? 'Refreshing...' : '↻ Refresh Data'}
        </button>
      </div>

      {error && (
        <div style={{ padding: '16px', backgroundColor: '#fef2f2', borderLeft: '4px solid #ef4444', color: '#b91c1c', borderRadius: '4px', marginBottom: '24px' }}>
          {error}
        </div>
      )}

      {/* Target Website Filter */}
      <div style={{ marginBottom: '24px', padding: '16px', backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', display: 'flex', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <label htmlFor="website-selector" style={{ fontSize: '14px', fontWeight: 600, color: '#374151' }}>
          Target Website:
        </label>
        <select
          id="website-selector"
          value={websiteFilter}
          onChange={(e) => setWebsiteFilter(e.target.value)}
          style={{ flex: 1, padding: '10px 14px', fontSize: '14px', borderRadius: '6px', border: '1px solid #d1d5db', outline: 'none', backgroundColor: '#f9fafb', fontFamily: 'monospace' }}
        >
          <option value="all" style={{ fontFamily: 'sans-serif', fontWeight: 600 }}>All Authorized Websites</option>
          {uniqueWebsites.map(url => <option key={url} value={url}>{url}</option>)}
        </select>
      </div>

      {/* Summary Cards */}
      <section className="stats-grid" style={{ marginBottom: '24px', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '16px' }}>
        <div className="stat-card" style={{ padding: '16px', backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', borderTop: '4px solid #111827' }}>
          <p style={{ margin: '0 0 6px 0', fontSize: '13px', color: '#6b7280' }}>Total Incidents</p>
          <h2 style={{ margin: 0, fontSize: '26px' }}>{stats.total}</h2>
        </div>
        <div className="stat-card" style={{ padding: '16px', backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', borderTop: '4px solid #dc2626' }}>
          <p style={{ margin: '0 0 6px 0', fontSize: '13px', color: '#6b7280' }}>Critical Threat Alerts</p>
          <h2 style={{ margin: 0, fontSize: '26px', color: '#dc2626' }}>{stats.critical}</h2>
        </div>
        <div className="stat-card" style={{ padding: '16px', backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', borderTop: '4px solid #ea580c' }}>
          <p style={{ margin: '0 0 6px 0', fontSize: '13px', color: '#6b7280' }}>High Severity</p>
          <h2 style={{ margin: 0, fontSize: '26px', color: '#ea580c' }}>{stats.high}</h2>
        </div>
        <div className="stat-card" style={{ padding: '16px', backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', borderTop: '4px solid #16a34a' }}>
          <p style={{ margin: '0 0 6px 0', fontSize: '13px', color: '#6b7280' }}>Confirmed Exploits</p>
          <h2 style={{ margin: 0, fontSize: '26px', color: '#16a34a' }}>{stats.confirmed}</h2>
        </div>
      </section>

      {/* Visual Analytics */}
      <section style={{ display: 'flex', flexWrap: 'wrap', gap: '20px', marginBottom: '24px' }}>
        <div className="dashboard-card" style={{ flex: '1 1 320px', padding: '20px', backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px' }}>
          <h3 style={{ margin: '0 0 4px 0', fontSize: '16px' }}>Attack Vector Distribution</h3>
          <p style={{ margin: '0 0 16px 0', fontSize: '13px', color: '#6b7280' }}>Aggregated signatures across monitored targets.</p>
          <div style={{ height: '220px', width: '100%' }}>
            {categoryChartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={categoryChartData} cx="50%" cy="50%" innerRadius={50} outerRadius={80} dataKey="value">
                    {categoryChartData.map((e, idx) => <Cell key={`cell-${idx}`} fill={e.color} />)}
                  </Pie>
                  <RechartsTooltip />
                  <Legend verticalAlign="bottom" height={24} wrapperStyle={{ fontSize: '12px' }} />
                </PieChart>
              </ResponsiveContainer>
            ) : <div style={{ textAlign: 'center', paddingTop: '80px', color: '#9ca3af' }}>No alert data available.</div>}
          </div>
        </div>

        <div className="dashboard-card" style={{ flex: '2 1 450px', padding: '20px', backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px' }}>
          <h3 style={{ margin: '0 0 4px 0', fontSize: '16px' }}>Lifecycle Enforcement Engine</h3>
          <p style={{ margin: '0 0 16px 0', fontSize: '13px', color: '#6b7280' }}>Automated controls & audit guarantees.</p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '13px', marginTop: '24px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid #f1f5f9' }}>
              <span>Event Collection Pipeline</span>
              <span style={{ fontWeight: 600, color: '#16a34a' }}>End-to-End Crawler Integrated</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid #f1f5f9' }}>
              <span>Engine Status</span>
              <span style={{ fontWeight: 600, color: '#16a34a' }}>Deterministic Signature Evaluation</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0' }}>
              <span>Deduplication Window</span>
              <span style={{ fontWeight: 600 }}>2-Hour Correlation Clustering</span>
            </div>
          </div>
        </div>
      </section>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '12px', borderBottom: '1px solid #e5e7eb', marginBottom: '20px' }}>
        <button
          onClick={() => { setActiveTab('alerts'); setExpandedAlertId(null); }}
          style={{ padding: '10px 16px', background: 'none', border: 'none', borderBottom: activeTab === 'alerts' ? '2px solid #0f172a' : 'none', fontWeight: 600, cursor: 'pointer', color: activeTab === 'alerts' ? '#0f172a' : '#64748b' }}
        >
          Active Incidents ({websiteFilteredAlerts.length})
        </button>
        <button
          onClick={() => { setActiveTab('traffic'); setExpandedAlertId(null); }}
          style={{ padding: '10px 16px', background: 'none', border: 'none', borderBottom: activeTab === 'traffic' ? '2px solid #0f172a' : 'none', fontWeight: 600, cursor: 'pointer', color: activeTab === 'traffic' ? '#0f172a' : '#64748b' }}
        >
          Raw Traffic Stream ({filteredLogs.length})
        </button>
      </div>

      {/* Tab: Alerts View */}
      {activeTab === 'alerts' && (
        <section className="dashboard-card" style={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', overflow: 'hidden' }}>
          <div style={{ padding: '16px', borderBottom: '1px solid #f3f4f6', display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <input
              type="text"
              placeholder="Filter by rule, IP, or path..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{ padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '13px', width: '250px' }}
            />
            <select value={severityFilter} onChange={(e) => setSeverityFilter(e.target.value)} style={{ padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '13px' }}>
              <option value="all">All Severities</option>
              <option value="critical">Critical</option>
              <option value="high">High</option>
              <option value="medium">Medium</option>
              <option value="low">Low</option>
            </select>
            <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} style={{ padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '13px' }}>
              <option value="all">All Statuses</option>
              <option value="new">New</option>
              <option value="investigating">Investigating</option>
              <option value="confirmed">Confirmed</option>
              <option value="false_positive">False Positive</option>
              <option value="resolved">Resolved</option>
            </select>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead style={{ backgroundColor: '#f9fafb', borderBottom: '1px solid #e5e7eb', color: '#6b7280', fontSize: '11px', textTransform: 'uppercase' }}>
                <tr>
                  <th style={{ padding: '12px 16px' }}>Severity</th>
                  <th style={{ padding: '12px 16px' }}>Rule / Attack Category</th>
                  <th style={{ padding: '12px 16px' }}>Source IP</th>
                  <th style={{ padding: '12px 16px' }}>Target Path</th>
                  <th style={{ padding: '12px 16px' }}>Assigned To</th>
                  <th style={{ padding: '12px 16px' }}>Status</th>
                  <th style={{ padding: '12px 16px' }}>Last Seen</th>
                  <th style={{ padding: '12px 16px', textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredAlerts.length > 0 ? (
                  filteredAlerts.map((a) => {
                    const isExpanded = expandedAlertId === a.id;
                    const nextAllowedStatuses = VALID_TRANSITIONS[a.status] || [];

                    return (
                      <React.Fragment key={a.id}>
                        <tr style={{ borderBottom: '1px solid #f3f4f6', backgroundColor: isExpanded ? '#f8fafc' : 'transparent' }}>
                          <td style={{ padding: '14px 16px' }}>{getSeverityBadge(a.severity)}</td>
                          <td style={{ padding: '14px 16px' }}>
                            <div style={{ fontWeight: 600 }}>{a.classification}</div>
                            <div style={{ fontSize: '11px', color: '#6b7280' }}>{a.rule_id}</div>
                          </td>
                          <td style={{ padding: '14px 16px', fontFamily: 'monospace' }}>{a.source_ip || 'N/A'}</td>
                          <td style={{ padding: '14px 16px', fontFamily: 'monospace', maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={a.endpoint}>
                            {a.endpoint}
                          </td>
                          <td style={{ padding: '14px 16px' }}>
                            <span style={{ fontSize: '12px', color: a.assigned_to ? '#111827' : '#9ca3af' }}>
                              {a.assigned_to_name || (a.assigned_to ? a.assigned_to_email : 'Unassigned')}
                            </span>
                          </td>
                          <td style={{ padding: '14px 16px' }}>{getStatusBadge(a.status)}</td>
                          <td style={{ padding: '14px 16px', color: '#6b7280', fontSize: '12px' }}>{new Date(a.last_seen_at).toLocaleTimeString()}</td>
                          <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                            <button
                              onClick={() => loadAlertDetails(a.id)}
                              style={{ padding: '5px 10px', fontSize: '12px', border: '1px solid #cbd5e1', borderRadius: '4px', cursor: 'pointer', backgroundColor: '#fff' }}
                            >
                              {isExpanded ? 'Collapse' : 'Investigate'}
                            </button>
                          </td>
                        </tr>

                        {/* Expandable Investigation Drawer */}
                        {isExpanded && (
                          <tr style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0' }}>
                            <td colSpan="8" style={{ padding: '20px 24px' }}>
                              {/* Action Bar: Assignment & FSM Status Transitions */}
                              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px', marginBottom: '20px', paddingBottom: '16px', borderBottom: '1px solid #e2e8f0' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                  <label style={{ fontSize: '12px', fontWeight: 600, color: '#475569' }}>Investigator Assignment:</label>
                                  <select
                                    value={a.assigned_to || ''}
                                    onChange={(e) => handleAssigneeChange(a.id, e.target.value)}
                                    style={{ padding: '6px 10px', fontSize: '12px', border: '1px solid #cbd5e1', borderRadius: '4px', backgroundColor: '#fff' }}
                                  >
                                    <option value="">Unassigned</option>
                                    {investigators.map((inv) => (
                                      <option key={inv.id} value={inv.id}>
                                        {inv.full_name ? `${inv.full_name} (${inv.email})` : inv.email}
                                      </option>
                                    ))}
                                  </select>
                                </div>

                                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                                  <input
                                    type="text"
                                    placeholder="Optional transition reason / note..."
                                    value={statusReason}
                                    onChange={(e) => setStatusReason(e.target.value)}
                                    style={{ padding: '6px 10px', fontSize: '12px', border: '1px solid #cbd5e1', borderRadius: '4px', width: '220px' }}
                                  />
                                  {nextAllowedStatuses.map((nextSt) => (
                                    <button
                                      key={nextSt}
                                      onClick={() => handleStatusChange(a.id, nextSt)}
                                      style={{
                                        padding: '6px 12px', fontSize: '12px', fontWeight: 600, borderRadius: '4px', cursor: 'pointer',
                                        backgroundColor: nextSt === 'confirmed' ? '#fee2e2' : nextSt === 'resolved' ? '#dcfce7' : '#fff',
                                        color: nextSt === 'confirmed' ? '#b91c1c' : nextSt === 'resolved' ? '#15803d' : '#0f172a',
                                        border: nextSt === 'confirmed' ? '1px solid #fca5a5' : nextSt === 'resolved' ? '1px solid #86efac' : '1px solid #cbd5e1'
                                      }}
                                    >
                                      Mark: {nextSt.replace('_', ' ')}
                                    </button>
                                  ))}
                                </div>
                              </div>

                              {/* Drawer Navigation Tabs */}
                              <div style={{ display: 'flex', gap: '16px', borderBottom: '1px solid #cbd5e1', marginBottom: '16px' }}>
                                {['notes', 'evidence', 'history'].map((tabKey) => (
                                  <button
                                    key={tabKey}
                                    onClick={() => setDrawerTab(tabKey)}
                                    style={{
                                      padding: '6px 0', border: 'none', background: 'none', cursor: 'pointer',
                                      fontWeight: 600, fontSize: '12px', textTransform: 'uppercase',
                                      borderBottom: drawerTab === tabKey ? '2px solid #0f172a' : 'none',
                                      color: drawerTab === tabKey ? '#0f172a' : '#64748b'
                                    }}
                                  >
                                    {tabKey === 'notes' ? `Notes (${notes.length})` : tabKey === 'evidence' ? 'Technical Evidence' : `Audit Trail (${history.length})`}
                                  </button>
                                ))}
                              </div>

                              {/* Tab Content: Notes */}
                              {drawerTab === 'notes' && (
                                <div>
                                  <div style={{ maxHeight: '200px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '10px', marginBottom: '16px' }}>
                                    {notes.length > 0 ? (
                                      notes.map((n) => (
                                        <div key={n.id} style={{ padding: '10px 14px', backgroundColor: '#fff', border: '1px solid #e2e8f0', borderRadius: '6px', fontSize: '12px' }}>
                                          <div style={{ display: 'flex', justifyContent: 'space-between', color: '#64748b', fontSize: '11px', marginBottom: '4px' }}>
                                            <span style={{ fontWeight: 600, color: '#1e293b' }}>{n.author_name || n.author_email}</span>
                                            <span>{new Date(n.created_at).toLocaleString()}</span>
                                          </div>
                                          <div style={{ color: '#334155', whiteSpace: 'pre-wrap' }}>{n.note}</div>
                                        </div>
                                      ))
                                    ) : (
                                      <p style={{ color: '#94a3b8', fontSize: '12px', margin: 0 }}>No analyst notes recorded yet.</p>
                                    )}
                                  </div>
                                  <form onSubmit={(e) => handleAddNote(e, a.id)} style={{ display: 'flex', gap: '8px' }}>
                                    <input
                                      type="text"
                                      placeholder="Add an investigation note (max 2000 chars)..."
                                      value={newNoteText}
                                      onChange={(e) => setNewNoteText(e.target.value)}
                                      maxLength={2000}
                                      style={{ flex: 1, padding: '8px 12px', fontSize: '12px', border: '1px solid #cbd5e1', borderRadius: '4px' }}
                                    />
                                    <button
                                      type="submit"
                                      disabled={submittingNote || !newNoteText.trim()}
                                      style={{ padding: '8px 16px', backgroundColor: '#0f172a', color: '#fff', border: 'none', borderRadius: '4px', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}
                                    >
                                      {submittingNote ? 'Saving...' : 'Post Note'}
                                    </button>
                                  </form>
                                </div>
                              )}

                              {/* Tab Content: Technical Evidence */}
                              {drawerTab === 'evidence' && (
                                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '16px' }}>
                                  <div>
                                    <h5 style={{ margin: '0 0 6px 0', fontSize: '11px', color: '#64748b', textTransform: 'uppercase' }}>Rule Description</h5>
                                    <p style={{ margin: '0 0 12px 0', fontSize: '12px' }}>{a.description}</p>
                                    <div style={{ fontSize: '12px', color: '#475569' }}>
                                      <div><strong>Target:</strong> {a.target_url}</div>
                                      <div><strong>Hits:</strong> {a.occurrence_count}</div>
                                      <div><strong>Confidence:</strong> {(a.confidence * 100).toFixed(0)}%</div>
                                    </div>
                                  </div>
                                  <div>
                                    <h5 style={{ margin: '0 0 6px 0', fontSize: '11px', color: '#64748b', textTransform: 'uppercase' }}>Captured Payload Evidence</h5>
                                    <pre style={{ margin: 0, padding: '12px', backgroundColor: '#0f172a', color: '#34d399', borderRadius: '6px', fontSize: '11px', overflowX: 'auto', fontFamily: 'monospace' }}>
                                      {JSON.stringify(a.evidence, null, 2)}
                                    </pre>
                                  </div>
                                </div>
                              )}

                              {/* Tab Content: Audit History */}
                              {drawerTab === 'history' && (
                                <div style={{ maxHeight: '200px', overflowY: 'auto' }}>
                                  <table style={{ width: '100%', fontSize: '11px', borderCollapse: 'collapse' }}>
                                    <thead>
                                      <tr style={{ color: '#64748b', borderBottom: '1px solid #e2e8f0', textAlign: 'left' }}>
                                        <th style={{ padding: '6px 8px' }}>Action</th>
                                        <th style={{ padding: '6px 8px' }}>Actor</th>
                                        <th style={{ padding: '6px 8px' }}>Change Details</th>
                                        <th style={{ padding: '6px 8px' }}>Timestamp</th>
                                      </tr>
                                    </thead>
                                    <tbody>
                                      {history.map((h) => (
                                        <tr key={h.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                                          <td style={{ padding: '6px 8px', fontWeight: 600, color: '#1e293b' }}>{h.action.replace('_', ' ')}</td>
                                          <td style={{ padding: '6px 8px' }}>{h.actor_name}</td>
                                          <td style={{ padding: '6px 8px', color: '#475569' }}>
                                            {h.previous_value && h.new_value ? `${h.previous_value} → ${h.new_value}` : h.new_value || JSON.stringify(h.metadata)}
                                          </td>
                                          <td style={{ padding: '6px 8px', color: '#94a3af' }}>{new Date(h.created_at).toLocaleString()}</td>
                                        </tr>
                                      ))}
                                    </tbody>
                                  </table>
                                </div>
                              )}
                            </td>
                          </tr>
                        )}
                      </React.Fragment>
                    );
                  })
                ) : (
                  <tr>
                    <td colSpan="8" style={{ padding: '40px', textAlign: 'center', color: '#9ca3af' }}>No security alerts found matching your criteria.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* Tab: Traffic View */}
      {activeTab === 'traffic' && (
        <section className="dashboard-card" style={{ backgroundColor: '#fff', border: '1px solid #e5e7eb', borderRadius: '12px', padding: '16px' }}>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead style={{ backgroundColor: '#f9fafb', color: '#6b7280', fontSize: '11px', textTransform: 'uppercase' }}>
                <tr>
                  <th style={{ padding: '10px' }}>Method</th>
                  <th style={{ padding: '10px' }}>Classification</th>
                  <th style={{ padding: '10px' }}>Endpoint</th>
                  <th style={{ padding: '10px' }}>Status</th>
                  <th style={{ padding: '10px' }}>Time</th>
                </tr>
              </thead>
              <tbody>
                {filteredLogs.length > 0 ? filteredLogs.map((l) => (
                  <tr key={l.id} style={{ borderBottom: '1px solid #f3f4f6' }}>
                    <td style={{ padding: '10px', fontWeight: 600 }}>{l.method}</td>
                    <td style={{ padding: '10px' }}>
                      <span style={{ padding: '2px 6px', borderRadius: '4px', fontSize: '11px', fontWeight: 'bold', backgroundColor: l.classification === 'benign' ? '#f3f4f6' : '#fee2e2', color: l.classification === 'benign' ? '#4b5563' : '#b91c1c', textTransform: 'uppercase' }}>
                        {l.classification}
                      </span>
                    </td>
                    <td style={{ padding: '10px', fontFamily: 'monospace' }}>{l.endpoint}</td>
                    <td style={{ padding: '10px' }}>{l.status_code || '—'}</td>
                    <td style={{ padding: '10px', color: '#6b7280' }}>{new Date(l.created_at).toLocaleTimeString()}</td>
                  </tr>
                )) : (
                  <tr>
                    <td colSpan="5" style={{ padding: '40px', textAlign: 'center', color: '#9ca3af' }}>No traffic logs matching your criteria.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
};

export default IntrusionDetection;