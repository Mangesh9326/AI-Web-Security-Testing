import React, { useEffect, useState } from 'react';
import { getAlerts } from '../services/intrusionService';
import { getScans } from '../services/scanService';
import { analyzeIntrusionAlert, generateIntrusionOverview } from '../services/aiService';
import { Activity, ShieldAlert, Search, RefreshCw, AlertCircle, Eye, AlertTriangle, Info, Clock, Server, BrainCircuit, CheckCircle2 } from 'lucide-react';

const SeverityBadge = ({ severity }) => {
  const styles = {
    critical: 'bg-red-500/10 text-red-400 ring-red-500/20',
    high: 'bg-orange-500/10 text-orange-400 ring-orange-500/20',
    medium: 'bg-yellow-500/10 text-yellow-400 ring-yellow-500/20',
    low: 'bg-blue-500/10 text-blue-400 ring-blue-500/20',
    info: 'bg-cyan-500/10 text-cyan-400 ring-cyan-500/20'
  };
  const style = styles[severity?.toLowerCase()] || 'bg-slate-500/10 text-slate-400 ring-slate-500/20';
  
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset capitalize ${style}`}>
      {severity}
    </span>
  );
};

export default function IntrusionDetection() {
  const [alerts, setAlerts] = useState([]);
  const [allWebsites, setAllWebsites] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState('all');
  const [websiteFilter, setWebsiteFilter] = useState('all');
  const [selectedAlert, setSelectedAlert] = useState(null);

  // AI States
  const [overview, setOverview] = useState(null);
  const [overviewLoading, setOverviewLoading] = useState(false);
  const [overviewError, setOverviewError] = useState('');
  const [aiAnalysis, setAiAnalysis] = useState({});

  const load = () => {
    setLoading(true);
    setError('');
    
    Promise.all([
      getAlerts(),
      getScans()
    ])
      .then(([alertsRes, scansRes]) => {
        // Set Alerts
        const alertsData = alertsRes.alerts || alertsRes.data || alertsRes;
        setAlerts(Array.isArray(alertsData) ? alertsData : []);

        // Build allWebsites globally from all scans
        const scansData = scansRes.scans || scansRes.data || scansRes;
        const scansArray = Array.isArray(scansData) ? scansData : [];
        const sites = new Set();
        scansArray.forEach(s => {
          const target = s.target_url;
          if (target) {
            try { sites.add(new URL(target).origin); }
            catch { sites.add(target); }
          }
        });
        setAllWebsites(Array.from(sites).sort());
      })
      .catch((e) => setError(e.response?.data?.error || e.message || 'Unable to load alerts.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  // Removed the useEffect that overrides "all" with the first website

  const filteredAlerts = alerts.filter(a => {
    const matchesSearch = 
      (a.classification || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
      (a.description || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (a.source_ip || '').toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesSev = severityFilter === 'all' || a.severity?.toLowerCase() === severityFilter;
    
    let website = a.target_url || a.endpoint || 'Unknown Website';
    try { website = new URL(website).origin; } catch {}
    const matchesWebsite = websiteFilter === 'all' || website === websiteFilter;
    
    return matchesSearch && matchesSev && matchesWebsite;
  });

  const handleGenerateOverview = async () => {
    setOverviewLoading(true);
    setOverviewError('');
    try {
      const res = await generateIntrusionOverview();
      setOverview(res.overview);
    } catch (e) {
      setOverviewError(e.response?.data?.error || e.message || 'Unable to generate AI SOC overview.');
    } finally {
      setOverviewLoading(false);
    }
  };

  const handleAnalyzeAlert = async (id) => {
    if (aiAnalysis[id]?.loading) return;
    
    setAiAnalysis(prev => ({
      ...prev,
      [id]: { ...prev[id], loading: true, error: '' }
    }));
    
    try {
      const res = await analyzeIntrusionAlert(id);
      setAiAnalysis(prev => ({
        ...prev,
        [id]: { data: res.analysis, loading: false, error: '' }
      }));
    } catch (e) {
      setAiAnalysis(prev => ({
        ...prev,
        [id]: { ...prev[id], loading: false, error: e.response?.data?.error || e.message || 'AI Analysis failed.' }
      }));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
            <Activity className="h-8 w-8 text-brand-500" />
            Intrusion Detection
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            Real-time security events and suspicious traffic.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <button onClick={handleGenerateOverview} className="btn-primary flex items-center gap-2" disabled={overviewLoading || alerts.length === 0}>
            {overviewLoading ? <RefreshCw className="h-4 w-4 animate-spin" /> : <BrainCircuit className="h-4 w-4" />}
            AI Threat Overview
          </button>
          <button onClick={load} className="btn-secondary" title="Refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* AI Security Overview Panel */}
      {(overview || overviewLoading || overviewError) && (
        <div className="card border-brand-500/30 bg-brand-900/10">
          <div className="px-6 py-4 border-b border-brand-500/20 flex items-center gap-2">
            <BrainCircuit className="h-5 w-5 text-brand-400" />
            <h3 className="text-lg font-semibold text-brand-100">AI Threat Overview</h3>
            <span className="ml-auto text-xs font-mono bg-brand-500/20 text-brand-300 px-2 py-0.5 rounded">AI-Generated Advisory</span>
          </div>
          <div className="p-6">
            {overviewLoading ? (
              <div className="flex flex-col items-center justify-center py-8 text-brand-300">
                <RefreshCw className="h-8 w-8 animate-spin mb-3" />
                <p>Analyzing intrusion alerts...</p>
              </div>
            ) : overviewError ? (
              <div className="p-4 bg-red-500/10 border-l-2 border-red-500 text-sm text-red-500">
                <p>{overviewError}</p>
                <button onClick={handleGenerateOverview} className="mt-2 text-red-400 hover:text-red-300 underline font-medium">Try Again</button>
              </div>
            ) : overview ? (
              <div className="space-y-6">
                <div>
                  <h4 className="text-sm font-semibold text-brand-300 uppercase tracking-wider mb-2">Overall Posture</h4>
                  <p className="text-slate-300 leading-relaxed bg-slate-900/50 p-4 rounded-md border border-slate-700">{overview.overallPosture}</p>
                </div>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h4 className="text-sm font-semibold text-brand-300 uppercase tracking-wider mb-2">Priority SOC Actions</h4>
                    <ul className="space-y-2">
                      {overview.priorityActions?.map((action, i) => (
                        <li key={i} className="flex items-start gap-2 text-sm text-slate-300">
                          <CheckCircle2 className="h-4 w-4 text-green-500 mt-0.5 flex-shrink-0" />
                          <span>{action}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                  <div>
                    <h4 className="text-sm font-semibold text-brand-300 uppercase tracking-wider mb-2">Common Attack Patterns</h4>
                    <ul className="space-y-2">
                      {overview.commonPatterns?.map((pattern, i) => (
                        <li key={i} className="flex items-start gap-2 text-sm text-slate-300">
                          <AlertTriangle className="h-4 w-4 text-orange-500 mt-0.5 flex-shrink-0" />
                          <span>{pattern}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>

                {overview.limitations && (
                  <div className="bg-slate-900/50 p-3 rounded border border-slate-800 flex items-start gap-2 mt-4">
                    <Info className="h-4 w-4 text-slate-400 mt-0.5 flex-shrink-0" />
                    <p className="text-xs text-slate-400">{overview.limitations}</p>
                  </div>
                )}
              </div>
            ) : null}
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        {/* Alerts List */}
        <div className="card flex flex-col h-[calc(100vh-200px)]">
          <div className="card-header flex flex-col sm:flex-row justify-between gap-4">
            <div className="relative w-full">
              <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                <Search className="h-4 w-4 text-slate-500" aria-hidden="true" />
              </div>
              <input
                type="text"
                className="block w-full rounded-md border-0 bg-slate-900 py-1.5 pl-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
                placeholder="Search alerts or IPs..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <div className="flex gap-2 w-full sm:w-auto">
              <select
                value={websiteFilter}
                onChange={(e) => setWebsiteFilter(e.target.value)}
                className="block w-full sm:w-48 rounded-md border-0 bg-slate-900 py-1.5 pl-3 pr-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6 truncate"
              >
                <option value="all">All Websites</option>
                {allWebsites.map(site => (
                  <option key={site} value={site}>{site}</option>
                ))}
              </select>
              <select
                value={severityFilter}
                onChange={(e) => setSeverityFilter(e.target.value)}
                className="block w-full sm:w-40 rounded-md border-0 bg-slate-900 py-1.5 pl-3 pr-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
              >
                <option value="all">All Severities</option>
                <option value="critical">Critical</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
                <option value="info">Info</option>
              </select>
            </div>
          </div>
          
          <div className="flex-1 overflow-y-auto bg-slate-900/50">
            {error && (
              <div className="p-4 bg-red-500/10 border-b border-red-500/50 flex items-center gap-3">
                <AlertCircle className="h-5 w-5 text-red-500" />
                <p className="text-sm text-red-500">{error}</p>
              </div>
            )}

            {loading && alerts.length === 0 ? (
              <div className="p-12 text-center text-slate-400">
                <RefreshCw className="h-8 w-8 animate-spin mx-auto text-brand-500 mb-3" />
                <p>Loading security events...</p>
              </div>
            ) : filteredAlerts.length > 0 ? (
              <ul className="divide-y divide-slate-800">
                {filteredAlerts.map((alert) => (
                  <li 
                    key={alert.id} 
                    className={`p-4 hover:bg-slate-800 cursor-pointer transition-colors ${selectedAlert?.id === alert.id ? 'bg-slate-800 border-l-2 border-brand-500' : 'border-l-2 border-transparent'}`}
                    onClick={() => setSelectedAlert(alert)}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <SeverityBadge severity={alert.severity} />
                        {aiAnalysis[alert.id]?.data?.priority && (
                          <span className="inline-flex items-center rounded-md bg-brand-500/10 px-2 py-0.5 text-[10px] font-medium text-brand-400 ring-1 ring-inset ring-brand-500/20">
                            {aiAnalysis[alert.id].data.priority}
                          </span>
                        )}
                        <span className="font-semibold text-white capitalize">{alert.classification || alert.rule_id || 'Unknown Event'}</span>
                      </div>
                      <span className="text-xs text-slate-500 flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        {new Date(alert.last_seen_at || alert.first_seen_at).toLocaleString()}
                      </span>
                    </div>
                    <div className="mt-2 text-sm text-slate-400 line-clamp-1">
                      {alert.description}
                    </div>
                    {alert.source_ip && (
                      <div className="mt-2 flex items-center gap-4 text-xs font-mono text-slate-500">
                        <span className="flex items-center gap-1"><Server className="h-3 w-3" /> SRC: {alert.source_ip}</span>
                        {(alert.endpoint || alert.target_url) && (
                          <span className="flex items-center gap-1 truncate"><Server className="h-3 w-3" /> TGT: {alert.endpoint || alert.target_url}</span>
                        )}
                      </div>
                    )}
                  </li>
                ))}
              </ul>
            ) : (
              <div className="p-16 text-center">
                <Activity className="mx-auto h-12 w-12 text-slate-600 mb-4" />
                <h3 className="mt-2 text-sm font-semibold text-white">No alerts found</h3>
                <p className="mt-1 text-sm text-slate-400">
                  Everything looks quiet.
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Alert Details Panel */}
        <div className="card h-[calc(100vh-200px)] overflow-y-auto hidden xl:block">
          <div className="card-header bg-slate-800/50 sticky top-0 backdrop-blur-md z-10">
            <h3 className="text-base font-semibold leading-6 text-white flex items-center gap-2">
              <Eye className="h-5 w-5 text-brand-500" />
              Investigation Details
            </h3>
          </div>
          <div className="p-6">
            {selectedAlert ? (
              <div className="space-y-6">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <SeverityBadge severity={selectedAlert.severity} />
                    <span className="text-xs text-slate-400">{new Date(selectedAlert.last_seen_at || selectedAlert.first_seen_at).toLocaleString()}</span>
                  </div>
                  <h4 className="text-xl font-bold text-white mb-4 capitalize">{selectedAlert.classification || selectedAlert.rule_id}</h4>
                  
                  <div className="bg-slate-900 rounded-md p-4 border border-slate-700">
                    <h5 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Description</h5>
                    <p className="text-sm text-slate-300">{selectedAlert.description || 'No description available.'}</p>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-slate-900 rounded-md p-4 border border-slate-700">
                    <h5 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Source IP</h5>
                    <p className="text-sm font-mono text-brand-400">{selectedAlert.source_ip || 'N/A'}</p>
                  </div>
                  <div className="bg-slate-900 rounded-md p-4 border border-slate-700 overflow-hidden">
                    <h5 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1">Target / Endpoint</h5>
                    <p className="text-sm font-mono text-brand-400 truncate" title={selectedAlert.endpoint || selectedAlert.target_url}>{selectedAlert.endpoint || selectedAlert.target_url || 'N/A'}</p>
                  </div>
                </div>

                {/* AI SOC Analyst Panel */}
                <div className="bg-brand-900/10 border border-brand-500/30 rounded-lg overflow-hidden mt-6">
                  <div className="bg-brand-500/10 px-4 py-3 flex items-center justify-between border-b border-brand-500/20">
                    <h4 className="text-sm font-semibold text-brand-300 flex items-center gap-2">
                      <BrainCircuit className="h-4 w-4" /> AI SOC Analyst
                    </h4>
                    {!aiAnalysis[selectedAlert.id] && (
                      <button 
                        onClick={() => handleAnalyzeAlert(selectedAlert.id)}
                        className="text-xs bg-brand-500 hover:bg-brand-600 text-white px-3 py-1.5 rounded transition-colors"
                      >
                        Analyze Alert
                      </button>
                    )}
                  </div>
                  
                  <div className="p-4">
                    {!aiAnalysis[selectedAlert.id] ? (
                      <p className="text-sm text-slate-400">Run an AI analysis to investigate this threat.</p>
                    ) : aiAnalysis[selectedAlert.id].loading ? (
                      <div className="flex items-center gap-3 text-brand-400 text-sm py-2">
                        <RefreshCw className="h-4 w-4 animate-spin" /> Analyzing intrusion telemetry...
                      </div>
                    ) : aiAnalysis[selectedAlert.id].error ? (
                      <div className="text-sm text-red-400 flex items-start gap-2">
                        <AlertCircle className="h-4 w-4 mt-0.5" />
                        <div>
                          <p>{aiAnalysis[selectedAlert.id].error}</p>
                          <button 
                            onClick={() => handleAnalyzeAlert(selectedAlert.id)}
                            className="mt-2 text-red-400 underline"
                          >
                            Retry Analysis
                          </button>
                        </div>
                      </div>
                    ) : aiAnalysis[selectedAlert.id].data ? (
                      <div className="space-y-5">
                        <div>
                          <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-1">Threat Summary</h5>
                          <p className="text-sm text-slate-300">{aiAnalysis[selectedAlert.id].data.aiSummary}</p>
                        </div>
                        
                        <div className="grid grid-cols-1 gap-5">
                          <div>
                            <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-1">Attack Scenario</h5>
                            <p className="text-sm text-slate-300">{aiAnalysis[selectedAlert.id].data.threatExplanation}</p>
                          </div>
                          <div>
                            <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-1">Priority Justification ({aiAnalysis[selectedAlert.id].data.priority})</h5>
                            <p className="text-sm text-slate-300">{aiAnalysis[selectedAlert.id].data.priorityReason}</p>
                          </div>
                        </div>

                        <div className="grid grid-cols-1 gap-5">
                          <div>
                            <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-2">Response Plan</h5>
                            <ul className="list-decimal pl-4 space-y-1">
                              {aiAnalysis[selectedAlert.id].data.responsePlan?.map((step, i) => (
                                <li key={i} className="text-sm text-slate-300">{step}</li>
                              ))}
                            </ul>
                          </div>
                          <div>
                            <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-2">Investigation Steps</h5>
                            <ul className="list-disc pl-4 space-y-1">
                              {aiAnalysis[selectedAlert.id].data.investigationSteps?.map((step, i) => (
                                <li key={i} className="text-sm text-slate-300">{step}</li>
                              ))}
                            </ul>
                          </div>
                        </div>

                        <div className="flex flex-col gap-1 pt-3 border-t border-brand-500/20 text-xs">
                          <span className="text-slate-400">Confidence: <span className="text-brand-300 font-medium">{aiAnalysis[selectedAlert.id].data.confidence}</span></span>
                          {aiAnalysis[selectedAlert.id].data.limitations && (
                            <span className="text-slate-400 max-w-full" title={aiAnalysis[selectedAlert.id].data.limitations}>
                              Limitations: {aiAnalysis[selectedAlert.id].data.limitations}
                            </span>
                          )}
                        </div>
                      </div>
                    ) : null}
                  </div>
                </div>

                {selectedAlert.evidence && (
                  <div>
                    <h5 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Evidence / Payload</h5>
                    <pre className="text-xs font-mono text-slate-300 bg-slate-950 p-4 rounded-md border border-slate-800 overflow-x-auto whitespace-pre-wrap">
                      {typeof selectedAlert.evidence === 'object' 
                        ? JSON.stringify(selectedAlert.evidence, null, 2) 
                        : selectedAlert.evidence}
                    </pre>
                  </div>
                )}
                
                <div className="pt-4 border-t border-slate-800 flex justify-end gap-2">
                  <button className="btn-secondary text-xs py-1.5">Acknowledge</button>
                  <button className="btn-danger text-xs py-1.5">Block IP</button>
                </div>
              </div>
            ) : (
              <div className="h-full flex flex-col items-center justify-center text-slate-500 mt-20">
                <Info className="h-12 w-12 mb-4 text-slate-600" />
                <p>Select an event to view details</p>
              </div>
            )}
          </div>
        </div>
        
      </div>
    </div>
  );
}