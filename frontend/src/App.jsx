import React from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import AppShell from './components/AppShell';

// Public Pages
import LandingPage from './pages/LandingPage';
import { Login, Register } from './pages/AuthPage';

// Protected Workspace Pages
import Dashboard from './pages/Dashboard';
import NewScan from './pages/NewScan';
import ScanDetails from './pages/ScanDetails';
import Vulnerabilities from './pages/Vulnerabilities';
import IntrusionDetection from './pages/IntrusionDetection';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import Profile from './pages/Profile';
import ApiTest from './pages/ApiTest';
import Scans from './pages/Scans';
import Logs from './pages/Logs';

import ProtectedRoute from './components/ProtectedRoute';

const App = () => {
  const location = useLocation();
  const publicPaths = ['/', '/login', '/signup', '/register'];
  const isPublicPage = publicPaths.includes(location.pathname);

  if (isPublicPage) {
    return (
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Register />} />
        <Route path="/register" element={<Register />} />
      </Routes>
    );
  }

  return (
    <ProtectedRoute>
      <AppShell>
        <Routes>
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/new-scan" element={<NewScan />} />
          <Route path="/scans" element={<Scans />} />
          <Route path="/scan/:id" element={<ScanDetails />} />
          <Route path="/vulnerabilities" element={<Vulnerabilities />} />
          <Route path="/findings" element={<Vulnerabilities />} />
          <Route path="/intrusion-detection" element={<IntrusionDetection />} />
          <Route path="/logs" element={<Logs />} />
          <Route path="/reports" element={<Reports />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="/api-test" element={<ApiTest />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </AppShell>
    </ProtectedRoute>
  );
};

export default App;