import React, { useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { register } from '../services/authService';
import { apiError } from '../services/api';

const Signup = () => {
  const auth = useAuth ? useAuth() : {};
  const navigate = useNavigate();

  const [form, setForm] = useState({
    full_name: '',
    email: '',
    password: '',
    confirmPassword: '',
  });
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  if (auth?.user) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!form.full_name.trim()) {
      setError('Please enter your full name.');
      return;
    }

    if (form.password.length < 12) {
      setError('Password must be at least 12 characters long.');
      return;
    }

    if (form.password !== form.confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setBusy(true);
    try {
      const res = await register({
        full_name: form.full_name.trim(),
        email: form.email.trim(),
        password: form.password,
      });

      // If backend returns a token directly on signup, go to dashboard; otherwise redirect to login
      if (res?.access_token) {
        localStorage.setItem('ai_websectest_token', res.access_token);
        navigate('/dashboard', { replace: true });
      } else {
        navigate('/login', { state: { registered: true }, replace: true });
      }
    } catch (err) {
      setError(apiError(err, 'Could not create account. Please verify your details.'));
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
            <p style={eyebrowStyle}>RESEARCHER REGISTRATION</p>
            <h1 style={{ fontSize: '26px', fontWeight: 800, color: '#09090b', margin: '0 0 6px 0' }}>
              Create your account
            </h1>
            <p style={{ fontSize: '14px', color: '#52525b', margin: 0 }}>
              Set up an isolated security testing workspace.
            </p>
          </div>

          {error && <div style={errorBannerStyle}>⚠ {error}</div>}

          <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <label htmlFor="signup-name" style={labelStyle}>
                Full Name
              </label>
              <input
                id="signup-name"
                type="text"
                value={form.full_name}
                onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                placeholder="Full Name"
                maxLength={200}
                required
                disabled={busy}
                style={inputStyle}
              />
            </div>

            <div>
              <label htmlFor="signup-email" style={labelStyle}>
                Email Address
              </label>
              <input
                id="signup-email"
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
                <label htmlFor="signup-password" style={{ ...labelStyle, marginBottom: 0 }}>
                  Password <span style={{ color: '#71717a', fontWeight: 400 }}>(12+ characters)</span>
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
                id="signup-password"
                type={showPassword ? 'text' : 'password'}
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                placeholder="Create a strong password (min 12 chars)"
                minLength={12}
                required
                disabled={busy}
                style={inputStyle}
              />
            </div>

            <div>
              <label htmlFor="signup-confirm" style={labelStyle}>
                Confirm Password
              </label>
              <input
                id="signup-confirm"
                type={showPassword ? 'text' : 'password'}
                value={form.confirmPassword}
                onChange={(e) => setForm({ ...form, confirmPassword: e.target.value })}
                placeholder="Repeat your password"
                minLength={12}
                required
                disabled={busy}
                style={inputStyle}
              />
            </div>

            <button type="submit" disabled={busy} style={primaryButtonStyle}>
              {busy ? 'Creating Account...' : 'Create Account →'}
            </button>
          </form>

          <div style={footerSwitchStyle}>
            Already registered?{' '}
            <Link to="/login" style={{ color: '#09090b', fontWeight: 700, textDecoration: 'underline' }}>
              Sign in
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
  maxWidth: '460px',
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

const footerSwitchStyle = {
  marginTop: '24px',
  paddingTop: '20px',
  borderTop: '1px solid #f4f4f5',
  textAlign: 'center',
  fontSize: '13px',
  color: '#52525b',
};

export default Signup;