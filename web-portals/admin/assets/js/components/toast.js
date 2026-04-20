/**
 * Sawari Admin Portal - Toast Notification Component
 */

class ToastManager {
  constructor() {
    this.container = null;
    this.init();
  }

  /**
   * Initialize toast container
   */
  init() {
    if (this.container) return;

    // Create container if it doesn't exist
    this.container = document.getElementById('toast-container');
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.id = 'toast-container';
      this.container.className = 'toast-container';
      document.body.appendChild(this.container);
    }
  }

  /**
   * Show a toast notification
   */
  show(message, type = 'info', duration = 4000) {
    this.init();

    const id = 'toast-' + Math.random().toString(36).substr(2, 9);

    const icons = {
      success: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><path d="M22 4L12 14.01l-3-3"/></svg>',
      error: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M15 9l-6 6M9 9l6 6"/></svg>',
      warning: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><path d="M12 9v4M12 17h.01"/></svg>',
      info: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>'
    };

    const toastHtml = `
      <div id="${id}" class="toast toast-${type}">
        ${icons[type] || icons.info}
        <span style="flex: 1;">${this.escapeHtml(message)}</span>
        <button onclick="Toast.dismiss('${id}')" style="background: none; border: none; color: inherit; cursor: pointer; padding: 4px; opacity: 0.7;">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M18 6L6 18M6 6l12 12"/>
          </svg>
        </button>
      </div>
    `;

    this.container.insertAdjacentHTML('beforeend', toastHtml);

    // Trigger animation
    const toast = document.getElementById(id);
    setTimeout(() => toast.classList.add('show'), 10);

    // Auto dismiss
    if (duration > 0) {
      setTimeout(() => this.dismiss(id), duration);
    }

    return id;
  }

  /**
   * Dismiss a toast
   */
  dismiss(id) {
    const toast = document.getElementById(id);
    if (toast) {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 300);
    }
  }

  /**
   * Show success toast
   */
  success(message, duration) {
    return this.show(message, 'success', duration);
  }

  /**
   * Show error toast
   */
  error(message, duration) {
    return this.show(message, 'error', duration);
  }

  /**
   * Show warning toast
   */
  warning(message, duration) {
    return this.show(message, 'warning', duration);
  }

  /**
   * Show info toast
   */
  info(message, duration) {
    return this.show(message, 'info', duration);
  }

  /**
   * Escape HTML
   */
  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

// Export singleton instance
export const Toast = new ToastManager();

// Also make available globally for inline onclick handlers
window.Toast = Toast;

export default Toast;
