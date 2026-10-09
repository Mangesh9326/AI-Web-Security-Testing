import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getScans } from '../services/scanService';
import { ListOrdered, Search, RefreshCw, AlertCircle, Play, FileText, ChevronRight } from 'lucide-react';

export default function Scans() {
  const [scans, setScans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const load = () => {
    setLoading(true);
    setError('');
    getScans()
      .then((res) => {
        const data = res.scans || res.data || res;
        setScans(Array.isArray(data) ? data : []);
      })
      .catch((e) => setError(e.response?.data?.error || e.message || 'Unable to load scans.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  const filteredScans = scans.filter(scan => 
    scan.target_url?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    scan.status?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
            <ListOrdered className="h-8 w-8 text-brand-500" />
            Scan History
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            A complete log of all automated security scans performed across your workspaces.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={load} className="btn-secondary" title="Refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <Link to="/new-scan" className="btn-primary flex items-center gap-2">
            <Play className="h-4 w-4" /> New Scan
          </Link>
        </div>
      </div>

      <div className="card">
        <div className="card-header flex flex-col sm:flex-row justify-between gap-4">
          <div className="relative w-full sm:max-w-xs">
            <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
              <Search className="h-4 w-4 text-slate-500" aria-hidden="true" />
            </div>
            <input
              type="text"
              className="block w-full rounded-md border-0 bg-slate-900 py-1.5 pl-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
              placeholder="Search target URL or status..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
        
        <div className="table-container">
          {error && (
            <div className="p-4 bg-red-500/10 border-b border-red-500/50 flex items-center gap-3">
              <AlertCircle className="h-5 w-5 text-red-500" />
              <p className="text-sm text-red-500">{error}</p>
            </div>
          )}

          {loading && scans.length === 0 ? (
            <div className="p-12 text-center text-slate-400">
              <RefreshCw className="h-8 w-8 animate-spin mx-auto text-brand-500 mb-3" />
              <p>Loading scan history...</p>
            </div>
          ) : filteredScans.length > 0 ? (
            <table className="table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Target URL</th>
                  <th>Status</th>
                  <th>Type</th>
                  <th>Started</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredScans.map((scan) => (
                  <tr key={scan.id} className="group">
                    <td className="text-slate-500 font-mono text-xs">
                      #{scan.id.toString().substring(0, 8)}
                    </td>
                    <td className="font-medium text-white max-w-xs truncate" title={scan.target_url}>
                      {scan.target_url}
                    </td>
                    <td>
                      <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${
                        scan.status === 'completed' ? 'bg-green-400/10 text-green-400 ring-green-400/20' :
                        scan.status === 'failed' ? 'bg-red-400/10 text-red-400 ring-red-400/20' :
                        'bg-brand-400/10 text-brand-400 ring-brand-400/20'
                      }`}>
                        {scan.status}
                      </span>
                    </td>
                    <td className="capitalize text-slate-400">
                      {scan.scan_type || 'Active'}
                    </td>
                    <td className="text-slate-400" title={new Date(scan.created_at).toLocaleString()}>
                       {scan.created_at ? new Date(scan.created_at).toLocaleDateString() : 'N/A'}
                    </td>
                    <td>
                      <Link 
                        to={`/scan/${scan.id}`} 
                        className="text-brand-400 hover:text-brand-300 font-medium text-sm inline-flex items-center opacity-80 group-hover:opacity-100 transition-opacity"
                      >
                        View Results <ChevronRight className="h-4 w-4 ml-1" />
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="p-16 text-center">
              <FileText className="mx-auto h-12 w-12 text-slate-600 mb-4" />
              <h3 className="mt-2 text-sm font-semibold text-white">No scans found</h3>
              <p className="mt-1 text-sm text-slate-400">
                {searchTerm ? 'No scans match your search criteria.' : 'Get started by creating a new scan.'}
              </p>
              {!searchTerm && (
                <div className="mt-6">
                  <Link to="/new-scan" className="btn-primary inline-flex items-center">
                    <Play className="mr-2 h-4 w-4" /> Start Scan
                  </Link>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
