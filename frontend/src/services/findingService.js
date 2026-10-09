import api from './api'
export const getFindings = (params = {}) => api.get('/findings', { params }).then((r) => r.data)
export const getScanFindings = (id) => api.get(`/findings/scan/${id}`).then((r) => r.data)
