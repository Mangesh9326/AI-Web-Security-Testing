import api from './api';

export const analyzeVulnerability = async (findingId) => {
  const response = await api.post('/ai/vulnerability-analysis', { findingId });
  return response.data;
};

export const generateSecurityOverview = async () => {
  const response = await api.post('/ai/security-overview');
  return response.data;
};

export const analyzeIntrusionAlert = async (alertId) => {
  const response = await api.post('/ai/intrusion-analysis', { alertId });
  return response.data;
};

export const generateIntrusionOverview = async () => {
  const response = await api.post('/ai/intrusion-overview');
  return response.data;
};
