import React from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import Navbar from './components/Navbar';
import Sidebar from './components/Sidebar';

// Public Pages
import LandingPage from './pages/LandingPage';
import { Login, Register } from './pages/AuthPage';

// Existing Protected Workspace Pages (Preserved Untouched)
import Dashboard from './pages/Dashboard';
import NewScan from './pages/NewScan';
import ScanDetails from './pages/ScanDetails';
import Vulnerabilities from './pages/Vulnerabilities';
import IntrusionDetection from './pages/IntrusionDetection';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import ApiTest from './pages/ApiTest';

const RequireAuth = ({ children }) => {
  const location = useLocation();
  const hasToken = Boolean(
    localStorage.getItem('ai_websectest_token') ||
    sessionStorage.getItem('ai_websectest_token')
  );

  if (!hasToken) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
};

const App = () => {
  const location = useLocation();
  const publicPaths = ['/', '/login', '/signup', '/register'];
  const isPublicPage = publicPaths.includes(location.pathname);

  // 1. Public Pages (Landing Page, Login, Sign Up)
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

  // 2. Protected Workspace Pages (Only visible after Signup / Login)
  return (
    <RequireAuth>
      <div className="app" style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
        <Navbar />
        <div className="app-body" style={{ display: 'flex', flex: 1, minHeight: 'calc(100vh - 64px)' }}>
          <Sidebar />
          <main
            className="main-content"
            style={{
              flex: 1,
              padding: '28px',
              backgroundColor: '#f8fafc',
              overflowY: 'auto',
              scrollBehavior: 'smooth',
            }}
          >
            <Routes>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/new-scan" element={<NewScan />} />
              <Route path="/scan/:id" element={<ScanDetails />} />
              <Route path="/vulnerabilities" element={<Vulnerabilities />} />
              <Route path="/intrusion-detection" element={<IntrusionDetection />} />
              <Route path="/reports" element={<Reports />} />
              <Route path="/settings" element={<Settings />} />
              <Route path="/profile" element={<Settings />} />
              <Route path="/api-test" element={<ApiTest />} />
              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Routes>
          </main>
        </div>
      </div>
    </RequireAuth>
  );
};

export default App;