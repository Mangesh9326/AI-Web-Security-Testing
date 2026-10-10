import React, { useEffect, useState } from 'react';
import { getTrafficLogs } from '../services/intrusionService';
import { getScans } from '../services/scanService';
import { FileText, Search, RefreshCw, AlertCircle, Clock, Server, Globe } from 'lucide-react';

export default function Logs() {
  const [logs, setLogs] = useState([]);
  const [allWebsites, setAllWebsites] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [websiteFilter, setWebsiteFilter] = useState('all');

  const load = () => {
    setLoading(true);
    setError('');
    
    Promise.all([
      getTrafficLogs(),
      getScans()
    ])
      .then(([logsRes, scansRes]) => {
        // Set Logs
        const logsData = logsRes.logs || logsRes.data || logsRes;
        setLogs(Array.isArray(logsData) ? logsData : []);

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
      .catch((e) => setError(e.response?.data?.error || e.message || 'Unable to load traffic logs.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  // Removed the useEffect that overrides "all" with the first website

  const filteredLogs = logs.filter(l => {
    const matchesSearch = 
      (l.source_ip || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
      (l.endpoint || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (l.method || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (l.user_agent || '').toLowerCase().includes(searchTerm.toLowerCase());
    
    let website = l.target_url || l.endpoint || 'Unknown Website';
    try { website = new URL(website).origin; } catch {}
    const matchesWebsite = websiteFilter === 'all' || website === websiteFilter;

    return matchesSearch && matchesWebsite;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
            <FileText className="h-8 w-8 text-brand-500" />
            System Traffic Logs
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            Raw traffic requests and connection logs analyzed by the system.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={load} className="btn-secondary" title="Refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="card">
        <div className="card-header flex flex-col md:flex-row justify-between gap-4 items-center">
          <div className="relative w-full md:max-w-xs">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-4 w-4 text-slate-500" aria-hidden="true" />
            </div>
            <input
              type="text"
              className="block w-full rounded-md border-0 bg-slate-900 py-1.5 pl-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
              placeholder="Search IPs, endpoints, methods..."
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
          </div>
        </div>
        
        <div className="table-container overflow-hidden">
          {error && (
            <div className="p-4 bg-red-500/10 border-b border-red-500/50 flex items-center gap-3">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <p className="text-sm text-red-500">{error}</p>
            </div>
          )}

          {loading && logs.length === 0 ? (
            <div className="p-12 text-center text-slate-400">
              <RefreshCw className="h-8 w-8 animate-spin mx-auto text-brand-500 mb-3" />
              <p>Loading traffic logs...</p>
            </div>
          ) : filteredLogs.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="table w-full">
                <thead>
                  <tr>
                    <th>Time</th>
                    <th>Source IP</th>
                    <th>Method</th>
                    <th>Endpoint</th>
                    <th>Status</th>
                    <th>User Agent</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800">
                  {filteredLogs.map((log) => (
                    <tr key={log.id} className="hover:bg-slate-800/50 transition-colors">
                      <td className="whitespace-nowrap text-slate-400">
                        {new Date(log.created_at).toLocaleString()}
                      </td>
                      <td className="font-mono text-brand-400">
                        {log.source_ip || 'N/A'}
                      </td>
                      <td>
                        <span className="bg-slate-800 text-slate-300 px-2 py-1 rounded text-xs font-mono">
                          {log.method || 'GET'}
                        </span>
                      </td>
                      <td className="text-slate-300 truncate max-w-[200px]" title={log.endpoint}>
                        {log.endpoint || log.target_url || 'N/A'}
                      </td>
                      <td>
                        <span className={`px-2 py-1 rounded text-xs font-mono ${
                          log.status_code >= 400 ? 'bg-red-500/10 text-red-400' :
                          log.status_code >= 300 ? 'bg-blue-500/10 text-blue-400' :
                          'bg-green-500/10 text-green-400'
                        }`}>
                          {log.status_code || 200}
                        </span>
                      </td>
                      <td className="text-slate-500 text-xs truncate max-w-[150px]" title={log.user_agent}>
                        {log.user_agent || 'N/A'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="p-16 text-center">
              <FileText className="mx-auto h-12 w-12 text-slate-600 mb-4" />
              <h3 className="mt-2 text-sm font-semibold text-white">No logs found</h3>
              <p className="mt-1 text-sm text-slate-400">
                {searchTerm || websiteFilter !== 'all' ? 'No traffic logs match your criteria.' : 'No traffic has been logged yet.'}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}