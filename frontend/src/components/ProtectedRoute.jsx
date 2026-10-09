import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

const ProtectedRoute = ({ children }) => {
  const auth = useAuth ? useAuth() : {};
  const location = useLocation();
  const hasToken =
    Boolean(localStorage.getItem('ai_websectest_token')) ||
    Boolean(sessionStorage.getItem('ai_websectest_token'));

  if (auth?.loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#fafafa', color: '#09090b', fontFamily: 'Inter, system-ui, sans-serif' }}>
        <div style={{ padding: '24px 32px', backgroundColor: '#ffffff', border: '1px solid #e4e4e7', borderRadius: '12px', fontSize: '14px', fontWeight: 600 }}>
          Verifying authenticated session...
        </div>
      </div>
    );
  }

  if (!auth?.user && !hasToken) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
};

export default ProtectedRoute;