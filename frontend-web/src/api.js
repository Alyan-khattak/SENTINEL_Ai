import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8001/api/v1';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const getRuns = async () => {
  const response = await apiClient.get('/runs');
  return response.data;
};

export const startRun = async (payload) => {
  const response = await apiClient.post('/runs', payload);
  return response.data;
};

export const getRunReport = async (runId) => {
  const response = await apiClient.get(`/runs/${runId}`);
  return response.data;
};

export const submitApproval = async (runId, approvalDecision) => {
  const response = await apiClient.post(`/runs/${runId}/approvals`, approvalDecision);
  return response.data;
};
