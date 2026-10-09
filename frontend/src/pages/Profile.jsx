import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

const Profile = () => {
  const auth = useAuth ? useAuth() : {};
  const navigate = useNavigate();
  const user = auth?.user;

  const handleLogout = () => {
    if (auth?.logout) {
      auth.logout();
    }
    localStorage.removeItem('ai_websectest_token');
    sessionStorage.removeItem('ai_websectest_token');
    navigate('/login', { replace: true });
  };

  const formatDate = (value) => {
    if (!value) return 'Not recorded';
    try {
      return new Date(value).toLocaleString();
    } catch {
      return String(value);
    }
  };

  return (
    <div style={{ maxWidth: '900px' }}>
      <div className="page-header" style={{ marginBottom: '24px' }}>
        <div>
          <p className="page-label">WORKSPACE / ACCOUNT</p>
          <h1 style={{ margin: '0 0 6px 0' }}>Researcher Profile</h1>
          <p className="page-description">
            View your authenticated researcher identity and session security settings.
          </p>
        </div>
      </div>

      {/* Identity Card */}
      <section
        className="dashboard-card"
        style={{
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: '20px',
          marginBottom: '24px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div
            style={{
              width: '56px',
              height: '56px',
              borderRadius: '50%',
              backgroundColor: '#09090b',
              color: '#ffffff',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '22px',
              fontWeight: 800,
              textTransform: 'uppercase',
            }}
          >
            {user?.full_name?.[0] || user?.email?.[0] || 'R'}
          </div>
          <div>
            <span style={{ fontSize: '11px', fontWeight: 700, color: '#71717a', letterSpacing: '0.06em' }}>
              AUTHENTICATED IDENTITY
            </span>
            <h2 style={{ margin: '4px 0 2px 0', fontSize: '20px', color: '#09090b' }}>
              {user?.full_name || 'Security Researcher'}
            </h2>
            <p style={{ margin: 0, fontSize: '14px', color: '#52525b' }}>{user?.email || 'Active Session'}</p>
          </div>
        </div>

        <button
          onClick={handleLogout}
          style={{
            padding: '10px 18px',
            borderRadius: '8px',
            backgroundColor: '#09090b',
            color: '#ffffff',
            border: '1px solid #09090b',
            fontSize: '13px',
            fontWeight: 600,
            cursor: 'pointer',
          }}
        >
          Sign Out →
        </button>
      </section>

      {/* Details Grid */}
      <section
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: '20px',
        }}
      >
        <div className="dashboard-card">
          <div className="card-header">
            <div>
              <h3>Account Details</h3>
              <p>Retrieved from /api/auth/me</p>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '14px' }}>
            <div style={rowStyle}>
              <span style={labelStyle}>Full Name</span>
              <span style={valStyle}>{user?.full_name || '—'}</span>
            </div>
            <div style={rowStyle}>
              <span style={labelStyle}>Email Address</span>
              <span style={valStyle}>{user?.email || '—'}</span>
            </div>
            <div style={rowStyle}>
              <span style={labelStyle}>Role</span>
              <span style={{ ...valStyle, textTransform: 'capitalize' }}>{user?.role || 'researcher'}</span>
            </div>
            <div style={rowStyle}>
              <span style={labelStyle}>Account Created</span>
              <span style={valStyle}>{formatDate(user?.created_at)}</span>
            </div>
            <div style={{ ...rowStyle, borderBottom: 'none' }}>
              <span style={labelStyle}>Last Login</span>
              <span style={valStyle}>{formatDate(user?.last_login_at)}</span>
            </div>
          </div>
        </div>

        <div className="dashboard-card">
          <div className="card-header">
            <div>
              <h3>Session & Security Notice</h3>
              <p>Authentication and token policy</p>
            </div>
          </div>
          <p style={{ fontSize: '14px', lineHeight: 1.65, color: '#52525b', margin: '0 0 14px 0' }}>
            Your workspace is protected using JWT bearer authentication. Access tokens are automatically
            attached by the Axios request interceptor and cleared immediately if the backend returns an
            expired or unauthorized (401) response.
          </p>
          <div
            style={{
              padding: '12px 14px',
              borderRadius: '8px',
              backgroundColor: '#fafafa',
              border: '1px solid #e4e4e7',
              fontSize: '13px',
              color: '#3f3f46',
            }}
          >
            <strong>Note:</strong> Password hashes and backend cryptographic secrets are never transmitted
            to the browser client.
          </div>
        </div>
      </section>
    </div>
  );
};

const rowStyle = {
  display: 'flex',
  justifyContent: 'space-between',
  paddingBottom: '10px',
  borderBottom: '1px solid #f4f4f5',
};

const labelStyle = {
  color: '#71717a',
  fontWeight: 500,
};

const valStyle = {
  color: '#09090b',
  fontWeight: 600,
};

export default Profile;