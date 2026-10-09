import React from 'react';
import { NavLink } from 'react-router-dom';

const Sidebar = () => {
  const mainLinks = [
    { to: '/dashboard', label: 'Dashboard', icon: '▣' },
    { to: '/new-scan', label: 'New Scan', icon: '+' },
    { to: '/vulnerabilities', label: 'Vulnerabilities', icon: '⚠' },
    { to: '/intrusion-detection', label: 'Intrusion Detection', icon: '◉' },
    { to: '/reports', label: 'Reports', icon: '▤' },
  ];

  const getLinkStyle = ({ isActive }) => ({
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    padding: '11px 14px',
    borderRadius: '8px',
    fontSize: '14px',
    fontWeight: isActive ? 600 : 500,
    textDecoration: 'none',
    color: isActive ? '#ffffff' : '#d1d5db',
    backgroundColor: isActive ? '#2563eb' : 'transparent',
    transition: 'background-color 0.15s ease',
  });

  return (
    <aside
      className="sidebar"
      style={{
        width: '240px',
        minWidth: '240px',
        backgroundColor: '#111827',
        color: '#ffffff',
        padding: '20px 14px',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
      }}
    >
      {/* Top Navigation Group */}
      <div>
        <div
          style={{
            fontSize: '11px',
            fontWeight: 700,
            letterSpacing: '0.08em',
            color: '#9ca3af',
            padding: '0 14px 12px',
          }}
        >
          SECURITY
        </div>

        <nav style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          {mainLinks.map((item) => (
            <NavLink key={item.to} to={item.to} style={getLinkStyle}>
              <span style={{ width: '18px', textAlign: 'center' }}>{item.icon}</span>
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </div>

      {/* Bottom Settings Link */}
      <div style={{ borderTop: '1px solid #1f2937', paddingTop: '14px' }}>
        <NavLink to="/settings" style={getLinkStyle}>
          <span style={{ width: '18px', textAlign: 'center' }}>⚙</span>
          <span>Settings</span>
        </NavLink>
      </div>
    </aside>
  );
};

export default Sidebar;