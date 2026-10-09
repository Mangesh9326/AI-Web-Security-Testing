import React from 'react';
import { Link } from 'react-router-dom';
import { ShieldAlert, Home, ArrowLeft } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-slate-950 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md text-center">
        <ShieldAlert className="mx-auto h-16 w-16 text-brand-500 mb-6" />
        <h2 className="text-3xl font-bold tracking-tight text-white sm:text-5xl">404</h2>
        <p className="mt-4 text-base leading-7 text-slate-400">
          Sorry, we couldn't find the page you're looking for.
        </p>
        <div className="mt-10 flex items-center justify-center gap-x-6">
          <Link
            to="/dashboard"
            className="btn-primary inline-flex items-center gap-2"
          >
            <Home className="h-4 w-4" /> Go to Dashboard
          </Link>
          <button onClick={() => window.history.back()} className="text-sm font-semibold leading-6 text-slate-300 hover:text-white flex items-center gap-1">
            <ArrowLeft className="h-4 w-4" /> Go back
          </button>
        </div>
      </div>
    </div>
  );
}
