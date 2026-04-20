/**
 * Sawari Admin Portal - Pagination Component
 */

export class Pagination {
  constructor(containerId, options = {}) {
    this.container = document.getElementById(containerId);
    this.currentPage = options.currentPage || 1;
    this.totalPages = options.totalPages || 1;
    this.onChange = options.onChange || null;

    this.render();
  }

  /**
   * Render pagination
   */
  render() {
    if (!this.container) return;

    if (this.totalPages <= 1) {
      this.container.innerHTML = '';
      return;
    }

    const pages = this.getPageNumbers();

    this.container.innerHTML = `
      <div class="pagination">
        <button
          class="pagination-btn"
          data-page="${this.currentPage - 1}"
          ${this.currentPage === 1 ? 'disabled' : ''}
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M15 18l-6-6 6-6"/>
          </svg>
        </button>

        ${pages.map(page => {
          if (page === '...') {
            return '<span style="padding: 0 8px; color: #9CA3AF;">...</span>';
          }
          return `
            <button
              class="pagination-btn ${page === this.currentPage ? 'active' : ''}"
              data-page="${page}"
            >
              ${page}
            </button>
          `;
        }).join('')}

        <button
          class="pagination-btn"
          data-page="${this.currentPage + 1}"
          ${this.currentPage === this.totalPages ? 'disabled' : ''}
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 18l6-6-6-6"/>
          </svg>
        </button>
      </div>
    `;

    this.bindEvents();
  }

  /**
   * Get page numbers to display
   */
  getPageNumbers() {
    const pages = [];
    const total = this.totalPages;
    const current = this.currentPage;

    if (total <= 7) {
      for (let i = 1; i <= total; i++) {
        pages.push(i);
      }
    } else {
      pages.push(1);

      if (current > 3) {
        pages.push('...');
      }

      const start = Math.max(2, current - 1);
      const end = Math.min(total - 1, current + 1);

      for (let i = start; i <= end; i++) {
        pages.push(i);
      }

      if (current < total - 2) {
        pages.push('...');
      }

      pages.push(total);
    }

    return pages;
  }

  /**
   * Bind event listeners
   */
  bindEvents() {
    if (!this.container) return;

    this.container.querySelectorAll('[data-page]').forEach(btn => {
      btn.addEventListener('click', () => {
        const page = parseInt(btn.dataset.page);
        if (page >= 1 && page <= this.totalPages && page !== this.currentPage) {
          this.setPage(page);
        }
      });
    });
  }

  /**
   * Set current page
   */
  setPage(page) {
    this.currentPage = page;
    this.render();

    if (this.onChange) {
      this.onChange(page);
    }

    return this;
  }

  /**
   * Set total pages
   */
  setTotalPages(total) {
    this.totalPages = total;
    if (this.currentPage > total) {
      this.currentPage = total || 1;
    }
    this.render();
    return this;
  }

  /**
   * Update pagination
   */
  update(currentPage, totalPages) {
    this.currentPage = currentPage;
    this.totalPages = totalPages;
    this.render();
    return this;
  }
}

export default Pagination;
