/**
 * Sawari Admin Portal - Tabs Component
 */

export class Tabs {
  constructor(containerId, options = {}) {
    this.container = document.getElementById(containerId);
    this.tabs = options.tabs || [];
    this.activeTab = options.activeTab || (this.tabs[0]?.id || null);
    this.onChange = options.onChange || null;

    this.render();
  }

  /**
   * Render tabs
   */
  render() {
    if (!this.container) return;

    this.container.innerHTML = `
      <div class="tabs">
        ${this.tabs.map(tab => `
          <button
            class="tab ${tab.id === this.activeTab ? 'active' : ''}"
            data-tab-id="${tab.id}"
          >
            ${tab.label}
            ${tab.count !== undefined ? `
              <span style="
                margin-left: 8px;
                padding: 2px 8px;
                border-radius: 9999px;
                font-size: 11px;
                background-color: ${tab.id === this.activeTab ? '#D1FAE5' : '#F3F4F6'};
                color: ${tab.id === this.activeTab ? '#047857' : '#4B5563'};
              ">${tab.count}</span>
            ` : ''}
          </button>
        `).join('')}
      </div>
    `;

    this.bindEvents();
  }

  /**
   * Bind event listeners
   */
  bindEvents() {
    if (!this.container) return;

    this.container.querySelectorAll('[data-tab-id]').forEach(btn => {
      btn.addEventListener('click', () => {
        const tabId = btn.dataset.tabId;
        this.setActive(tabId);
      });
    });
  }

  /**
   * Set active tab
   */
  setActive(tabId) {
    if (this.activeTab === tabId) return;

    this.activeTab = tabId;
    this.render();

    if (this.onChange) {
      this.onChange(tabId);
    }

    return this;
  }

  /**
   * Get active tab
   */
  getActive() {
    return this.activeTab;
  }

  /**
   * Update tab count
   */
  setCount(tabId, count) {
    const tab = this.tabs.find(t => t.id === tabId);
    if (tab) {
      tab.count = count;
      this.render();
    }
    return this;
  }
}

export default Tabs;
