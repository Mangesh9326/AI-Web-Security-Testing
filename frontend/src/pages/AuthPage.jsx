import React, { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import api, { apiError } from '../services/api';

// Helper to check if user is already logged in
const isAuthenticated = () => {
  return Boolean(
    localStorage.getItem('ai_websectest_token') ||
    sessionStorage.getItem('ai_websectest_token')
  );
};

function AuthLayout({ children, title, subtitle }) {
  return (
    <div
      style={{
        minHeight: '100vh',
        backgroundColor: '#f9fafb',
        color: '#111827',
        display: 'flex',
        flexDirection: 'column',
        fontFamily: 'Inter, system-ui, -apple-system, sans-serif',
      }}
    >
      {/* Top Navigation Bar */}
      <div
        style={{
          maxWidth: '1200px',
          width: '100%',
          margin: '0 auto',
          padding: '20px 24px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          boxSizing: 'border-box',
        }}
      >
        <Link
          to="/"
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            textDecoration: 'none',
            color: '#111827',
            fontWeight: 800,
            fontSize: '18px',
          }}
        >
          <span>🛡️</span>
          <span>AI-WebSecTest</span>
        </Link>
        <Link
          to="/"
          style={{
            fontSize: '14px',
            fontWeight: 600,
            color: '#4b5563',
            textDecoration: 'none',
          }}
        >
          ← Back to Landing Page
        </Link>
      </div>

      {/* Centered Form Card */}
      <div
        style={{
          flex: 1,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '24px',
        }}
      >
        <div
          style={{
            width: '100%',
            maxWidth: '440px',
            backgroundColor: '#ffffff',
            border: '1px solid #e5e7eb',
            borderRadius: '14px',
            padding: '36px 32px',
            boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.06)',
          }}
        >
          <p
            style={{
              fontSize: '11px',
              fontWeight: 700,
              letterSpacing: '0.08em',
              color: '#6b7280',
              margin: '0 0 6px 0',
              textTransform: 'uppercase',
            }}
          >
            Security Workspace Access
          </p>
          <h1 style={{ fontSize: '26px', fontWeight: 800, margin: '0 0 6px 0', color: '#111827' }}>
            {title}
          </h1>
          <p style={{ fontSize: '14px', color: '#6b7280', margin: '0 0 24px 0' }}>{subtitle}</p>
          {children}
        </div>
      </div>
    </div>
  );
}

export function Login() {
  const location = useLocation();
  const navigate = useNavigate();

  const [form, setForm] = useState({ email: '', password: '' });
  const [showPassword, setShowPassword] = useState(false);
  const [showForgot, setShowForgot] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const justRegistered = location.state?.registered;

  if (isAuthenticated()) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setBusy(true);

    try {
      const emailClean = form.email.trim();
      let res;

      // Try standard JSON login first; fallback to OAuth2 form-urlencoded if FastAPI expects username/password form data
      try {
        res = await api.post('/auth/login', {
          email: emailClean,
          password: form.password,
        });
      } catch (firstErr) {
        if (firstErr.response && firstErr.response.status === 422) {
          const formData = new URLSearchParams();
          formData.append('username', emailClean);
          formData.append('password', form.password);
          res = await api.post('/auth/login', formData, {
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          });
        } else {
          throw firstErr;
        }
      }

      const data = res.data || {};
      const token = data.access_token || data.token || 'authenticated_session';

      // Save token to both storages so no component ever loses session
      localStorage.setItem('ai_websectest_token', token);
      sessionStorage.setItem('ai_websectest_token', token);

      // Fetch or store user profile for Navbar & Settings
      if (data.user) {
        localStorage.setItem('ai_websectest_user', JSON.stringify(data.user));
      } else {
        try {
          const meRes = await api.get('/auth/me');
          localStorage.setItem('ai_websectest_user', JSON.stringify(meRes.data));
        } catch {
          localStorage.setItem(
            'ai_websectest_user',
            JSON.stringify({
              full_name: emailClean.split('@')[0],
              email: emailClean,
            })
          );
        }
      }

      // Navigate directly to the Dashboard
      navigate('/dashboard', { replace: true });
    } catch (err) {
      setError(apiError(err, 'Invalid email or password. Please check your credentials.'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthLayout title="Welcome back" subtitle="Sign in to access your security dashboard.">
      {justRegistered && (
        <div style={successBannerStyle}>
          ✓ Account created! Please sign in with your new email and password.
        </div>
      )}

      {error && <div style={errorBannerStyle}>⚠ {error}</div>}

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div>
          <label style={labelStyle}>Email Address</label>
          <input
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            required
            placeholder="you@university.edu"
            style={inputStyle}
          />
        </div>

        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
            <label style={{ ...labelStyle, marginBottom: 0 }}>Password</label>
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              style={linkButtonStyle}
            >
              {showPassword ? 'Hide' : 'Show'}
            </button>
          </div>
          <input
            type={showPassword ? 'text' : 'password'}
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            required
            placeholder="••••••••••••"
            style={inputStyle}
          />
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <button
            type="button"
            onClick={() => setShowForgot(!showForgot)}
            style={linkButtonStyle}
          >
            Forgot password?
          </button>
        </div>

        {showForgot && (
          <div
            style={{
              padding: '12px',
              borderRadius: '8px',
              backgroundColor: '#f3f4f6',
              border: '1px solid #e5e7eb',
              fontSize: '12.5px',
              color: '#374151',
              lineHeight: 1.5,
            }}
          >
            <strong>Password Reset:</strong> Because this is a local M.Sc. research server without an external SMTP email server configured, you can either register a new researcher account on the{' '}
            <Link to="/signup" style={{ color: '#111827', fontWeight: 700 }}>
              Sign Up page
            </Link>{' '}
            or update your password inside <strong>Settings → Change Password</strong> once logged in.
          </div>
        )}

        <button type="submit" disabled={busy} style={primaryButtonStyle}>
          {busy ? 'Signing in...' : 'Login to Dashboard →'}
        </button>
      </form>

      <p style={switchTextStyle}>
        Don&apos;t have an account?{' '}
        <Link to="/signup" style={{ color: '#111827', fontWeight: 700 }}>
          Sign Up
        </Link>
      </p>
    </AuthLayout>
  );
}

export function Register() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    full_name: '',
    email: '',
    password: '',
    confirm: '',
  });
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  if (isAuthenticated()) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!form.full_name.trim()) {
      return setError('Please enter your full name.');
    }
    if (form.password.length < 12) {
      return setError('Password must be at least 12 characters long.');
    }
    if (form.password !== form.confirm) {
      return setError('Passwords do not match.');
    }

    setBusy(true);
    try {
      const emailClean = form.email.trim();
      const nameClean = form.full_name.trim();

      // 1. Register the user in FastAPI
      const regRes = await api.post('/auth/register', {
        full_name: nameClean,
        email: emailClean,
        password: form.password,
      });

      // 2. If register returned a token, or if we can auto-login immediately, go straight to /dashboard!
      let token = regRes.data?.access_token || regRes.data?.token;

      if (!token) {
        try {
          const loginRes = await api.post('/auth/login', {
            email: emailClean,
            password: form.password,
          });
          token = loginRes.data?.access_token || loginRes.data?.token;
        } catch {
          // If auto-login isn't supported, redirect cleanly to /login
        }
      }

      if (token) {
        localStorage.setItem('ai_websectest_token', token);
        sessionStorage.setItem('ai_websectest_token', token);
        localStorage.setItem(
          'ai_websectest_user',
          JSON.stringify({
            full_name: nameClean,
            email: emailClean,
            created_at: new Date().toISOString(),
          })
        );
        navigate('/dashboard', { replace: true });
      } else {
        navigate('/login', { state: { registered: true }, replace: true });
      }
    } catch (err) {
      setError(apiError(err, 'Could not create account. Check if the backend is running.'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthLayout title="Create your account" subtitle="Register to access your security workspace.">
      {error && <div style={errorBannerStyle}>⚠ {error}</div>}

      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
        <div>
          <label style={labelStyle}>Full Name</label>
          <input
            type="text"
            value={form.full_name}
            onChange={(e) => setForm({ ...form, full_name: e.target.value })}
            required
            placeholder="Your Full Name"
            style={inputStyle}
          />
        </div>

        <div>
          <label style={labelStyle}>Email Address</label>
          <input
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            required
            placeholder="you@university.edu"
            style={inputStyle}
          />
        </div>

        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
            <label style={{ ...labelStyle, marginBottom: 0 }}>
              Password <span style={{ fontWeight: 400, color: '#6b7280' }}>(min 12 chars)</span>
            </label>
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              style={linkButtonStyle}
            >
              {showPassword ? 'Hide' : 'Show'}
            </button>
          </div>
          <input
            type={showPassword ? 'text' : 'password'}
            value={form.password}
            onChange={(e) => setForm({ ...form, password: e.target.value })}
            required
            minLength={12}
            placeholder="Create a strong password (12+ chars)"
            style={inputStyle}
          />
        </div>

        <div>
          <label style={labelStyle}>Confirm Password</label>
          <input
            type={showPassword ? 'text' : 'password'}
            value={form.confirm}
            onChange={(e) => setForm({ ...form, confirm: e.target.value })}
            required
            minLength={12}
            placeholder="Repeat your password"
            style={inputStyle}
          />
        </div>

        <button type="submit" disabled={busy} style={primaryButtonStyle}>
          {busy ? 'Creating Account...' : 'Sign Up & Open Dashboard →'}
        </button>
      </form>

      <p style={switchTextStyle}>
        Already registered?{' '}
        <Link to="/login" style={{ color: '#111827', fontWeight: 700 }}>
          Sign In
        </Link>
      </p>
    </AuthLayout>
  );
}

const labelStyle = {
  display: 'block',
  fontSize: '13px',
  fontWeight: 600,
  color: '#111827',
  marginBottom: '6px',
};

const inputStyle = {
  width: '100%',
  padding: '11px 14px',
  fontSize: '14px',
  borderRadius: '8px',
  border: '1px solid #d1d5db',
  outline: 'none',
  boxSizing: 'border-box',
};

const primaryButtonStyle = {
  width: '100%',
  padding: '12px 16px',
  borderRadius: '8px',
  backgroundColor: '#111827',
  color: '#ffffff',
  border: 'none',
  fontSize: '14px',
  fontWeight: 700,
  cursor: 'pointer',
  marginTop: '4px',
};

const linkButtonStyle = {
  background: 'none',
  border: 'none',
  padding: 0,
  fontSize: '12px',
  fontWeight: 600,
  color: '#4b5563',
  cursor: 'pointer',
};

const errorBannerStyle = {
  padding: '12px 14px',
  borderRadius: '8px',
  backgroundColor: '#fef2f2',
  border: '1px solid #fecaca',
  color: '#991b1b',
  fontSize: '13px',
  marginBottom: '16px',
};

const successBannerStyle = {
  padding: '12px 14px',
  borderRadius: '8px',
  backgroundColor: '#f0fdf4',
  border: '1px solid #bbf7d0',
  color: '#166534',
  fontSize: '13px',
  marginBottom: '16px',
};

const switchTextStyle = {
  marginTop: '22px',
  paddingTop: '18px',
  borderTop: '1px solid #f3f4f6',
  textAlign: 'center',
  fontSize: '13.5px',
  color: '#4b5563',
};

export default Login;