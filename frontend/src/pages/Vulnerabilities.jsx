import React, { useEffect, useState } from 'react';
import { getAllFindings } from '../services/scanService';
import { analyzeVulnerability, generateSecurityOverview } from '../services/aiService';
import { ShieldAlert, Search, RefreshCw, AlertCircle, AlertTriangle, Bug, Info, ArrowUpRight, ChevronDown, ChevronUp, Globe, BrainCircuit, CheckCircle2 } from 'lucide-react';
import { Link } from 'react-router-dom';

const SeverityIcon = ({ severity }) => {
  switch(severity?.toLowerCase()) {
    case 'critical': return <ShieldAlert className="h-4 w-4 text-red-500" />;
    case 'high': return <AlertTriangle className="h-4 w-4 text-orange-500" />;
    case 'medium': return <AlertTriangle className="h-4 w-4 text-yellow-500" />;
    case 'low': return <Bug className="h-4 w-4 text-blue-500" />;
    case 'info': return <Info className="h-4 w-4 text-cyan-500" />;
    default: return <Info className="h-4 w-4 text-slate-500" />;
  }
};

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
      <SeverityIcon severity={severity} />
      {severity}
    </span>
  );
};

export default function Vulnerabilities() {
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState('all');
  const [websiteFilter, setWebsiteFilter] = useState('all');
  const [expandedId, setExpandedId] = useState(null);

  // AI States
  const [overview, setOverview] = useState(null);
  const [overviewLoading, setOverviewLoading] = useState(false);
  const [overviewError, setOverviewError] = useState('');
  
  const [aiAnalysis, setAiAnalysis] = useState({}); // { [findingId]: { data: object, loading: boolean, error: string } }

  const load = () => {
    setLoading(true);
    setError('');
    getAllFindings()
      .then((res) => {
        const data = res.findings || res.data || res;
        setFindings(Array.isArray(data) ? data : []);
      })
      .catch((e) => setError(e.response?.data?.error || e.message || 'Unable to load findings.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  const allWebsites = React.useMemo(() => {
    const sites = new Set();
    findings.forEach(f => {
      const target = f.target_url || f.affected_url || 'Unknown Website';
      try { sites.add(new URL(target).origin); }
      catch { sites.add(target); }
    });
    return Array.from(sites).sort();
  }, [findings]);

  // Removed the useEffect that overrides "all" with the first website

  const filteredFindings = findings.filter(f => {
    const matchesSearch = 
      (f.title || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
      (f.description || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (f.affected_url || '').toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesSev = severityFilter === 'all' || f.severity?.toLowerCase() === severityFilter;
    
    let website = f.target_url || f.affected_url || 'Unknown Website';
    try { website = new URL(website).origin; } catch {}
    const matchesWebsite = websiteFilter === 'all' || website === websiteFilter;
    
    return matchesSearch && matchesSev && matchesWebsite;
  });

  const groupedFindings = filteredFindings.reduce((acc, finding) => {
    let website = finding.target_url || finding.affected_url || 'Unknown Website';
    try { website = new URL(website).origin; } catch {}
    
    if (!acc[website]) acc[website] = [];
    acc[website].push(finding);
    return acc;
  }, {});

  const toggleExpand = (id) => {
    setExpandedId(expandedId === id ? null : id);
  };

  const handleGenerateOverview = async () => {
    setOverviewLoading(true);
    setOverviewError('');
    try {
      const res = await generateSecurityOverview();
      setOverview(res.overview);
    } catch (e) {
      setOverviewError(e.response?.data?.error || e.message || 'Unable to generate AI overview.');
    } finally {
      setOverviewLoading(false);
    }
  };

  const handleAnalyzeFinding = async (id) => {
    if (aiAnalysis[id]?.loading) return; // Prevent duplicate requests
    
    setAiAnalysis(prev => ({
      ...prev,
      [id]: { ...prev[id], loading: true, error: '' }
    }));
    
    try {
      const res = await analyzeVulnerability(id);
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
            <ShieldAlert className="h-8 w-8 text-brand-500" />
            Vulnerabilities
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            Discovered security flaws grouped by target website.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <button onClick={handleGenerateOverview} className="btn-primary flex items-center gap-2" disabled={overviewLoading || findings.length === 0}>
            {overviewLoading ? <RefreshCw className="h-4 w-4 animate-spin" /> : <BrainCircuit className="h-4 w-4" />}
            Generate Security Insights
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
            <h3 className="text-lg font-semibold text-brand-100">AI Security Overview</h3>
            <span className="ml-auto text-xs font-mono bg-brand-500/20 text-brand-300 px-2 py-0.5 rounded">AI-Generated Advisory</span>
          </div>
          <div className="p-6">
            {overviewLoading ? (
              <div className="flex flex-col items-center justify-center py-8 text-brand-300">
                <RefreshCw className="h-8 w-8 animate-spin mb-3" />
                <p>Analyzing workspace vulnerabilities...</p>
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
                    <h4 className="text-sm font-semibold text-brand-300 uppercase tracking-wider mb-2">Priority Actions</h4>
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
                    <h4 className="text-sm font-semibold text-brand-300 uppercase tracking-wider mb-2">Common Patterns & Insights</h4>
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

      <div className="card">
        <div className="card-header flex flex-col md:flex-row justify-between gap-4 items-center">
          <div className="relative w-full md:max-w-xs">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-4 w-4 text-slate-500" aria-hidden="true" />
            </div>
            <input
              type="text"
              className="block w-full rounded-md border-0 bg-slate-900 py-1.5 pl-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
              placeholder="Search findings..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="w-full md:w-auto flex flex-col sm:flex-row gap-3">
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
        
        <div className="table-container bg-transparent">
          {error && (
            <div className="p-4 bg-red-500/10 border-b border-red-500/50 flex items-center gap-3">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <p className="text-sm text-red-500">{error}</p>
            </div>
          )}

          {loading && findings.length === 0 ? (
            <div className="p-12 text-center text-slate-400">
              <RefreshCw className="h-8 w-8 animate-spin mx-auto text-brand-500 mb-3" />
              <p>Loading findings...</p>
            </div>
          ) : filteredFindings.length > 0 ? (
            <div className="space-y-6">
              {Object.entries(groupedFindings).map(([website, siteFindings]) => (
                <div key={website} className="border border-slate-700 rounded-lg overflow-hidden bg-slate-900">
                  <div className="px-6 py-4 bg-slate-800/80 border-b border-slate-700 flex items-center justify-between">
                    <h3 className="text-base font-semibold text-white flex items-center gap-2">
                      <Globe className="h-5 w-5 text-brand-500" /> {website}
                    </h3>
                    <span className="text-xs font-medium text-slate-300 bg-slate-900 px-3 py-1 rounded-full border border-slate-700">
                      {siteFindings.length} {siteFindings.length === 1 ? 'Finding' : 'Findings'}
                    </span>
                  </div>
                  <table className="table w-full m-0">
                    <thead>
                      <tr className="bg-slate-900/50">
                        <th className="w-8 border-y-0"></th>
                        <th className="border-y-0">Severity</th>
                        <th className="border-y-0">AI Priority</th>
                        <th className="border-y-0">Title</th>
                        <th className="border-y-0">Affected URL</th>
                        <th className="border-y-0">Scan ID</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/50">
                      {siteFindings.map((finding) => (
                        <React.Fragment key={finding.id}>
                          <tr 
                            className={`cursor-pointer transition-colors hover:bg-slate-800/80 ${expandedId === finding.id ? 'bg-slate-800' : ''}`}
                            onClick={() => toggleExpand(finding.id)}
                          >
                            <td className="px-6 py-4 w-8 text-slate-400">
                              {expandedId === finding.id ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <SeverityBadge severity={finding.severity} />
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              {aiAnalysis[finding.id]?.data?.priority ? (
                                <span className="inline-flex items-center rounded-md bg-brand-500/10 px-2 py-1 text-xs font-medium text-brand-400 ring-1 ring-inset ring-brand-500/20">
                                  {aiAnalysis[finding.id].data.priority}
                                </span>
                              ) : (
                                <span className="text-slate-600 text-xs">-</span>
                              )}
                            </td>
                            <td className="px-6 py-4 font-medium text-white max-w-sm truncate" title={finding.title || finding.vulnerability_type}>
                              {finding.title || finding.vulnerability_type?.replace(/_/g, ' ') || 'Unknown Issue'}
                            </td>
                            <td className="px-6 py-4 text-slate-400 max-w-xs truncate" title={finding.affected_url}>
                              {finding.affected_url || 'N/A'}
                            </td>
                            <td className="px-6 py-4">
                              <Link 
                                to={`/scan/${finding.scan_id}`} 
                                className="text-brand-400 hover:text-brand-300 text-sm font-medium inline-flex items-center gap-1"
                                onClick={(e) => e.stopPropagation()}
                              >
                                View Scan <ArrowUpRight className="h-3 w-3" />
                              </Link>
                            </td>
                          </tr>
                          {expandedId === finding.id && (
                            <tr>
                              <td colSpan={6} className="bg-slate-950 p-0 border-b border-slate-700 inset-shadow">
                                <div className="p-6 md:pl-24 space-y-6">
                                  
                                  {/* Original Data Details */}
                                  <div>
                                    <h4 className="text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">Description</h4>
                                    <p className="text-sm text-slate-300 leading-relaxed max-w-4xl bg-slate-900 p-4 rounded-md border border-slate-800">
                                      {finding.description || 'No description provided.'}
                                    </p>
                                  </div>

                                  {finding.evidence && (
                                    <div>
                                      <h4 className="text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">Evidence</h4>
                                      <pre className="text-xs font-mono text-brand-300 bg-slate-900 p-4 rounded-md border border-slate-800 overflow-x-auto whitespace-pre-wrap">
                                        {finding.evidence}
                                      </pre>
                                    </div>
                                  )}

                                  {/* AI Analyst Section */}
                                  <div className="bg-brand-900/10 border border-brand-500/30 rounded-lg overflow-hidden mt-6">
                                    <div className="bg-brand-500/10 px-4 py-3 flex items-center justify-between border-b border-brand-500/20">
                                      <h4 className="text-sm font-semibold text-brand-300 flex items-center gap-2">
                                        <BrainCircuit className="h-4 w-4" /> AI Vulnerability Analyst
                                      </h4>
                                      {!aiAnalysis[finding.id] && (
                                        <button 
                                          onClick={(e) => { e.stopPropagation(); handleAnalyzeFinding(finding.id); }}
                                          className="text-xs bg-brand-500 hover:bg-brand-600 text-white px-3 py-1.5 rounded transition-colors"
                                        >
                                          Analyze with AI
                                        </button>
                                      )}
                                    </div>
                                    
                                    <div className="p-4">
                                      {!aiAnalysis[finding.id] ? (
                                        <p className="text-sm text-slate-400">Click analyze to generate an AI assessment of this finding.</p>
                                      ) : aiAnalysis[finding.id].loading ? (
                                        <div className="flex items-center gap-3 text-brand-400 text-sm py-2">
                                          <RefreshCw className="h-4 w-4 animate-spin" /> Analyzing vulnerability details...
                                        </div>
                                      ) : aiAnalysis[finding.id].error ? (
                                        <div className="text-sm text-red-400 flex items-start gap-2">
                                          <AlertCircle className="h-4 w-4 mt-0.5" />
                                          <div>
                                            <p>{aiAnalysis[finding.id].error}</p>
                                            <button 
                                              onClick={() => handleAnalyzeFinding(finding.id)}
                                              className="mt-2 text-red-400 underline"
                                            >
                                              Retry Analysis
                                            </button>
                                          </div>
                                        </div>
                                      ) : aiAnalysis[finding.id].data ? (
                                        <div className="space-y-5">
                                          <div>
                                            <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-1">AI Summary</h5>
                                            <p className="text-sm text-slate-300">{aiAnalysis[finding.id].data.aiSummary}</p>
                                          </div>
                                          
                                          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
                                            <div>
                                              <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-1">Risk Explanation</h5>
                                              <p className="text-sm text-slate-300">{aiAnalysis[finding.id].data.riskExplanation}</p>
                                            </div>
                                            <div>
                                              <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-1">Priority Justification ({aiAnalysis[finding.id].data.priority})</h5>
                                              <p className="text-sm text-slate-300">{aiAnalysis[finding.id].data.priorityReason}</p>
                                            </div>
                                          </div>

                                          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
                                            <div>
                                              <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-2">Remediation Plan</h5>
                                              <ul className="list-decimal pl-4 space-y-1">
                                                {aiAnalysis[finding.id].data.remediationPlan?.map((step, i) => (
                                                  <li key={i} className="text-sm text-slate-300">{step}</li>
                                                ))}
                                              </ul>
                                            </div>
                                            <div>
                                              <h5 className="text-xs font-semibold text-brand-300 uppercase tracking-wider mb-2">Validation Steps</h5>
                                              <ul className="list-disc pl-4 space-y-1">
                                                {aiAnalysis[finding.id].data.validationSteps?.map((step, i) => (
                                                  <li key={i} className="text-sm text-slate-300">{step}</li>
                                                ))}
                                              </ul>
                                            </div>
                                          </div>

                                          <div className="flex items-center gap-4 pt-2 border-t border-brand-500/20 text-xs">
                                            <span className="text-slate-400">Confidence: <span className="text-brand-300 font-medium">{aiAnalysis[finding.id].data.confidence}</span></span>
                                            {aiAnalysis[finding.id].data.limitations && (
                                              <span className="text-slate-400 truncate max-w-xl" title={aiAnalysis[finding.id].data.limitations}>
                                                Limitations: {aiAnalysis[finding.id].data.limitations}
                                              </span>
                                            )}
                                          </div>
                                        </div>
                                      ) : null}
                                    </div>
                                  </div>

                                  {finding.remediation && !aiAnalysis[finding.id]?.data && (
                                    <div>
                                      <h4 className="text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">Original Remediation Recommendation</h4>
                                      <div className="text-sm text-slate-300 leading-relaxed bg-slate-900 p-4 rounded-md border border-slate-800">
                                        {finding.remediation}
                                      </div>
                                    </div>
                                  )}
                                  
                                </div>
                              </td>
                            </tr>
                          )}
                        </React.Fragment>
                      ))}
                    </tbody>
                  </table>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-16 text-center">
              <ShieldAlert className="mx-auto h-12 w-12 text-slate-600 mb-4" />
              <h3 className="mt-2 text-sm font-semibold text-white">No findings</h3>
              <p className="mt-1 text-sm text-slate-400">
                {searchTerm || severityFilter !== 'all' ? 'No findings match your criteria.' : 'Great job! No vulnerabilities discovered.'}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}