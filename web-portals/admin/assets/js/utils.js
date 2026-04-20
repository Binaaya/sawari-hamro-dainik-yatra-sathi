/**
 * Sawari Admin Portal - Utility Functions
 */

/**
 * Format currency in NPR format
 */
export function formatCurrency(amount) {
  if (amount === null || amount === undefined) return 'Rs. 0';
  return `Rs. ${Number(amount).toLocaleString('en-NP')}`;
}

/**
 * Format date to readable format
 */
export function formatDate(dateString) {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

/**
 * Format datetime to readable format
 */
export function formatDateTime(dateString) {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Format time only
 */
export function formatTime(dateString) {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Get badge CSS class based on status
 */
export function getStatusBadgeClass(status) {
  const statusClasses = {
    // Approval statuses
    'Pending': 'badge-pending',
    'Approved': 'badge-approved',
    'Rejected': 'badge-rejected',

    // Card statuses
    'Active': 'badge-active',
    'Inactive': 'badge-inactive',
    'Deactivated': 'badge-inactive',

    // Complaint statuses
    'InProgress': 'badge-in-progress',
    'Resolved': 'badge-resolved',
    'Rejected': 'badge-rejected',

    // Ride statuses
    'Ongoing': 'badge-in-progress',
    'Completed': 'badge-approved',
    'Cancelled': 'badge-dismissed'
  };

  return statusClasses[status] || 'badge-pending';
}

/**
 * Debounce function - delays execution until after wait period
 */
export function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

/**
 * Validate email format
 */
export function validateEmail(email) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
}

/**
 * Validate phone number (Nepal format)
 */
export function validatePhone(phone) {
  const re = /^(98|97|96)\d{8}$/;
  return re.test(phone.replace(/\D/g, ''));
}

/**
 * Truncate text with ellipsis
 */
export function truncateText(text, maxLength = 50) {
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
}

/**
 * Generate random ID
 */
export function generateId() {
  return Math.random().toString(36).substring(2, 11);
}

/**
 * Parse URL query parameters
 */
export function parseQueryParams() {
  const params = new URLSearchParams(window.location.search);
  const result = {};
  for (const [key, value] of params) {
    result[key] = value;
  }
  return result;
}

/**
 * Set URL query parameters without reloading
 */
export function setQueryParams(params) {
  const url = new URL(window.location.href);
  Object.keys(params).forEach(key => {
    if (params[key] !== undefined && params[key] !== null && params[key] !== '') {
      url.searchParams.set(key, params[key]);
    } else {
      url.searchParams.delete(key);
    }
  });
  window.history.replaceState({}, '', url);
}

/**
 * Escape HTML to prevent XSS
 */
export function escapeHtml(text) {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

/**
 * Get relative time (e.g., "2 hours ago")
 */
export function getRelativeTime(dateString) {
  if (!dateString) return '-';

  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now - date;
  const diffSecs = Math.floor(diffMs / 1000);
  const diffMins = Math.floor(diffSecs / 60);
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffSecs < 60) return 'just now';
  if (diffMins < 60) return `${diffMins} minute${diffMins > 1 ? 's' : ''} ago`;
  if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
  if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;

  return formatDate(dateString);
}

/**
 * Download data as CSV
 */
export function downloadCSV(data, filename) {
  if (!data || data.length === 0) return;

  const headers = Object.keys(data[0]);
  const csvContent = [
    headers.join(','),
    ...data.map(row =>
      headers.map(header => {
        let cell = row[header] ?? '';
        // Escape quotes and wrap in quotes if contains comma
        if (typeof cell === 'string' && (cell.includes(',') || cell.includes('"'))) {
          cell = `"${cell.replace(/"/g, '""')}"`;
        }
        return cell;
      }).join(',')
    )
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = `${filename}_${formatDate(new Date())}.csv`;
  link.click();
}

/**
 * Capitalize first letter
 */
export function capitalize(str) {
  if (!str) return '';
  return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
}

/**
 * Format file size
 */
export function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
