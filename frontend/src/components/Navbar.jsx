import React, { useState, useEffect, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../services/api';

const Navbar = () => {
  const navigate = useNavigate();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [profileUser, setProfileUser] = useState(() => {
    try {
      const saved = localStorage.getItem('ai_websectest_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });
  const menuRef = useRef(null);

  useEffect(() => {
    const token =
      localStorage.getItem('ai_websectest_token') ||
      sessionStorage.getItem('ai_websectest_token');

    if (token) {
      api
        .get('/auth/me')
        .then((res) => {
          if (res.data) {
            setProfileUser(res.data);
            localStorage.setItem('ai_websectest_user', JSON.stringify(res.data));
          }
        })
        .catch(() => {});
    }
  }, []);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLogout = () => {
    setDropdownOpen(false);
    localStorage.removeItem('ai_websectest_token');
    localStorage.removeItem('ai_websectest_user');
    sessionStorage.removeItem('ai_websectest_token');
    navigate('/login', { replace: true });
  };

  const displayName =
    profileUser?.full_name ||
    profileUser?.email?.split('@')[0] ||
    'Researcher';
  const displayEmail = profileUser?.email || '';
  const initial = (displayName[0] || 'U').toUpperCase();

  return (
    <header
      className="navbar"
      style={{
        height: '64px',
        backgroundColor: '#ffffff',
        borderBottom: '1px solid #e5e7eb',
        padding: '0 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        position: 'sticky',
        top: 0,
        zIndex: 40,
      }}
    >
      <Link
        to="/dashboard"
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          textDecoration: 'none',
          color: '#111827',
          fontWeight: 700,
          fontSize: '18px',
        }}
      >
        <span style={{ fontSize: '20px' }}>🛡️</span>
        <span>AI-WebSecTest</span>
      </Link>

      {/* Dynamic Logged-in User Profile Menu */}
      <div ref={menuRef} style={{ position: 'relative' }}>
        <button
          type="button"
          onClick={() => setDropdownOpen((prev) => !prev)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            padding: '6px 12px',
            borderRadius: '9999px',
            border: '1px solid #e5e7eb',
            backgroundColor: '#f9fafb',
            cursor: 'pointer',
            color: '#111827',
            fontSize: '14px',
            fontWeight: 600,
          }}
        >
          <span
            style={{
              width: '28px',
              height: '28px',
              borderRadius: '50%',
              backgroundColor: '#111827',
              color: '#ffffff',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '13px',
              fontWeight: 700,
            }}
          >
            {initial}
          </span>
          <span>{displayName}</span>
          <span style={{ fontSize: '11px', color: '#6b7280' }}>▾</span>
        </button>

        {dropdownOpen && (
          <div
            style={{
              position: 'absolute',
              right: 0,
              top: 'calc(100% + 8px)',
              width: '240px',
              backgroundColor: '#ffffff',
              border: '1px solid #e5e7eb',
              borderRadius: '12px',
              boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.12)',
              padding: '8px',
              zIndex: 100,
            }}
          >
            <div style={{ padding: '10px 12px', borderBottom: '1px solid #f3f4f6', marginBottom: '6px' }}>
              <div style={{ fontWeight: 700, fontSize: '14px', color: '#111827' }}>{displayName}</div>
              {displayEmail && (
                <div style={{ fontSize: '12px', color: '#6b7280', marginTop: '2px', wordBreak: 'break-all' }}>
                  {displayEmail}
                </div>
              )}
            </div>

            <button
              type="button"
              onClick={() => {
                setDropdownOpen(false);
                navigate('/settings?tab=profile');
              }}
              style={menuItemStyle}
            >
              👤 My Profile
            </button>

            <button
              type="button"
              onClick={() => {
                setDropdownOpen(false);
                navigate('/settings?tab=account');
              }}
              style={menuItemStyle}
            >
              ⚙️ Settings
            </button>

            <button
              type="button"
              onClick={() => {
                setDropdownOpen(false);
                navigate('/settings?tab=password');
              }}
              style={menuItemStyle}
            >
              🔒 Change Password
            </button>

            <div style={{ borderTop: '1px solid #f3f4f6', margin: '6px 0' }} />

            <button
              type="button"
              onClick={handleLogout}
              style={{ ...menuItemStyle, color: '#dc2626', fontWeight: 600 }}
            >
              ↪ Logout
            </button>
          </div>
        )}
      </div>
    </header>
  );
};

const menuItemStyle = {
  width: '100%',
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
  padding: '9px 12px',
  borderRadius: '8px',
  border: 'none',
  backgroundColor: 'transparent',
  color: '#374151',
  fontSize: '13.5px',
  fontWeight: 500,
  textAlign: 'left',
  cursor: 'pointer',
};

export default Navbar;