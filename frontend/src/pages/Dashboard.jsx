import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  PieChart, Pie, Cell, Tooltip as RechartsTooltip, ResponsiveContainer, Legend,
  BarChart, Bar, XAxis, YAxis, CartesianGrid
} from 'recharts';
import { getScans, getAllFindings } from '../services/scanService';
import { getAlerts } from '../services/intrusionService';
import { useAuth } from '../hooks/useAuth';
import { ShieldAlert, Activity, Bug, ListOrdered, ArrowRight, RefreshCw } from 'lucide-react';

const COLORS = {
  critical: '#ef4444',
  high: '#f97316',
  medium: '#eab308',
  low: '#3b82f6',
  info: '#06b6d4',
  success: '#10b981'
};

const StatCard = ({ title, value, icon: Icon, color, to }) => (
  <div className="card">
    <div className="p-6">
      <div className="flex items-center">
        <div className="flex-shrink-0">
          <Icon className={`h-8 w-8 ${color}`} />
        </div>
        <div className="ml-5 w-0 flex-1">
          <dl>
            <dt className="text-sm font-medium text-slate-400 truncate">{title}</dt>
            <dd>
              <div className="text-2xl font-bold text-white">{value}</div>
            </dd>
          </dl>
        </div>
      </div>
    </div>
    {to && (
      <div className="bg-slate-800/50 px-6 py-3 border-t border-slate-700">
        <div className="text-sm">
          <Link to={to} className="font-medium text-brand-400 hover:text-brand-300 flex items-center gap-1">
            View all <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      </div>
    )}
  </div>
);

export default function Dashboard() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  
  const [stats, setStats] = useState({
    totalScans: 0,
    runningScans: 0,
    totalFindings: 0,
    criticalFindings: 0,
    totalAlerts: 0
  });

  const [severityData, setSeverityData] = useState([]);
  const [recentScans, setRecentScans] = useState([]);
  
  const loadData = async () => {
    setLoading(true);
    try {
      const [scansRes, findingsRes, alertsRes] = await Promise.all([
        getScans(),
        getAllFindings(),
        getAlerts()
      ]);

      const scansData = scansRes.scans || scansRes.data || scansRes || [];
      const scans = Array.isArray(scansData) ? scansData : [];
      
      const findingsData = findingsRes.findings || findingsRes.data || findingsRes || [];
      const findings = Array.isArray(findingsData) ? findingsData : [];
      
      const alertsData = alertsRes.alerts || alertsRes.data || alertsRes || [];
      const alerts = Array.isArray(alertsData) ? alertsData : [];

      // Calculate Stats
      const running = scans.filter(s => s.status === 'running' || s.status === 'pending').length;
      const criticals = findings.filter(f => f.severity === 'critical').length;
      
      setStats({
        totalScans: scans.length,
        runningScans: running,
        totalFindings: findings.length,
        criticalFindings: criticals,
        totalAlerts: alerts.length
      });

      // Prepare Chart Data
      const sevCounts = { critical: 0, high: 0, medium: 0, low: 0, info: 0 };
      findings.forEach(f => {
        if (sevCounts[f.severity] !== undefined) sevCounts[f.severity]++;
      });
      
      setSeverityData([
        { name: 'Critical', value: sevCounts.critical, color: COLORS.critical },
        { name: 'High', value: sevCounts.high, color: COLORS.high },
        { name: 'Medium', value: sevCounts.medium, color: COLORS.medium },
        { name: 'Low', value: sevCounts.low, color: COLORS.low },
        { name: 'Info', value: sevCounts.info, color: COLORS.info }
      ].filter(d => d.value > 0));

      setRecentScans(scans.slice(0, 5));

    } catch (err) {
      console.error("Dashboard data load error:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center min-h-[400px]">
        <RefreshCw className="h-8 w-8 animate-spin text-brand-500" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight">
            Security Overview
          </h2>
          <p className="mt-1 text-sm text-slate-400">
            Welcome back, {user?.fullName || user?.email || 'User'}. Here's what's happening.
          </p>
        </div>
        <div>
          <Link to="/new-scan" className="btn-primary">
            New Scan
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard 
          title="Total Scans" 
          value={stats.totalScans} 
          icon={ListOrdered} 
          color="text-blue-500"
          to="/scans" 
        />
        <StatCard 
          title="Running Scans" 
          value={stats.runningScans} 
          icon={RefreshCw} 
          color="text-brand-500"
        />
        <StatCard 
          title="Critical Findings" 
          value={stats.criticalFindings} 
          icon={Bug} 
          color="text-red-500"
          to="/vulnerabilities" 
        />
        <StatCard 
          title="Intrusion Alerts" 
          value={stats.totalAlerts} 
          icon={Activity} 
          color="text-orange-500"
          to="/intrusion-detection" 
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Vulnerability Breakdown Chart */}
        <div className="card lg:col-span-1">
          <div className="card-header">
            <h3 className="text-base font-semibold leading-6 text-white">Vulnerabilities by Severity</h3>
          </div>
          <div className="card-body h-80 flex flex-col items-center justify-center">
            {severityData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={severityData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={90}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {severityData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <RechartsTooltip 
                    contentStyle={{ backgroundColor: '#1e293b', borderColor: '#334155', color: '#f8fafc' }}
                    itemStyle={{ color: '#f8fafc' }}
                  />
                  <Legend wrapperStyle={{ fontSize: '12px', color: '#cbd5e1' }} />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center text-slate-500">
                <ShieldAlert className="mx-auto h-12 w-12 text-slate-600 mb-2" />
                <p>No vulnerabilities found.</p>
              </div>
            )}
          </div>
        </div>

        {/* Recent Scans Table */}
        <div className="card lg:col-span-2 flex flex-col">
          <div className="card-header flex justify-between items-center">
            <h3 className="text-base font-semibold leading-6 text-white">Recent Scans</h3>
            <Link to="/scans" className="text-sm font-medium text-brand-400 hover:text-brand-300">View all</Link>
          </div>
          <div className="table-container flex-1">
            {recentScans.length > 0 ? (
              <table className="table">
                <thead>
                  <tr>
                    <th>Target</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {recentScans.map((scan) => (
                    <tr key={scan.id}>
                      <td className="font-medium text-white">{scan.target_url}</td>
                      <td>
                        <span className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset ${
                          scan.status === 'completed' ? 'bg-green-400/10 text-green-400 ring-green-400/20' :
                          scan.status === 'failed' ? 'bg-red-400/10 text-red-400 ring-red-400/20' :
                          'bg-brand-400/10 text-brand-400 ring-brand-400/20'
                        }`}>
                          {scan.status}
                        </span>
                      </td>
                      <td className="text-slate-400">
                        {new Date(scan.created_at).toLocaleDateString()}
                      </td>
                      <td>
                        <Link to={`/scan/${scan.id}`} className="text-brand-400 hover:text-brand-300 font-medium text-sm">
                          Details
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <div className="p-8 text-center text-slate-500">
                <p>No scans performed yet.</p>
                <Link to="/new-scan" className="mt-4 btn-primary inline-flex">Start a Scan</Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}