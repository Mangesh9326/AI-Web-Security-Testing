import React, { useEffect, useState } from 'react';
import { checkApiHealth } from '../services/api';

const ApiTest = () => {
  const [status, setStatus] = useState('loading');
  const [data, setData] = useState(null);
  const [errorMsg, setErrorMsg] = useState('');

  useEffect(() => {
    checkApiHealth()
      .then((response) => {
        setData(response.data);
        setStatus('success');
      })
      .catch((error) => {
        setErrorMsg(error.message || 'An error occurred while connecting to the backend.');
        setStatus('error');
      });
  }, []);

  return (
    <div className="dashboard-card" style={{ maxWidth: '600px', margin: '30px auto', padding: '30px' }}>
      <h2 style={{ marginBottom: '20px', color: '#111827' }}>API Connection Test</h2>
      
      {status === 'loading' && (
        <div style={{ padding: '20px', backgroundColor: '#f3f4f6', borderRadius: '8px', color: '#374151' }}>
          ⏳ Connecting to FastAPI...
        </div>
      )}

      {status === 'success' && data && (
        <div style={{ padding: '20px', backgroundColor: '#f0fdf4', border: '1px solid #bbf7d0', borderRadius: '8px' }}>
          <h3 style={{ color: '#166534', marginTop: 0, marginBottom: '15px' }}>✅ FastAPI Connected</h3>
          <p style={{ margin: '8px 0', color: '#374151' }}><strong>Service:</strong> {data.service}</p>
          <p style={{ margin: '8px 0', color: '#374151' }}><strong>Status:</strong> {data.status}</p>
        </div>
      )}

      {status === 'error' && (
        <div style={{ padding: '20px', backgroundColor: '#fef2f2', border: '1px solid #fecaca', borderRadius: '8px' }}>
          <h3 style={{ color: '#991b1b', marginTop: 0, marginBottom: '15px' }}>❌ FastAPI Connection Failed</h3>
          <p style={{ color: '#7f1d1d' }}>{errorMsg}</p>
        </div>
      )}
    </div>
  );
};

export default ApiTest;