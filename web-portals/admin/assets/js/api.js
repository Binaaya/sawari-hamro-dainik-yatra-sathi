/**
 * Sawari Admin Portal - API Service
 * Handles all HTTP requests to the backend
 */

import { API_BASE_URL } from './config.js';

class ApiService {
  constructor() {
    this.baseUrl = API_BASE_URL;
    this.authToken = null;
  }

  /**
   * Set the authentication token
   */
  setAuthToken(token) {
    this.authToken = token;
  }

  /**
   * Get headers for requests
   */
  getHeaders() {
    const headers = {
      'Content-Type': 'application/json'
    };
    if (this.authToken) {
      headers['Authorization'] = `Bearer ${this.authToken}`;
    }
    return headers;
  }

  /**
   * Perform a GET request to the given endpoint.
   */
  async get(endpoint, params = {}) {
    try {
      const url = new URL(`${this.baseUrl}${endpoint}`);
      Object.keys(params).forEach(key => {
        if (params[key] !== undefined && params[key] !== null) {
          url.searchParams.append(key, params[key]);
        }
      });

      const response = await fetch(url, {
        method: 'GET',
        headers: this.getHeaders()
      });

      return this.handleResponse(response);
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Perform a POST request to the given endpoint.
   */
  async post(endpoint, data = {}) {
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(data)
      });

      return this.handleResponse(response);
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Perform a PUT request to the given endpoint.
   */
  async put(endpoint, data = {}) {
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: 'PUT',
        headers: this.getHeaders(),
        body: JSON.stringify(data)
      });

      return this.handleResponse(response);
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Perform a PUT request with FormData (for file uploads).
   */
  async putFormData(endpoint, formData) {
    try {
      const headers = {};
      if (this.authToken) {
        headers['Authorization'] = `Bearer ${this.authToken}`;
      }
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: 'PUT',
        headers,
        body: formData
      });
      return this.handleResponse(response);
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Perform a DELETE request to the given endpoint.
   */
  async delete(endpoint) {
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: 'DELETE',
        headers: this.getHeaders()
      });

      return this.handleResponse(response);
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Handle HTTP response
   */
  async handleResponse(response) {
    try {
      const data = await response.json();

      if (response.status === 401) {
        // Token expired or invalid - redirect to login
        window.location.href = 'login.html';
        return { success: false, error: 'Session expired' };
      }

      return data;
    } catch (error) {
      return { success: false, error: 'Failed to parse response' };
    }
  }

  // Auth Endpoints

  async getCurrentUser() {
    return this.get('/auth/me');
  }

  // Dashboard Endpoints

  async getDashboard() {
    return this.get('/admin/dashboard');
  }

  // Operator Endpoints

  async getPendingOperators() {
    return this.get('/admin/operators/pending');
  }

  async getAllOperators(params = {}) {
    return this.get('/admin/operators', params);
  }

  async approveOperator(operatorId) {
    return this.post(`/admin/operators/${operatorId}/approve`);
  }

  async rejectOperator(operatorId, reason = '') {
    return this.post(`/admin/operators/${operatorId}/reject`, { reason });
  }

  // Vehicle Endpoints

  async getPendingVehicles() {
    return this.get('/admin/vehicles/pending');
  }

  async getAllVehicles(params = {}) {
    return this.get('/admin/vehicles', params);
  }

  async approveVehicle(vehicleId) {
    return this.post(`/admin/vehicles/${vehicleId}/approve`);
  }

  async rejectVehicle(vehicleId, reason = '') {
    return this.post(`/admin/vehicles/${vehicleId}/reject`, { reason });
  }

  // Passenger Endpoints

  async getPassengers(params = {}) {
    return this.get('/admin/passengers', params);
  }

  async getPassenger(passengerId) {
    return this.get(`/admin/passengers/${passengerId}`);
  }

  async updatePassenger(passengerId, formData) {
    return this.putFormData(`/admin/passengers/${passengerId}`, formData);
  }

  async topUpPassenger(passengerId, amount, receiptNumber = null) {
    const data = { amount };
    if (receiptNumber) data.receiptNumber = receiptNumber;
    return this.post(`/admin/passengers/${passengerId}/topup`, data);
  }

  async deleteUser(userId) {
    return this.delete(`/admin/users/${userId}`);
  }

  // RFID Card Endpoints

  async getRfidCards(params = {}) {
    return this.get('/admin/rfid-cards', params);
  }

  async scanAssignRfidCard(cardUid, passengerId) {
    return this.post('/admin/rfid-cards/scan-assign', { cardUid, passengerId });
  }

  async deactivateRfidCard(cardId, reason = '') {
    return this.post(`/admin/rfid-cards/${cardId}/deactivate`, { reason });
  }

  async deleteRfidCard(cardId) {
    return this.delete(`/admin/rfid-cards/${cardId}`);
  }

  // Complaint Endpoints

  async getComplaints(params = {}) {
    return this.get('/admin/complaints', params);
  }

  async getComplaint(complaintId) {
    return this.get(`/admin/complaints/${complaintId}`);
  }

  async updateComplaint(complaintId, status, resolution = '') {
    return this.put(`/admin/complaints/${complaintId}`, { status, resolution });
  }

  // Route Endpoints

  async getRoutes() {
    return this.get('/admin/routes');
  }

  async createRoute(data) {
    return this.post('/admin/routes', data);
  }

  async updateRoute(routeId, data) {
    return this.put(`/admin/routes/${routeId}`, data);
  }

  // Stop Endpoints

  async getStops() {
    return this.get('/admin/stops');
  }

  async createStop(data) {
    return this.post('/admin/stops', data);
  }

  // Fare Structure Endpoints

  async getFareStructure(routeId = null) {
    const params = routeId ? { routeId } : {};
    return this.get('/admin/fare-structure', params);
  }

  async updateFareStructure(data) {
    return this.put('/admin/fare-structure', data);
  }

  // Route Stop Management

  async deleteRoute(routeId) {
    return this.delete(`/admin/routes/${routeId}`);
  }

  async getRouteStops(routeId) {
    return this.get(`/admin/routes/${routeId}/stops`);
  }

  async updateStop(stopId, data) {
    return this.put(`/admin/stops/${stopId}`, data);
  }

  // Vehicle Route Endpoints

  async getVehicleRoutes() {
    return this.get('/admin/vehicle-routes');
  }

  async assignVehicleRoute(data) {
    return this.post('/admin/vehicle-routes', data);
  }

  async removeVehicleRoute(vehicleId, routeId) {
    return this.delete(`/admin/vehicle-routes/${vehicleId}/${routeId}`);
  }

  // Report Endpoints

  async getRideReports(params = {}) {
    return this.get('/admin/reports/rides', params);
  }

  async getRevenueReports(params = {}) {
    return this.get('/admin/reports/revenue', params);
  }

  async getTransactionReports(params = {}) {
    return this.get('/admin/reports/transactions', params);
  }

  // Notification Endpoints

  async getNotifications(limit = 10) {
    return this.get('/notifications', { limit });
  }

  async markNotificationRead(notificationId) {
    return this.put(`/notifications/${notificationId}/read`, {});
  }
}

export const api = new ApiService();
export default api;
