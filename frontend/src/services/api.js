import axios from 'axios';

// Create an Axios instance with base URL from environment variable
// In development: http://localhost:8000/api/v1
// In Docker:      http://backend:8000/api/v1
// In production:  Configured via NGINX reverse proxy
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000, // 10 second timeout
});

// ---- Request Interceptor ----
// Add auth tokens or logging before requests are sent
api.interceptors.request.use(
  (config) => {
    // Future: Add JWT token here
    // const token = localStorage.getItem('token');
    // if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
  },
  (error) => Promise.reject(error)
);

// ---- Response Interceptor ----
// Handle common error patterns globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response) {
      console.error('API Error:', error.response.status, error.response.data);
    } else if (error.request) {
      console.error('Network Error: No response from server');
    }
    return Promise.reject(error);
  }
);

// ========================
// Expense API Functions
// ========================
export const expenseApi = {
  // Get all expenses with pagination and filtering
  getAll: (params = {}) =>
    api.get('/expenses/', { params }),

  // Get a single expense by ID
  getById: (id) =>
    api.get(`/expenses/${id}`),

  // Create a new expense
  create: (data) =>
    api.post('/expenses/', data),

  // Update an existing expense
  update: (id, data) =>
    api.put(`/expenses/${id}`, data),

  // Delete an expense
  delete: (id) =>
    api.delete(`/expenses/${id}`),

  // Get expense analytics/summary
  getAnalytics: () =>
    api.get('/expenses/analytics/summary'),
};

// ========================
// Category API Functions
// ========================
export const categoryApi = {
  // List all available categories
  getAll: () =>
    api.get('/categories/'),

  // Get spending stats per category
  getStats: () =>
    api.get('/categories/stats'),
};

export default api;
