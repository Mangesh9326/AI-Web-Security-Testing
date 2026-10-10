import React, { useEffect, useState } from 'react';
import { getAllFindings } from '../services/scanService';
import { Search, RefreshCw, AlertCircle, Clock, ExternalLink, ShieldAlert, CheckCircle2, SlidersHorizontal, Eye, Filter } from 'lucide-react';
import { Link } from 'react-router-dom';

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
    <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset capitalize ${style}`}>
      {severity}
    </span>
  );
};

const StatusBadge = ({ status }) => {
  const styles = {
    open: 'bg-blue-500/10 text-blue-400 ring-blue-500/20',
    in_progress: 'bg-yellow-500/10 text-yellow-400 ring-yellow-500/20',
    resolved: 'bg-green-500/10 text-green-400 ring-green-500/20',
    ignored: 'bg-slate-500/10 text-slate-400 ring-slate-500/20'
  };
  const style = styles[status?.toLowerCase()] || 'bg-slate-500/10 text-slate-400 ring-slate-500/20';
  return (
    <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset capitalize ${style}`}>
      {status ? status.replace('_', ' ') : 'Unknown'}
    </span>
  );
};

export default function Findings() {
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');

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

  const filteredFindings = findings.filter(f => {
    const matchesSearch = 
      (f.title || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
      (f.vulnerability_type || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (f.affected_url || '').toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesSev = severityFilter === 'all' || f.severity?.toLowerCase() === severityFilter;
    const matchesStatus = statusFilter === 'all' || f.status?.toLowerCase() === statusFilter;
    
    return matchesSearch && matchesSev && matchesStatus;
  });

  return (
    <div className="space-y-6 h-[calc(100vh-120px)] flex flex-col">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
            <CheckCircle2 className="h-8 w-8 text-brand-500" />
            Security Findings
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            A flat, searchable log of all discovered security findings across all scans and websites.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={load} className="btn-secondary flex items-center gap-2" title="Refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      <div className="card flex flex-col flex-1 min-h-0">
        <div className="card-header flex flex-col md:flex-row justify-between gap-4 items-center bg-slate-900 border-b border-slate-800">
          <div className="relative w-full md:max-w-md">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-4 w-4 text-slate-500" aria-hidden="true" />
            </div>
            <input
              type="text"
              className="block w-full rounded-md border-0 bg-slate-950 py-1.5 pl-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
              placeholder="Search by title, type, or URL..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <div className="w-full md:w-auto flex flex-col sm:flex-row gap-3">
            <div className="flex items-center gap-2 bg-slate-950 rounded-md ring-1 ring-inset ring-slate-700 px-3 py-1.5">
              <SlidersHorizontal className="h-4 w-4 text-slate-500" />
              <select
                value={severityFilter}
                onChange={(e) => setSeverityFilter(e.target.value)}
                className="bg-transparent border-0 text-white sm:text-sm focus:ring-0 p-0 pr-6"
              >
                <option value="all">All Severities</option>
                <option value="critical">Critical</option>
                <option value="high">High</option>
                <option value="medium">Medium</option>
                <option value="low">Low</option>
                <option value="info">Info</option>
              </select>
            </div>
            
            <div className="flex items-center gap-2 bg-slate-950 rounded-md ring-1 ring-inset ring-slate-700 px-3 py-1.5">
              <Filter className="h-4 w-4 text-slate-500" />
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="bg-transparent border-0 text-white sm:text-sm focus:ring-0 p-0 pr-6"
              >
                <option value="all">All Statuses</option>
                <option value="open">Open</option>
                <option value="in_progress">In Progress</option>
                <option value="resolved">Resolved</option>
                <option value="ignored">Ignored</option>
              </select>
            </div>
          </div>
        </div>
        
        <div className="flex-1 overflow-auto">
          {error && (
            <div className="p-4 bg-red-500/10 border-b border-red-500/50 flex items-center gap-3 m-4 rounded-md">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <p className="text-sm text-red-500">{error}</p>
            </div>
          )}

          {loading && findings.length === 0 ? (
            <div className="p-20 text-center text-slate-400">
              <RefreshCw className="h-8 w-8 animate-spin mx-auto text-brand-500 mb-4" />
              <p>Loading findings repository...</p>
            </div>
          ) : filteredFindings.length > 0 ? (
            <table className="table w-full m-0 border-0">
              <thead className="sticky top-0 bg-slate-900 z-10 shadow-sm border-b border-slate-700">
                <tr>
                  <th className="border-y-0 px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Severity</th>
                  <th className="border-y-0 px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Finding & Type</th>
                  <th className="border-y-0 px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Status</th>
                  <th className="border-y-0 px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Detected</th>
                  <th className="border-y-0 px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {filteredFindings.map((finding) => (
                  <tr key={finding.id} className="hover:bg-slate-800/50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <SeverityBadge severity={finding.severity} />
                    </td>
                    <td className="px-6 py-4">
                      <div className="font-medium text-white max-w-lg truncate" title={finding.title || finding.vulnerability_type}>
                        {finding.title || finding.vulnerability_type?.replace(/_/g, ' ') || 'Unknown Issue'}
                      </div>
                      <div className="text-xs text-slate-500 mt-1 flex items-center gap-2">
                        {finding.cwe_id && <span className="bg-slate-800 px-1.5 py-0.5 rounded text-[10px] uppercase font-mono">{finding.cwe_id}</span>}
                        <span className="truncate max-w-md">{finding.affected_url || finding.target_url || 'N/A'}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <StatusBadge status={finding.status || 'open'} />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-400">
                      <div className="flex items-center gap-1.5">
                        <Clock className="h-3.5 w-3.5" />
                        {new Date(finding.detected_at || finding.created_at).toLocaleDateString()}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right">
                      <Link 
                        to={`/scan/${finding.scan_id}`} 
                        className="inline-flex items-center gap-1.5 rounded bg-brand-500/10 px-3 py-1.5 text-xs font-medium text-brand-400 hover:bg-brand-500/20 transition-colors"
                      >
                        <Eye className="h-3.5 w-3.5" />
                        Details
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="p-16 text-center">
              <ShieldAlert className="mx-auto h-12 w-12 text-slate-600 mb-4" />
              <h3 className="mt-2 text-sm font-semibold text-white">No findings to display</h3>
              <p className="mt-1 text-sm text-slate-400">
                {searchTerm || severityFilter !== 'all' || statusFilter !== 'all' ? 'Try adjusting your filters.' : 'The scan repository is empty.'}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
