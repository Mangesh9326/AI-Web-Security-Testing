import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api',
  headers: {
    'Content-Type': 'application/json',
  }
});

// Request interceptor for ai_websectest_token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('ai_websectest_token') || sessionStorage.getItem('ai_websectest_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor for 401
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('ai_websectest_token');
      sessionStorage.removeItem('ai_websectest_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Helper for extracting API errors
export const apiError = (error, defaultMessage = 'An error occurred') => {
  if (error.response && error.response.data && error.response.data.detail) {
    return error.response.data.detail;
  }
  return error.message || defaultMessage;
};

// FastAPI health check endpoint
export const checkApiHealth = () => {
  return api.get('/health');
};

export default api;
