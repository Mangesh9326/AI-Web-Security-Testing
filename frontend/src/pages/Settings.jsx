import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { Settings as SettingsIcon, Bell, Shield, Key, Save, Loader2, CheckCircle2 } from 'lucide-react';

export default function Settings() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [saved, setSaved] = useState(false);
  
  const [settings, setSettings] = useState({
    emailNotifications: true,
    alertThreshold: 'high',
    autoScan: false,
    darkMode: true
  });

  const handleSave = (e) => {
    e.preventDefault();
    setLoading(true);
    setSaved(false);
    
    // Simulate API call
    setTimeout(() => {
      setLoading(false);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    }, 800);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
          <SettingsIcon className="h-8 w-8 text-brand-500" />
          Workspace Settings
        </h2>
        <p className="mt-1 text-sm text-slate-400">
          Manage your AI-WebSec application preferences and workspace defaults.
        </p>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        
        {/* Notifications Section */}
        <div className="card">
          <div className="card-header flex items-center gap-2">
            <Bell className="h-5 w-5 text-slate-400" />
            <h3 className="text-base font-semibold text-white">Notifications</h3>
          </div>
          <div className="card-body space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <label htmlFor="emailNotifs" className="text-sm font-medium text-slate-200 block">Email Alerts</label>
                <p className="text-xs text-slate-500 mt-1">Receive email notifications for critical security events.</p>
              </div>
              <div className="flex items-center">
                <input
                  id="emailNotifs"
                  type="checkbox"
                  checked={settings.emailNotifications}
                  onChange={(e) => setSettings({...settings, emailNotifications: e.target.checked})}
                  className="h-4 w-4 rounded border-slate-700 bg-slate-900 text-brand-600 focus:ring-brand-600 focus:ring-offset-slate-900"
                />
              </div>
            </div>

            <hr className="border-slate-800" />

            <div>
              <label htmlFor="alertThreshold" className="label">Alert Threshold</label>
              <select
                id="alertThreshold"
                value={settings.alertThreshold}
                onChange={(e) => setSettings({...settings, alertThreshold: e.target.value})}
                className="mt-2 block w-full sm:max-w-xs"
              >
                <option value="critical">Critical Only</option>
                <option value="high">High & Critical</option>
                <option value="medium">Medium and Above</option>
                <option value="all">All Events</option>
              </select>
              <p className="mt-2 text-xs text-slate-500">
                Minimum severity level required to trigger an immediate notification.
              </p>
            </div>
          </div>
        </div>

        {/* Security Section */}
        <div className="card">
          <div className="card-header flex items-center gap-2">
            <Shield className="h-5 w-5 text-slate-400" />
            <h3 className="text-base font-semibold text-white">Security & Scanning</h3>
          </div>
          <div className="card-body space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <label htmlFor="autoScan" className="text-sm font-medium text-slate-200 block">Automated Recurring Scans</label>
                <p className="text-xs text-slate-500 mt-1">Automatically run baseline scans against registered targets weekly.</p>
              </div>
              <div className="flex items-center">
                <input
                  id="autoScan"
                  type="checkbox"
                  checked={settings.autoScan}
                  onChange={(e) => setSettings({...settings, autoScan: e.target.checked})}
                  className="h-4 w-4 rounded border-slate-700 bg-slate-900 text-brand-600 focus:ring-brand-600 focus:ring-offset-slate-900"
                />
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-end items-center gap-4">
          {saved && (
            <span className="text-sm font-medium text-green-400 flex items-center gap-1.5 animate-in fade-in">
              <CheckCircle2 className="h-4 w-4" /> Settings saved
            </span>
          )}
          <button type="submit" className="btn-primary" disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <Save className="h-4 w-4 mr-2" />}
            Save Changes
          </button>
        </div>

      </form>
    </div>
  );
}