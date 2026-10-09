import React, { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { apiError } from '../services/api';

const Login = () => {
  const auth = useAuth ? useAuth() : {};
  const location = useLocation();
  const navigate = useNavigate();

  const [form, setForm] = useState({ email: '', password: '' });
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const justRegistered = location.state?.registered;

  if (auth?.user) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!form.email.trim() || !form.password) {
      setError('Please enter both your email address and password.');
      return;
    }

    setBusy(true);
    try {
      await auth.login({ email: form.email.trim(), password: form.password });
      const destination = location.state?.from?.pathname || '/dashboard';
      navigate(destination, { replace: true });
    } catch (err) {
      setError(apiError(err, 'Invalid email or password. Please try again.'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div style={pageContainerStyle}>
      {/* Top Bar */}
      <div style={topBarStyle}>
        <Link to="/" style={brandLinkStyle}>
          <span style={logoBadgeStyle}>WST</span>
          <span>AI-WebSecTest</span>
        </Link>
        <Link to="/" style={backLinkStyle}>
          ← Back to Home
        </Link>
      </div>

      {/* Centered Card */}
      <div style={mainCenterStyle}>
        <div style={cardStyle}>
          <div style={{ marginBottom: '24px' }}>
            <p style={eyebrowStyle}>AUTHENTICATION</p>
            <h1 style={{ fontSize: '26px', fontWeight: 800, color: '#09090b', margin: '0 0 6px 0' }}>
              Sign in to your workspace
            </h1>
            <p style={{ fontSize: '14px', color: '#52525b', margin: 0 }}>
              Enter your researcher credentials to access AI-WebSecTest.
            </p>
          </div>

          {justRegistered && (
            <div style={successBannerStyle}>
              ✓ Account created successfully. Please sign in with your credentials.
            </div>
          )}

          {error && <div style={errorBannerStyle}>⚠ {error}</div>}

          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
            <div>
              <label htmlFor="login-email" style={labelStyle}>
                Email Address
              </label>
              <input
                id="login-email"
                type="email"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                placeholder="researcher@university.edu"
                autoComplete="email"
                required
                disabled={busy}
                style={inputStyle}
              />
            </div>

            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <label htmlFor="login-password" style={{ ...labelStyle, marginBottom: 0 }}>
                  Password
                </label>
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  style={toggleBtnStyle}
                >
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>
              <input
                id="login-password"
                type={showPassword ? 'text' : 'password'}
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                placeholder="••••••••••••"
                autoComplete="current-password"
                required
                disabled={busy}
                style={inputStyle}
              />
            </div>

            <button type="submit" disabled={busy} style={primaryButtonStyle}>
              {busy ? 'Authenticating...' : 'Sign In →'}
            </button>
          </form>

          <div style={footerSwitchStyle}>
            Don&apos;t have an account?{' '}
            <Link to="/signup" style={{ color: '#09090b', fontWeight: 700, textDecoration: 'underline' }}>
              Create an account
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

const pageContainerStyle = {
  minHeight: '100vh',
  backgroundColor: '#fafafa',
  color: '#09090b',
  display: 'flex',
  flexDirection: 'column',
  fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
};

const topBarStyle = {
  maxWidth: '1200px',
  width: '100%',
  margin: '0 auto',
  padding: '20px 24px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
};

const brandLinkStyle = {
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
  textDecoration: 'none',
  color: '#09090b',
  fontWeight: 800,
  fontSize: '16px',
};

const logoBadgeStyle = {
  width: '30px',
  height: '30px',
  borderRadius: '7px',
  backgroundColor: '#09090b',
  color: '#ffffff',
  display: 'inline-flex',
  alignItems: 'center',
  justifyContent: 'center',
  fontSize: '12px',
  fontWeight: 800,
};

const backLinkStyle = {
  fontSize: '13px',
  fontWeight: 600,
  color: '#52525b',
  textDecoration: 'none',
};

const mainCenterStyle = {
  flexGrow: 1,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  padding: '24px',
};

const cardStyle = {
  width: '100%',
  maxWidth: '440px',
  backgroundColor: '#ffffff',
  border: '1px solid #e4e4e7',
  borderRadius: '14px',
  padding: '36px 32px',
  boxShadow: '0 10px 25px -10px rgba(0, 0, 0, 0.06)',
};

const eyebrowStyle = {
  fontSize: '11px',
  fontWeight: 700,
  letterSpacing: '0.08em',
  color: '#71717a',
  margin: '0 0 6px 0',
};

const labelStyle = {
  display: 'block',
  fontSize: '13px',
  fontWeight: 600,
  color: '#18181b',
  marginBottom: '6px',
};

const inputStyle = {
  width: '100%',
  padding: '11px 14px',
  fontSize: '14px',
  borderRadius: '8px',
  border: '1px solid #d4d4d8',
  backgroundColor: '#ffffff',
  color: '#09090b',
  outline: 'none',
  boxSizing: 'border-box',
};

const toggleBtnStyle = {
  background: 'none',
  border: 'none',
  padding: 0,
  fontSize: '12px',
  fontWeight: 600,
  color: '#52525b',
  cursor: 'pointer',
};

const primaryButtonStyle = {
  width: '100%',
  padding: '12px 16px',
  borderRadius: '8px',
  backgroundColor: '#09090b',
  color: '#ffffff',
  border: '1px solid #09090b',
  fontSize: '14px',
  fontWeight: 600,
  cursor: 'pointer',
  marginTop: '4px',
};

const errorBannerStyle = {
  padding: '12px 14px',
  borderRadius: '8px',
  backgroundColor: '#fef2f2',
  border: '1px solid #fecaca',
  color: '#991b1b',
  fontSize: '13px',
  fontWeight: 500,
  marginBottom: '18px',
};

const successBannerStyle = {
  padding: '12px 14px',
  borderRadius: '8px',
  backgroundColor: '#f0fdf4',
  border: '1px solid #bbf7d0',
  color: '#166534',
  fontSize: '13px',
  fontWeight: 500,
  marginBottom: '18px',
};

const footerSwitchStyle = {
  marginTop: '24px',
  paddingTop: '20px',
  borderTop: '1px solid #f4f4f5',
  textAlign: 'center',
  fontSize: '13px',
  color: '#52525b',
};

export default Login;