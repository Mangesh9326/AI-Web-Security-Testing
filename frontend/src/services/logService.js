import api from './api'
export const getLogs = (params = {}) => api.get('/logs', { params }).then((r) => r.data)
