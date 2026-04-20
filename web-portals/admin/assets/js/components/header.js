/**
 * Sawari Admin Portal - Header Component
 */

import { auth } from '../auth.js';

export class Header {
  constructor(containerId, user) {
    this.container = document.getElementById(containerId);
    this.user = user;
    this.dropdownOpen = false;
    this.render();
    this.bindEvents();
  }

  /**
   * Render header
   */
  render() {
    if (!this.container) return;

    const userName = this.user?.fullname || this.user?.email || 'Admin';
    const userEmail = this.user?.email || '';

    this.container.innerHTML = `
      <header class="header">
        <!-- Mobile menu button -->
        <button id="mobile-menu-btn" class="btn-outline" style="display: none; padding: 8px;">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 12h18M3 6h18M3 18h18"/>
          </svg>
        </button>

        <!-- Page title will be set by individual pages -->
        <h1 id="page-title" style="font-size: 20px; font-weight: 600; color: #111827; margin: 0;"></h1>

        <!-- User dropdown -->
        <div style="position: relative;">
          <button id="user-dropdown-btn" style="display: flex; align-items: center; gap: 12px; padding: 8px 12px; border-radius: 8px; border: none; background: transparent; cursor: pointer; transition: background 0.2s;">
            <div style="text-align: right;">
              <div style="font-size: 14px; font-weight: 500; color: #111827;">${this.escapeHtml(userName)}</div>
              <div style="font-size: 12px; color: #6B7280;">Administrator</div>
            </div>
            <div style="width: 40px; height: 40px; background: linear-gradient(135deg, #10B981, #3B82F6); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: 600;">
              ${userName.charAt(0).toUpperCase()}
            </div>
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M4 6l4 4 4-4"/>
            </svg>
          </button>

          <!-- Dropdown menu -->
          <div id="user-dropdown-menu" style="display: none; position: absolute; right: 0; top: 100%; margin-top: 8px; background: white; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.15); min-width: 200px; overflow: hidden; z-index: 50;">
            <div style="padding: 16px; border-bottom: 1px solid #E5E7EB;">
              <div style="font-size: 14px; font-weight: 500; color: #111827;">${this.escapeHtml(userName)}</div>
              <div style="font-size: 12px; color: #6B7280;">${this.escapeHtml(userEmail)}</div>
            </div>
            <div style="padding: 8px;">
              <button id="logout-btn" style="width: 100%; display: flex; align-items: center; gap: 10px; padding: 10px 12px; border: none; background: transparent; cursor: pointer; border-radius: 8px; color: #D4183D; transition: background 0.2s;">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4M16 17l5-5-5-5M21 12H9"/>
                </svg>
                <span style="font-size: 14px;">Sign out</span>
              </button>
            </div>
          </div>
        </div>
      </header>
    `;
  }

  /**
   * Bind event listeners
   */
  bindEvents() {
    // Dropdown toggle
    const dropdownBtn = document.getElementById('user-dropdown-btn');
    const dropdownMenu = document.getElementById('user-dropdown-menu');

    if (dropdownBtn && dropdownMenu) {
      dropdownBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.dropdownOpen = !this.dropdownOpen;
        dropdownMenu.style.display = this.dropdownOpen ? 'block' : 'none';
      });

      // Close dropdown when clicking outside
      document.addEventListener('click', () => {
        this.dropdownOpen = false;
        dropdownMenu.style.display = 'none';
      });
    }

    // Logout button
    const logoutBtn = document.getElementById('logout-btn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', async () => {
        await auth.signOut();
        window.location.href = 'login.html';
      });
    }

    // Mobile menu button
    const mobileMenuBtn = document.getElementById('mobile-menu-btn');
    if (mobileMenuBtn) {
      mobileMenuBtn.addEventListener('click', () => {
        const sidebar = document.querySelector('.sidebar');
        if (sidebar) {
          sidebar.classList.toggle('open');
        }
      });
    }
  }

  /**
   * Set page title
   */
  setPageTitle(title) {
    const titleEl = document.getElementById('page-title');
    if (titleEl) {
      titleEl.textContent = title;
    }
  }

  /**
   * Escape HTML to prevent XSS
   */
  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
}

export default Header;
