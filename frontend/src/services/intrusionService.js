import api from "./api";

export const getTrafficLogs = async (params = {}) => {
  const query = new URLSearchParams();
  if (params.limit) query.append("limit", params.limit);
  if (params.cursor) query.append("cursor", params.cursor);
  if (params.classification && params.classification !== "all") {
    query.append("classification", params.classification);
  }
  const response = await api.get(`/intrusion/traffic?${query.toString()}`);
  return response.data;
};

export const getAlerts = async (params = {}) => {
  const query = new URLSearchParams();
  if (params.limit) query.append("limit", params.limit);
  if (params.severity && params.severity !== "all") query.append("severity", params.severity);
  if (params.status && params.status !== "all") query.append("status", params.status);
  if (params.assigned_to) query.append("assigned_to", params.assigned_to);
  const response = await api.get(`/intrusion/alerts?${query.toString()}`);
  return response.data;
};

export const getAlertDetails = async (alertId) => {
  const response = await api.get(`/intrusion/alerts/${alertId}`);
  return response.data;
};

export const updateAlertStatus = async (alertId, status, note = null) => {
  const response = await api.patch(`/intrusion/alerts/${alertId}/status`, { status, note });
  return response.data;
};

export const getAlertNotes = async (alertId) => {
  const response = await api.get(`/intrusion/alerts/${alertId}/notes`);
  return response.data;
};

export const addAlertNote = async (alertId, note) => {
  const response = await api.post(`/intrusion/alerts/${alertId}/notes`, { note });
  return response.data;
};

export const getAlertHistory = async (alertId) => {
  const response = await api.get(`/intrusion/alerts/${alertId}/history`);
  return response.data;
};

export const updateAlertAssignment = async (alertId, assigned_to) => {
  const response = await api.patch(`/intrusion/alerts/${alertId}/assignment`, { assigned_to });
  return response.data;
};

export const getInvestigators = async () => {
  const response = await api.get("/intrusion/investigators");
  return response.data;
};

export const getIntrusionMetrics = async () => {
  const response = await api.get("/intrusion/metrics");
  return response.data;
};

export const reprocessEvents = async () => {
  const response = await api.post("/intrusion/reprocess");
  return response.data;
};