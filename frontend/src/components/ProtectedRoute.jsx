import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function ProtectedRoute({ children }) {
  const { user, loading } = useAuth();
  const location = useLocation();
  const hasToken =
    Boolean(localStorage.getItem('ai_websectest_token')) ||
    Boolean(sessionStorage.getItem('ai_websectest_token'));

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-brand-500"></div>
      </div>
    );
  }

  if (!user && !hasToken) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
}