import React, { useEffect, useState, useRef, useMemo } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { cancelScan, getScan, getScanStatus, getScanFindings, createScan } from '../services/scanService';
import { apiError } from '../services/api';

const stages = ['queued', 'crawling', 'passive', 'active', 'analyzing', 'completed'];
const titles = { 
  queued: 'Queued', 
  crawling: 'Crawling', 
  passive: 'Passive Analysis', 
  active: 'Active Testing', 
  analyzing: 'AI Analysis', 
  completed: 'Completed' 
};

export default function ScanDetails() {
  const { id } = useParams();
  const navigate = useNavigate();

  const [scan, setScan] = useState(null);
  const [status, setStatus] = useState(null);
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [findingsLoading, setFindingsLoading] = useState(false);
  const [findingsError, setFindingsError] = useState('');
  const [error, setError] = useState('');
  const [cancelling, setCancelling] = useState(false);
  const [showCancelModal, setShowCancelModal] = useState(false);

  // Findings UI filters and expansion
  const [severityFilter, setSeverityFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [expandedFindingId, setExpandedFindingId] = useState(null);

  const timerRef = useRef(null);
  const activeScanIdRef = useRef(id);

  useEffect(() => {
    activeScanIdRef.current = id;
  }, [id]);

  const formatDate = (dateVal) => {
    if (!dateVal) return 'Not available';
    const parsed = new Date(dateVal);
    return Number.isNaN(parsed.getTime()) ? 'Not available' : parsed.toLocaleString();
  };

  const loadFindingsData = async (scanId) => {
    try {
      setFindingsLoading(true);
      setFindingsError('');
      const findingsRes = await getScanFindings(scanId);
      if (activeScanIdRef.current !== scanId) return;

      const rawFindings = findingsRes?.findings || (Array.isArray(findingsRes) ? findingsRes : []);
      setFindings(rawFindings);
    } catch (err) {
      if (activeScanIdRef.current !== scanId) return;
      setFindingsError(apiError(err, 'Failed to retrieve scan findings.'));
    } finally {
      if (activeScanIdRef.current === scanId) {
        setFindingsLoading(false);
      }
    }
  };

  const loadScanData = async (isInitial = false) => {
    const currentId = id;
    try {
      if (isInitial) setLoading(true);

      const [detailRes, statusRes] = await Promise.all([
        getScan(currentId),
        getScanStatus(currentId)
      ]);

      if (activeScanIdRef.current !== currentId) return;

      const unwrappedScan = detailRes?.scan || detailRes;
      setScan(unwrappedScan);
      setStatus(statusRes);
      setError('');

      // Fetch findings if initial load or if status count diverges
      if (isInitial || (statusRes?.findings_count > 0 && findings.length === 0)) {
        await loadFindingsData(currentId);
      }

      if (['queued', 'crawling', 'passive', 'active', 'analyzing'].includes(statusRes?.status)) {
        timerRef.current = setTimeout(() => {
          loadScanData(false);
        }, 4000);
      } else if (statusRes?.status === 'completed' && findings.length === 0) {
        await loadFindingsData(currentId);
      }
    } catch (err) {
      if (activeScanIdRef.current !== currentId) return;
      setError(apiError(err, 'Unable to load scan details.'));
    } finally {
      if (activeScanIdRef.current === currentId && isInitial) {
        setLoading(false);
      }
    }
  };

  useEffect(() => {
    loadScanData(true);

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [id]);

  const handleCancel = async () => {
    setCancelling(true);
    try {
      const updatedRes = await cancelScan(id);
      const updatedScan = updatedRes?.scan || updatedRes;
      setScan(updatedScan);
      setStatus((prev) => ({ ...prev, status: updatedScan.status }));
      setShowCancelModal(false);
    } catch (err) {
      setError(apiError(err, 'Failed to cancel scan.'));
    } finally {
      setCancelling(false);
    }
  };

  const getStatusBadge = (currentStatus) => {
    switch (currentStatus) {
      case 'completed': return 'bg-green-100 text-green-800 border-green-200';
      case 'failed': return 'bg-red-100 text-red-800 border-red-200';
      case 'cancelled': return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'queued': return 'bg-blue-100 text-blue-800 border-blue-200';
      default: return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    }
  };

  const getSeverityBadge = (severity) => {
    const sev = String(severity || '').toLowerCase();
    switch (sev) {
      case 'critical': return 'bg-red-600 text-white';
      case 'high': return 'bg-orange-500 text-white';
      case 'medium': return 'bg-amber-500 text-white';
      case 'low': return 'bg-blue-600 text-white';
      default: return 'bg-slate-500 text-white';
    }
  };

  // Filter findings based on severity and text search
  const filteredFindings = useMemo(() => {
    return findings.filter((f) => {
      const matchSeverity = severityFilter === 'all' || String(f.severity).toLowerCase() === severityFilter.toLowerCase();
      const query = searchQuery.trim().toLowerCase();
      const matchSearch = !query || 
        (f.title && f.title.toLowerCase().includes(query)) ||
        (f.affected_url && f.affected_url.toLowerCase().includes(query)) ||
        (f.vulnerability_type && f.vulnerability_type.toLowerCase().includes(query)) ||
        (f.cwe_id && f.cwe_id.toLowerCase().includes(query));
      return matchSeverity && matchSearch;
    });
  }, [findings, severityFilter, searchQuery]);

  if (loading && !scan) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 flex justify-center items-center">
        <div className="flex flex-col items-center">
          <svg className="animate-spin h-8 w-8 text-blue-600 mb-4" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <p className="text-gray-500 font-medium">Loading scan details and findings...</p>
        </div>
      </div>
    );
  }

  if (error && !scan) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 text-center">
          <h3 className="text-lg font-medium text-red-800 mb-2">Error Loading Scan</h3>
          <p className="text-red-600 mb-4">{error}</p>
          <button onClick={() => loadScanData(true)} className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition">
            Retry
          </button>
        </div>
      </div>
    );
  }

  const currentStatus = status?.status || scan?.status || 'queued';
  const running = stages.slice(0, -1).includes(currentStatus);
  const currentStageIndex = stages.indexOf(currentStatus);
  const isTerminal = ['completed', 'failed', 'cancelled'].includes(currentStatus);
  const config = scan?.scan_config || {};

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
        <div>
          <nav className="text-xs font-semibold tracking-wider text-gray-500 uppercase mb-2">Scanner / Details</nav>
          <div className="flex items-center gap-3 mb-1">
            <h1 className="text-2xl font-bold text-gray-900">Scan Details</h1>
            <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${getStatusBadge(currentStatus)}`}>
              {currentStatus.toUpperCase()}
            </span>
          </div>
          <p className="text-sm text-gray-600 font-mono flex items-center gap-2">
            UUID: {scan?.id}
            <button onClick={() => navigator.clipboard.writeText(scan?.id || '')} className="text-gray-400 hover:text-blue-600" title="Copy UUID">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
              </svg>
            </button>
          </p>
          {scan?.target_url && (
            <a href={scan.target_url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-blue-600 hover:text-blue-800 text-sm font-medium mt-2">
              {scan.target_url}
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
              </svg>
            </a>
          )}
        </div>
        <div className="flex items-center gap-3">
          <Link to="/vulnerabilities" className="px-4 py-2 bg-white border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 transition shadow-sm">
            All Vulnerabilities
          </Link>
          <button onClick={() => navigate('/scans')} className="px-4 py-2 bg-white border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 transition shadow-sm">
            All Scans
          </button>
          {running && (
            <button 
              onClick={() => setShowCancelModal(true)} 
              className="px-4 py-2 bg-red-600 border border-transparent rounded-md text-sm font-medium text-white hover:bg-red-700 transition shadow-sm"
            >
              Cancel Scan
            </button>
          )}
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 rounded text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Metrics Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          ['Pages Discovered', status?.pages_discovered ?? scan?.pages_discovered ?? 0, 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'],
          ['Requests Analyzed', status?.requests_analyzed ?? scan?.requests_analyzed ?? 0, 'M13 10V3L4 14h7v7l9-11h-7z'],
          ['Endpoints Found', status?.endpoints_found ?? scan?.endpoints_found ?? 0, 'M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1'],
          ['Total Findings', status?.findings_count ?? scan?.findings_count ?? findings.length, 'M20.618 5.984A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z']
        ].map(([mTitle, value, iconPath]) => (
          <div key={mTitle} className="bg-white rounded-xl shadow-sm border border-gray-200 p-5 flex items-center">
            <div className="p-3 rounded-lg bg-blue-50 text-blue-600 mr-4">
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d={iconPath}></path>
              </svg>
            </div>
            <div>
              <p className="text-sm font-medium text-gray-500 mb-1">{mTitle}</p>
              <h2 className="text-2xl font-bold text-gray-900">{value}</h2>
            </div>
          </div>
        ))}
      </div>

      {/* Progress & Configuration */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* Progress Panel */}
        <section className="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex justify-between items-center mb-6">
            <h3 className="text-lg font-semibold text-gray-900">Scan Progress</h3>
            <span className="text-sm font-medium text-gray-500">{titles[currentStatus] || currentStatus}</span>
          </div>

          <div className="mb-2 flex justify-between items-end">
            <span className="text-sm font-medium text-gray-700">Completion</span>
            <span className="text-2xl font-bold text-blue-600">{status?.progress_percent ?? (currentStatus === 'completed' ? 100 : 0)}%</span>
          </div>
          
          <div className="w-full bg-gray-100 rounded-full h-3 mb-8 overflow-hidden">
            <div 
              className={`h-3 rounded-full transition-all duration-500 ease-out ${
                ['cancelled', 'failed'].includes(currentStatus) ? 'bg-gray-400' : 'bg-blue-600'
              }`} 
              style={{ width: `${status?.progress_percent ?? (currentStatus === 'completed' ? 100 : 0)}%` }}
            ></div>
          </div>

          <div className="relative">
            <div className="absolute left-3.5 top-2 bottom-2 w-0.5 bg-gray-100"></div>
            <ul className="relative space-y-4">
              {stages.map((stage, index) => {
                const isCompleted = currentStageIndex > index || currentStatus === 'completed';
                const isCurrent = currentStageIndex === index && !isTerminal;
                const isSkippedActive = stage === 'active' && scan && !scan.active;
                
                return (
                  <li key={stage} className="flex items-center gap-4">
                    <div className={`relative z-10 w-7 h-7 rounded-full flex items-center justify-center border-2 
                      ${isCompleted ? 'bg-green-500 border-green-500 text-white' : 
                        isCurrent ? 'bg-white border-blue-600' : 'bg-white border-gray-300'}`}
                    >
                      {isCompleted && (
                        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                      )}
                      {isCurrent && <div className="w-2.5 h-2.5 rounded-full bg-blue-600 animate-pulse"></div>}
                    </div>
                    <div>
                      <span className={`text-sm font-medium ${isCompleted || isCurrent ? 'text-gray-900' : 'text-gray-400'}`}>
                        {titles[stage]}
                      </span>
                      {isSkippedActive && (
                        <span className="ml-2 text-xs text-gray-400 italic">(Passive Mode - Skipped)</span>
                      )}
                    </div>
                  </li>
                );
              })}
            </ul>
          </div>

          {status?.error_message && (
            <div className="mt-6 p-4 bg-red-50 border-l-4 border-red-500 rounded text-sm text-red-800">
              <strong>Scan Error:</strong> {status.error_message}
            </div>
          )}
        </section>

        {/* Configuration Panel */}
        <aside className="lg:col-span-1 bg-white rounded-xl shadow-sm border border-gray-200 p-6 sticky top-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4 pb-4 border-b border-gray-100">Configuration</h3>
          <div className="space-y-4">
            {[
              ['Profile', scan?.scan_type || config?.scan_type || 'standard'],
              ['Scope', scan?.scope_type || config?.scope_type || 'single_url'],
              ['Created', formatDate(scan?.created_at)],
              ['Started', formatDate(scan?.started_at)],
              ['Completed', formatDate(scan?.completed_at)],
              ['Max Pages', scan?.max_pages ?? config?.max_pages ?? 'Not specified'],
              ['Crawl Depth', scan?.crawl_depth ?? config?.crawl_depth ?? 'Not specified'],
              ['Auth Method', scan?.authentication_type ?? config?.authentication_type ?? 'none'],
              ['Active Mode', scan?.active ? 'Enabled' : 'Disabled (Passive only)'],
              ['Security Checks', (scan?.security_checks || config?.security_checks || []).map((c) => String(c).replaceAll('_', ' ')).join(', ') || 'None configured']
            ].map(([cKey, cVal]) => (
              <div key={cKey} className="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-1">
                <span className="text-sm font-medium text-gray-500 w-32 shrink-0">{cKey}</span>
                <span className="text-sm text-gray-900 font-medium text-left sm:text-right break-words capitalize max-w-[200px]">
                  {String(cVal)}
                </span>
              </div>
            ))}
          </div>
        </aside>
      </div>

      {/* Security Findings Section */}
      <section className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4 border-b border-gray-100">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Security Findings</h2>
            <p className="text-sm text-gray-500">Vulnerabilities and security misconfigurations identified for this scan.</p>
          </div>
          <button 
            onClick={() => loadFindingsData(id)} 
            disabled={findingsLoading}
            className="self-start sm:self-auto px-3 py-1.5 bg-gray-50 hover:bg-gray-100 border border-gray-300 rounded text-xs font-semibold text-gray-700 flex items-center gap-1.5 transition"
          >
            <svg className={`w-3.5 h-3.5 ${findingsLoading ? 'animate-spin' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
            </svg>
            Refresh Findings
          </button>
        </div>

        {/* Filter Toolbar */}
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4">
          <div className="flex flex-wrap items-center gap-2">
            {['all', 'critical', 'high', 'medium', 'low', 'info'].map((sev) => (
              <button
                key={sev}
                onClick={() => setSeverityFilter(sev)}
                className={`px-3 py-1.5 rounded-full text-xs font-medium capitalize transition ${
                  severityFilter === sev
                    ? 'bg-gray-900 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {sev}
              </button>
            ))}
          </div>
          <div className="relative min-w-[280px]">
            <input
              type="text"
              placeholder="Search by title, URL, or CWE..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full px-3 py-2 pl-9 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <svg className="w-4 h-4 text-gray-400 absolute left-3 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
            </svg>
          </div>
        </div>

        {/* Diagnostic Warning: Stored count > 0 but array empty */}
        {(status?.findings_count > 0 || scan?.findings_count > 0) && findings.length === 0 && !findingsLoading && (
          <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-3">
            <svg className="w-5 h-5 text-amber-600 mt-0.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
            </svg>
            <div>
              <h4 className="text-sm font-semibold text-amber-800">Diagnostic Discrepancy Notice</h4>
              <p className="text-xs text-amber-700 mt-1">
                The scan record reports {status?.findings_count || scan?.findings_count} finding(s), but no records were returned by the findings query.
                Ensure you are logged in as the scan owner ({scan?.user_id}) and the database connection is active.
              </p>
            </div>
          </div>
        )}

        {findingsError && (
          <div className="p-4 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 flex justify-between items-center">
            <span>{findingsError}</span>
            <button onClick={() => loadFindingsData(id)} className="underline font-semibold hover:text-red-900">
              Retry
            </button>
          </div>
        )}

        {/* Findings Table */}
        {filteredFindings.length > 0 ? (
          <div className="overflow-x-auto border border-gray-200 rounded-lg">
            <table className="min-w-full divide-y divide-gray-200 text-left text-sm">
              <thead className="bg-gray-50 text-gray-500 font-semibold text-xs uppercase tracking-wider">
                <tr>
                  <th className="px-4 py-3">Severity</th>
                  <th className="px-4 py-3">Vulnerability / Category</th>
                  <th className="px-4 py-3">Affected URL</th>
                  <th className="px-4 py-3">CWE / CVSS</th>
                  <th className="px-4 py-3">Confidence</th>
                  <th className="px-4 py-3 text-right">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 bg-white">
                {filteredFindings.map((f) => {
                  const isExpanded = expandedFindingId === f.id;
                  return (
                    <React.Fragment key={f.id}>
                      <tr className="hover:bg-gray-50 transition">
                        <td className="px-4 py-3.5 whitespace-nowrap">
                          <span className={`px-2.5 py-1 rounded text-xs font-bold uppercase ${getSeverityBadge(f.severity)}`}>
                            {f.severity}
                          </span>
                        </td>
                        <td className="px-4 py-3.5">
                          <div className="font-semibold text-gray-900">{f.title}</div>
                          <div className="text-xs text-gray-500">{f.vulnerability_type?.replaceAll('_', ' ')}</div>
                        </td>
                        <td className="px-4 py-3.5 max-w-xs truncate font-mono text-xs text-gray-600" title={f.affected_url}>
                          {f.affected_url || 'N/A'}
                        </td>
                        <td className="px-4 py-3.5 whitespace-nowrap text-xs text-gray-700">
                          <div>{f.cwe_id || 'N/A'}</div>
                          {f.cvss_score && <div className="text-gray-500">CVSS {f.cvss_score}</div>}
                        </td>
                        <td className="px-4 py-3.5 whitespace-nowrap text-xs text-gray-700">
                          {f.ai_confidence ? `${(Number(f.ai_confidence) * 100).toFixed(0)}%` : 'Rule-based'}
                        </td>
                        <td className="px-4 py-3.5 whitespace-nowrap text-right">
                          <button
                            onClick={() => setExpandedFindingId(isExpanded ? null : f.id)}
                            className="px-2.5 py-1 text-xs font-medium text-blue-600 hover:text-blue-800 bg-blue-50 hover:bg-blue-100 rounded transition"
                          >
                            {isExpanded ? 'Hide' : 'Inspect'}
                          </button>
                        </td>
                      </tr>

                      {/* Expandable Inspection Drawer */}
                      {isExpanded && (
                        <tr className="bg-slate-50">
                          <td colSpan="6" className="px-6 py-4 space-y-4 text-xs text-gray-700">
                            <div>
                              <h4 className="font-bold text-gray-900 text-sm mb-1">Description</h4>
                              <p className="leading-relaxed whitespace-pre-wrap">{f.description || 'No description provided.'}</p>
                            </div>

                            {f.evidence && Object.keys(f.evidence).length > 0 && (
                              <div>
                                <h4 className="font-bold text-gray-900 text-sm mb-1">Technical Evidence</h4>
                                <pre className="bg-gray-900 text-emerald-400 p-3 rounded overflow-x-auto text-xs font-mono">
                                  {typeof f.evidence === 'object' ? JSON.stringify(f.evidence, null, 2) : String(f.evidence)}
                                </pre>
                              </div>
                            )}

                            <div>
                              <h4 className="font-bold text-gray-900 text-sm mb-1">Remediation Recommendation</h4>
                              <p className="leading-relaxed whitespace-pre-wrap text-emerald-800 bg-emerald-50 p-3 rounded border border-emerald-200">
                                {f.remediation || 'Follow OWASP defensive hardening guidance for this vulnerability class.'}
                              </p>
                            </div>

                            <div className="flex justify-between items-center text-gray-500 pt-2 border-t border-gray-200">
                              <span>Finding ID: <code className="font-mono text-gray-700">{f.id}</code></span>
                              <span>Detected at: {formatDate(f.detected_at)}</span>
                            </div>
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
          <div className="py-12 text-center border-2 border-dashed border-gray-200 rounded-lg">
            <svg className="w-12 h-12 text-gray-300 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path>
            </svg>
            <h4 className="text-base font-semibold text-gray-900 mb-1">
              {findings.length === 0 ? 'No Vulnerabilities Found' : 'No Matching Findings'}
            </h4>
            <p className="text-xs text-gray-500 max-w-sm mx-auto">
              {findings.length === 0 
                ? 'No security vulnerabilities or headers weaknesses were recorded for this target.' 
                : 'Try adjusting your severity filter or search keywords.'}
            </p>
          </div>
        )}
      </section>

      {/* Cancellation Modal */}
      {showCancelModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto" role="dialog" aria-modal="true">
          <div className="flex items-center justify-center min-h-screen px-4 text-center">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={() => !cancelling && setShowCancelModal(false)}></div>
            <div className="inline-block bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:max-w-lg w-full z-10 p-6 space-y-4">
              <div className="flex items-start gap-3">
                <div className="p-2 bg-red-100 rounded-full text-red-600 shrink-0">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
                  </svg>
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900">Cancel Security Assessment</h3>
                  <p className="text-sm text-gray-500 mt-1">
                    Are you sure you want to stop this scan? Analysis will halt immediately, and any findings identified up to this point will be retained.
                  </p>
                </div>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  disabled={cancelling}
                  onClick={() => setShowCancelModal(false)}
                  className="px-4 py-2 bg-white border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Keep Running
                </button>
                <button
                  type="button"
                  disabled={cancelling}
                  onClick={handleCancel}
                  className="px-4 py-2 bg-red-600 rounded-md text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
                >
                  {cancelling ? 'Cancelling...' : 'Confirm Cancellation'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}