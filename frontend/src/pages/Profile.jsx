import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { updateProfile } from '../services/profileService';
import { User, Mail, Save, Loader2, CheckCircle2, ShieldAlert } from 'lucide-react';

export default function Profile() {
  const { user, setUser } = useAuth();
  const [loading, setLoading] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');
  
  const [formData, setFormData] = useState({
    fullName: user?.fullName || '',
    email: user?.email || '',
  });

  const handleSave = async (e) => {
    e.preventDefault();
    setLoading(true);
    setSaved(false);
    setError('');
    
    try {
      const data = await updateProfile({ fullName: formData.fullName, email: formData.email });
      setUser(data.profile);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (err) {
      setError(err.response?.data?.error || err.message || 'Unable to update profile.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight flex items-center gap-2">
          <User className="h-8 w-8 text-brand-500" />
          My Profile
        </h2>
        <p className="mt-1 text-sm text-slate-400">
          Manage your account information and credentials.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Profile Form */}
        <div className="card lg:col-span-2">
          <div className="card-header">
            <h3 className="text-base font-semibold text-white">Personal Information</h3>
          </div>
          <form onSubmit={handleSave}>
            <div className="card-body space-y-6">
              
              {error && (
                <div className="p-3 bg-red-500/10 border-l-2 border-red-500 flex items-center gap-2 text-sm text-red-500 rounded">
                  <ShieldAlert className="h-4 w-4" />
                  {error}
                </div>
              )}

              <div>
                <label htmlFor="fullName" className="label flex items-center gap-2">
                  <User className="h-4 w-4 text-slate-400" /> Full Name
                </label>
                <div className="mt-2">
                  <input
                    type="text"
                    id="fullName"
                    value={formData.fullName}
                    onChange={(e) => setFormData({...formData, fullName: e.target.value})}
                    className="block w-full sm:max-w-md"
                  />
                </div>
              </div>

              <div>
                <label htmlFor="email" className="label flex items-center gap-2">
                  <Mail className="h-4 w-4 text-slate-400" /> Email Address
                </label>
                <div className="mt-2">
                  <input
                    type="email"
                    id="email"
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    className="block w-full sm:max-w-md"
                    placeholder="you@example.com"
                  />
                </div>
              </div>

            </div>
            
            <div className="card-footer flex justify-end gap-4 items-center">
              {saved && (
                <span className="text-sm font-medium text-green-400 flex items-center gap-1.5 animate-in fade-in">
                  <CheckCircle2 className="h-4 w-4" /> Profile updated
                </span>
              )}
              <button type="submit" className="btn-primary" disabled={loading}>
                {loading ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <Save className="h-4 w-4 mr-2" />}
                Save Changes
              </button>
            </div>
          </form>
        </div>

        {/* Account Status / Role */}
        <div className="card h-fit">
          <div className="card-header">
            <h3 className="text-base font-semibold text-white">Account Status</h3>
          </div>
          <div className="card-body">
            <div className="flex items-center gap-4">
              <div className="h-12 w-12 rounded-full bg-brand-600 flex items-center justify-center text-lg font-bold text-white ring-4 ring-slate-800">
                {user?.fullName?.charAt(0).toUpperCase() || user?.email?.charAt(0).toUpperCase() || 'U'}
              </div>
              <div>
                <p className="text-sm font-medium text-white">{user?.fullName || user?.email}</p>
                <p className="text-xs text-slate-400 capitalize flex items-center gap-1 mt-1">
                  <ShieldAlert className="h-3 w-3 text-brand-500" /> {user?.role || 'Analyst'}
                </p>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}