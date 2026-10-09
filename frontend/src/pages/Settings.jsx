import React, { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import api, { apiError } from '../services/api';

const Settings = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const activeTab = searchParams.get('tab') || 'profile';

  const [user, setUser] = useState(() => {
    try {
      const saved = localStorage.getItem('ai_websectest_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const [fullName, setFullName] = useState(user?.full_name || '');
  const [profileMsg, setProfileMsg] = useState({ type: '', text: '' });

  const [passwords, setPasswords] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [showPass, setShowPass] = useState(false);
  const [passMsg, setPassMsg] = useState({ type: '', text: '' });

  useEffect(() => {
    api
      .get('/auth/me')
      .then((res) => {
        if (res.data) {
          setUser(res.data);
          setFullName(res.data.full_name || '');
          localStorage.setItem('ai_websectest_user', JSON.stringify(res.data));
        }
      })
      .catch(() => {});
  }, []);

  const handleProfileUpdate = (e) => {
    e.preventDefault();
    if (!fullName.trim()) {
      setProfileMsg({ type: 'error', text: 'Full name cannot be empty.' });
      return;
    }
    const updated = { ...user, full_name: fullName.trim() };
    setUser(updated);
    localStorage.setItem('ai_websectest_user', JSON.stringify(updated));
    setProfileMsg({ type: 'success', text: 'Profile display name updated successfully.' });
  };

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    setPassMsg({ type: '', text: '' });

    if (passwords.newPassword.length < 12) {
      setPassMsg({ type: 'error', text: 'New password must be at least 12 characters long.' });
      return;
    }
    if (passwords.newPassword !== passwords.confirmPassword) {
      setPassMsg({ type: 'error', text: 'New password and confirm password do not match.' });
      return;
    }

    try {
      await api.post('/auth/change-password', {
        current_password: passwords.currentPassword,
        new_password: passwords.newPassword,
      });
      setPassMsg({ type: 'success', text: 'Password changed successfully.' });
      setPasswords({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (err) {
      if (err.response && (err.response.status === 404 || err.response.status === 405)) {
        setPassMsg({
          type: 'error',
          text: 'Password validated (12+ chars). Note: FastAPI backend does not have POST /api/auth/change-password enabled yet.',
        });
      } else {
        setPassMsg({ type: 'error', text: apiError(err, 'Unable to change password.') });
      }
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('ai_websectest_token');
    localStorage.removeItem('ai_websectest_user');
    sessionStorage.removeItem('ai_websectest_token');
    navigate('/login', { replace: true });
  };

  return (
    <div style={{ maxWidth: '860px' }}>
      <div className="page-header" style={{ marginBottom: '24px' }}>
        <div>
          <p className="page-label">WORKSPACE / SETTINGS</p>
          <h1>Profile & Account Settings</h1>
          <p className="page-description">
            View your logged-in profile, update account settings, change password, or sign out.
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '10px', marginBottom: '24px', flexWrap: 'wrap' }}>
        {[
          { id: 'profile', label: '👤 My Profile' },
          { id: 'account', label: '⚙️ Settings' },
          { id: 'password', label: '🔒 Change Password' },
        ].map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setSearchParams({ tab: tab.id })}
            style={{
              padding: '10px 18px',
              borderRadius: '8px',
              fontSize: '14px',
              fontWeight: 600,
              cursor: 'pointer',
              border: activeTab === tab.id ? '1px solid #111827' : '1px solid #d1d5db',
              backgroundColor: activeTab === tab.id ? '#111827' : '#ffffff',
              color: activeTab === tab.id ? '#ffffff' : '#374151',
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* My Profile Tab */}
      {activeTab === 'profile' && (
        <div className="dashboard-card" style={{ marginBottom: '24px' }}>
          <h3>Logged-In User Profile</h3>
          <div style={{ display: 'grid', gap: '12px', marginTop: '16px', fontSize: '14px' }}>
            <div style={rowStyle}>
              <span style={{ color: '#6b7280' }}>Full Name</span>
              <strong>{user?.full_name || 'Researcher'}</strong>
            </div>
            <div style={rowStyle}>
              <span style={{ color: '#6b7280' }}>Email Address</span>
              <strong>{user?.email || '—'}</strong>
            </div>
            <div style={rowStyle}>
              <span style={{ color: '#6b7280' }}>Session Status</span>
              <strong style={{ color: '#16a34a' }}>● Authenticated</strong>
            </div>
          </div>
        </div>
      )}

      {/* Account Settings Tab */}
      {activeTab === 'account' && (
        <div className="dashboard-card" style={{ marginBottom: '24px' }}>
          <h3>Update Profile Name</h3>
          {profileMsg.text && (
            <div style={profileMsg.type === 'success' ? successStyle : errorStyle}>
              {profileMsg.text}
            </div>
          )}
          <form onSubmit={handleProfileUpdate} style={{ maxWidth: '440px', marginTop: '16px' }}>
            <div style={{ marginBottom: '16px' }}>
              <label style={labelStyle}>Full Name</label>
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                style={inputStyle}
              />
            </div>
            <button type="submit" style={btnStyle}>
              Save Profile Name
            </button>
          </form>
        </div>
      )}

      {/* Change Password Tab */}
      {activeTab === 'password' && (
        <div className="dashboard-card" style={{ marginBottom: '24px' }}>
          <h3>Change Password</h3>
          {passMsg.text && (
            <div style={passMsg.type === 'success' ? successStyle : errorStyle}>
              {passMsg.text}
            </div>
          )}
          <form onSubmit={handlePasswordChange} style={{ maxWidth: '440px', marginTop: '16px' }}>
            <div style={{ marginBottom: '14px' }}>
              <label style={labelStyle}>Current Password</label>
              <input
                type={showPass ? 'text' : 'password'}
                value={passwords.currentPassword}
                onChange={(e) => setPasswords({ ...passwords, currentPassword: e.target.value })}
                required
                style={inputStyle}
              />
            </div>
            <div style={{ marginBottom: '14px' }}>
              <label style={labelStyle}>New Password (12+ chars)</label>
              <input
                type={showPass ? 'text' : 'password'}
                value={passwords.newPassword}
                onChange={(e) => setPasswords({ ...passwords, newPassword: e.target.value })}
                required
                minLength={12}
                style={inputStyle}
              />
            </div>
            <div style={{ marginBottom: '14px' }}>
              <label style={labelStyle}>Confirm New Password</label>
              <input
                type={showPass ? 'text' : 'password'}
                value={passwords.confirmPassword}
                onChange={(e) => setPasswords({ ...passwords, confirmPassword: e.target.value })}
                required
                minLength={12}
                style={inputStyle}
              />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ fontSize: '13px', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={showPass}
                  onChange={() => setShowPass(!showPass)}
                  style={{ marginRight: '8px' }}
                />
                Show passwords
              </label>
            </div>
            <button type="submit" style={btnStyle}>
              Update Password
            </button>
          </form>
        </div>
      )}

      {/* Logout Card */}
      <div className="dashboard-card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h3 style={{ margin: 0 }}>Log Out</h3>
          <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#6b7280' }}>
            End your current session and return to the Login screen.
          </p>
        </div>
        <button
          onClick={handleLogout}
          style={{
            padding: '10px 18px',
            borderRadius: '8px',
            backgroundColor: '#fef2f2',
            color: '#dc2626',
            border: '1px solid #fecaca',
            fontWeight: 700,
            cursor: 'pointer',
          }}
        >
          ↪ Log Out
        </button>
      </div>
    </div>
  );
};

const rowStyle = {
  display: 'flex',
  justifyContent: 'space-between',
  padding: '10px 0',
  borderBottom: '1px solid #f3f4f6',
};

const labelStyle = {
  display: 'block',
  fontSize: '13px',
  fontWeight: 600,
  marginBottom: '6px',
};

const inputStyle = {
  width: '100%',
  padding: '10px 14px',
  borderRadius: '8px',
  border: '1px solid #d1d5db',
  boxSizing: 'border-box',
};

const btnStyle = {
  padding: '10px 18px',
  borderRadius: '8px',
  backgroundColor: '#111827',
  color: '#ffffff',
  border: 'none',
  fontWeight: 600,
  cursor: 'pointer',
};

const errorStyle = {
  padding: '10px 14px',
  borderRadius: '8px',
  backgroundColor: '#fef2f2',
  color: '#991b1b',
  border: '1px solid #fecaca',
  fontSize: '13px',
  marginTop: '12px',
};

const successStyle = {
  padding: '10px 14px',
  borderRadius: '8px',
  backgroundColor: '#f0fdf4',
  color: '#166534',
  border: '1px solid #bbf7d0',
  fontSize: '13px',
  marginTop: '12px',
};

export default Settings;