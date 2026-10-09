import React, { useEffect, useState, useCallback, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { 
  getAllFindings, updateFindingStatus, getFindingNotes, addFindingNote, getFindingHistory 
} from '../services/scanService';
import { apiError } from '../services/api';

const VALID_TRANSITIONS = {
  open: ["in_progress", "accepted_risk", "false_positive"],
  in_progress: ["resolved", "accepted_risk", "false_positive", "open"],
  resolved: ["open", "in_progress"],
  accepted_risk: ["open"],
  false_positive: ["open"]
};

const Vulnerabilities = () => {
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');

  // Filtering states
  const [websiteFilter, setWebsiteFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  
  // Drawer States
  const [expandedFindingId, setExpandedFindingId] = useState(null);
  const [drawerTab, setDrawerTab] = useState('evidence'); // 'evidence', 'notes', 'history'
  const [notes, setNotes] = useState([]);
  const [history, setHistory] = useState([]);
  const [newNoteText, setNewNoteText] = useState('');
  const [submittingNote, setSubmittingNote] = useState(false);

  const loadFindingsData = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError('');

    try {
      const response = await getAllFindings();
      const list = response?.findings || (Array.isArray(response) ? response : []);
      setFindings(list);
    } catch (err) {
      setError(apiError(err, 'Unable to retrieve vulnerabilities from the backend.'));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadFindingsData();
  }, [loadFindingsData]);

  const uniqueWebsites = useMemo(() => {
    const urls = findings.map(f => f.target_url).filter(Boolean);
    return Array.from(new Set(urls)).sort();
  }, [findings]);

  const filteredFindings = useMemo(() => {
    return findings.filter((f) => {
      const query = searchTerm.trim().toLowerCase();
      const title = (f.title || f.name || '').toLowerCase();
      const type = (f.vulnerability_type || '').toLowerCase();
      const target = (f.affected_url || f.target_url || '').toLowerCase();

      const matchesWebsite = websiteFilter === 'all' || f.target_url === websiteFilter;
      const matchesSearch = !query || title.includes(query) || type.includes(query) || target.includes(query) || String(f.id).includes(query);
      const matchesSeverity = severityFilter === 'all' || String(f.severity).toLowerCase() === severityFilter;
      const matchesStatus = statusFilter === 'all' || String(f.status || 'open').toLowerCase() === statusFilter;

      return matchesWebsite && matchesSearch && matchesSeverity && matchesStatus;
    });
  }, [findings, websiteFilter, searchTerm, severityFilter, statusFilter]);

  const countSeverity = (sev) => filteredFindings.filter((f) => String(f.severity).toLowerCase() === sev).length;

  const loadFindingDetails = async (findingId) => {
    if (expandedFindingId === findingId) {
      setExpandedFindingId(null);
      return;
    }
    setExpandedFindingId(findingId);
    setDrawerTab('evidence');
    try {
      const [notesRes, historyRes] = await Promise.all([
        getFindingNotes(findingId),
        getFindingHistory(findingId)
      ]);
      setNotes(notesRes?.notes || []);
      setHistory(historyRes?.history || []);
    } catch (err) {
      console.error('Failed to load details:', err);
    }
  };

  const handleStatusChange = async (findingId, nextStatus) => {
    try {
      await updateFindingStatus(findingId, nextStatus);
      await loadFindingsData(true);
      const [notesRes, historyRes] = await Promise.all([
        getFindingNotes(findingId),
        getFindingHistory(findingId)
      ]);
      setNotes(notesRes?.notes || []);
      setHistory(historyRes?.history || []);
    } catch (err) {
      alert(apiError(err, 'Failed to update finding status.'));
    }
  };

  const handleAddNote = async (e, findingId) => {
    e.preventDefault();
    if (!newNoteText.trim()) return;
    setSubmittingNote(true);
    try {
      const res = await addFindingNote(findingId, newNoteText.trim());
      setNotes(prev => [...prev, res.note]);
      setNewNoteText('');
      const historyRes = await getFindingHistory(findingId);
      setHistory(historyRes?.history || []);
    } catch (err) {
      alert(apiError(err, 'Failed to post remediation note.'));
    } finally {
      setSubmittingNote(false);
    }
  };

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
      open: { bg: '#fef2f2', text: '#dc2626' },
      in_progress: { bg: '#eff6ff', text: '#2563eb' },
      resolved: { bg: '#f0fdf4', text: '#16a34a' },
      accepted_risk: { bg: '#fefce8', text: '#ca8a04' },
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
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
        <div>
          <nav className="text-xs font-semibold tracking-wider text-gray-500 uppercase mb-2">Security / Vulnerabilities</nav>
          <h1 className="text-2xl font-bold text-gray-900 mb-1">Remediation Management</h1>
          <p className="text-sm text-gray-600">Track, prioritize, and verify vulnerabilities identified by the passive scanner.</p>
        </div>
        <button
          onClick={() => loadFindingsData(true)}
          disabled={refreshing || loading}
          className="self-start sm:self-auto px-4 py-2 bg-white border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 transition shadow-sm flex items-center gap-2"
        >
          {refreshing ? 'Refreshing...' : '↻ Refresh Findings'}
        </button>
      </div>

      {error && <div className="p-4 bg-red-50 border-l-4 border-red-500 rounded text-sm text-red-700"><strong>Error:</strong> {error}</div>}

      {/* Target & Scope Selection */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-4 flex flex-col sm:flex-row items-center gap-4">
        <label htmlFor="website-selector" className="text-sm font-semibold text-gray-700 whitespace-nowrap">
          Target Website:
        </label>
        <select
          id="website-selector"
          value={websiteFilter}
          onChange={(e) => setWebsiteFilter(e.target.value)}
          className="w-full sm:w-auto flex-1 px-4 py-2.5 text-sm bg-gray-50 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono"
        >
          <option value="all" className="font-sans font-semibold">All Authorized Websites</option>
          {uniqueWebsites.map(url => <option key={url} value={url}>{url}</option>)}
        </select>
      </div>

      {/* Aggregated Risk Metrics */}
      <section className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div className="bg-white rounded-xl shadow-sm border-t-4 border-gray-900 border-x border-b border-gray-200 p-5">
          <p className="text-sm font-medium text-gray-500 mb-1">Total</p>
          <h2 className="text-2xl font-bold text-gray-900">{filteredFindings.length}</h2>
        </div>
        <div className="bg-white rounded-xl shadow-sm border-t-4 border-red-600 border-x border-b border-gray-200 p-5">
          <p className="text-sm font-medium text-gray-500 mb-1">Critical</p>
          <h2 className="text-2xl font-bold text-red-600">{countSeverity('critical')}</h2>
        </div>
        <div className="bg-white rounded-xl shadow-sm border-t-4 border-orange-500 border-x border-b border-gray-200 p-5">
          <p className="text-sm font-medium text-gray-500 mb-1">High</p>
          <h2 className="text-2xl font-bold text-orange-500">{countSeverity('high')}</h2>
        </div>
        <div className="bg-white rounded-xl shadow-sm border-t-4 border-amber-500 border-x border-b border-gray-200 p-5">
          <p className="text-sm font-medium text-gray-500 mb-1">Medium</p>
          <h2 className="text-2xl font-bold text-amber-500">{countSeverity('medium')}</h2>
        </div>
        <div className="bg-white rounded-xl shadow-sm border-t-4 border-blue-600 border-x border-b border-gray-200 p-5">
          <p className="text-sm font-medium text-gray-500 mb-1">Low</p>
          <h2 className="text-2xl font-bold text-blue-600">{countSeverity('low')}</h2>
        </div>
        <div className="bg-white rounded-xl shadow-sm border-t-4 border-slate-500 border-x border-b border-gray-200 p-5">
          <p className="text-sm font-medium text-gray-500 mb-1">Info</p>
          <h2 className="text-2xl font-bold text-slate-500">{countSeverity('info')}</h2>
        </div>
      </section>

      {/* Primary Remediation Table */}
      <section className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 space-y-6">
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4 pb-4 border-b border-gray-100">
          <div className="flex flex-col sm:flex-row items-center gap-3">
            <select value={severityFilter} onChange={(e) => setSeverityFilter(e.target.value)} className="w-full sm:w-auto px-3 py-2 text-sm bg-gray-50 border border-gray-300 rounded-lg">
              <option value="all">All Severities</option>
              <option value="critical">Critical</option><option value="high">High</option><option value="medium">Medium</option><option value="low">Low</option><option value="info">Info</option>
            </select>
            <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="w-full sm:w-auto px-3 py-2 text-sm bg-gray-50 border border-gray-300 rounded-lg capitalize">
              <option value="all">All Statuses</option>
              <option value="open">Open</option><option value="in_progress">In Progress</option><option value="resolved">Resolved</option><option value="accepted_risk">Accepted Risk</option><option value="false_positive">False Positive</option>
            </select>
          </div>
          
          <div className="relative w-full md:w-80">
            <input type="text" placeholder="Search finding, URL, or ID..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="w-full px-3 py-2 pl-9 text-sm border border-gray-300 rounded-lg" />
            <svg className="w-4 h-4 text-gray-400 absolute left-3 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
          </div>
        </div>

        {loading ? (
          <div className="py-12 flex justify-center items-center">Loading Findings...</div>
        ) : filteredFindings.length > 0 ? (
          <div className="overflow-x-auto border border-gray-200 rounded-lg">
            <table className="min-w-full divide-y divide-gray-200 text-left text-sm">
              <thead className="bg-gray-50 text-gray-500 font-semibold text-xs uppercase tracking-wider">
                <tr>
                  <th className="px-4 py-3">Severity</th>
                  <th className="px-4 py-3">Vulnerability</th>
                  <th className="px-4 py-3">Affected Asset</th>
                  <th className="px-4 py-3">Workflow State</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {filteredFindings.map((f) => {
                  const isExpanded = expandedFindingId === f.id;
                  const nextAllowedStatuses = VALID_TRANSITIONS[f.status] || [];

                  return (
                    <React.Fragment key={f.id}>
                      <tr className="hover:bg-gray-50 transition">
                        <td className="px-4 py-3.5 whitespace-nowrap">{getSeverityBadge(f.severity)}</td>
                        <td className="px-4 py-3.5">
                          <div className="font-bold text-gray-900">{f.title}</div>
                          <div className="text-xs text-gray-500">{f.vulnerability_type?.replaceAll('_', ' ')}</div>
                        </td>
                        <td className="px-4 py-3.5 max-w-[200px] truncate font-mono text-xs text-gray-600" title={f.affected_url || f.target_url}>
                          {f.affected_url || f.target_url || 'Target Wide'}
                        </td>
                        <td className="px-4 py-3.5 whitespace-nowrap">
                          {getStatusBadge(f.status)}
                          <div className="text-[10px] text-gray-500 mt-1">Conf: {(f.ai_confidence * 100).toFixed(0)}%</div>
                        </td>
                        <td className="px-4 py-3.5 whitespace-nowrap text-right">
                          <button onClick={() => loadFindingDetails(f.id)} className="px-2.5 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 hover:bg-blue-100 rounded transition">
                            {isExpanded ? 'Collapse' : 'Remediate'}
                          </button>
                        </td>
                      </tr>

                      {/* Expandable Remediation Drawer */}
                      {isExpanded && (
                        <tr className="bg-slate-50 border-b-2 border-slate-200">
                          <td colSpan="5" className="px-6 py-5 text-sm text-gray-700">
                            {/* Workflow Bar */}
                            <div className="flex justify-between items-center flex-wrap gap-4 mb-5 pb-4 border-b border-gray-200">
                              <div className="flex gap-2">
                                <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider mt-2 mr-2">Set State:</span>
                                {nextAllowedStatuses.map((nextSt) => (
                                  <button
                                    key={nextSt}
                                    onClick={() => handleStatusChange(f.id, nextSt)}
                                    className="px-3 py-1.5 text-xs font-semibold border border-gray-300 bg-white rounded hover:bg-gray-50"
                                  >
                                    Mark as {nextSt.replace('_', ' ')}
                                  </button>
                                ))}
                              </div>
                              {f.scan_id && (
                                <Link to={`/scan/${f.scan_id}`} className="px-3 py-1.5 text-xs font-semibold bg-gray-900 text-white rounded">
                                  View Source Scan
                                </Link>
                              )}
                            </div>

                            {/* Tabs */}
                            <div className="flex gap-4 border-b border-gray-300 mb-4">
                              {['evidence', 'notes', 'history'].map((tab) => (
                                <button key={tab} onClick={() => setDrawerTab(tab)} className={`pb-2 text-xs font-bold uppercase tracking-wider ${drawerTab === tab ? 'border-b-2 border-gray-900 text-gray-900' : 'text-gray-500'}`}>
                                  {tab === 'evidence' ? 'Technical Details' : tab === 'notes' ? `Notes (${notes.length})` : `Audit Trail (${history.length})`}
                                </button>
                              ))}
                            </div>

                            {/* Content */}
                            {drawerTab === 'evidence' && (
                              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                <div>
                                  <h4 className="font-bold text-xs uppercase text-gray-500 mb-1">Vulnerability Description</h4>
                                  <p className="whitespace-pre-wrap mb-4">{f.description}</p>
                                  <h4 className="font-bold text-xs uppercase text-gray-500 mb-1">Remediation Guidance</h4>
                                  <p className="p-3 bg-emerald-50 text-emerald-900 border border-emerald-200 rounded">{f.remediation}</p>
                                </div>
                                <div>
                                  <h4 className="font-bold text-xs uppercase text-gray-500 mb-1">Context & Evidence</h4>
                                  <pre className="p-3 bg-gray-900 text-emerald-400 rounded text-xs font-mono overflow-x-auto mb-4 border border-gray-800">
                                    {JSON.stringify(f.evidence, null, 2)}
                                  </pre>
                                  <div className="grid grid-cols-2 gap-2 text-xs p-3 bg-white border border-gray-200 rounded">
                                    <div><span className="font-semibold text-gray-500">First Seen:</span> {formatDate(f.created_at)}</div>
                                    <div><span className="font-semibold text-gray-500">Last Seen:</span> {formatDate(f.last_seen_at || f.created_at)}</div>
                                    <div><span className="font-semibold text-gray-500">CVSS:</span> {f.cvss_score || 'N/A'}</div>
                                    <div><span className="font-semibold text-gray-500">Finding ID:</span> <span className="font-mono text-gray-400">{String(f.id).split('-')[0]}...</span></div>
                                  </div>
                                </div>
                              </div>
                            )}

                            {drawerTab === 'notes' && (
                              <div>
                                <div className="max-h-48 overflow-y-auto space-y-2 mb-4">
                                  {notes.length > 0 ? notes.map(n => (
                                    <div key={n.id} className="p-3 bg-white border border-gray-200 rounded text-xs">
                                      <div className="flex justify-between text-gray-500 mb-1">
                                        <span className="font-bold text-gray-900">{n.author_name || n.author_email}</span>
                                        <span>{new Date(n.created_at).toLocaleString()}</span>
                                      </div>
                                      <div className="whitespace-pre-wrap text-gray-700">{n.note}</div>
                                    </div>
                                  )) : <p className="text-xs text-gray-500">No remediation notes exist yet.</p>}
                                </div>
                                <form onSubmit={(e) => handleAddNote(e, f.id)} className="flex gap-2">
                                  <input type="text" placeholder="Add a remediation note..." value={newNoteText} onChange={(e) => setNewNoteText(e.target.value)} className="flex-1 p-2 text-xs border border-gray-300 rounded" />
                                  <button type="submit" disabled={submittingNote || !newNoteText.trim()} className="px-4 py-2 bg-gray-900 text-white text-xs font-bold rounded">Post</button>
                                </form>
                              </div>
                            )}

                            {drawerTab === 'history' && (
                              <table className="w-full text-xs text-left">
                                <thead>
                                  <tr className="text-gray-500 border-b border-gray-200">
                                    <th className="py-2">Action</th><th className="py-2">Actor</th><th className="py-2">Details</th><th className="py-2">Time</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {history.map(h => (
                                    <tr key={h.id} className="border-b border-gray-100">
                                      <td className="py-2 font-bold text-gray-900">{h.action.replace('_', ' ')}</td>
                                      <td className="py-2">{h.actor_name}</td>
                                      <td className="py-2 text-gray-600">{h.previous_value && h.new_value ? `${h.previous_value} → ${h.new_value}` : h.new_value || ''}</td>
                                      <td className="py-2 text-gray-400">{new Date(h.created_at).toLocaleString()}</td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>
                            )}
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="py-16 text-center border-2 border-dashed border-gray-200 rounded-lg text-gray-500 text-sm">
            {websiteFilter !== 'all' ? `No vulnerabilities match your criteria for ${websiteFilter}.` : 'Your authorized scans have not identified any vulnerabilities.'}
          </div>
        )}
      </section>
    </div>
  );
};

export default Vulnerabilities;