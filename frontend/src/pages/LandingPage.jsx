import React, { useState } from 'react';
import { Link } from 'react-router-dom';

const LandingPage = () => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const scrollToSection = (id) => {
    setMobileMenuOpen(false);
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  const features = [
    {
      title: 'Automated Security Testing',
      badge: 'Core Engine',
      description:
        'Organize and launch authorized web application scans with configurable crawler, passive, and active testing parameters.',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="12" cy="12" r="10" />
          <line x1="22" y1="12" x2="18" y2="12" />
          <line x1="6" y1="12" x2="2" y2="12" />
          <line x1="12" y1="6" x2="12" y2="2" />
          <line x1="12" y1="22" x2="12" y2="18" />
        </svg>
      ),
    },
    {
      title: 'AI-Based Vulnerability Classification',
      badge: 'ML Workflow',
      description:
        'Classify discovered security findings using an ML-assisted workflow that structures vulnerability categories, confidence, and severity.',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <path d="M12 2L2 7l10 5 10-5-10-5z" />
          <path d="M2 17l10 5 10-5" />
          <path d="M2 12l10 5 10-5" />
        </svg>
      ),
    },
    {
      title: 'Intrusion Detection',
      badge: 'Traffic Analysis',
      description:
        'Present suspicious request patterns and traffic-related security events in a structured monitoring view for rapid analyst triage.',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
        </svg>
      ),
    },
    {
      title: 'Risk Prioritization',
      badge: 'Triage',
      description:
        'Help security teams and researchers review findings based on severity and risk indicators so critical issues are addressed first.',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
          <line x1="12" y1="9" x2="12" y2="13" />
          <line x1="12" y1="17" x2="12.01" y2="17" />
        </svg>
      ),
    },
    {
      title: 'Security Dashboard',
      badge: 'Unified View',
      description:
        'Monitor scan summaries, vulnerability distributions, and security events in one cohesive interface with clean visual indicators.',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <rect x="3" y="3" width="7" height="7" rx="1" />
          <rect x="14" y="3" width="7" height="7" rx="1" />
          <rect x="14" y="14" width="7" height="7" rx="1" />
          <rect x="3" y="14" width="7" height="7" rx="1" />
        </svg>
      ),
    },
    {
      title: 'Reports & Assessment Summaries',
      badge: 'Documentation',
      description:
        'Review and organize scan results into structured security assessment summaries designed for clear technical documentation.',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
          <polyline points="14 2 14 8 20 8" />
          <line x1="16" y1="13" x2="8" y2="13" />
          <line x1="16" y1="17" x2="8" y2="17" />
          <polyline points="10 9 9 9 8 9" />
        </svg>
      ),
    },
  ];

  const workflowSteps = [
    {
      step: '01',
      title: 'Create Account & Sign In',
      status: 'Operational',
      description: 'Authenticate into your isolated researcher workspace using JWT-backed session management.',
    },
    {
      step: '02',
      title: 'Add Authorized Target',
      status: 'Operational',
      description: 'Specify a web application URL you own or have explicit written permission to test.',
    },
    {
      step: '03',
      title: 'Run Security Scan',
      status: 'Operational / Staged',
      description: 'Configure crawler, passive, and active scan options and record the scan task via the FastAPI backend.',
    },
    {
      step: '04',
      title: 'Review Findings & Classification',
      status: 'Research Workflow',
      description: 'Inspect categorized vulnerabilities, CWE mappings, and ML-assisted severity classifications.',
    },
    {
      step: '05',
      title: 'Examine Risk & Reports',
      status: 'Dashboard & Demo View',
      description: 'Prioritize remediation using severity breakdowns, intrusion event logs, and structured assessment reports.',
    },
  ];

  return (
    <div style={{ backgroundColor: '#ffffff', color: '#09090b', minHeight: '100vh', fontFamily: 'Inter, system-ui, -apple-system, sans-serif' }}>
      {/* 1. STICKY PUBLIC NAVIGATION BAR */}
      <header
        style={{
          position: 'sticky',
          top: 0,
          zIndex: 50,
          backgroundColor: 'rgba(255, 255, 255, 0.92)',
          backdropFilter: 'blur(10px)',
          borderBottom: '1px solid #e4e4e7',
        }}
      >
        <div
          style={{
            maxWidth: '1200px',
            margin: '0 auto',
            padding: '0 24px',
            height: '68px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          {/* Left: Brand Logo */}
          <Link
            to="/"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              textDecoration: 'none',
              color: '#09090b',
              fontWeight: 700,
              fontSize: '17px',
              letterSpacing: '-0.02em',
            }}
          >
            <span
              style={{
                width: '32px',
                height: '32px',
                borderRadius: '8px',
                backgroundColor: '#09090b',
                color: '#ffffff',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '14px',
                fontWeight: 800,
              }}
            >
              🛡️
            </span>
            <span>AI-WebSecTest</span>
          </Link>

          {/* Center: Desktop Navigation Links */}
          <nav
            className="desktop-nav"
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '28px',
            }}
          >
            <button
              onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
              style={navLinkStyle}
            >
              Home
            </button>
            <button onClick={() => scrollToSection('features')} style={navLinkStyle}>
              Features
            </button>
            <button onClick={() => scrollToSection('how-it-works')} style={navLinkStyle}>
              How It Works
            </button>
            <button onClick={() => scrollToSection('about')} style={navLinkStyle}>
              About
            </button>
          </nav>

          {/* Right: Auth Actions */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <Link
              to="/login"
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                fontSize: '14px',
                fontWeight: 600,
                color: '#09090b',
                backgroundColor: '#ffffff',
                border: '1px solid #d4d4d8',
                textDecoration: 'none',
                transition: 'all 0.15s ease',
              }}
            >
              Login
            </Link>
            <Link
              to="/signup"
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                fontSize: '14px',
                fontWeight: 600,
                color: '#ffffff',
                backgroundColor: '#09090b',
                border: '1px solid #09090b',
                textDecoration: 'none',
                transition: 'all 0.15s ease',
              }}
            >
              Sign Up
            </Link>

            {/* Mobile Hamburger Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle navigation menu"
              style={{
                display: 'none',
                padding: '8px',
                borderRadius: '6px',
                border: '1px solid #e4e4e7',
                background: '#ffffff',
                cursor: 'pointer',
              }}
              className="mobile-menu-btn"
            >
              ☰
            </button>
          </div>
        </div>

        {/* Mobile Dropdown Menu */}
        {mobileMenuOpen && (
          <div
            style={{
              borderTop: '1px solid #e4e4e7',
              backgroundColor: '#ffffff',
              padding: '16px 24px',
              display: 'flex',
              flexDirection: 'column',
              gap: '12px',
            }}
          >
            <button onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })} style={mobileNavLinkStyle}>
              Home
            </button>
            <button onClick={() => scrollToSection('features')} style={mobileNavLinkStyle}>
              Features
            </button>
            <button onClick={() => scrollToSection('how-it-works')} style={mobileNavLinkStyle}>
              How It Works
            </button>
            <button onClick={() => scrollToSection('about')} style={mobileNavLinkStyle}>
              About
            </button>
          </div>
        )}
      </header>

      {/* 2. HERO SECTION */}
      <section
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
          padding: '72px 24px 64px',
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '48px',
          alignItems: 'center',
        }}
      >
        {/* Left Column: Headline & CTAs */}
        <div>
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '6px 12px',
              borderRadius: '9999px',
              backgroundColor: '#f4f4f5',
              border: '1px solid #e4e4e7',
              fontSize: '12px',
              fontWeight: 600,
              color: '#27272a',
              marginBottom: '20px',
            }}
          >
            <span style={{ width: '7px', height: '7px', borderRadius: '50%', backgroundColor: '#16a34a' }} />
            M.Sc. Cybersecurity Research Framework
          </div>

          <h1
            style={{
              fontSize: 'clamp(32px, 4.5vw, 52px)',
              fontWeight: 800,
              lineHeight: 1.12,
              letterSpacing: '-0.03em',
              color: '#09090b',
              margin: '0 0 20px 0',
            }}
          >
            Smarter Security Testing for Modern Web Applications
          </h1>

          <p
            style={{
              fontSize: '17px',
              lineHeight: 1.65,
              color: '#52525b',
              margin: '0 0 28px 0',
              maxWidth: '560px',
            }}
          >
            AI-WebSecTest combines automated web security testing, intelligent vulnerability
            classification, intrusion detection, and risk prioritization in one platform.
          </p>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', marginBottom: '24px' }}>
            <Link
              to="/signup"
              style={{
                padding: '13px 24px',
                borderRadius: '8px',
                backgroundColor: '#09090b',
                color: '#ffffff',
                fontSize: '15px',
                fontWeight: 600,
                textDecoration: 'none',
                border: '1px solid #09090b',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              Get Started <span>→</span>
            </Link>
            <button
              onClick={() => scrollToSection('features')}
              style={{
                padding: '13px 24px',
                borderRadius: '8px',
                backgroundColor: '#ffffff',
                color: '#09090b',
                fontSize: '15px',
                fontWeight: 600,
                border: '1px solid #09090b',
                cursor: 'pointer',
              }}
            >
              Explore Features
            </button>
          </div>

          {/* Concise Trust / Authorization Note */}
          <div
            style={{
              padding: '12px 16px',
              borderRadius: '8px',
              backgroundColor: '#fafafa',
              border: '1px solid #e4e4e7',
              fontSize: '13px',
              color: '#52525b',
              lineHeight: 1.5,
            }}
          >
            <strong style={{ color: '#09090b' }}>Authorized Testing Only:</strong> Security scans must
            only be performed on web applications and systems you own or have explicit authorization to test.
          </div>
        </div>

        {/* Right Column: Clean Security Workspace Preview Card */}
        <div
          style={{
            backgroundColor: '#fafafa',
            border: '1px solid #e4e4e7',
            borderRadius: '14px',
            padding: '20px',
            boxShadow: '0 12px 32px -12px rgba(9, 9, 11, 0.08)',
          }}
        >
          {/* Mock Window Top Bar */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              paddingBottom: '14px',
              marginBottom: '16px',
              borderBottom: '1px solid #e4e4e7',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#d4d4d8' }} />
              <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#d4d4d8' }} />
              <span style={{ width: '10px', height: '10px', borderRadius: '50%', backgroundColor: '#d4d4d8' }} />
              <span style={{ marginLeft: '8px', fontSize: '12px', fontFamily: 'monospace', color: '#71717a' }}>
                workspace / security-overview
              </span>
            </div>
            <span
              style={{
                fontSize: '11px',
                fontWeight: 600,
                padding: '3px 8px',
                borderRadius: '9999px',
                backgroundColor: '#dcfce7',
                color: '#166534',
                border: '1px solid #bbf7d0',
              }}
            >
              Platform Preview
            </span>
          </div>

          {/* Mini KPI Row */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(3, 1fr)',
              gap: '10px',
              marginBottom: '16px',
            }}
          >
            <div style={previewStatCardStyle}>
              <span style={{ fontSize: '11px', color: '#71717a', fontWeight: 600 }}>TOTAL FINDINGS</span>
              <div style={{ fontSize: '22px', fontWeight: 800, color: '#09090b', marginTop: '4px' }}>15</div>
              <span style={{ fontSize: '11px', color: '#52525b' }}>Classified items</span>
            </div>
            <div style={previewStatCardStyle}>
              <span style={{ fontSize: '11px', color: '#71717a', fontWeight: 600 }}>CRITICAL / HIGH</span>
              <div style={{ fontSize: '22px', fontWeight: 800, color: '#dc2626', marginTop: '4px' }}>5</div>
              <span style={{ fontSize: '11px', color: '#52525b' }}>Priority triage</span>
            </div>
            <div style={previewStatCardStyle}>
              <span style={{ fontSize: '11px', color: '#71717a', fontWeight: 600 }}>IDS MONITOR</span>
              <div style={{ fontSize: '22px', fontWeight: 800, color: '#16a34a', marginTop: '4px' }}>Active</div>
              <span style={{ fontSize: '11px', color: '#52525b' }}>Event telemetry</span>
            </div>
          </div>

          {/* Severity Bar Visualization */}
          <div
            style={{
              backgroundColor: '#ffffff',
              border: '1px solid #e4e4e7',
              borderRadius: '10px',
              padding: '14px',
              marginBottom: '14px',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: 600, marginBottom: '8px' }}>
              <span>Risk Prioritization Distribution</span>
              <span style={{ color: '#71717a' }}>Scan #SCAN-001</span>
            </div>
            <div style={{ display: 'flex', height: '8px', borderRadius: '9999px', overflow: 'hidden', gap: '2px' }}>
              <div style={{ width: '10%', backgroundColor: '#dc2626' }} title="Critical" />
              <div style={{ width: '25%', backgroundColor: '#ea580c' }} title="High" />
              <div style={{ width: '40%', backgroundColor: '#eab308' }} title="Medium" />
              <div style={{ width: '25%', backgroundColor: '#16a34a' }} title="Low" />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: '#71717a', marginTop: '8px' }}>
              <span>● 1 Critical</span>
              <span>● 4 High</span>
              <span>● 6 Medium</span>
              <span>● 4 Low</span>
            </div>
          </div>

          {/* Mini Findings List */}
          <div
            style={{
              backgroundColor: '#ffffff',
              border: '1px solid #e4e4e7',
              borderRadius: '10px',
              padding: '12px 14px',
            }}
          >
            <div style={{ fontSize: '12px', fontWeight: 600, marginBottom: '8px', color: '#09090b' }}>
              Recent Classified Findings
            </div>
            {[
              { id: 'VULN-001', title: 'SQL Injection', sev: 'Critical', color: '#dc2626', bg: '#fef2f2' },
              { id: 'VULN-002', title: 'Cross-Site Scripting (XSS)', sev: 'High', color: '#ea580c', bg: '#fff7ed' },
              { id: 'VULN-003', title: 'Missing Security Headers', sev: 'Medium', color: '#ca8a04', bg: '#fefce8' },
            ].map((item) => (
              <div
                key={item.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '7px 0',
                  borderTop: '1px solid #f4f4f5',
                  fontSize: '12px',
                }}
              >
                <div>
                  <span style={{ fontFamily: 'monospace', color: '#71717a', marginRight: '8px' }}>{item.id}</span>
                  <span style={{ fontWeight: 600, color: '#09090b' }}>{item.title}</span>
                </div>
                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: 600,
                    padding: '2px 8px',
                    borderRadius: '9999px',
                    color: item.color,
                    backgroundColor: item.bg,
                  }}
                >
                  {item.sev}
                </span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 3. WHY AI-WEBSECTEST? SECTION */}
      <section
        style={{
          backgroundColor: '#fafafa',
          borderTop: '1px solid #e4e4e7',
          borderBottom: '1px solid #e4e4e7',
          padding: '72px 24px',
        }}
      >
        <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
          <div style={{ maxWidth: '680px', marginBottom: '44px' }}>
            <p style={eyebrowStyle}>WHY AI-WEBSECTEST?</p>
            <h2 style={sectionTitleStyle}>
              Addressing the Complexity of Modern Web Application Security
            </h2>
            <p style={sectionSubtitleStyle}>
              Security assessments often generate fragmented data across multiple tools. AI-WebSecTest
              provides a structured workspace to streamline testing, classification, and review.
            </p>
          </div>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
              gap: '20px',
            }}
          >
            {[
              {
                title: 'Manual Testing Takes Significant Time',
                desc: 'Repeatedly configuring and tracking routine web application checks manually slows down assessment cycles.',
              },
              {
                title: 'Findings Are Difficult to Prioritize',
                desc: 'Raw scanner outputs can overwhelm analysts without structured severity classification and risk indicators.',
              },
              {
                title: 'Fragmented Visibility Across Tools',
                desc: 'Teams need a clearer, consolidated view of both application vulnerabilities and suspicious request activity.',
              },
              {
                title: 'Unified Security Review Workspace',
                desc: 'A single dashboard helps researchers and developers organize scans, inspect findings, and review reports in one place.',
              },
            ].map((card, idx) => (
              <div
                key={idx}
                style={{
                  backgroundColor: '#ffffff',
                  border: '1px solid #e4e4e7',
                  borderRadius: '12px',
                  padding: '24px',
                }}
              >
                <div
                  style={{
                    width: '28px',
                    height: '28px',
                    borderRadius: '6px',
                    backgroundColor: '#f4f4f5',
                    color: '#09090b',
                    fontWeight: 700,
                    fontSize: '13px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    marginBottom: '14px',
                  }}
                >
                  0{idx + 1}
                </div>
                <h3 style={{ fontSize: '16px', fontWeight: 700, margin: '0 0 8px 0', color: '#09090b' }}>
                  {card.title}
                </h3>
                <p style={{ fontSize: '14px', lineHeight: 1.6, color: '#52525b', margin: 0 }}>{card.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 4. FEATURES SECTION */}
      <section id="features" style={{ maxWidth: '1200px', margin: '0 auto', padding: '80px 24px' }}>
        <div style={{ maxWidth: '680px', marginBottom: '48px' }}>
          <p style={eyebrowStyle}>PLATFORM CAPABILITIES</p>
          <h2 style={sectionTitleStyle}>Core Modules of the AI-WebSecTest Framework</h2>
          <p style={sectionSubtitleStyle}>
            Designed to support reproducible web security testing, structured vulnerability triage,
            and intrusion monitoring within an integrated architecture.
          </p>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
            gap: '24px',
          }}
        >
          {features.map((feat, idx) => (
            <div
              key={idx}
              style={{
                backgroundColor: '#ffffff',
                border: '1px solid #e4e4e7',
                borderRadius: '12px',
                padding: '28px',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
              }}
            >
              <div>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    marginBottom: '18px',
                  }}
                >
                  <div
                    style={{
                      width: '40px',
                      height: '40px',
                      borderRadius: '10px',
                      backgroundColor: '#f4f4f5',
                      border: '1px solid #e4e4e7',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#09090b',
                    }}
                  >
                    {feat.icon}
                  </div>
                  <span
                    style={{
                      fontSize: '11px',
                      fontWeight: 600,
                      padding: '4px 10px',
                      borderRadius: '9999px',
                      backgroundColor: '#f4f4f5',
                      color: '#3f3f46',
                    }}
                  >
                    {feat.badge}
                  </span>
                </div>

                <h3 style={{ fontSize: '18px', fontWeight: 700, color: '#09090b', margin: '0 0 10px 0' }}>
                  {feat.title}
                </h3>
                <p style={{ fontSize: '14px', lineHeight: 1.65, color: '#52525b', margin: 0 }}>
                  {feat.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 5. HOW IT WORKS SECTION */}
      <section
        id="how-it-works"
        style={{
          backgroundColor: '#fafafa',
          borderTop: '1px solid #e4e4e7',
          borderBottom: '1px solid #e4e4e7',
          padding: '80px 24px',
        }}
      >
        <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
          <div style={{ maxWidth: '680px', marginBottom: '48px' }}>
            <p style={eyebrowStyle}>ASSESSMENT WORKFLOW</p>
            <h2 style={sectionTitleStyle}>How AI-WebSecTest Works</h2>
            <p style={sectionSubtitleStyle}>
              A transparent, five-stage workflow from target registration to prioritized reporting.
              Current operational modules and research demonstration stages are clearly labeled.
            </p>
          </div>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))',
              gap: '16px',
            }}
          >
            {workflowSteps.map((item) => (
              <div
                key={item.step}
                style={{
                  backgroundColor: '#ffffff',
                  border: '1px solid #e4e4e7',
                  borderRadius: '12px',
                  padding: '22px',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                }}
              >
                <div>
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      marginBottom: '14px',
                    }}
                  >
                    <span
                      style={{
                        fontFamily: 'monospace',
                        fontSize: '13px',
                        fontWeight: 700,
                        padding: '4px 8px',
                        borderRadius: '6px',
                        backgroundColor: '#09090b',
                        color: '#ffffff',
                      }}
                    >
                      STEP {item.step}
                    </span>
                    <span
                      style={{
                        fontSize: '11px',
                        fontWeight: 600,
                        color: '#52525b',
                        backgroundColor: '#f4f4f5',
                        padding: '3px 8px',
                        borderRadius: '9999px',
                      }}
                    >
                      {item.status}
                    </span>
                  </div>
                  <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#09090b', margin: '0 0 8px 0' }}>
                    {item.title}
                  </h3>
                  <p style={{ fontSize: '13.5px', lineHeight: 1.6, color: '#52525b', margin: 0 }}>
                    {item.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 6. ABOUT & RESEARCH ATTRIBUTION SECTION */}
      <section id="about" style={{ maxWidth: '1200px', margin: '0 auto', padding: '80px 24px' }}>
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
            gap: '40px',
            alignItems: 'start',
          }}
        >
          {/* Left: Research Overview */}
          <div>
            <p style={eyebrowStyle}>ABOUT THE PROJECT</p>
            <h2 style={sectionTitleStyle}>AI-WebSecTest Research Framework</h2>
            <p style={{ fontSize: '15px', lineHeight: 1.7, color: '#3f3f46', marginBottom: '16px' }}>
              <strong>AI-WebSecTest</strong> (<em>“AI-Assisted Automated Security Testing and Intrusion
              Detection for Web Applications: A Framework for Vulnerability Classification and Risk
              Prioritization”</em>) is an M.Sc. Computer Science research project focused on bridging
              automated security scanning with structured analytical workflows.
            </p>
            <p style={{ fontSize: '15px', lineHeight: 1.7, color: '#52525b', marginBottom: '24px' }}>
              Built with a modern React frontend, Python FastAPI backend, and PostgreSQL persistence layer,
              the platform investigates how machine-learning-assisted classification and risk scoring can
              help security analysts interpret web vulnerabilities and suspicious traffic more effectively.
            </p>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(2, 1fr)',
                gap: '12px',
              }}
            >
              {[
                'Automated Web Security Testing',
                'ML Vulnerability Classification',
                'Intrusion Detection Telemetry',
                'Risk-Based Prioritization',
              ].map((focus, i) => (
                <div
                  key={i}
                  style={{
                    padding: '12px 14px',
                    borderRadius: '8px',
                    backgroundColor: '#fafafa',
                    border: '1px solid #e4e4e7',
                    fontSize: '13px',
                    fontWeight: 600,
                    color: '#18181b',
                  }}
                >
                  ✓ {focus}
                </div>
              ))}
            </div>
          </div>

          {/* Right: Editable Academic Creator Card */}
          <div
            style={{
              backgroundColor: '#fafafa',
              border: '1px solid #e4e4e7',
              borderRadius: '14px',
              padding: '28px',
            }}
          >
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                paddingBottom: '16px',
                marginBottom: '20px',
                borderBottom: '1px solid #e4e4e7',
              }}
            >
              <div>
                <span style={{ fontSize: '11px', fontWeight: 700, letterSpacing: '0.06em', color: '#71717a' }}>
                  ACADEMIC ATTRIBUTION
                </span>
                <h3 style={{ fontSize: '18px', fontWeight: 700, margin: '4px 0 0 0', color: '#09090b' }}>
                  Researcher & Project Details
                </h3>
              </div>
              <span
                style={{
                  fontSize: '11px',
                  fontWeight: 600,
                  padding: '4px 10px',
                  borderRadius: '9999px',
                  backgroundColor: '#ffffff',
                  border: '1px solid #d4d4d8',
                  color: '#3f3f46',
                }}
              >
                M.Sc. CS
              </span>
            </div>

            <dl style={{ margin: 0, display: 'grid', gap: '14px' }}>
              <div style={metaRowStyle}>
                <dt style={metaLabelStyle}>Project Title</dt>
                <dd style={metaValueStyle}>AI-WebSecTest</dd>
              </div>
              <div style={metaRowStyle}>
                <dt style={metaLabelStyle}>Student / Researcher</dt>
                <dd style={metaValueStyle}>[Student Name — Editable Placeholder]</dd>
              </div>
              <div style={metaRowStyle}>
                <dt style={metaLabelStyle}>Course / Program</dt>
                <dd style={metaValueStyle}>M.Sc. Computer Science</dd>
              </div>
              <div style={metaRowStyle}>
                <dt style={metaLabelStyle}>Institution / College</dt>
                <dd style={metaValueStyle}>[Institution / College Name — Editable Placeholder]</dd>
              </div>
              <div style={{ ...metaRowStyle, borderBottom: 'none', paddingBottom: 0 }}>
                <dt style={metaLabelStyle}>Project Guide</dt>
                <dd style={metaValueStyle}>[Project Guide Name — Editable Placeholder]</dd>
              </div>
            </dl>
          </div>
        </div>
      </section>

      {/* 7. CALL-TO-ACTION BANNER */}
      <section style={{ padding: '0 24px 72px' }}>
        <div
          style={{
            maxWidth: '1200px',
            margin: '0 auto',
            backgroundColor: '#09090b',
            color: '#ffffff',
            borderRadius: '16px',
            padding: '48px 32px',
            display: 'flex',
            flexWrap: 'wrap',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '24px',
          }}
        >
          <div style={{ maxWidth: '620px' }}>
            <h2 style={{ fontSize: '28px', fontWeight: 800, margin: '0 0 10px 0', letterSpacing: '-0.02em' }}>
              Ready to explore the AI-WebSecTest workspace?
            </h2>
            <p style={{ fontSize: '15px', color: '#a1a1aa', margin: 0, lineHeight: 1.6 }}>
              Create a researcher account to configure authorized web application scans, inspect
              classified findings, and review security assessment reports.
            </p>
          </div>

          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <Link
              to="/signup"
              style={{
                padding: '12px 22px',
                borderRadius: '8px',
                backgroundColor: '#ffffff',
                color: '#09090b',
                fontSize: '14px',
                fontWeight: 700,
                textDecoration: 'none',
              }}
            >
              Create Account
            </Link>
            <Link
              to="/login"
              style={{
                padding: '12px 22px',
                borderRadius: '8px',
                backgroundColor: 'transparent',
                color: '#ffffff',
                border: '1px solid #3f3f46',
                fontSize: '14px',
                fontWeight: 600,
                textDecoration: 'none',
              }}
            >
              Sign In
            </Link>
          </div>
        </div>
      </section>

      {/* 8. FOOTER */}
      <footer
        style={{
          borderTop: '1px solid #e4e4e7',
          backgroundColor: '#fafafa',
          padding: '40px 24px',
        }}
      >
        <div
          style={{
            maxWidth: '1200px',
            margin: '0 auto',
            display: 'flex',
            flexWrap: 'wrap',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: '20px',
          }}
        >
          <div>
            <div style={{ fontWeight: 700, fontSize: '15px', color: '#09090b' }}>AI-WebSecTest</div>
            <p style={{ fontSize: '13px', color: '#71717a', margin: '4px 0 0 0' }}>
              © {new Date().getFullYear()} AI-WebSecTest • M.Sc. Computer Science Research Project
            </p>
          </div>

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '20px', fontSize: '13px', fontWeight: 500 }}>
            <button onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })} style={footerLinkStyle}>
              Home
            </button>
            <button onClick={() => scrollToSection('features')} style={footerLinkStyle}>
              Features
            </button>
            <button onClick={() => scrollToSection('about')} style={footerLinkStyle}>
              About
            </button>
            <Link to="/login" style={{ ...footerLinkStyle, textDecoration: 'none' }}>
              Login
            </Link>
            <Link to="/signup" style={{ ...footerLinkStyle, textDecoration: 'none' }}>
              Sign Up
            </Link>
            <button onClick={() => scrollToSection('about')} style={footerLinkStyle}>
              Contact
            </button>
          </div>
        </div>
      </footer>
    </div>
  );
};

// --- CLEAN REUSABLE INLINE STYLE OBJECTS ---
const navLinkStyle = {
  background: 'none',
  border: 'none',
  padding: 0,
  fontSize: '14px',
  fontWeight: 500,
  color: '#3f3f46',
  cursor: 'pointer',
};

const mobileNavLinkStyle = {
  background: 'none',
  border: 'none',
  padding: '8px 0',
  fontSize: '15px',
  fontWeight: 600,
  color: '#09090b',
  textAlign: 'left',
  cursor: 'pointer',
};

const previewStatCardStyle = {
  backgroundColor: '#ffffff',
  border: '1px solid #e4e4e7',
  borderRadius: '10px',
  padding: '12px',
};

const eyebrowStyle = {
  fontSize: '12px',
  fontWeight: 700,
  letterSpacing: '0.08em',
  color: '#52525b',
  margin: '0 0 8px 0',
};

const sectionTitleStyle = {
  fontSize: 'clamp(24px, 3vw, 34px)',
  fontWeight: 800,
  letterSpacing: '-0.025em',
  color: '#09090b',
  margin: '0 0 12px 0',
};

const sectionSubtitleStyle = {
  fontSize: '16px',
  lineHeight: 1.6,
  color: '#52525b',
  margin: 0,
};

const metaRowStyle = {
  display: 'flex',
  justifyContent: 'space-between',
  gap: '16px',
  paddingBottom: '12px',
  borderBottom: '1px solid #e4e4e7',
  fontSize: '14px',
};

const metaLabelStyle = {
  color: '#71717a',
  fontWeight: 500,
};

const metaValueStyle = {
  margin: 0,
  color: '#09090b',
  fontWeight: 600,
  textAlign: 'right',
};

const footerLinkStyle = {
  background: 'none',
  border: 'none',
  padding: 0,
  color: '#52525b',
  cursor: 'pointer',
  fontSize: '13px',
  fontWeight: 500,
};

export default LandingPage;