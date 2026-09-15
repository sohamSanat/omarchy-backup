class GalleryView {
  constructor() {
    this.container = document.getElementById('gallery-container');
    this.header = document.getElementById('gallery-header');
    this.content = document.getElementById('gallery-content');
    this.emptyState = document.getElementById('empty-gallery');
    this.searchInput = document.getElementById('search-input');
    this.searchClearBtn = document.getElementById('search-clear-btn');

    this.currentFolder = null;
    this.currentTitle = 'Photos';
    this.allPhotos = [];
    this.filteredPhotos = [];
    this.selectedPaths = new Set();
    this.isSelectMode = false;

    this.sortMode = window.appStore.get('sort') || 'date-desc';
    this.filterMode = 'all'; // 'all', 'photos', 'videos', 'favorites'
    this.gridSize = window.appStore.get('gridSize') || 'medium';
    this.searchQuery = '';

    this.initToolbar();
    this.initSearch();
    this.initSelectionBar();
  }

  async loadFolder(folderPath, folderName) {
    this.currentAlbum = null;
    if (window.albumsManager) {
      window.albumsManager.hideHome();
    }
    const breadcrumb = document.getElementById('album-breadcrumb-bar');
    if (breadcrumb) breadcrumb.classList.remove('show');

    this.currentFolder = folderPath;
    this.currentTitle = folderName || folderPath.split('/').filter(Boolean).pop() || 'Photos';
    this.selectedPaths.clear();
    this.exitSelectMode();

    // Update Header
    this.updateHeaderUI();

    // Scan folder for photos
    const scanResult = await window.api.scanFolder(folderPath, true);
    this.allPhotos = scanResult.photos || [];
    const totalCount = scanResult.totalPhotos || this.allPhotos.length;

    // Update Subtitle: e.g. "311 photos in this folder and subfolders"
    const subtitleEl = document.getElementById('folder-subtitle');
    if (subtitleEl) {
      subtitleEl.textContent = `${totalCount} photo${totalCount === 1 ? '' : 's'} in this folder and subfolders`;
    }

    // Update document title and search placeholder
    document.title = `${this.currentTitle} - P-gallery`;
    if (this.searchInput) {
      this.searchInput.placeholder = `Search in ${this.currentTitle}`;
    }

    this.applyFilterAndSort();
  }

  async loadAlbum(album) {
    this.currentFolder = 'album:' + album.id;
    this.currentAlbum = album;
    this.currentTitle = album.name;
    this.selectedPaths.clear();
    this.exitSelectMode();

    if (window.albumsManager) {
      window.albumsManager.hideHome();
    }

    const breadcrumb = document.getElementById('album-breadcrumb-bar');
    if (breadcrumb) {
      breadcrumb.classList.add('show');
      const breadcrumbName = document.getElementById('album-breadcrumb-name');
      if (breadcrumbName) breadcrumbName.textContent = album.name;
    }

    const iconEl = document.getElementById('folder-header-icon');
    if (iconEl) iconEl.innerHTML = Icons.albums;

    this.updateHeaderUI(album.name, `Loading photos from ${(album.folders || []).length} folders...`);

    document.title = `${album.name} - P-gallery`;
    if (this.searchInput) {
      this.searchInput.placeholder = `Search in ${album.name}`;
    }

    const res = await window.api.getAlbumPhotos(album.folders || []);
    const photos = Array.isArray(res) ? res : ((res && res.photos) ? res.photos : []);
    this.allPhotos = photos;
    this.updateHeaderUI(album.name, `${photos.length} photo${photos.length === 1 ? '' : 's'} across ${(album.folders || []).length} folder${(album.folders || []).length === 1 ? '' : 's'}`);
    this.applyFilterAndSort();
  }


  async loadFavorites() {
    this.currentAlbum = null;
    if (window.albumsManager) window.albumsManager.hideHome();
    const breadcrumb = document.getElementById('album-breadcrumb-bar');
    if (breadcrumb) breadcrumb.classList.remove('show');

    this.currentFolder = 'favorites';
    this.currentTitle = 'Favourites';
    this.selectedPaths.clear();
    this.exitSelectMode();

    const favPaths = window.appStore.get('favorites') || [];
    const photos = [];
    for (const p of favPaths) {
      const name = p.split('/').pop();
      photos.push({
        name,
        path: p,
        size: 0,
        mtime: Date.now()
      });
    }

    this.allPhotos = photos;
    this.updateHeaderUI('Favourites', `${photos.length} favorite photo${photos.length === 1 ? '' : 's'}`);
    document.title = 'Favourites - P-gallery';
    if (this.searchInput) this.searchInput.placeholder = 'Search in Favourites';
    this.applyFilterAndSort();
  }

  async loadMemories() {
    this.currentAlbum = null;
    if (window.albumsManager) window.albumsManager.hideHome();
    const breadcrumb = document.getElementById('album-breadcrumb-bar');
    if (breadcrumb) breadcrumb.classList.remove('show');

    this.currentFolder = 'memories';
    this.currentTitle = 'Memories';
    this.selectedPaths.clear();
    this.exitSelectMode();

    this.updateHeaderUI('Memories', 'Photos and highlights from your collection');
    document.title = 'Memories - P-gallery';
    if (this.searchInput) this.searchInput.placeholder = 'Search in Memories';
    this.applyFilterAndSort();
  }


  updateHeaderUI(customTitle, customSubtitle) {
    const titleEl = document.getElementById('folder-title');
    const subtitleEl = document.getElementById('folder-subtitle');
    const iconEl = document.getElementById('folder-header-icon');

    if (titleEl) titleEl.textContent = customTitle || this.currentTitle;
    if (subtitleEl && customSubtitle) subtitleEl.textContent = customSubtitle;
    if (iconEl) iconEl.innerHTML = this.currentAlbum ? Icons.albums : Icons.folderFilled;
  }

  initToolbar() {
    // Select button
    const selectBtn = document.getElementById('btn-select');
    if (selectBtn) {
      selectBtn.onclick = () => {
        if (this.isSelectMode) {
          this.exitSelectMode();
        } else {
          this.enterSelectMode();
        }
      };
    }

    // Slideshow button
    const slideshowBtn = document.getElementById('btn-slideshow');
    if (slideshowBtn) {
      slideshowBtn.onclick = () => {
        if (this.filteredPhotos.length > 0) {
          window.photoViewer.open(this.filteredPhotos, 0);
          window.photoViewer.startSlideshow();
        }
      };
    }

    // Sort button & flyout
    this.setupFlyout('btn-sort', 'flyout-sort', (action) => {
      this.sortMode = action;
      window.appStore.set('sort', action);
      this.applyFilterAndSort();
    });

    // Filter button & flyout
    this.setupFlyout('btn-filter', 'flyout-filter', (action) => {
      this.filterMode = action;
      this.applyFilterAndSort();
    });

    // View grid size & flyout
    this.setupFlyout('btn-view', 'flyout-view', (action) => {
      this.gridSize = action;
      window.appStore.set('gridSize', action);
      this.renderPhotos();
    });

    // More options flyout
    this.setupFlyout('btn-more', 'flyout-more', async (action) => {
      if (action === 'refresh') {
        if (this.currentFolder && this.currentFolder !== 'favourites' && this.currentFolder !== 'memories') {
          await this.loadFolder(this.currentFolder, this.currentTitle);
        }
      } else if (action === 'reveal') {
        if (this.currentFolder && this.currentFolder.startsWith('/')) {
          await window.api.revealInFileManager(this.currentFolder);
        }
      } else if (action === 'copy-path') {
        if (this.currentFolder && this.currentFolder.startsWith('/')) {
          navigator.clipboard.writeText(this.currentFolder);
        }
      }
    });
  }

  setupFlyout(triggerBtnId, flyoutId, callback) {
    const btn = document.getElementById(triggerBtnId);
    const flyout = document.getElementById(flyoutId);
    if (!btn || !flyout) return;

    btn.onclick = (e) => {
      e.stopPropagation();
      // Close other flyouts
      document.querySelectorAll('.flyout-menu').forEach(f => {
        if (f !== flyout) f.classList.remove('show');
      });

      const rect = btn.getBoundingClientRect();
      flyout.style.top = `${rect.bottom + 6}px`;
      flyout.style.right = `${window.innerWidth - rect.right}px`;
      flyout.classList.toggle('show');
    };

    flyout.querySelectorAll('.flyout-item').forEach(item => {
      item.onclick = (e) => {
        e.stopPropagation();
        flyout.classList.remove('show');
        const action = item.dataset.action;
        if (callback && action) callback(action);
      };
    });

    window.addEventListener('click', (e) => {
      if (!flyout.contains(e.target) && e.target !== btn) {
        flyout.classList.remove('show');
      }
    });
  }

  initSearch() {
    if (!this.searchInput) return;

    const handleSearch = Utils.debounce(() => {
      this.searchQuery = this.searchInput.value.trim().toLowerCase();
      if (this.searchClearBtn) {
        this.searchClearBtn.classList.toggle('visible', this.searchQuery.length > 0);
      }
      this.applyFilterAndSort();
    }, 120);

    this.searchInput.addEventListener('input', handleSearch);

    if (this.searchClearBtn) {
      this.searchClearBtn.onclick = () => {
        this.searchInput.value = '';
        this.searchQuery = '';
        this.searchClearBtn.classList.remove('visible');
        this.applyFilterAndSort();
      };
    }
  }

  applyFilterAndSort() {
    let photos = Array.isArray(this.allPhotos) ? [...this.allPhotos] : [];

    // Filter by search query
    if (this.searchQuery) {
      photos = photos.filter(p => {
        const nameMatch = p.name.toLowerCase().includes(this.searchQuery);
        const dateStr = Utils.formatDate(p.mtime).toLowerCase();
        return nameMatch || dateStr.includes(this.searchQuery);
      });
    }

    // Filter by type
    if (this.filterMode === 'photos') {
      photos = photos.filter(p => !p.isVideo);
    } else if (this.filterMode === 'videos') {
      photos = photos.filter(p => p.isVideo);
    } else if (this.filterMode === 'favorites') {
      photos = photos.filter(p => window.appStore.isFavorite(p.path));
    }

    // Sort photos
    photos.sort((a, b) => {
      if (this.sortMode === 'date-desc') {
        return (b.mtime || 0) - (a.mtime || 0);
      } else if (this.sortMode === 'date-asc') {
        return (a.mtime || 0) - (b.mtime || 0);
      } else if (this.sortMode === 'name-asc') {
        return a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' });
      } else if (this.sortMode === 'name-desc') {
        return b.name.localeCompare(a.name, undefined, { numeric: true, sensitivity: 'base' });
      } else if (this.sortMode === 'size-desc') {
        return (b.size || 0) - (a.size || 0);
      }
      return 0;
    });

    this.filteredPhotos = photos;
    this.renderPhotos();
  }

  renderPhotos() {
    this.content.innerHTML = '';

    if (this.filteredPhotos.length === 0) {
      this.emptyState.classList.add('show');
      return;
    }
    this.emptyState.classList.remove('show');

    // Group photos by date range / timeline
    const timelineTimestamps = this.filteredPhotos.map(p => p.mtime).filter(Boolean);
    const dateRangeLabel = Utils.formatDateRange(timelineTimestamps) || 'Timeline';

    const groupWrapper = document.createElement('div');
    groupWrapper.className = 'timeline-group';

    // Group Header: e.g. "26 July 2025 - 3 August 2025"
    const groupHeader = document.createElement('div');
    groupHeader.className = 'timeline-header';
    groupHeader.textContent = dateRangeLabel;
    groupWrapper.appendChild(groupHeader);

    // Photo Grid
    const grid = document.createElement('div');
    grid.className = `photo-grid size-${this.gridSize}`;
    if (this.isSelectMode) grid.classList.add('select-mode');

    this.filteredPhotos.forEach((photo, index) => {
      const card = this.createPhotoCard(photo, index);
      grid.appendChild(card);
    });

    groupWrapper.appendChild(grid);
    this.content.appendChild(groupWrapper);
  }

  createPhotoCard(photo, index) {
    const card = document.createElement('div');
    card.className = 'photo-card';
    card.dataset.path = photo.path;
    card.dataset.index = index;

    if (this.selectedPaths.has(photo.path)) {
      card.classList.add('selected');
    }
    if (window.appStore.isFavorite(photo.path)) {
      card.classList.add('is-favorite');
    }

    // Thumbnail Image
    const img = document.createElement('img');
    img.className = 'photo-thumb';
    img.loading = 'lazy';
    img.alt = photo.name;
    // Hardware accelerated custom scheme
    img.src = `photo://${photo.path}`;
    card.appendChild(img);

    // Selection Checkbox Overlay (Top Left)
    const checkbox = document.createElement('div');
    checkbox.className = 'card-overlay-checkbox';
    checkbox.innerHTML = Icons.check;
    checkbox.onclick = (e) => {
      e.stopPropagation();
      this.toggleSelection(photo.path, card);
    };
    card.appendChild(checkbox);

    // Favorite Heart Overlay (Top Right)
    const favBtn = document.createElement('div');
    favBtn.className = 'card-overlay-fav';
    favBtn.innerHTML = window.appStore.isFavorite(photo.path) ? Icons.heartFilled : Icons.heart;
    favBtn.onclick = async (e) => {
      e.stopPropagation();
      const isFav = await window.appStore.toggleFavorite(photo.path);
      card.classList.toggle('is-favorite', isFav);
      favBtn.innerHTML = isFav ? Icons.heartFilled : Icons.heart;
    };
    card.appendChild(favBtn);

    // Album Cover Badge & Overlay Button (when viewing an album)
    if (this.currentAlbum) {
      const isCover = this.currentAlbum.coverPhoto === photo.path;
      if (isCover) {
        card.classList.add('is-cover');
        const coverBadge = document.createElement('div');
        coverBadge.className = 'card-cover-badge';
        coverBadge.innerHTML = `★ <span>Cover</span>`;
        card.appendChild(coverBadge);
      }

      const setCoverBtn = document.createElement('button');
      setCoverBtn.className = 'card-overlay-cover-btn';
      setCoverBtn.title = isCover ? 'Current Album Cover' : 'Set as Album Cover';
      setCoverBtn.innerHTML = Icons.albums;
      setCoverBtn.onclick = async (e) => {
        e.stopPropagation();
        if (window.albumsManager && this.currentAlbum) {
          await window.albumsManager.setAlbumCover(this.currentAlbum.id, photo.path);
          this.currentAlbum.coverPhoto = photo.path;
          this.renderPhotos();
        }
      };
      card.appendChild(setCoverBtn);
    }

    // Video badge if video
    if (photo.isVideo) {
      const badge = document.createElement('div');
      badge.className = 'card-video-badge';
      badge.innerHTML = `${Icons.slideshow} <span>Video</span>`;
      card.appendChild(badge);
    }

    // Card click
    card.onclick = (e) => {
      if (this.isSelectMode) {
        this.toggleSelection(photo.path, card);
      } else {
        window.photoViewer.open(this.filteredPhotos, index);
      }
    };

    return card;
  }

  toggleSelection(filePath, cardElement) {
    if (this.selectedPaths.has(filePath)) {
      this.selectedPaths.delete(filePath);
      cardElement?.classList.remove('selected');
    } else {
      this.selectedPaths.add(filePath);
      cardElement?.classList.add('selected');
    }

    if (this.selectedPaths.size > 0 && !this.isSelectMode) {
      this.enterSelectMode();
    }
    this.updateSelectionBar();
  }

  enterSelectMode() {
    this.isSelectMode = true;
    const selectBtn = document.getElementById('btn-select');
    if (selectBtn) selectBtn.classList.add('active');

    document.querySelectorAll('.photo-grid').forEach(g => g.classList.add('select-mode'));
    this.updateSelectionBar();
  }

  exitSelectMode() {
    this.isSelectMode = false;
    this.selectedPaths.clear();
    const selectBtn = document.getElementById('btn-select');
    if (selectBtn) selectBtn.classList.remove('active');

    document.querySelectorAll('.photo-grid').forEach(g => g.classList.remove('select-mode'));
    document.querySelectorAll('.photo-card.selected').forEach(c => c.classList.remove('selected'));

    const bar = document.getElementById('selection-bar');
    if (bar) bar.classList.remove('show');
  }

  initSelectionBar() {
    const bar = document.getElementById('selection-bar');
    if (!bar) return;

    bar.innerHTML = `
      <span class="selection-count" id="selection-count-text">0 selected</span>
      <div class="selection-actions">
        <button class="btn" id="btn-sel-all">Select All</button>
        <button class="btn" id="btn-sel-fav">Favourite</button>
        <button class="btn btn-danger" id="btn-sel-delete">Delete</button>
        <button class="btn" id="btn-sel-cancel">Cancel</button>
      </div>
    `;

    document.getElementById('btn-sel-all').onclick = () => {
      this.filteredPhotos.forEach(p => this.selectedPaths.add(p.path));
      document.querySelectorAll('.photo-card').forEach(c => c.classList.add('selected'));
      this.updateSelectionBar();
    };

    document.getElementById('btn-sel-fav').onclick = async () => {
      for (const p of this.selectedPaths) {
        if (!window.appStore.isFavorite(p)) {
          await window.appStore.toggleFavorite(p);
        }
      }
      this.renderPhotos();
      this.exitSelectMode();
    };

    document.getElementById('btn-sel-delete').onclick = async () => {
      if (confirm(`Delete ${this.selectedPaths.size} photo(s)?`)) {
        for (const p of this.selectedPaths) {
          await window.api.trashFile(p);
        }
        await this.loadFolder(this.currentFolder, this.currentTitle);
      }
    };

    document.getElementById('btn-sel-cancel').onclick = () => {
      this.exitSelectMode();
    };
  }

  updateSelectionBar() {
    const bar = document.getElementById('selection-bar');
    const countEl = document.getElementById('selection-count-text');
    if (!bar || !countEl) return;

    const count = this.selectedPaths.size;
    countEl.textContent = `${count} selected`;
    bar.classList.toggle('show', this.isSelectMode);
  }
}

window.galleryView = new GalleryView();
