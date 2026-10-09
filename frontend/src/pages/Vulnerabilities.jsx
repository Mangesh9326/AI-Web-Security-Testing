import React, { useEffect, useState } from 'react';
import { getAllFindings } from '../services/scanService';
import { ShieldAlert, Search, RefreshCw, AlertCircle, AlertTriangle, Bug, Info, ArrowUpRight, ChevronDown, ChevronUp, Globe } from 'lucide-react';
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

  // Default to the first website if "all" is selected, to prevent showing everything at once
  useEffect(() => {
    if (websiteFilter === 'all' && allWebsites.length > 0) {
      setWebsiteFilter(allWebsites[0]);
    }
  }, [allWebsites, websiteFilter]);

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
    const target = finding.target_url || finding.affected_url || 'Unknown Website';
    let website = target;
    try {
      website = new URL(target).origin;
    } catch {
      // Ignore if not a valid URL
    }
    if (!acc[website]) acc[website] = [];
    acc[website].push(finding);
    return acc;
  }, {});

  const toggleExpand = (id) => {
    setExpandedId(expandedId === id ? null : id);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
            <ShieldAlert className="h-8 w-8 text-brand-500" />
            Findings & Vulnerabilities
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            A consolidated view of all discovered security issues across your applications.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={load} className="btn-secondary" title="Refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="card">
        <div className="card-header flex flex-col sm:flex-row justify-between gap-4 items-center">
          <div className="relative w-full sm:max-w-xs">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-4 w-4 text-slate-500" aria-hidden="true" />
            </div>
            <input
              type="text"
              className="block w-full rounded-md border-0 bg-slate-900 py-1.5 pl-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
              placeholder="Search findings, URLs, descriptions..."
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
                              <td colSpan={5} className="bg-slate-950 p-0 border-b border-slate-700 inset-shadow">
                                <div className="p-6 md:pl-24 space-y-6">
                                  
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

                                  {finding.remediation && (
                                    <div>
                                      <h4 className="text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">Remediation Recommendation</h4>
                                      <div className="text-sm text-slate-300 leading-relaxed bg-brand-900/20 p-4 rounded-md border border-brand-500/20">
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