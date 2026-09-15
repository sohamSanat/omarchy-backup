/**
 * P-gallery App Lock Screen Manager
 * Biometric (Fingerprint) & Sudo/User Password Dual Authentication
 */

class AppLock {
  constructor() {
    this.isLocked = true;
    this.isAuthenticating = false;
    this.passwordVisible = false;

    // DOM Elements
    this.overlay = document.getElementById('app-lock-screen');
    this.card = document.getElementById('lock-card');
    this.appLogo = document.getElementById('lock-app-logo');
    this.shieldIcon = document.getElementById('lock-shield-icon');
    this.usernameEl = document.getElementById('lock-username');
    this.userAvatarEl = document.getElementById('lock-user-avatar');
    this.fpIcon = document.getElementById('lock-fp-icon');
    this.fpStatus = document.getElementById('lock-fp-status');
    this.passwordForm = document.getElementById('lock-password-form');
    this.inputWrap = document.getElementById('lock-input-wrap');
    this.keyIcon = document.getElementById('lock-key-icon');
    this.passwordInput = document.getElementById('lock-password-input');
    this.togglePwdBtn = document.getElementById('lock-toggle-pwd-btn');
    this.submitBtn = document.getElementById('lock-submit-btn');
    this.submitIcon = document.getElementById('lock-submit-icon');
    this.errorMsg = document.getElementById('lock-error-msg');
    this.titlebarLockBtn = document.getElementById('btn-lock-app');
    this.winMinBtn = document.getElementById('lock-win-min');
    this.winCloseBtn = document.getElementById('lock-win-close');

    this.init();
  }

  async init() {
    this.populateIcons();
    await this.loadUserInfo();
    this.bindEvents();

    try {
      const initData = await window.api.getInitialData();
      if (initData && initData.isTestUnlocked) {
        this.unlock();
        return;
      }
    } catch (e) {}

    this.startFingerprintListening();

    // Auto focus password input
    setTimeout(() => {
      if (this.passwordInput && this.isLocked) {
        this.passwordInput.focus();
      }
    }, 150);
  }

  populateIcons() {
    if (this.appLogo && typeof Icons !== 'undefined') {
      this.appLogo.innerHTML = Icons.photosLogo;
    }
    if (this.shieldIcon && typeof Icons !== 'undefined') {
      this.shieldIcon.innerHTML = Icons.shield;
    }
    if (this.fpIcon && typeof Icons !== 'undefined') {
      this.fpIcon.innerHTML = Icons.fingerprint;
    }
    if (this.keyIcon && typeof Icons !== 'undefined') {
      this.keyIcon.innerHTML = Icons.lock;
    }
    if (this.togglePwdBtn && typeof Icons !== 'undefined') {
      this.togglePwdBtn.innerHTML = Icons.eye;
    }
    if (this.submitIcon && typeof Icons !== 'undefined') {
      this.submitIcon.innerHTML = Icons.arrowRight;
    }
    if (this.titlebarLockBtn && typeof Icons !== 'undefined') {
      this.titlebarLockBtn.innerHTML = Icons.lock;
    }
  }

  async loadUserInfo() {
    try {
      const info = await window.api.getUserInfo();
      if (info && info.username) {
        if (this.usernameEl) {
          this.usernameEl.textContent = info.username;
        }
        if (this.userAvatarEl) {
          this.userAvatarEl.textContent = info.username.charAt(0).toUpperCase();
        }
      }
    } catch (e) {
      console.error('Failed to load user info:', e);
    }
  }

  bindEvents() {
    // Window controls on lock screen
    if (this.winMinBtn) {
      this.winMinBtn.onclick = () => window.api.minimize();
    }
    if (this.winCloseBtn) {
      this.winCloseBtn.onclick = () => window.api.close();
    }

    // Titlebar lock button
    if (this.titlebarLockBtn) {
      this.titlebarLockBtn.onclick = () => {
        if (!this.isLocked) {
          this.lock();
        }
      };
    }

    // Toggle password visibility
    if (this.togglePwdBtn) {
      this.togglePwdBtn.onclick = () => this.togglePasswordVisibility();
    }

    // Password form submit
    if (this.passwordForm) {
      this.passwordForm.onsubmit = (e) => {
        e.preventDefault();
        this.submitPassword();
        return false;
      };
    }

    // Clear error on password input typing
    if (this.passwordInput) {
      this.passwordInput.oninput = () => {
        this.clearError();
      };
      this.passwordInput.onkeydown = (e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          this.submitPassword();
        }
      };
    }

    // Fingerprint IPC events from main process
    window.api.onFingerprintStatus((statusText) => {
      if (!this.isLocked) return;
      this.updateFingerprintStatus(statusText);
    });

    window.api.onFingerprintSuccess(() => {
      if (!this.isLocked) return;
      this.onFingerprintSuccess();
    });
  }

  togglePasswordVisibility() {
    this.passwordVisible = !this.passwordVisible;
    if (this.passwordInput) {
      this.passwordInput.type = this.passwordVisible ? 'text' : 'password';
    }
    if (this.togglePwdBtn && typeof Icons !== 'undefined') {
      this.togglePwdBtn.innerHTML = this.passwordVisible ? Icons.eyeOff : Icons.eye;
      this.togglePwdBtn.title = this.passwordVisible ? 'Hide password' : 'Show password';
    }
    if (this.passwordInput) {
      this.passwordInput.focus();
    }
  }

  startFingerprintListening() {
    try {
      window.api.startFingerprintAuth();
    } catch (e) {
      console.error('Failed to start fingerprint auth:', e);
    }
  }

  updateFingerprintStatus(statusText) {
    if (!this.fpStatus) return;
    this.fpStatus.textContent = statusText;
    if (statusText.toLowerCase().includes('not recognized') || statusText.toLowerCase().includes('error')) {
      this.fpStatus.className = 'lock-fp-status error';
      if (this.card) {
        this.card.classList.add('shake');
        setTimeout(() => this.card?.classList.remove('shake'), 450);
      }
    } else {
      this.fpStatus.className = 'lock-fp-status';
    }
  }

  onFingerprintSuccess() {
    if (this.fpStatus) {
      this.fpStatus.textContent = 'Fingerprint verified! Unlocking...';
      this.fpStatus.className = 'lock-fp-status success';
    }
    if (this.fpIcon) {
      this.fpIcon.classList.add('verified');
    }
    // Animate unlock after brief pause for visual feedback
    setTimeout(() => {
      this.unlock();
    }, 400);
  }

  async submitPassword() {
    if (this.isAuthenticating || !this.isLocked) return;
    const password = this.passwordInput ? this.passwordInput.value : '';
    if (!password) {
      if (this.passwordInput) this.passwordInput.focus();
      return;
    }

    this.isAuthenticating = true;
    this.clearError();
    if (this.submitBtn) this.submitBtn.disabled = true;

    try {
      const res = await window.api.verifyPassword(password);
      if (res && res.success) {
        this.unlock();
      } else {
        this.showError('Incorrect password. Please try again.');
        if (this.passwordInput) {
          this.passwordInput.select();
          this.passwordInput.focus();
        }
      }
    } catch (err) {
      this.showError('Authentication error. Please try again.');
    } finally {
      this.isAuthenticating = false;
      if (this.submitBtn) this.submitBtn.disabled = false;
    }
  }

  showError(msg) {
    if (this.errorMsg) {
      this.errorMsg.textContent = msg;
      this.errorMsg.classList.add('show');
    }
    if (this.inputWrap) {
      this.inputWrap.classList.add('error');
    }
    if (this.card) {
      this.card.classList.add('shake');
      setTimeout(() => this.card?.classList.remove('shake'), 450);
    }
  }

  clearError() {
    if (this.errorMsg) {
      this.errorMsg.classList.remove('show');
    }
    if (this.inputWrap) {
      this.inputWrap.classList.remove('error');
    }
  }

  unlock() {
    this.isLocked = false;
    if (this.passwordInput) {
      this.passwordInput.value = '';
    }
    this.clearError();

    // Visual unlock transition
    if (this.overlay) {
      this.overlay.classList.add('unlocked');
      setTimeout(() => {
        if (!this.isLocked && this.overlay) {
          this.overlay.style.display = 'none';
        }
      }, 350);
    }

    // Stop biometric listening to free sensor
    try {
      window.api.stopFingerprintAuth();
    } catch (e) {}

    // Focus main search input if available
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
      searchInput.focus();
    }
  }

  lock() {
    this.isLocked = true;
    this.passwordVisible = false;
    if (this.passwordInput) {
      this.passwordInput.type = 'password';
      this.passwordInput.value = '';
    }
    if (this.togglePwdBtn && typeof Icons !== 'undefined') {
      this.togglePwdBtn.innerHTML = Icons.eye;
      this.togglePwdBtn.title = 'Show password';
    }
    this.clearError();

    if (this.fpStatus) {
      this.fpStatus.textContent = 'Touch the fingerprint sensor or enter your password';
      this.fpStatus.className = 'lock-fp-status';
    }
    if (this.fpIcon) {
      this.fpIcon.classList.remove('verified');
    }

    if (this.overlay) {
      this.overlay.style.display = 'flex';
      // Force reflow for transition
      void this.overlay.offsetWidth;
      this.overlay.classList.remove('unlocked');
    }

    this.startFingerprintListening();

    setTimeout(() => {
      if (this.passwordInput) {
        this.passwordInput.focus();
      }
    }, 150);
  }
}

// Initialize Lock Screen when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.appLock = new AppLock();
  });
} else {
  window.appLock = new AppLock();
}
