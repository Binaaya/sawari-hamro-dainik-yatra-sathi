/**
 * Sawari Admin Portal - Modal Component
 */

export class Modal {
  constructor(options = {}) {
    this.id = options.id || 'modal-' + Math.random().toString(36).substr(2, 9);
    this.title = options.title || 'Modal';
    this.size = options.size || 'md'; // sm, md, lg, xl
    this.closable = options.closable !== false;
    this.onClose = options.onClose || null;
    this.onConfirm = options.onConfirm || null;
    this.confirmText = options.confirmText || 'Confirm';
    this.cancelText = options.cancelText || 'Cancel';
    this.confirmClass = options.confirmClass || 'btn-primary';
    this.showFooter = options.showFooter !== false;

    this.element = null;
    this.create();
  }

  /**
   * Get modal width based on size
   */
  getWidth() {
    const sizes = {
      'sm': '400px',
      'md': '500px',
      'lg': '700px',
      'xl': '900px'
    };
    return sizes[this.size] || sizes['md'];
  }

  /**
   * Create modal element
   */
  create() {
    // Remove existing modal with same ID
    const existing = document.getElementById(this.id);
    if (existing) existing.remove();

    // Create modal HTML
    const modalHtml = `
      <div id="${this.id}" class="modal-overlay">
        <div class="modal" style="max-width: ${this.getWidth()};">
          <div class="modal-header">
            <h3 class="modal-title">${this.escapeHtml(this.title)}</h3>
            ${this.closable ? `
              <button class="modal-close" data-action="close">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M18 6L6 18M6 6l12 12"/>
                </svg>
              </button>
            ` : ''}
          </div>
          <div class="modal-body" id="${this.id}-body">
            <!-- Content will be inserted here -->
          </div>
          ${this.showFooter ? `
            <div class="modal-footer">
              <button class="btn btn-secondary" data-action="cancel">${this.cancelText}</button>
              <button class="btn ${this.confirmClass}" data-action="confirm">${this.confirmText}</button>
            </div>
          ` : ''}
        </div>
      </div>
    `;

    // Add to DOM
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    this.element = document.getElementById(this.id);

    // Bind events
    this.bindEvents();
  }

  /**
   * Bind event listeners
   */
  bindEvents() {
    if (!this.element) return;

    // Close button
    const closeBtn = this.element.querySelector('[data-action="close"]');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => this.close());
    }

    // Cancel button
    const cancelBtn = this.element.querySelector('[data-action="cancel"]');
    if (cancelBtn) {
      cancelBtn.addEventListener('click', () => this.close());
    }

    // Confirm button
    const confirmBtn = this.element.querySelector('[data-action="confirm"]');
    if (confirmBtn) {
      confirmBtn.addEventListener('click', () => {
        if (this.onConfirm) {
          this.onConfirm();
        }
      });
    }

    // Click on overlay to close
    this.element.addEventListener('click', (e) => {
      if (e.target === this.element && this.closable) {
        this.close();
      }
    });

    // ESC key to close
    this.escHandler = (e) => {
      if (e.key === 'Escape' && this.closable) {
        this.close();
      }
    };
    document.addEventListener('keydown', this.escHandler);
  }

  /**
   * Set modal body content
   */
  setContent(html) {
    const body = document.getElementById(`${this.id}-body`);
    if (body) {
      body.innerHTML = html;
    }
    return this;
  }

  /**
   * Set modal title
   */
  setTitle(title) {
    this.title = title;
    const titleEl = this.element?.querySelector('.modal-title');
    if (titleEl) {
      titleEl.textContent = title;
    }
    return this;
  }

  /**
   * Open modal
   */
  open() {
    if (this.element) {
      this.element.classList.add('active');
      document.body.style.overflow = 'hidden';
    }
    return this;
  }

  /**
   * Close modal
   */
  close() {
    if (this.element) {
      this.element.classList.remove('active');
      document.body.style.overflow = '';

      if (this.onClose) {
        this.onClose();
      }
    }
    return this;
  }

  /**
   * Destroy modal
   */
  destroy() {
    if (this.escHandler) {
      document.removeEventListener('keydown', this.escHandler);
    }
    if (this.element) {
      this.element.remove();
    }
  }

  /**
   * Set loading state on confirm button
   */
  setLoading(loading) {
    const confirmBtn = this.element?.querySelector('[data-action="confirm"]');
    if (confirmBtn) {
      confirmBtn.disabled = loading;
      if (loading) {
        confirmBtn.innerHTML = '<span class="spinner" style="width: 16px; height: 16px;"></span>';
      } else {
        confirmBtn.textContent = this.confirmText;
      }
    }
    return this;
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

  /**
   * Static method: Show confirmation dialog
   */
  static confirm(title, message, onConfirm) {
    const modal = new Modal({
      title,
      size: 'sm',
      confirmText: 'Confirm',
      confirmClass: 'btn-danger',
      onConfirm: async () => {
        modal.setLoading(true);
        try {
          await onConfirm();
          modal.close();
        } catch (error) {
          modal.setLoading(false);
        }
      }
    });

    modal.setContent(`
      <p style="color: #4B5563; line-height: 1.6;">${message}</p>
    `);

    modal.open();
    return modal;
  }

  /**
   * Static method: Show alert dialog
   */
  static alert(title, message) {
    const modal = new Modal({
      title,
      size: 'sm',
      showFooter: false
    });

    modal.setContent(`
      <p style="color: #4B5563; line-height: 1.6; margin-bottom: 20px;">${message}</p>
      <button class="btn btn-primary" style="width: 100%;" onclick="this.closest('.modal-overlay').classList.remove('active'); document.body.style.overflow = '';">
        OK
      </button>
    `);

    modal.open();
    return modal;
  }
}

export default Modal;
