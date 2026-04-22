/**
 * Admin Portal - Authentication Service
 */

import { api } from './api.js';

const SESSION_TIMEOUT = 30 * 60 * 1000; // 30 minutes

class AuthService {
  constructor() {
    this.currentUser = null;
  }

  isSessionExpired() {
    const loginTime = localStorage.getItem('sawari_admin_login_time');
    if (!loginTime) return true;
    return Date.now() - parseInt(loginTime) > SESSION_TIMEOUT;
  }

  /**
   * Sign in with email and password
   */
  async signIn(email, password) {
    try {
      const userCredential = await firebase.auth().signInWithEmailAndPassword(email, password);
      const idToken = await userCredential.user.getIdToken();
      
      // Set token in API service
      api.setAuthToken(idToken);
      
      // Verify user role
      const response = await api.getCurrentUser();
      if (!response.success) {
        await this.signOut();
        throw new Error(response.error || 'Failed to get user info');
      }

      if (response.data.user.role !== 'Admin') {
        await this.signOut();
        throw new Error('Access denied. Admin role required.');
      }

      this.currentUser = response.data.user;
      localStorage.setItem('sawari_admin_login_time', Date.now().toString());
      return { success: true, user: this.currentUser };
    } catch (error) {
      return { success: false, error: this.getAuthErrorMessage(error) };
    }
  }

  /**
   * Sign out
   */
  async signOut() {
    try {
      await firebase.auth().signOut();
      this.currentUser = null;
      api.setAuthToken(null);
      localStorage.removeItem('sawari_admin_login_time');
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Check if user is authenticated and has correct role
   */
  async checkAuth() {
    return new Promise((resolve) => {
      firebase.auth().onAuthStateChanged(async (firebaseUser) => {
        if (!firebaseUser || this.isSessionExpired()) {
          if (firebaseUser) await this.signOut();
          resolve(null);
          return;
        }

        try {
          const idToken = await firebaseUser.getIdToken(true);
          api.setAuthToken(idToken);

          const response = await api.getCurrentUser();
          if (!response.success) {
            resolve(null);
            return;
          }

          if (response.data.user.role !== 'Admin') {
            await this.signOut();
            resolve(null);
            return;
          }

          this.currentUser = response.data.user;
          resolve(this.currentUser);
        } catch (error) {
          console.error('Auth check error:', error);
          resolve(null);
        }
      });
    });
  }

  /**
   * Convert Firebase auth error to user-friendly message
   */
  getAuthErrorMessage(error) {
    const code = error.code || '';
    switch (code) {
      case 'auth/invalid-credential':
      case 'auth/wrong-password':
      case 'auth/user-not-found':
        return 'Invalid email or password.';
      case 'auth/invalid-email':
        return 'Please enter a valid email address.';
      case 'auth/user-disabled':
        return 'This account has been disabled.';
      case 'auth/too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'auth/network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return error.message || 'Login failed. Please try again.';
    }
  }

  /**
   * Get current user
   */
  getCurrentUser() {
    return this.currentUser;
  }
}

export const auth = new AuthService();
export default auth;
