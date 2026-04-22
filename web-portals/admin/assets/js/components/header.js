/**
 * Sawari Admin Portal - Header Component
 */

import { auth } from '../auth.js';
import { api } from '../api.js';

export class Header {
  constructor(containerId, user) {
    this.container = document.getElementById(containerId);
    this.user = user;
    this.dropdownOpen = false;
    this.notifOpen = false;
    this.notifications = [];
    this.unreadCount = 0;
    this.render();
    this.bindEvents();
    this.loadNotifications();
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

        <!-- Notification Bell -->
        <div style="position: relative; margin-right: 8px;">
          <button id="notif-btn" style="position: relative; padding: 8px; border-radius: 8px; border: none; background: transparent; cursor: pointer; transition: background 0.2s;" title="Notifications">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" fill="none" stroke="#374151" stroke-width="2">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0"/>
            </svg>
            <span id="notif-badge" style="display:none; position:absolute; top:4px; right:4px; background:#EF4444; color:white; font-size:10px; font-weight:700; border-radius:999px; min-width:16px; height:16px; line-height:16px; text-align:center; padding:0 3px;"></span>
          </button>
          <div id="notif-dropdown" style="display:none; position:absolute; right:0; top:calc(100% + 8px); background:white; border-radius:12px; box-shadow:0 4px 20px rgba(0,0,0,0.15); width:320px; overflow:hidden; z-index:60;">
            <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 16px; border-bottom:1px solid #E5E7EB;">
              <span style="font-size:14px; font-weight:600; color:#111827;">Notifications</span>
              <button id="notif-mark-all" style="font-size:12px; color:#10B981; background:none; border:none; cursor:pointer; font-weight:500;">Mark all read</button>
            </div>
            <div id="notif-list" style="max-height:320px; overflow-y:auto;"></div>
          </div>
        </div>

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

    // Notification bell
    const notifBtn = document.getElementById('notif-btn');
    const notifDropdown = document.getElementById('notif-dropdown');
    const notifMarkAll = document.getElementById('notif-mark-all');

    if (notifBtn && notifDropdown) {
      notifBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.notifOpen = !this.notifOpen;
        notifDropdown.style.display = this.notifOpen ? 'block' : 'none';
        if (this.notifOpen) this.dropdownOpen = false;
        if (document.getElementById('user-dropdown-menu')) {
          document.getElementById('user-dropdown-menu').style.display = 'none';
        }
      });

      document.addEventListener('click', () => {
        this.notifOpen = false;
        notifDropdown.style.display = 'none';
      });
    }

    if (notifMarkAll) {
      notifMarkAll.addEventListener('click', async (e) => {
        e.stopPropagation();
        const unread = this.notifications.filter(n => !n.isread);
        await Promise.all(unread.map(n => api.markNotificationRead(n.notificationid)));
        this.notifications = this.notifications.map(n => ({ ...n, isread: true }));
        this.unreadCount = 0;
        this.renderNotifications();
        this.updateBadge();
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

  async loadNotifications() {
    try {
      const res = await api.getNotifications(10);
      if (res.success && res.data?.notifications) {
        this.notifications = res.data.notifications;
        this.unreadCount = res.data.unread ?? 0;
        this.renderNotifications();
        this.updateBadge();
      }
    } catch (_) {}
  }

  renderNotifications() {
    const list = document.getElementById('notif-list');
    if (!list) return;

    if (this.notifications.length === 0) {
      list.innerHTML = `<div style="padding:24px; text-align:center; color:#9CA3AF; font-size:14px;">No notifications</div>`;
      return;
    }

    list.innerHTML = this.notifications.map(n => `
      <div style="padding:12px 16px; border-bottom:1px solid #F3F4F6; background:${n.isread ? 'white' : '#F0FDF4'}; cursor:default;">
        <div style="font-size:13px; font-weight:600; color:#111827;">${this.escapeHtml(n.title)}</div>
        <div style="font-size:12px; color:#6B7280; margin-top:2px;">${this.escapeHtml(n.message)}</div>
        <div style="font-size:11px; color:#9CA3AF; margin-top:4px;">${new Date(n.createdat).toLocaleString()}</div>
      </div>
    `).join('');
  }

  updateBadge() {
    const badge = document.getElementById('notif-badge');
    if (!badge) return;
    if (this.unreadCount > 0) {
      badge.style.display = 'block';
      badge.textContent = this.unreadCount > 99 ? '99+' : this.unreadCount;
    } else {
      badge.style.display = 'none';
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
