/**
 * Sawari Admin Portal - Data Table Component
 */

import { escapeHtml } from '../utils.js';

export class DataTable {
  constructor(containerId, options = {}) {
    this.container = document.getElementById(containerId);
    this.columns = options.columns || [];
    this.data = [];
    this.loading = false;
    this.emptyMessage = options.emptyMessage || 'No data available';
    this.onRowClick = options.onRowClick || null;
    this.rowActions = options.rowActions || [];

    this.render();
  }

  /**
   * Set table data
   */
  setData(data) {
    this.data = data || [];
    this.loading = false;
    this.render();
    return this;
  }

  /**
   * Set loading state
   */
  setLoading(loading) {
    this.loading = loading;
    this.render();
    return this;
  }

  /**
   * Render table
   */
  render() {
    if (!this.container) return;

    if (this.loading) {
      this.container.innerHTML = `
        <div class="table-container">
          <div style="padding: 60px; text-align: center;">
            <div class="spinner" style="margin: 0 auto;"></div>
            <p style="margin-top: 16px; color: #6B7280;">Loading...</p>
          </div>
        </div>
      `;
      return;
    }

    if (this.data.length === 0) {
      this.container.innerHTML = `
        <div class="table-container">
          <div class="empty-state">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
            </svg>
            <p>${this.emptyMessage}</p>
          </div>
        </div>
      `;
      return;
    }

    const hasActions = this.rowActions.length > 0;

    this.container.innerHTML = `
      <div class="table-container">
        <table class="data-table">
          <thead>
            <tr>
              ${this.columns.map(col => `
                <th style="${col.width ? `width: ${col.width};` : ''}">${col.label}</th>
              `).join('')}
              ${hasActions ? '<th style="white-space: nowrap;">Actions</th>' : ''}
            </tr>
          </thead>
          <tbody>
            ${this.data.map((row, rowIndex) => `
              <tr data-row-index="${rowIndex}" ${this.onRowClick ? 'style="cursor: pointer;"' : ''}>
                ${this.columns.map(col => `
                  <td>${this.renderCell(row, col)}</td>
                `).join('')}
                ${hasActions ? `
                  <td style="white-space: nowrap;">
                    <div style="display: flex; gap: 6px; flex-wrap: nowrap;">
                      ${this.rowActions.map(action => {
                        if (action.show && !action.show(row)) return '';
                        const content = action.icon
                          ? action.icon + '<span style="margin-left:4px;">' + action.label + '</span>'
                          : action.label;
                        return `<button
                          class="btn btn-sm ${action.class || 'btn-outline'}"
                          data-action="${action.id}"
                          data-row-index="${rowIndex}"
                          title="${action.label}"
                          style="padding: 5px 10px; font-size: 12px; white-space: nowrap; display: inline-flex; align-items: center;"
                        >${content}</button>`;
                      }).join('')}
                    </div>
                  </td>
                ` : ''}
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;

    this.bindEvents();
  }

  /**
   * Render cell content
   */
  renderCell(row, column) {
    const value = this.getNestedValue(row, column.key);

    // Custom render function
    if (column.render) {
      return column.render(value, row);
    }

    // Default rendering based on type
    if (value === null || value === undefined) {
      return '<span style="color: #9CA3AF;">-</span>';
    }

    return escapeHtml(String(value));
  }

  /**
   * Get nested object value using dot notation
   */
  getNestedValue(obj, key) {
    return key.split('.').reduce((o, k) => (o || {})[k], obj);
  }

  /**
   * Bind event listeners
   */
  bindEvents() {
    if (!this.container) return;

    // Row click
    if (this.onRowClick) {
      this.container.querySelectorAll('tbody tr').forEach(tr => {
        tr.addEventListener('click', (e) => {
          // Don't trigger if clicking on action button
          if (e.target.closest('[data-action]')) return;

          const rowIndex = parseInt(tr.dataset.rowIndex);
          this.onRowClick(this.data[rowIndex], rowIndex);
        });
      });
    }

    // Action buttons
    this.container.querySelectorAll('[data-action]').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const actionId = btn.dataset.action;
        const rowIndex = parseInt(btn.dataset.rowIndex);
        const action = this.rowActions.find(a => a.id === actionId);

        if (action && action.onClick) {
          action.onClick(this.data[rowIndex], rowIndex);
        }
      });
    });
  }

  /**
   * Add row action
   */
  addAction(action) {
    this.rowActions.push(action);
    return this;
  }
}

export default DataTable;
