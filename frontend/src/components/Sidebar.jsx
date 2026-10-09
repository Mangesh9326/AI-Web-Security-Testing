import { Link, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  ScanLine, 
  ListOrdered, 
  History, 
  ShieldAlert, 
  ShieldBan, 
  Activity, 
  FileText, 
  Settings, 
  User, 
  LogOut,
  X,
  Menu
} from 'lucide-react';
import { useAuth } from '../hooks/useAuth';

export default function Sidebar({ mobileOpen, setMobileOpen }) {
  const location = useLocation();
  const { logout } = useAuth();
  
  const navGroups = [
    {
      title: 'Overview',
      items: [
        { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard }
      ]
    },
    {
      title: 'Security Operations',
      items: [
        { name: 'New Scan', path: '/new-scan', icon: ScanLine },
        { name: 'Scan History', path: '/scans', icon: History },
        { name: 'Findings', path: '/findings', icon: ShieldAlert },
        { name: 'Vulnerabilities', path: '/vulnerabilities', icon: ShieldBan },
        { name: 'Intrusion Detection', path: '/intrusion-detection', icon: Activity },
        { name: 'Logs', path: '/logs', icon: FileText },
      ]
    },
    {
      title: 'Reporting',
      items: [
        { name: 'Reports', path: '/reports', icon: FileText }
      ]
    },
    {
      title: 'Preferences',
      items: [
        { name: 'Settings', path: '/settings', icon: Settings },
        { name: 'Profile', path: '/profile', icon: User }
      ]
    }
  ];

  // Note: some paths above are mapped back to existing routes since they didn't all exist.
  // We'll update the routes in App.jsx to match exactly what's needed.

  const renderNavItems = () => (
    <div className="flex-1 px-4 space-y-8 overflow-y-auto py-6">
      {navGroups.map((group, idx) => (
        <div key={idx}>
          <h3 className="px-3 text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">
            {group.title}
          </h3>
          <div className="space-y-1">
            {group.items.map((item) => {
              const isActive = location.pathname.startsWith(item.path) && item.path !== '/' || location.pathname === item.path;
              const Icon = item.icon;
              return (
                <Link
                  key={item.name}
                  to={item.path}
                  onClick={() => setMobileOpen && setMobileOpen(false)}
                  className={`group flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                    isActive
                      ? 'bg-brand-500/10 text-brand-400'
                      : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                  }`}
                >
                  <Icon className={`mr-3 flex-shrink-0 h-5 w-5 ${isActive ? 'text-brand-400' : 'text-slate-400 group-hover:text-slate-300'}`} />
                  {item.name}
                </Link>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );

  return (
    <>
      {/* Mobile sidebar overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-40 lg:hidden" role="dialog" aria-modal="true">
          <div className="fixed inset-0 bg-slate-900/80 backdrop-blur-sm" onClick={() => setMobileOpen(false)}></div>
          <div className="fixed inset-y-0 left-0 flex w-72 flex-col bg-slate-900 border-r border-slate-800">
            <div className="flex h-16 shrink-0 items-center justify-between px-6 border-b border-slate-800 bg-slate-900/50">
              <span className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
                <ShieldAlert className="h-6 w-6 text-brand-500" />
                AI-WebSec
              </span>
              <button onClick={() => setMobileOpen(false)} className="text-slate-400 hover:text-white">
                <X className="h-6 w-6" />
              </button>
            </div>
            {renderNavItems()}
            <div className="p-4 border-t border-slate-800">
               <button onClick={logout} className="flex w-full items-center px-3 py-2 text-sm font-medium text-slate-300 rounded-md hover:bg-slate-800 hover:text-white transition-colors">
                 <LogOut className="mr-3 h-5 w-5 text-slate-400" />
                 Sign out
               </button>
            </div>
          </div>
        </div>
      )}

      {/* Desktop sidebar */}
      <div className="hidden lg:fixed lg:inset-y-0 lg:flex lg:w-64 lg:flex-col lg:border-r lg:border-slate-800 lg:bg-slate-900/95 lg:backdrop-blur-md">
        <div className="flex h-16 shrink-0 items-center px-6 border-b border-slate-800">
          <span className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <ShieldAlert className="h-6 w-6 text-brand-500" />
            AI-WebSec
          </span>
        </div>
        {renderNavItems()}
        <div className="p-4 border-t border-slate-800">
           <button onClick={logout} className="flex w-full items-center px-3 py-2 text-sm font-medium text-slate-300 rounded-md hover:bg-slate-800 hover:text-white transition-colors">
             <LogOut className="mr-3 h-5 w-5 text-slate-400" />
             Sign out
           </button>
        </div>
      </div>
    </>
  );
}