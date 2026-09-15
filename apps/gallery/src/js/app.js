class App {
  constructor() {
    this.init();
  }

  async init() {
    // Load store
    await window.appStore.init();

    // Setup Theme
    await this.applyTheme(window.appStore.get('theme') || 'dark');

    // Titlebar branding & controls
    this.setupTitlebar();

    // Window controls
    this.setupWindowControls();

    // Settings Modal
    this.setupSettingsModal();

    // Get Initial data from Main
    const initialData = await window.api.getInitialData();
    const config = initialData?.config || {};
    const sources = config.sources || [];
    const lastOpened = config.lastOpenedFolder;

    // Listen for window maximize changes
    window.api.onMaximizeChange((isMax) => {
      const maxBtn = document.getElementById('win-btn-max');
      if (maxBtn) {
        maxBtn.innerHTML = isMax ? Icons.restore : Icons.maximize;
      }
    });

    // Initialize sidebar tree
    await window.sidebarTree.init(sources, null);

    if (initialData?.isTestCollapsed) {
      document.getElementById('sidebar')?.classList.add('collapsed');
    }

    // Handle target path if passed as argument
    const initialTarget = await window.api.getTargetArg();
    if (initialTarget) {
      await this.handleOpenTarget(initialTarget);
    } else {
      // Default to Albums Home Page
      if (window.albumsManager) {
        window.albumsManager.showHome();
      }
    }

    // Listen for open target (file or folder passed via second-instance)
    window.api.onOpenTarget(async (targetPath) => {
      await this.handleOpenTarget(targetPath);
    });
  }

  async handleOpenTarget(targetPath) {
    if (!targetPath) return;
    if (targetPath === '--collapsed') {
      window.albumsManager?.showHome();
      document.getElementById('sidebar')?.classList.add('collapsed');
      return;
    }
    if (targetPath === '--home') {
      window.albumsManager?.showHome();
      return;
    }
    if (targetPath === '--modal') {
      window.albumsManager?.openAlbumModal();
      return;
    }
    if (targetPath.startsWith('--album:')) {
      const albumId = targetPath.replace('--album:', '');
      window.albumsManager?.openAlbum(albumId);
      return;
    }
    if (targetPath.match(/\.(jpg|jpeg|png|webp|gif|bmp|avif|svg)$/i)) {
      const dir = targetPath.substring(0, targetPath.lastIndexOf('/'));
      await window.sidebarTree.navigateTo(dir);
      const photoIndex = window.galleryView.filteredPhotos.findIndex(p => p.path === targetPath);
      if (photoIndex !== -1) {
        window.photoViewer.open(window.galleryView.filteredPhotos, photoIndex);
      } else if (window.galleryView.filteredPhotos.length > 0) {
        window.photoViewer.open(window.galleryView.filteredPhotos, 0);
      }
    } else {
      await window.sidebarTree.navigateTo(targetPath);
    }
  }

  async applyTheme(themeName) {
    document.documentElement.setAttribute('data-theme', themeName);

    if (themeName === 'omarchy') {
      try {
        const omarchyTheme = await window.api.getOmarchyTheme();
        if (omarchyTheme) {
          document.documentElement.style.setProperty('--omarchy-bg', omarchyTheme.background);
          document.documentElement.style.setProperty('--omarchy-fg', omarchyTheme.foreground);
          document.documentElement.style.setProperty('--omarchy-accent', omarchyTheme.accent);
        }
      } catch (e) {
        console.warn('Omarchy theme fetch failed:', e);
      }
    }
  }

  setupTitlebar() {
    // App Logo
    const logoEl = document.getElementById('titlebar-logo');
    if (logoEl) logoEl.innerHTML = Icons.photosLogo;

    // Search Icon
    const searchIconEl = document.getElementById('search-icon-wrapper');
    if (searchIconEl) searchIconEl.innerHTML = Icons.search;

    const clearBtn = document.getElementById('search-clear-btn');
    if (clearBtn) clearBtn.innerHTML = Icons.clear;

    // Import Button
    const importBtn = document.getElementById('btn-import');
    if (importBtn) {
      importBtn.innerHTML = `${Icons.import} <span>Import</span> <span class="btn-chevron">${Icons.chevronDown}</span>`;
      importBtn.onclick = async () => {
        const folder = await window.api.addCustomFolder();
        if (folder) {
          await window.appStore.addSource(folder);
          await window.sidebarTree.init(window.appStore.get('sources'), folder);
        }
      };
    }

    // Settings Button
    const settingsBtn = document.getElementById('btn-settings');
    if (settingsBtn) {
      settingsBtn.innerHTML = Icons.settings;
      settingsBtn.onclick = () => {
        this.openSettingsModal();
      };
    }

    // Hamburger button
    const hamburgerBtn = document.getElementById('hamburger-btn');
    if (hamburgerBtn) hamburgerBtn.innerHTML = Icons.hamburger;
  }

  setupWindowControls() {
    const minBtn = document.getElementById('win-btn-min');
    const maxBtn = document.getElementById('win-btn-max');
    const closeBtn = document.getElementById('win-btn-close');

    if (minBtn) {
      minBtn.innerHTML = Icons.minimize;
      minBtn.onclick = () => window.api.minimize();
    }
    if (maxBtn) {
      maxBtn.innerHTML = Icons.maximize;
      maxBtn.onclick = () => window.api.maximize();
    }
    if (closeBtn) {
      closeBtn.innerHTML = Icons.close;
      closeBtn.onclick = () => window.api.close();
    }
  }

  setupSettingsModal() {
    const modal = document.getElementById('settings-modal');
    const closeBtn = document.getElementById('settings-btn-close');
    const themeSelect = document.getElementById('settings-theme-select');
    const addFolderBtn = document.getElementById('settings-btn-add-folder');

    if (closeBtn) {
      closeBtn.onclick = () => modal.classList.remove('show');
    }

    if (themeSelect) {
      themeSelect.value = window.appStore.get('theme') || 'dark';
      themeSelect.onchange = async () => {
        const newTheme = themeSelect.value;
        await window.appStore.set('theme', newTheme);
        await this.applyTheme(newTheme);
      };
    }

    if (addFolderBtn) {
      addFolderBtn.onclick = async () => {
        const folder = await window.api.addCustomFolder();
        if (folder) {
          await window.appStore.addSource(folder);
          await window.sidebarTree.init(window.appStore.get('sources'), folder);
          this.renderSettingsSources();
        }
      };
    }

    modal.onclick = (e) => {
      if (e.target === modal) modal.classList.remove('show');
    };
  }

  openSettingsModal() {
    const modal = document.getElementById('settings-modal');
    if (!modal) return;
    this.renderSettingsSources();
    modal.classList.add('show');
  }

  renderSettingsSources() {
    const listEl = document.getElementById('settings-sources-list');
    if (!listEl) return;
    const sources = window.appStore.get('sources') || [];

    listEl.innerHTML = '';
    sources.forEach(src => {
      const row = document.createElement('div');
      row.style.cssText = 'display:flex; align-items:center; justify-content:space-between; padding:6px 10px; background:var(--bg-control); border-radius:4px; margin-bottom:6px; font-size:12.5px;';

      const pathText = document.createElement('span');
      pathText.style.cssText = 'white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:320px;';
      pathText.textContent = src;
      row.appendChild(pathText);

      const delBtn = document.createElement('button');
      delBtn.className = 'btn btn-danger';
      delBtn.style.cssText = 'padding:2px 8px; font-size:11px;';
      delBtn.textContent = 'Remove';
      delBtn.onclick = async () => {
        await window.appStore.removeSource(src);
        await window.sidebarTree.init(window.appStore.get('sources'));
        this.renderSettingsSources();
      };
      row.appendChild(delBtn);

      listEl.appendChild(row);
    });
  }
}

document.addEventListener('DOMContentLoaded', () => {
  window.app = new App();
});
