import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { getScan, getScanFindings } from '../services/scanService';
import { 
  ArrowLeft, RefreshCw, AlertCircle, CheckCircle2, XCircle, 
  ShieldAlert, Target, Clock, Activity, FileText, Bug, 
  Globe, Server, ChevronDown, ChevronUp, Settings as SettingsIcon 
} from 'lucide-react';

const StatusBadge = ({ status }) => {
  if (!status) return null;
  const styles = {
    completed: 'bg-green-500/10 text-green-400 ring-green-500/20',
    failed: 'bg-red-500/10 text-red-400 ring-red-500/20',
    running: 'bg-brand-500/10 text-brand-400 ring-brand-500/20 animate-pulse',
    pending: 'bg-yellow-500/10 text-yellow-400 ring-yellow-500/20',
  };
  const icon = {
    completed: <CheckCircle2 className="h-4 w-4 mr-1.5" />,
    failed: <XCircle className="h-4 w-4 mr-1.5" />,
    running: <RefreshCw className="h-4 w-4 mr-1.5 animate-spin" />,
    pending: <Clock className="h-4 w-4 mr-1.5" />,
  };
  
  return (
    <span className={`inline-flex items-center rounded-md px-2.5 py-1 text-sm font-medium ring-1 ring-inset capitalize ${styles[status.toLowerCase()] || styles.pending}`}>
      {icon[status.toLowerCase()] || icon.pending}
      {status}
    </span>
  );
};

const SeverityBadge = ({ severity }) => {
  const styles = {
    critical: 'bg-red-500/10 text-red-500 ring-red-500/20',
    high: 'bg-orange-500/10 text-orange-500 ring-orange-500/20',
    medium: 'bg-yellow-500/10 text-yellow-500 ring-yellow-500/20',
    low: 'bg-blue-500/10 text-blue-500 ring-blue-500/20',
    info: 'bg-slate-500/10 text-slate-400 ring-slate-500/20',
  };
  return (
    <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset capitalize ${styles[severity?.toLowerCase()] || styles.info}`}>
      {severity}
    </span>
  );
};

export default function ScanDetails() {
  const { id } = useParams();
  const [scan, setScan] = useState(null);
  const [findings, setFindings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [findingsLoading, setFindingsLoading] = useState(false);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('summary');
  const [expandedRows, setExpandedRows] = useState(new Set());

  const load = () => {
    setLoading(true);
    setError('');
    getScan(id)
      .then((res) => {
        const scanData = res.scan || res.data || res;
        setScan(Array.isArray(scanData) ? scanData[0] : scanData);
      })
      .catch((e) => setError(e.response?.data?.error || e.message || 'Unable to load scan details.'))
      .finally(() => setLoading(false));
  };

  const loadFindings = () => {
    setFindingsLoading(true);
    getScanFindings(id)
      .then((res) => {
         const data = res.findings || res.data || res;
         setFindings(Array.isArray(data) ? data : []);
      })
      .catch((e) => console.error("Failed to load findings", e))
      .finally(() => setFindingsLoading(false));
  };

  useEffect(() => {
    load();
    // Auto-refresh if running
    let interval;
    if (scan?.status === 'running' || scan?.status === 'pending') {
      interval = setInterval(load, 5000);
    }
    return () => clearInterval(interval);
  }, [id, scan?.status]);

  useEffect(() => {
    if (activeTab === 'findings' && scan && findings.length === 0) {
      loadFindings();
    }
  }, [activeTab, scan]);

  const toggleRow = (findingId) => {
    const newExpanded = new Set(expandedRows);
    if (newExpanded.has(findingId)) {
      newExpanded.delete(findingId);
    } else {
      newExpanded.add(findingId);
    }
    setExpandedRows(newExpanded);
  };

  if (loading && !scan) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <RefreshCw className="h-10 w-10 animate-spin text-brand-500" />
      </div>
    );
  }

  if (error && !scan) {
    return (
      <div className="p-6 bg-red-500/10 border border-red-500/50 rounded-lg flex items-start gap-4">
        <AlertCircle className="h-6 w-6 text-red-500 mt-0.5" />
        <div>
          <h3 className="text-base font-semibold text-red-500">Error Loading Scan</h3>
          <p className="mt-1 text-sm text-red-400">{error}</p>
          <button onClick={load} className="mt-4 btn-danger text-sm py-1.5">Retry</button>
        </div>
      </div>
    );
  }

  if (!scan) return null;

  return (
    <div className="space-y-6">
      
      {/* Header */}
      <div>
        <Link to="/scans" className="text-sm font-medium text-slate-400 hover:text-white flex items-center mb-4 transition-colors">
          <ArrowLeft className="h-4 w-4 mr-1" /> Back to Scans
        </Link>
        <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
          <div>
            <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
              Scan Details
            </h2>
            <p className="mt-1 text-sm text-slate-400 font-mono">
              ID: {scan.id}
            </p>
          </div>
          <div className="flex items-center gap-3">
            <StatusBadge status={scan.status} />
            <button onClick={load} className="btn-secondary" title="Refresh">
              <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Meta Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-slate-900 border border-slate-800 rounded-lg p-5 flex items-start gap-4 shadow-sm">
          <div className="bg-brand-500/10 p-2.5 rounded-lg border border-brand-500/20">
            <Target className="h-6 w-6 text-brand-500" />
          </div>
          <div className="min-w-0">
            <p className="text-sm font-medium text-slate-400">Target</p>
            <p className="mt-1 text-base font-semibold text-white truncate" title={scan.target_url}>
              {scan.target_url}
            </p>
          </div>
        </div>
        
        <div className="bg-slate-900 border border-slate-800 rounded-lg p-5 flex items-start gap-4 shadow-sm">
          <div className="bg-blue-500/10 p-2.5 rounded-lg border border-blue-500/20">
            <Activity className="h-6 w-6 text-blue-500" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-400">Scan Profile</p>
            <p className="mt-1 text-base font-semibold text-white capitalize">{scan.scan_type || 'Active'}</p>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 rounded-lg p-5 flex items-start gap-4 shadow-sm">
          <div className="bg-slate-800 p-2.5 rounded-lg border border-slate-700">
            <Clock className="h-6 w-6 text-slate-300" />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-400">Started At</p>
            <p className="mt-1 text-base font-semibold text-white">
              {new Date(scan.created_at).toLocaleString()}
            </p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-slate-800">
        <nav className="-mb-px flex space-x-8" aria-label="Tabs">
          <button
            onClick={() => setActiveTab('summary')}
            className={`whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium flex items-center gap-2 ${
              activeTab === 'summary'
                ? 'border-brand-500 text-brand-400'
                : 'border-transparent text-slate-400 hover:border-slate-700 hover:text-slate-300'
            }`}
          >
            <FileText className="h-4 w-4" /> Summary
          </button>
          <button
            onClick={() => setActiveTab('findings')}
            className={`whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium flex items-center gap-2 ${
              activeTab === 'findings'
                ? 'border-brand-500 text-brand-400'
                : 'border-transparent text-slate-400 hover:border-slate-700 hover:text-slate-300'
            }`}
          >
            <ShieldAlert className="h-4 w-4" /> Findings
            {(scan.findings_count > 0 || scan.critical_count > 0) && (
               <span className="ml-2 py-0.5 px-2 rounded-full bg-slate-800 text-xs text-white">
                 {scan.findings_count || 0}
               </span>
            )}
          </button>
        </nav>
      </div>

      {/* Tab Content */}
      <div className="py-4">
        {activeTab === 'summary' && (
          <div className="space-y-6">
            
            {scan.error_message && (
               <div className="bg-red-500/10 border border-red-500/50 p-4 rounded-md flex items-start gap-3">
                 <AlertCircle className="h-5 w-5 text-red-500 flex-shrink-0 mt-0.5" />
                 <div>
                   <h3 className="text-sm font-medium text-red-500">Scan Failed with Error</h3>
                   <p className="text-sm text-red-400 mt-1">{scan.error_message}</p>
                 </div>
               </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              
              {/* Execution Metrics */}
              <div className="card">
                <div className="card-header border-b border-slate-800 pb-4">
                  <h3 className="text-base font-semibold text-white flex items-center gap-2">
                    <Activity className="h-4 w-4 text-brand-500" /> Execution Metrics
                  </h3>
                </div>
                <div className="card-body py-4">
                  <dl className="divide-y divide-slate-800">
                    <div className="py-3 flex justify-between">
                      <dt className="text-sm font-medium text-slate-400">Pages Discovered</dt>
                      <dd className="text-sm font-semibold text-white">{scan.pages_discovered || 0}</dd>
                    </div>
                    <div className="py-3 flex justify-between">
                      <dt className="text-sm font-medium text-slate-400">Requests Analyzed</dt>
                      <dd className="text-sm font-semibold text-white">{scan.requests_analyzed || 0}</dd>
                    </div>
                    <div className="py-3 flex justify-between">
                      <dt className="text-sm font-medium text-slate-400">Endpoints Found</dt>
                      <dd className="text-sm font-semibold text-white">{scan.endpoints_found || 0}</dd>
                    </div>
                    <div className="py-3 flex justify-between">
                      <dt className="text-sm font-medium text-slate-400">Total Findings</dt>
                      <dd className="text-sm font-semibold text-brand-400">{scan.findings_count || 0}</dd>
                    </div>
                    {scan.completed_at && (
                      <div className="py-3 flex justify-between">
                        <dt className="text-sm font-medium text-slate-400">Completed At</dt>
                        <dd className="text-sm font-semibold text-white">{new Date(scan.completed_at).toLocaleString()}</dd>
                      </div>
                    )}
                  </dl>
                </div>
              </div>

              {/* Scan Configuration Details */}
              <div className="card">
                <div className="card-header border-b border-slate-800 pb-4">
                  <h3 className="text-base font-semibold text-white flex items-center gap-2">
                    <SettingsIcon className="h-4 w-4 text-slate-400" /> Configuration Used
                  </h3>
                </div>
                <div className="card-body p-0">
                  <div className="p-4 bg-slate-950 rounded-b-lg overflow-x-auto h-full">
                    <pre className="text-xs font-mono text-slate-300 whitespace-pre-wrap">
                      {typeof scan.scan_config === 'object' 
                        ? JSON.stringify(scan.scan_config, null, 2) 
                        : (scan.scan_config || 'No configuration data available')}
                    </pre>
                  </div>
                </div>
              </div>

            </div>
          </div>
        )}

        {activeTab === 'findings' && (
          <div className="space-y-4">
             {findingsLoading ? (
               <div className="flex h-32 items-center justify-center">
                 <RefreshCw className="h-6 w-6 animate-spin text-brand-500" />
               </div>
             ) : findings.length === 0 ? (
               <div className="card">
                 <div className="card-body p-12 text-center text-slate-400">
                    <ShieldAlert className="h-12 w-12 mx-auto text-slate-600 mb-4" />
                    <h3 className="text-base font-semibold text-white mb-2">No findings yet</h3>
                    <p className="text-sm">
                      {scan.status === 'completed' 
                         ? 'This scan did not produce any vulnerability findings.' 
                         : 'Findings will appear here once the scan progresses.'}
                    </p>
                 </div>
               </div>
             ) : (
               <div className="card overflow-hidden">
                 <div className="overflow-x-auto">
                   <table className="table w-full">
                     <thead>
                       <tr>
                         <th>Vulnerability</th>
                         <th>Severity</th>
                         <th>Category</th>
                         <th>Endpoint</th>
                       </tr>
                     </thead>
                     <tbody className="divide-y divide-slate-800">
                       {findings.map((finding) => (
                         <React.Fragment key={finding.id}>
                           <tr 
                             className="hover:bg-slate-800/50 cursor-pointer transition-colors"
                             onClick={() => toggleRow(finding.id)}
                           >
                             <td className="font-medium text-white flex items-center gap-2">
                               {expandedRows.has(finding.id) ? (
                                 <ChevronUp className="h-4 w-4 text-slate-400" />
                               ) : (
                                 <ChevronDown className="h-4 w-4 text-slate-400" />
                               )}
                               {finding.title || finding.vulnerability_type || 'Unknown Vulnerability'}
                             </td>
                             <td><SeverityBadge severity={finding.severity} /></td>
                             <td className="text-slate-400 capitalize">{finding.vulnerability_type?.replace(/_/g, ' ') || 'N/A'}</td>
                             <td className="text-slate-400 truncate max-w-[200px]" title={finding.affected_url}>
                               {finding.affected_url || scan.target_url}
                             </td>
                           </tr>
                           
                           {/* Expanded Details Row */}
                           {expandedRows.has(finding.id) && (
                             <tr>
                               <td colSpan={4} className="p-0 border-0">
                                 <div className="bg-slate-900/50 p-6 border-b border-slate-800 inset-shadow">
                                   <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                     <div>
                                       <h4 className="text-sm font-semibold text-slate-200 mb-2">Description</h4>
                                       <p className="text-sm text-slate-400 leading-relaxed">
                                         {finding.description || 'No description provided.'}
                                       </p>
                                     </div>
                                     <div>
                                       <h4 className="text-sm font-semibold text-slate-200 mb-2">Remediation</h4>
                                       <p className="text-sm text-slate-400 leading-relaxed">
                                         {finding.remediation || 'No remediation provided.'}
                                       </p>
                                     </div>
                                   </div>
                                 </div>
                               </td>
                             </tr>
                           )}
                         </React.Fragment>
                       ))}
                     </tbody>
                   </table>
                 </div>
               </div>
             )}
          </div>
        )}
      </div>

    </div>
  );
}