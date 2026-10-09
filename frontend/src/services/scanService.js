import api from './api';

export const getScans = async (params = {}) => {
  const response = await api.get('/scans', { params });
  return response.data;
};

export const getScan = async (id) => {
  const response = await api.get(`/scans/${id}`);
  return response.data;
};

export const getScanStatus = async (id) => {
  const response = await api.get(`/scans/${id}/status`);
  return response.data;
};

// NEW: Fetch detailed crawler progress and limits
export const getScanCoverage = async (id) => {
  const response = await api.get(`/scans/${id}/coverage`);
  return response.data;
};

// NEW: Fetch individual discovered endpoints (with optional status/pagination filters)
export const getScanEndpoints = async (id, params = {}) => {
  const response = await api.get(`/scans/${id}/endpoints`, { params });
  return response.data;
};

export const getScanFindings = async (id) => {
  const response = await api.get(`/scans/${id}/findings`);
  return response.data;
};

export const getAllFindings = async (params = {}) => {
  const response = await api.get('/scans/all/findings', { params });
  return response.data;
};

export const createScan = async (data) => {
  const response = await api.post('/scans', data);
  
  // Validate HTTP 202 returned a distinct scan ID before allowing UI navigation
  if (!response.data || !response.data.id) {
    throw new Error("Invalid response from server: Missing scan ID.");
  }
  
  return response.data;
};

export const cancelScan = async (id) => {
  const response = await api.post(`/scans/${id}/cancel`);
  return response.data;
};

// VULNERABILITY REMEDIATION LIFECYCLE

export const updateFindingStatus = async (findingId, status, notes = null) => {
  const response = await api.patch(`/scans/findings/${findingId}/status`, { status, notes });
  return response.data;
};

export const getFindingNotes = async (findingId) => {
  const response = await api.get(`/scans/findings/${findingId}/notes`);
  return response.data;
};

export const addFindingNote = async (findingId, note) => {
  const response = await api.post(`/scans/findings/${findingId}/notes`, { note });
  return response.data;
};

export const getFindingHistory = async (findingId) => {
  const response = await api.get(`/scans/findings/${findingId}/history`);
  return response.data;
};