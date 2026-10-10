import { Menu, Bell } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useLocation } from 'react-router-dom';

export default function Navbar({ setMobileOpen }) {
  const { user } = useAuth();
  const location = useLocation();

  const getPageTitle = () => {
    const path = location.pathname;
    if (path === '/dashboard') return 'Dashboard';
    if (path === '/new-scan') return 'New Scan';
    if (path.startsWith('/scan/')) return 'Scan Details';
    if (path === '/vulnerabilities') return 'Findings & Vulnerabilities';
    if (path === '/intrusion-detection') return 'Intrusion Detection';
    if (path === '/reports') return 'Reports';
    if (path === '/settings') return 'Settings';
    if (path === '/profile') return 'Profile';
    return 'AI-WebSec';
  };

  return (
    <header className="sticky top-0 z-10 flex h-16 shrink-0 items-center gap-x-4 border-b border-slate-800 bg-slate-900/80 backdrop-blur-md px-4 sm:gap-x-6 sm:px-6 lg:px-8">
      <button
        type="button"
        className="-m-2.5 p-2.5 text-slate-400 lg:hidden hover:text-white"
        onClick={() => setMobileOpen(true)}
      >
        <span className="sr-only">Open sidebar</span>
        <Menu className="h-6 w-6" aria-hidden="true" />
      </button>

      <div className="flex flex-1 items-center justify-between gap-x-4 self-stretch lg:gap-x-6">
        <h1 className="text-lg font-semibold leading-6 text-white">{getPageTitle()}</h1>
        
        <div className="flex items-center gap-x-4 lg:gap-x-6">
          {/* Notifications (Placeholder - no backend for this currently) */}
          <button type="button" className="-m-2.5 p-2.5 text-slate-400 hover:text-white">
            <span className="sr-only">View notifications</span>
            <Bell className="h-5 w-5" aria-hidden="true" />
          </button>

          {/* Separator */}
          <div className="hidden lg:block lg:h-6 lg:w-px lg:bg-slate-800" aria-hidden="true" />

          {/* Profile */}
          <div className="flex items-center gap-x-4">
            <div className="h-8 w-8 rounded-full bg-brand-600 flex items-center justify-center text-sm font-medium text-white ring-2 ring-slate-800">
              {user?.username?.charAt(0).toUpperCase() || 'U'}
            </div>
            <span className="hidden lg:flex lg:items-center text-sm font-semibold leading-6 text-slate-200">
              {user?.username}
            </span>
          </div>
        </div>
      </div>
    </header>
  );
}