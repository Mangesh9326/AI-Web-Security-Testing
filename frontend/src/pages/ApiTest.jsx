import React, { useState } from 'react';
import { checkApiHealth } from '../services/api';
import { Activity, Play, CheckCircle2, XCircle, RefreshCw } from 'lucide-react';

export default function ApiTest() {
  const [status, setStatus] = useState('unknown');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  const runTest = async () => {
    setLoading(true);
    setStatus('testing');
    setMessage('');
    try {
      const res = await checkApiHealth();
      setStatus('success');
      setMessage(JSON.stringify(res.data, null, 2));
    } catch (err) {
      setStatus('error');
      setMessage(err.message || 'API connection failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
          <Activity className="h-8 w-8 text-brand-500" />
          API Diagnostic
        </h2>
        <p className="mt-1 text-sm text-slate-400">
          Verify connectivity to the backend services.
        </p>
      </div>

      <div className="card">
        <div className="card-body">
          <button 
            onClick={runTest} 
            disabled={loading}
            className="btn-primary inline-flex items-center"
          >
            {loading ? <RefreshCw className="animate-spin h-4 w-4 mr-2" /> : <Play className="h-4 w-4 mr-2" />}
            Test Connection
          </button>

          <div className="mt-8 space-y-4">
            <h4 className="text-sm font-medium text-slate-300">Connection Status:</h4>
            
            <div className="flex items-center gap-2">
              {status === 'unknown' && <span className="text-slate-500">Not tested yet</span>}
              {status === 'testing' && <span className="text-brand-400 animate-pulse">Testing...</span>}
              {status === 'success' && <span className="text-green-400 flex items-center gap-1.5"><CheckCircle2 className="h-5 w-5" /> Connected successfully</span>}
              {status === 'error' && <span className="text-red-400 flex items-center gap-1.5"><XCircle className="h-5 w-5" /> Connection failed</span>}
            </div>

            {message && (
              <div className="mt-4">
                <h4 className="text-sm font-medium text-slate-300 mb-2">Response:</h4>
                <pre className="p-4 text-xs font-mono text-brand-300 bg-slate-950 rounded-md border border-slate-800 overflow-x-auto">
                  {message}
                </pre>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}