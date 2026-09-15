class SidebarTree {
  constructor() {
    this.container = document.getElementById('sidebar-content');
    this.sidebar = document.getElementById('sidebar');
    this.resizer = document.getElementById('sidebar-resizer');
    this.hamburgerBtn = document.getElementById('hamburger-btn');
    this.activePath = null;
    this.nodeCache = new Map(); // path -> subdirs array
    this.initResizer();
    this.initHamburger();
  }

  async init(sources, defaultFolder) {
    this.sources = sources || [];
    this.renderSidebarStructure();
    this.updateFavoritesCount();

    window.appStore.subscribe((key, val) => {
      if (key === 'favorites') {
        this.updateFavoritesCount();
      }
    });

    await this.populateSourcesTree();

    if (defaultFolder) {
      await this.navigateTo(defaultFolder);
    }
  }

  updateFavoritesCount() {
    const favCountEl = document.getElementById('fav-badge-count');
    const favs = window.appStore.get('favorites') || [];
    if (favCountEl) {
      favCountEl.textContent = favs.length;
      favCountEl.style.display = favs.length > 0 ? 'inline-block' : 'none';
    }
  }

  renderSidebarStructure() {
    this.container.innerHTML = `
      <div class="sidebar-nav">
        <!-- Home / Albums -->
        <div class="nav-item active" id="nav-home" data-type="home" title="Home">
          <span class="nav-icon">${Icons.home}</span>
          <span class="nav-label">Home</span>
          <span class="badge-count" id="albums-badge-count" style="display:none;">0</span>
        </div>

        <!-- Gallery -->
        <div class="nav-item" id="nav-gallery" data-type="gallery" title="Gallery">
          <span class="nav-icon">${Icons.gallery}</span>
          <span class="nav-label">Gallery</span>
          <div class="nav-actions">
            <button class="nav-action-btn" id="btn-add-folder-sidebar" title="Add Folder">${Icons.addFolder}</button>
          </div>
        </div>

        <!-- Favourites -->
        <div class="nav-item" id="nav-favourites" data-type="favourites" title="Favourites">
          <span class="nav-icon">${Icons.heart}</span>
          <span class="nav-label">Favourites</span>
          <span class="badge-count" id="fav-badge-count" style="display:none;">0</span>
        </div>


        <!-- Personal Section -->
        <div class="sidebar-section">
          <div class="section-header" id="section-personal-header" title="Soham - Personal">
            <span class="section-icon" style="color: #0078D4;">${Icons.cloud}</span>
            <span class="section-label">Soham - Personal</span>
            <span class="section-chevron" id="chevron-personal">${Icons.chevronUp}</span>
          </div>
          <div class="tree-container" id="personal-tree-container">
            <div class="nav-item" id="nav-memories" data-type="memories" title="Memories">
              <span class="nav-icon">${Icons.memories}</span>
              <span class="nav-label">Memories</span>
            </div>
            <div class="nav-item" id="nav-pictures" data-type="folder" data-path="${this.getHomePicturesPath()}" title="Pictures">
              <span class="nav-icon">${Icons.folder}</span>
              <span class="nav-label">Pictures</span>
              <span class="section-chevron" style="width:16px; height:16px;">${Icons.chevronDown}</span>
            </div>
          </div>
        </div>

        <!-- iCloud / Cloud Section -->
        <div class="sidebar-section">
          <div class="nav-item" id="nav-icloud" style="padding: 0 10px;" title="iCloud Photos">
            <span class="nav-icon" style="color: #FFA000;">${Icons.photosLogo}</span>
            <span class="nav-label">iCloud Photos</span>
          </div>
        </div>

        <!-- This PC Section -->
        <div class="sidebar-section">
          <div class="section-header" id="section-thispc-header" title="This PC">
            <span class="section-icon">${Icons.pc}</span>
            <span class="section-label">This PC</span>
            <span class="section-chevron" id="chevron-thispc">${Icons.chevronUp}</span>
          </div>
          <div class="tree-container" id="thispc-tree-container">
            <!-- Root sources populated dynamically -->
          </div>
        </div>
      </div>
    `;

    // Wire up standard nav clicks
    const homeNav = document.getElementById('nav-home');
    if (homeNav) {
      homeNav.onclick = () => {
        this.setActiveElement(homeNav);
        if (window.albumsManager) {
          window.albumsManager.showHome();
        }
      };
    }

    document.getElementById('nav-gallery').onclick = () => {
      this.setActiveElement(document.getElementById('nav-gallery'));
      const defaultSrc = this.sources[0] || this.getHomePicturesPath();
      window.galleryView.loadFolder(defaultSrc, 'Gallery');
    };

    document.getElementById('nav-favourites').onclick = () => {
      this.setActiveElement(document.getElementById('nav-favourites'));
      window.galleryView.loadFavorites();
    };

    document.getElementById('nav-memories').onclick = () => {
      this.setActiveElement(document.getElementById('nav-memories'));
      window.galleryView.loadMemories();
    };

    const picItem = document.getElementById('nav-pictures');
    picItem.onclick = () => {
      this.setActiveElement(picItem);
      window.galleryView.loadFolder(picItem.dataset.path, 'Pictures');
    };

    document.getElementById('nav-icloud').onclick = () => {
      this.setActiveElement(document.getElementById('nav-icloud'));
      const defaultSrc = this.sources[0] || this.getHomePicturesPath();
      window.galleryView.loadFolder(defaultSrc, 'iCloud Photos');
    };

    // Add folder button in sidebar
    document.getElementById('btn-add-folder-sidebar').onclick = async (e) => {
      e.stopPropagation();
      const folder = await window.api.addCustomFolder();
      if (folder) {
        await window.appStore.addSource(folder);
        this.sources = window.appStore.get('sources');
        await this.populateSourcesTree();
        this.navigateTo(folder);
      }
    };

    // Toggle section headers
    this.wireSectionToggle('section-personal-header', 'personal-tree-container', 'chevron-personal');
    this.wireSectionToggle('section-thispc-header', 'thispc-tree-container', 'chevron-thispc');
  }

  getHomePicturesPath() {
    return this.sources[0] || '/home/soham/Pictures/p-gallery-section';
  }

  wireSectionToggle(headerId, containerId, chevronId) {
    const header = document.getElementById(headerId);
    const container = document.getElementById(containerId);
    const chevron = document.getElementById(chevronId);
    if (!header || !container) return;

    header.onclick = () => {
      if (this.sidebar.classList.contains('collapsed')) {
        this.sidebar.classList.remove('collapsed');
        container.classList.remove('collapsed');
        if (chevron) {
          chevron.innerHTML = Icons.chevronUp;
        }
        return;
      }
      const isCollapsed = container.classList.toggle('collapsed');
      if (chevron) {
        chevron.innerHTML = isCollapsed ? Icons.chevronDown : Icons.chevronUp;
      }
    };
  }

  async populateSourcesTree() {
    const container = document.getElementById('thispc-tree-container');
    if (!container) return;
    container.innerHTML = '';

    const picturesDir = this.getHomePicturesPath();
    const dirData = await window.api.readDir(picturesDir);

    if (dirData && dirData.subdirs) {
      for (const sub of dirData.subdirs) {
        if (sub.name === 'm') {
          // If 'm' directory exists inside Pictures, list its items directly under This PC!
          const mData = await window.api.readDir(sub.path);
          if (mData && mData.subdirs) {
            for (const mSub of mData.subdirs) {
              const node = await this.createTreeNode(mSub.name, mSub.path, 1);
              container.appendChild(node);
            }
          }
        } else {
          const node = await this.createTreeNode(sub.name, sub.path, 1);
          container.appendChild(node);
        }
      }
    }
  }

  async createTreeNode(name, fullPath, depth = 1) {
    const node = document.createElement('div');
    node.className = 'tree-node';
    node.dataset.path = fullPath;
    node.dataset.name = name;

    const row = document.createElement('div');
    row.className = 'tree-row';
    row.dataset.path = fullPath;

    // 1. Indentation
    const indent = document.createElement('div');
    indent.className = 'tree-indent';
    indent.style.width = `${depth * 14}px`;
    row.appendChild(indent);

    // 2. Folder Icon
    const icon = document.createElement('div');
    icon.className = 'tree-icon';
    icon.innerHTML = Icons.folder;
    row.appendChild(icon);

    // 3. Folder Name
    const label = document.createElement('div');
    label.className = 'tree-name';
    label.textContent = name;
    row.appendChild(label);

    // 4. Chevron (on the right)
    const chevron = document.createElement('div');
    chevron.className = 'tree-chevron';
    chevron.innerHTML = Icons.chevronDown;
    row.appendChild(chevron);

    node.appendChild(row);

    // Container for child items
    const childrenContainer = document.createElement('div');
    childrenContainer.className = 'tree-children collapsed';
    node.appendChild(childrenContainer);

    // Pre-check subdirectories to show or hide chevron
    window.api.readDir(fullPath).then(dirData => {
      if (dirData && dirData.subdirs && dirData.subdirs.length > 0) {
        this.nodeCache.set(fullPath, dirData.subdirs);
        chevron.style.display = 'flex';
      } else {
        chevron.style.display = 'none';
      }
    });

    chevron.onclick = async (e) => {
      e.stopPropagation();
      await this.toggleNode(node, fullPath, depth);
    };

    row.onclick = async (e) => {
      if (e.target.closest('.tree-chevron')) return;
      this.setActiveElement(row);
      this.activePath = fullPath;
      await window.galleryView.loadFolder(fullPath, name);
    };

    return node;
  }

  async toggleNode(node, fullPath, depth) {
    const chevron = node.querySelector('.tree-chevron');
    const children = node.querySelector('.tree-children');
    const isExpanded = !children.classList.contains('collapsed');

    if (isExpanded) {
      children.classList.add('collapsed');
      chevron.innerHTML = Icons.chevronDown;
    } else {
      await this.expandNode(node, fullPath, depth);
    }
  }

  async expandNode(node, fullPath, depth) {
    const chevron = node.querySelector('.tree-chevron');
    const children = node.querySelector('.tree-children');

    if (!this.nodeCache.has(fullPath)) {
      const dirData = await window.api.readDir(fullPath);
      if (dirData && dirData.subdirs) {
        this.nodeCache.set(fullPath, dirData.subdirs);
      }
    }

    const subdirs = this.nodeCache.get(fullPath);
    if (subdirs && subdirs.length > 0) {
      children.innerHTML = '';
      for (const sub of subdirs) {
        const childNode = await this.createTreeNode(sub.name, sub.path, depth + 1);
        children.appendChild(childNode);
      }
      children.classList.remove('collapsed');
      chevron.innerHTML = Icons.chevronUp;
      chevron.style.display = 'flex';
    } else {
      chevron.style.display = 'none';
    }
  }

  async revealPath(targetPath) {
    let search = true;
    let attempts = 0;
    while (search && attempts < 8) {
      attempts++;
      search = false;
      const nodes = document.querySelectorAll('.tree-node');
      for (const node of nodes) {
        const nodePath = node.dataset.path;
        if (targetPath.startsWith(nodePath) && targetPath !== nodePath) {
          const children = node.querySelector('.tree-children');
          if (children && children.classList.contains('collapsed')) {
            const depth = Math.floor((node.querySelector('.tree-indent')?.offsetWidth || 14) / 14);
            await this.expandNode(node, nodePath, depth);
            search = true;
            break;
          }
        }
      }
    }
  }

  async navigateTo(targetPath) {
    this.activePath = targetPath;
    const folderName = targetPath.split('/').filter(Boolean).pop() || 'Photos';

    // Auto-expand parents to target
    await this.revealPath(targetPath);

    const targetRow = document.querySelector(`.tree-row[data-path="${CSS.escape(targetPath)}"]`);
    if (targetRow) {
      this.setActiveElement(targetRow);
      targetRow.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    await window.galleryView.loadFolder(targetPath, folderName);
  }

  setActiveElement(element) {
    document.querySelectorAll('.nav-item, .tree-row').forEach(el => el.classList.remove('active'));
    if (element) {
      element.classList.add('active');
    }
  }

  initResizer() {
    let isDragging = false;
    let startX = 0;
    let startWidth = 260;

    const savedWidth = window.appStore.get('sidebarWidth') || 260;
    this.sidebar.style.width = `${savedWidth}px`;

    this.resizer.addEventListener('mousedown', (e) => {
      isDragging = true;
      startX = e.clientX;
      startWidth = this.sidebar.offsetWidth;
      this.resizer.classList.add('dragging');
      document.body.style.cursor = 'col-resize';
      e.preventDefault();
    });

    window.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      const dx = e.clientX - startX;
      let newWidth = startWidth + dx;
      if (newWidth < 180) newWidth = 180;
      if (newWidth > 450) newWidth = 450;
      this.sidebar.style.width = `${newWidth}px`;
    });

    window.addEventListener('mouseup', () => {
      if (isDragging) {
        isDragging = false;
        this.resizer.classList.remove('dragging');
        document.body.style.cursor = 'default';
        window.appStore.set('sidebarWidth', this.sidebar.offsetWidth);
      }
    });
  }

  initHamburger() {
    this.hamburgerBtn.onclick = () => {
      this.sidebar.classList.toggle('collapsed');
    };
  }
}

window.sidebarTree = new SidebarTree();
