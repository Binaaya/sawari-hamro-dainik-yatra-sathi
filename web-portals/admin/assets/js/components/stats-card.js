/**
 * Sawari Admin Portal - Stats Card Component
 */

import { formatCurrency } from '../utils.js';

export class StatsCard {
  constructor(containerId, options = {}) {
    this.container = document.getElementById(containerId);
    this.label = options.label || 'Stat';
    this.value = options.value || 0;
    this.icon = options.icon || 'chart';
    this.color = options.color || 'emerald';
    this.isCurrency = options.isCurrency || false;
    this.subValue = options.subValue || null;
    this.subLabel = options.subLabel || null;

    this.render();
  }

  /**
   * Get icon SVG
   */
  getIconSvg() {
    const icons = {
      'users': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>',
      'building': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"/>',
      'truck': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17a2 2 0 11-4 0 2 2 0 014 0zM19 17a2 2 0 11-4 0 2 2 0 014 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16V6a1 1 0 00-1-1H4a1 1 0 00-1 1v10a1 1 0 001 1h1m8-1a1 1 0 01-1 1H9m4-1V8a1 1 0 011-1h2.586a1 1 0 01.707.293l3.414 3.414a1 1 0 01.293.707V16a1 1 0 01-1 1h-1m-6-1a1 1 0 001 1h1M5 17a2 2 0 104 0m-4 0a2 2 0 114 0m6 0a2 2 0 104 0m-4 0a2 2 0 114 0"/>',
      'ticket': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 5v2m0 4v2m0 4v2M5 5a2 2 0 00-2 2v3a2 2 0 110 4v3a2 2 0 002 2h14a2 2 0 002-2v-3a2 2 0 110-4V7a2 2 0 00-2-2H5z"/>',
      'currency': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>',
      'message': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>',
      'chart': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>'
    };
    return icons[this.icon] || icons['chart'];
  }

  /**
   * Get color classes
   */
  getColorClasses() {
    const colors = {
      'emerald': { bg: '#ECFDF5', icon: '#10B981' },
      'blue': { bg: '#EFF6FF', icon: '#3B82F6' },
      'purple': { bg: '#F5F3FF', icon: '#8B5CF6' },
      'orange': { bg: '#FFF7ED', icon: '#F97316' },
      'red': { bg: '#FEF2F2', icon: '#EF4444' },
      'yellow': { bg: '#FFFBEB', icon: '#F59E0B' }
    };
    return colors[this.color] || colors['emerald'];
  }

  /**
   * Render card
   */
  render() {
    if (!this.container) return;

    const colors = this.getColorClasses();
    const displayValue = this.isCurrency ? formatCurrency(this.value) : this.value.toLocaleString();

    this.container.innerHTML = `
      <div class="stats-card">
        <div>
          <p style="font-size: 13px; color: #6B7280; margin: 0 0 4px 0;">${this.label}</p>
          <p style="font-size: 28px; font-weight: 700; color: #111827; margin: 0;">${displayValue}</p>
          ${this.subValue !== null ? `
            <p style="font-size: 12px; color: #6B7280; margin-top: 4px;">
              ${this.subLabel || ''} <span style="font-weight: 500; color: #111827;">${this.subValue}</span>
            </p>
          ` : ''}
        </div>
        <div class="icon" style="background-color: ${colors.bg}; color: ${colors.icon};">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" stroke="currentColor">
            ${this.getIconSvg()}
          </svg>
        </div>
      </div>
    `;
  }

  /**
   * Update value
   */
  setValue(value, subValue = null) {
    this.value = value;
    if (subValue !== null) this.subValue = subValue;
    this.render();
    return this;
  }
}

export default StatsCard;
