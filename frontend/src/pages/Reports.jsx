import React, { useEffect, useState } from 'react';
import { getScans } from '../services/scanService';
import { FileText, Download, RefreshCw, AlertCircle, Calendar } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function Reports() {
  const [scans, setScans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = () => {
    setLoading(true);
    setError('');
    getScans()
      .then((res) => {
        const data = res.scans || res.data || res;
        const scansArray = Array.isArray(data) ? data : [];
        const finishedScans = scansArray.filter(s => s.status === 'completed' || s.status === 'failed');
        setScans(finishedScans);
      })
      .catch((e) => setError(e.response?.data?.error || e.message || 'Unable to load scans for reporting.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  const handleDownload = (scanId) => {
    // Placeholder for PDF generation/download logic
    alert(`Report generation for scan #${scanId} is not yet implemented in the backend.`);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
            <FileText className="h-8 w-8 text-brand-500" />
            Security Reports
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            Generate and download executive and technical security reports for completed scans.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={load} className="btn-secondary" title="Refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
           <h3 className="text-base font-semibold text-white">Available Reports</h3>
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
              <p>Loading available reports...</p>
            </div>
          ) : scans.length > 0 ? (
            <table className="table">
              <thead>
                <tr>
                  <th>Report Target</th>
                  <th>Scan Date</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {scans.map((scan) => (
                  <tr key={scan.id}>
                    <td className="font-medium text-white max-w-xs truncate" title={scan.target_url}>
                      {scan.target_url}
                      <div className="text-xs text-slate-500 font-mono mt-1">Scan ID: {scan.id}</div>
                    </td>
                    <td className="text-slate-400 whitespace-nowrap">
                       <div className="flex items-center gap-1.5">
                         <Calendar className="h-4 w-4 text-slate-500" />
                         {new Date(scan.created_at).toLocaleDateString()}
                       </div>
                    </td>
                    <td>
                      <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${
                        scan.status === 'completed' ? 'bg-green-400/10 text-green-400 ring-green-400/20' :
                        'bg-red-400/10 text-red-400 ring-red-400/20'
                      }`}>
                        {scan.status}
                      </span>
                    </td>
                    <td>
                      <div className="flex items-center gap-3">
                        <Link 
                          to={`/scan/${scan.id}`} 
                          className="text-brand-400 hover:text-brand-300 font-medium text-sm"
                        >
                          View Online
                        </Link>
                        <button 
                          onClick={() => handleDownload(scan.id)}
                          className="text-slate-400 hover:text-white font-medium text-sm inline-flex items-center gap-1"
                        >
                          <Download className="h-4 w-4" /> PDF
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="p-16 text-center">
              <FileText className="mx-auto h-12 w-12 text-slate-600 mb-4" />
              <h3 className="mt-2 text-sm font-semibold text-white">No reports available</h3>
              <p className="mt-1 text-sm text-slate-400">
                Complete a scan to generate a report.
              </p>
              <div className="mt-6">
                <Link to="/new-scan" className="btn-primary inline-flex items-center">
                  Start a Scan
                </Link>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}