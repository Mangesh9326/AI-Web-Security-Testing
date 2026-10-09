import React, { useEffect, useState } from 'react';
import { getAlerts } from '../services/intrusionService';
import { Activity, ShieldAlert, Search, RefreshCw, AlertCircle, Eye, AlertTriangle, Info, Clock, Server } from 'lucide-react';

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
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [severityFilter, setSeverityFilter] = useState('all');
  const [websiteFilter, setWebsiteFilter] = useState('all');
  const [selectedAlert, setSelectedAlert] = useState(null);

  const load = () => {
    setLoading(true);
    setError('');
    getAlerts()
      .then((res) => {
        const data = res.alerts || res.data || res;
        setAlerts(Array.isArray(data) ? data : []);
      })
      .catch((e) => setError(e.response?.data?.error || e.message || 'Unable to load alerts.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  const allWebsites = React.useMemo(() => {
    const sites = new Set();
    alerts.forEach(a => {
      const target = a.target_url || a.endpoint || 'Unknown Website';
      try { sites.add(new URL(target).origin); }
      catch { sites.add(target); }
    });
    return Array.from(sites).sort();
  }, [alerts]);

  useEffect(() => {
    if (websiteFilter === 'all' && allWebsites.length > 0) {
      setWebsiteFilter(allWebsites[0]);
    }
  }, [allWebsites, websiteFilter]);

  const filteredAlerts = alerts.filter(a => {
    const eventType = (a.classification || a.rule_id || '').toLowerCase();
    const matchesSearch = 
      eventType.includes(searchTerm.toLowerCase()) || 
      (a.source_ip || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
      (a.description || '').toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesSev = severityFilter === 'all' || a.severity?.toLowerCase() === severityFilter;
    
    let website = a.target_url || a.endpoint || 'Unknown Website';
    try { website = new URL(website).origin; } catch {}
    const matchesWebsite = websiteFilter === 'all' || website === websiteFilter;

    return matchesSearch && matchesSev && matchesWebsite;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
            <Activity className="h-8 w-8 text-brand-500" />
            Intrusion Detection
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            Real-time monitoring of security events and suspicious activity.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={load} className="btn-secondary" title="Refresh">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        
        {/* Alerts List */}
        <div className="card xl:col-span-2 flex flex-col h-[calc(100vh-200px)]">
          <div className="card-header flex flex-col sm:flex-row justify-between gap-4 items-center">
            <div className="relative w-full">
              <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                <Search className="h-4 w-4 text-slate-500" aria-hidden="true" />
              </div>
              <input
                type="text"
                className="block w-full rounded-md border-0 bg-slate-900 py-1.5 pl-10 text-white shadow-sm ring-1 ring-inset ring-slate-700 focus:ring-2 focus:ring-inset focus:ring-brand-500 sm:text-sm sm:leading-6"
                placeholder="Search events, IPs, descriptions..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <div className="w-full md:w-auto flex flex-col sm:flex-row gap-3 shrink-0">
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