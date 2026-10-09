import React from 'react';
import { Link } from 'react-router-dom';
import { ShieldAlert, ShieldCheck, Zap, Activity, ChevronRight } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';

export default function LandingPage() {
  const { user } = useAuth();

  return (
    <div className="bg-slate-950 min-h-screen text-slate-200 selection:bg-brand-500/30 font-sans">
      {/* Header */}
      <header className="absolute inset-x-0 top-0 z-50">
        <nav className="flex items-center justify-between p-6 lg:px-8 max-w-7xl mx-auto" aria-label="Global">
          <div className="flex lg:flex-1">
            <Link to="/" className="-m-1.5 p-1.5 flex items-center gap-2">
              <ShieldAlert className="h-8 w-8 text-brand-500" />
              <span className="text-xl font-bold text-white tracking-tight">AI-WebSec</span>
            </Link>
          </div>
          <div className="flex flex-1 justify-end items-center gap-x-6">
            {user ? (
              <Link
                to="/dashboard"
                className="rounded-md bg-brand-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600"
              >
                Go to Dashboard
              </Link>
            ) : (
              <>
                <Link to="/login" className="text-sm font-semibold leading-6 text-white hover:text-brand-400">
                  Log in
                </Link>
                <Link
                  to="/register"
                  className="rounded-md bg-brand-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600"
                >
                  Get started
                </Link>
              </>
            )}
          </div>
        </nav>
      </header>

      <main>
        {/* Hero section */}
        <div className="relative isolate pt-14">
          <div className="absolute inset-x-0 -top-40 -z-10 transform-gpu overflow-hidden blur-3xl sm:-top-80" aria-hidden="true">
            <div className="relative left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 rotate-[30deg] bg-gradient-to-tr from-[#06b6d4] to-[#3b82f6] opacity-20 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]"></div>
          </div>
          <div className="py-24 sm:py-32 lg:pb-40">
            <div className="mx-auto max-w-7xl px-6 lg:px-8">
              <div className="mx-auto max-w-2xl text-center">
                <div className="hidden sm:mb-8 sm:flex sm:justify-center">
                  <div className="relative rounded-full px-3 py-1 text-sm leading-6 text-slate-400 ring-1 ring-slate-700/50 hover:ring-slate-700">
                    Announcing our next-generation scanning engine.{' '}
                    <Link to="/register" className="font-semibold text-brand-400">
                      <span className="absolute inset-0" aria-hidden="true" />
                      Read more <span aria-hidden="true">&rarr;</span>
                    </Link>
                  </div>
                </div>
                <h1 className="text-4xl font-bold tracking-tight text-white sm:text-6xl">
                  Automated Security for Modern Web Apps
                </h1>
                <p className="mt-6 text-lg leading-8 text-slate-400">
                  AI-WebSecTest is a fast, precise, and automated web vulnerability scanner designed for modern applications. Discover flaws, investigate intrusions, and secure your endpoints.
                </p>
                <div className="mt-10 flex items-center justify-center gap-x-6">
                  {user ? (
                    <Link
                      to="/dashboard"
                      className="rounded-md bg-brand-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600"
                    >
                      Open Dashboard
                    </Link>
                  ) : (
                    <Link
                      to="/register"
                      className="rounded-md bg-brand-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600"
                    >
                      Start Scanning
                    </Link>
                  )}
                  <a href="#features" className="text-sm font-semibold leading-6 text-white hover:text-brand-400 flex items-center gap-1">
                    Learn more <ChevronRight className="h-4 w-4" />
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Feature section */}
        <div id="features" className="mx-auto max-w-7xl px-6 lg:px-8 py-24 sm:py-32">
          <div className="mx-auto max-w-2xl lg:text-center">
            <h2 className="text-base font-semibold leading-7 text-brand-400">Deploy faster</h2>
            <p className="mt-2 text-3xl font-bold tracking-tight text-white sm:text-4xl">
              Everything you need to secure your app
            </p>
            <p className="mt-6 text-lg leading-8 text-slate-400">
              Stop guessing if your endpoints are secure. Automate discovery, track vulnerabilities, and generate actionable reports in minutes.
            </p>
          </div>
          <div className="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
            <dl className="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
              <div className="flex flex-col">
                <dt className="flex items-center gap-x-3 text-base font-semibold leading-7 text-white">
                  <div className="h-10 w-10 flex items-center justify-center rounded-lg bg-slate-900 border border-slate-800 shadow-sm">
                    <Zap className="h-6 w-6 text-brand-500" aria-hidden="true" />
                  </div>
                  Fast Automated Scanning
                </dt>
                <dd className="mt-4 flex flex-auto flex-col text-base leading-7 text-slate-400">
                  <p className="flex-auto">
                    Initiate deep crawls and vulnerability checks with pre-configured scan profiles tailored for APIs and Single Page Applications.
                  </p>
                </dd>
              </div>
              <div className="flex flex-col">
                <dt className="flex items-center gap-x-3 text-base font-semibold leading-7 text-white">
                  <div className="h-10 w-10 flex items-center justify-center rounded-lg bg-slate-900 border border-slate-800 shadow-sm">
                    <ShieldCheck className="h-6 w-6 text-brand-500" aria-hidden="true" />
                  </div>
                  Clear Actionable Findings
                </dt>
                <dd className="mt-4 flex flex-auto flex-col text-base leading-7 text-slate-400">
                  <p className="flex-auto">
                    No more noisy false positives. Findings are prioritized by severity, providing exact evidence and remediation guidance.
                  </p>
                </dd>
              </div>
              <div className="flex flex-col">
                <dt className="flex items-center gap-x-3 text-base font-semibold leading-7 text-white">
                  <div className="h-10 w-10 flex items-center justify-center rounded-lg bg-slate-900 border border-slate-800 shadow-sm">
                    <Activity className="h-6 w-6 text-brand-500" aria-hidden="true" />
                  </div>
                  Intrusion Detection
                </dt>
                <dd className="mt-4 flex flex-auto flex-col text-base leading-7 text-slate-400">
                  <p className="flex-auto">
                    Monitor security events and potential malicious activity in real-time. Investigate logs to uncover persistent threats.
                  </p>
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </main>
      
      <footer className="border-t border-slate-800 py-12 mt-20">
        <div className="mx-auto max-w-7xl px-6 lg:px-8 flex flex-col md:flex-row justify-between items-center">
          <div className="flex items-center gap-2 mb-4 md:mb-0">
            <ShieldAlert className="h-6 w-6 text-brand-500" />
            <span className="text-lg font-bold text-white tracking-tight">AI-WebSec</span>
          </div>
          <p className="text-sm text-slate-500">
            &copy; {new Date().getFullYear()} AI-WebSecTest. All rights reserved.
          </p>
          <div className="flex gap-4 mt-4 md:mt-0">
             <a href="#" className="text-slate-500 hover:text-white">
               GitHub
             </a>
          </div>
        </div>
      </footer>
    </div>
  );
}