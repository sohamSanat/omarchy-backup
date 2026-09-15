class AlbumsManager {
  constructor() {
    this.view = document.getElementById('albums-view');
    this.grid = document.getElementById('albums-grid');
    this.emptyState = document.getElementById('albums-empty');
    this.modal = document.getElementById('album-modal');
    this.breadcrumbBar = document.getElementById('album-breadcrumb-bar');
    this.backBtn = document.getElementById('album-back-btn');

    this.allAlbums = [];
    this.allFolders = [];
    this.editingAlbumId = null;
    this.selectedFolderPaths = new Set();
    this.selectedCoverPhoto = null;
    this.searchQuery = '';

    // Grouping & Multi-Selection state
    this.groupBy = window.appStore.get('albumGroupBy') || 'group';
    this.collapsedGroups = new Set();
    this.isSelectMode = false;
    this.selectedAlbumIds = new Set();
    this.activeMoveAlbumId = null;

    this.init();
  }

  async init() {
    this.setupListeners();
    this.setupModal();
    this.setupGroupFlyoutsAndModals();

    window.appStore.subscribe((key, val) => {
      if (key === 'albums' || key === 'albumGroups' || key === 'albumGroupBy' || key === 'init') {
        if (key === 'albumGroupBy') this.groupBy = val;
        this.renderAlbums(this.searchQuery);
      }
    });

    // Initial render
    this.renderAlbums();
  }

  setupListeners() {
    // New Album button in header
    const newBtn = document.getElementById('btn-new-album');
    if (newBtn) {
      newBtn.onclick = () => this.openAlbumModal();
    }

    // Albums search input
    const searchInput = document.getElementById('search-albums-input');
    if (searchInput) {
      searchInput.oninput = Utils.debounce(() => {
        this.searchQuery = searchInput.value.trim().toLowerCase();
        this.renderAlbums(this.searchQuery);
      }, 100);
    }

    // Titlebar search input sync when on albums view
    const titlebarSearch = document.getElementById('search-input');
    if (titlebarSearch) {
      titlebarSearch.addEventListener('input', Utils.debounce(() => {
        if (this.view && !this.view.classList.contains('hidden') && this.view.style.display !== 'none') {
          this.searchQuery = titlebarSearch.value.trim().toLowerCase();
          if (searchInput) searchInput.value = titlebarSearch.value;
          this.renderAlbums(this.searchQuery);
        }
      }, 100));
    }

    // Breadcrumb Back button in Gallery header
    if (this.backBtn) {
      this.backBtn.onclick = () => {
        this.showHome();
      };
    }
  }

  setupGroupFlyoutsAndModals() {
    // 1. Group By Button & Flyout
    const groupByBtn = document.getElementById('btn-album-group-by');
    const groupByFlyout = document.getElementById('flyout-album-group');
    const groupByLabel = document.getElementById('album-group-by-label');

    const updateGroupByUI = () => {
      if (!groupByLabel) return;
      if (this.groupBy === 'group') groupByLabel.textContent = 'Group: Custom';
      else if (this.groupBy === 'date') groupByLabel.textContent = 'Group: Date';
      else if (this.groupBy === 'folders') groupByLabel.textContent = 'Group: Folders';
      else groupByLabel.textContent = 'Group: None';

      if (groupByFlyout) {
        groupByFlyout.querySelectorAll('.flyout-item').forEach(item => {
          if (item.dataset.action === this.groupBy) {
            item.classList.add('active');
          } else {
            item.classList.remove('active');
          }
        });
      }
    };
    updateGroupByUI();

    if (groupByBtn && groupByFlyout) {
      groupByBtn.onclick = (e) => {
        e.stopPropagation();
        this.closeAllFlyouts();
        const rect = groupByBtn.getBoundingClientRect();
        groupByFlyout.style.top = `${rect.bottom + 6}px`;
        groupByFlyout.style.left = `${rect.left}px`;
        groupByFlyout.classList.toggle('show');
      };

      groupByFlyout.querySelectorAll('.flyout-item').forEach(item => {
        item.onclick = async (e) => {
          e.stopPropagation();
          groupByFlyout.classList.remove('show');
          const action = item.dataset.action;
          if (action) {
            this.groupBy = action;
            await window.appStore.set('albumGroupBy', action);
            updateGroupByUI();
            this.renderAlbums(this.searchQuery);
          }
        };
      });
    }

    // 2. New Group Button
    const newGroupBtn = document.getElementById('btn-new-group');
    if (newGroupBtn) {
      newGroupBtn.onclick = () => {
        this.openGroupModal();
      };
    }

    // 3. Multi-Select Toggle Button
    const selectBtn = document.getElementById('btn-album-select');
    if (selectBtn) {
      selectBtn.onclick = () => {
        this.toggleSelectMode();
      };
    }

    // 4. Selection Bar Actions
    const selMoveBtn = document.getElementById('album-sel-btn-group');
    if (selMoveBtn) {
      selMoveBtn.onclick = (e) => {
        e.stopPropagation();
        this.openMoveToGroupFlyout(null, selMoveBtn);
      };
    }

    const selDeleteBtn = document.getElementById('album-sel-btn-delete');
    if (selDeleteBtn) {
      selDeleteBtn.onclick = () => {
        this.deleteSelectedAlbums();
      };
    }

    const selCloseBtn = document.getElementById('album-sel-btn-close');
    if (selCloseBtn) {
      selCloseBtn.onclick = () => {
        this.exitSelectMode();
      };
    }

    // Close flyouts on outside click
    window.addEventListener('click', (e) => {
      const moveFlyout = document.getElementById('flyout-move-group');
      if (moveFlyout && !moveFlyout.contains(e.target)) {
        moveFlyout.classList.remove('show');
      }
      if (groupByFlyout && !groupByFlyout.contains(e.target) && e.target !== groupByBtn) {
        groupByFlyout.classList.remove('show');
      }
    });
  }

  closeAllFlyouts() {
    document.querySelectorAll('.flyout-menu').forEach(f => f.classList.remove('show'));
  }

  toggleSelectMode() {
    this.isSelectMode = !this.isSelectMode;
    const btn = document.getElementById('btn-album-select');
    const bar = document.getElementById('album-selection-bar');

    if (this.isSelectMode) {
      if (btn) btn.classList.add('active');
      if (this.view) this.view.classList.add('is-select-mode');
      if (bar) bar.classList.add('show');
      this.updateSelectionBar();
    } else {
      this.exitSelectMode();
    }
  }

  exitSelectMode() {
    this.isSelectMode = false;
    this.selectedAlbumIds.clear();
    const btn = document.getElementById('btn-album-select');
    const bar = document.getElementById('album-selection-bar');
    if (btn) btn.classList.remove('active');
    if (this.view) this.view.classList.remove('is-select-mode');
    if (bar) bar.classList.remove('show');
    document.querySelectorAll('.album-card.selected').forEach(c => c.classList.remove('selected'));
  }

  toggleAlbumSelection(albumId, cardEl) {
    if (this.selectedAlbumIds.has(albumId)) {
      this.selectedAlbumIds.delete(albumId);
      if (cardEl) cardEl.classList.remove('selected');
    } else {
      this.selectedAlbumIds.add(albumId);
      if (cardEl) cardEl.classList.add('selected');
    }
    this.updateSelectionBar();
  }

  updateSelectionBar() {
    const countEl = document.getElementById('album-selection-count');
    const count = this.selectedAlbumIds.size;
    if (countEl) {
      countEl.textContent = `${count} album${count === 1 ? '' : 's'} selected`;
    }
  }

  async deleteSelectedAlbums() {
    const count = this.selectedAlbumIds.size;
    if (count === 0) return;
    if (confirm(`Are you sure you want to delete ${count} selected album${count === 1 ? '' : 's'}?\n(Your actual image files and folders will not be deleted)`)) {
      for (const id of this.selectedAlbumIds) {
        await window.appStore.deleteAlbum(id);
      }
      this.exitSelectMode();
      this.renderAlbums(this.searchQuery);
      Utils.showToast(`Deleted ${count} album${count === 1 ? '' : 's'}`);
    }
  }

  openGroupModal(editingGroup = null, onSavedCallback = null) {
    const modal = document.getElementById('group-modal');
    const title = document.getElementById('group-modal-title');
    const input = document.getElementById('group-modal-name-input');
    const saveBtn = document.getElementById('group-modal-save-btn');
    const cancelBtn = document.getElementById('group-modal-cancel-btn');
    if (!modal || !input) return;

    if (editingGroup) {
      if (title) title.textContent = 'Rename Album Group';
      input.value = editingGroup;
      if (saveBtn) saveBtn.textContent = 'Rename';
    } else {
      if (title) title.textContent = 'New Album Group';
      input.value = '';
      if (saveBtn) saveBtn.textContent = 'Create Group';
    }

    const closeModal = () => {
      modal.classList.remove('show');
    };

    if (cancelBtn) cancelBtn.onclick = closeModal;
    modal.onclick = (e) => {
      if (e.target === modal) closeModal();
    };

    if (saveBtn) {
      saveBtn.onclick = async () => {
        const val = input.value.trim();
        if (!val) {
          input.focus();
          return;
        }
        closeModal();
        if (editingGroup) {
          await window.appStore.renameAlbumGroup(editingGroup, val);
          Utils.showToast(`Renamed group to "${val}"`);
        } else {
          await window.appStore.addAlbumGroup(val);
          Utils.showToast(`Created group "${val}"`);
        }
        if (onSavedCallback) {
          await onSavedCallback(val);
        }
        this.renderAlbums(this.searchQuery);
      };
    }

    modal.classList.add('show');
    setTimeout(() => input.focus(), 50);
  }

  openMoveToGroupFlyout(targetAlbumId, triggerBtn) {
    const flyout = document.getElementById('flyout-move-group');
    const itemsContainer = document.getElementById('flyout-move-group-items');
    if (!flyout || !itemsContainer || !triggerBtn) return;

    this.activeMoveAlbumId = targetAlbumId;
    const groups = window.appStore.getAlbumGroups();

    itemsContainer.innerHTML = '';
    groups.forEach(g => {
      const item = document.createElement('div');
      item.className = 'flyout-item';
      item.innerHTML = `<span style="display:flex; align-items:center; gap:8px;">${Icons.folder} ${g}</span>`;
      item.onclick = async (e) => {
        e.stopPropagation();
        flyout.classList.remove('show');
        if (this.activeMoveAlbumId) {
          await window.appStore.setAlbumGroup(this.activeMoveAlbumId, g);
          Utils.showToast(`Moved album to group "${g}"`);
        } else if (this.selectedAlbumIds.size > 0) {
          await window.appStore.setAlbumsGroup(Array.from(this.selectedAlbumIds), g);
          Utils.showToast(`Moved ${this.selectedAlbumIds.size} albums to group "${g}"`);
          this.exitSelectMode();
        }
        this.renderAlbums(this.searchQuery);
      };
      itemsContainer.appendChild(item);
    });

    const newGroupItem = flyout.querySelector('[data-action="__new_group__"]');
    if (newGroupItem) {
      newGroupItem.onclick = (e) => {
        e.stopPropagation();
        flyout.classList.remove('show');
        this.openGroupModal(null, async (newGroupName) => {
          if (this.activeMoveAlbumId) {
            await window.appStore.setAlbumGroup(this.activeMoveAlbumId, newGroupName);
            Utils.showToast(`Moved album to group "${newGroupName}"`);
          } else if (this.selectedAlbumIds.size > 0) {
            await window.appStore.setAlbumsGroup(Array.from(this.selectedAlbumIds), newGroupName);
            Utils.showToast(`Moved ${this.selectedAlbumIds.size} albums to group "${newGroupName}"`);
            this.exitSelectMode();
          }
          this.renderAlbums(this.searchQuery);
        });
      };
    }

    const ungroupItem = flyout.querySelector('[data-action="__ungroup__"]');
    if (ungroupItem) {
      ungroupItem.onclick = async (e) => {
        e.stopPropagation();
        flyout.classList.remove('show');
        if (this.activeMoveAlbumId) {
          await window.appStore.setAlbumGroup(this.activeMoveAlbumId, '');
          Utils.showToast('Removed album from group');
        } else if (this.selectedAlbumIds.size > 0) {
          await window.appStore.setAlbumsGroup(Array.from(this.selectedAlbumIds), '');
          Utils.showToast(`Removed ${this.selectedAlbumIds.size} albums from group`);
          this.exitSelectMode();
        }
        this.renderAlbums(this.searchQuery);
      };
    }

    // Position flyout
    const rect = triggerBtn.getBoundingClientRect();
    flyout.style.top = `${Math.min(rect.bottom + 6, window.innerHeight - 260)}px`;
    flyout.style.left = `${Math.min(rect.left, window.innerWidth - 220)}px`;
    flyout.classList.add('show');
  }

  setupModal() {
    if (!this.modal) return;

    const closeBtn = document.getElementById('album-modal-close-btn');
    const cancelBtn = document.getElementById('album-modal-cancel-btn');
    const saveBtn = document.getElementById('album-modal-save-btn');
    const filterInput = document.getElementById('album-folder-filter');
    const selectAllBtn = document.getElementById('album-folders-select-all');
    const clearAllBtn = document.getElementById('album-folders-clear-all');

    if (closeBtn) closeBtn.onclick = () => this.closeModal();
    if (cancelBtn) cancelBtn.onclick = () => this.closeModal();

    this.modal.onclick = (e) => {
      if (e.target === this.modal) this.closeModal();
    };

    if (filterInput) {
      filterInput.oninput = () => {
        this.renderFolderChecklist(filterInput.value.trim().toLowerCase());
      };
    }

    if (selectAllBtn) {
      selectAllBtn.onclick = () => {
        const query = (filterInput ? filterInput.value.trim().toLowerCase() : '');
        this.allFolders.forEach(f => {
          if (!query || f.relPath.toLowerCase().includes(query)) {
            this.selectedFolderPaths.add(f.path);
          }
        });
        this.renderFolderChecklist(query);
        this.updateModalStats();
      };
    }

    if (clearAllBtn) {
      clearAllBtn.onclick = () => {
        this.selectedFolderPaths.clear();
        const query = (filterInput ? filterInput.value.trim().toLowerCase() : '');
        this.renderFolderChecklist(query);
        this.updateModalStats();
      };
    }

    if (saveBtn) {
      saveBtn.onclick = () => this.saveAlbumFromModal();
    }

    // Cover Photo Picker Handlers
    const browseCoversBtn = document.getElementById('btn-browse-album-covers');
    const browseFileBtn = document.getElementById('btn-browse-file-cover');
    const modalBrowseFileBtn = document.getElementById('btn-modal-browse-file');
    const previewWrap = document.getElementById('album-cover-preview-wrap');
    const resetCoverBtn = document.getElementById('btn-reset-album-cover');
    const pickerCloseBtn = document.getElementById('cover-picker-close-btn');
    const pickerCancelBtn = document.getElementById('cover-picker-cancel-btn');
    const pickerSearch = document.getElementById('cover-picker-search');
    const closeDrawerBtn = document.getElementById('cover-drawer-close');
    const drawer = document.getElementById('cover-photos-drawer');
    const coverModal = document.getElementById('cover-picker-modal');

    if (browseCoversBtn) {
      browseCoversBtn.onclick = () => {
        this.openCoverPickerModal();
      };
    }

    if (previewWrap) {
      previewWrap.onclick = () => {
        this.openCoverPickerModal();
      };
    }

    if (browseFileBtn) {
      browseFileBtn.onclick = () => {
        this.browseCustomCoverFile();
      };
    }

    if (modalBrowseFileBtn) {
      modalBrowseFileBtn.onclick = () => {
        this.browseCustomCoverFile();
      };
    }

    if (pickerCloseBtn) {
      pickerCloseBtn.onclick = () => this.closeCoverPickerModal();
    }

    if (pickerCancelBtn) {
      pickerCancelBtn.onclick = () => this.closeCoverPickerModal();
    }

    if (coverModal) {
      coverModal.onclick = (e) => {
        if (e.target === coverModal) this.closeCoverPickerModal();
      };
    }

    if (pickerSearch) {
      pickerSearch.oninput = () => {
        this.filterCoverPickerPhotos(pickerSearch.value.trim().toLowerCase());
      };
    }

    if (closeDrawerBtn) {
      closeDrawerBtn.onclick = () => {
        if (drawer) drawer.style.display = 'none';
      };
    }

    if (resetCoverBtn) {
      resetCoverBtn.onclick = () => {
        this.selectedCoverPhoto = null;
        this.updateCoverPreview();
        if (drawer && drawer.style.display !== 'none') {
          this.renderCoverPhotosGrid();
        }
        Utils.showToast('Cover reset to default first photo');
      };
    }
  }

  updateCoverPreview() {
    const previewImg = document.getElementById('album-cover-preview-img');
    const previewEmpty = document.getElementById('album-cover-preview-empty');
    const infoText = document.getElementById('album-cover-info-text');
    const resetBtn = document.getElementById('btn-reset-album-cover');

    let currentCover = this.selectedCoverPhoto;

    // If no custom cover set, find first photo from selected folders
    if (!currentCover) {
      for (const f of this.allFolders) {
        if (this.selectedFolderPaths.has(f.path) && f.firstPhoto) {
          currentCover = f.firstPhoto;
          break;
        }
      }
    }

    if (currentCover) {
      if (previewImg) {
        previewImg.src = `photo://${currentCover}`;
        previewImg.style.display = 'block';
      }
      if (previewEmpty) previewEmpty.style.display = 'none';

      if (infoText) {
        const fname = currentCover.split('/').pop();
        if (this.selectedCoverPhoto) {
          infoText.innerHTML = `Custom cover: <strong>${fname}</strong>`;
        } else {
          infoText.textContent = `Default (First photo in album): ${fname}`;
        }
      }
      if (resetBtn) resetBtn.style.display = this.selectedCoverPhoto ? 'inline-flex' : 'none';
    } else {
      if (previewImg) previewImg.style.display = 'none';
      if (previewEmpty) previewEmpty.style.display = 'flex';
      if (infoText) infoText.textContent = 'No photos in selected folders';
      if (resetBtn) resetBtn.style.display = 'none';
    }
  }

  async renderCoverPhotosGrid() {
    const grid = document.getElementById('cover-photos-grid');
    if (!grid) return;
    grid.innerHTML = '<div style="padding:14px; font-size:12px; color:var(--text-muted);">Loading photos from selected folders...</div>';

    const folders = Array.from(this.selectedFolderPaths);
    if (folders.length === 0) {
      grid.innerHTML = '<div style="padding:14px; font-size:12px; color:var(--text-muted);">Select at least one folder above first to pick a cover image.</div>';
      return;
    }

    const res = await window.api.getAlbumPhotos(folders);
    const photos = res.photos || [];

    if (photos.length === 0) {
      grid.innerHTML = '<div style="padding:14px; font-size:12px; color:var(--text-muted);">No images found in the selected folders.</div>';
      return;
    }

    grid.innerHTML = '';
    photos.forEach((p, idx) => {
      const item = document.createElement('div');
      item.className = 'cover-photo-thumb-item';
      
      const isCurrent = (this.selectedCoverPhoto === p.path) || (!this.selectedCoverPhoto && idx === 0);
      if (isCurrent) item.classList.add('selected');

      item.innerHTML = `
        <img class="cover-photo-thumb-img" loading="lazy" src="photo://${p.path}" alt="${p.name}" title="${p.name}" />
        ${isCurrent ? `<div class="cover-photo-thumb-badge">${Icons.check}</div>` : ''}
      `;

      item.onclick = () => {
        this.selectedCoverPhoto = p.path;
        this.updateCoverPreview();

        grid.querySelectorAll('.cover-photo-thumb-item').forEach(el => {
          el.classList.remove('selected');
          const b = el.querySelector('.cover-photo-thumb-badge');
          if (b) b.remove();
        });
        item.classList.add('selected');
        const badge = document.createElement('div');
        badge.className = 'cover-photo-thumb-badge';
        badge.innerHTML = Icons.check;
        item.appendChild(badge);

        Utils.showToast(`Selected "${p.name}" as album cover!`);
      };

      grid.appendChild(item);
    });
  }

  async browseCustomCoverFile() {
    try {
      if (!window.api || !window.api.chooseImageFile) {
        Utils.showToast('File picker not supported');
        return;
      }
      const res = await window.api.chooseImageFile();
      if (res) {
        const filePath = typeof res === 'string' ? res : res.filePath;
        const fileName = (typeof res === 'object' && res.fileName) ? res.fileName : (filePath ? filePath.split('/').pop() : 'image');
        if (filePath) {
          this.selectedCoverPhoto = filePath;
          this.updateCoverPreview();
          this.closeCoverPickerModal();
          Utils.showToast(`Selected "${fileName}" as album cover!`);
        }
      }
    } catch (err) {
      console.error('Failed to choose image file:', err);
      Utils.showToast('Failed to select file');
    }
  }

  async openCoverPickerModal() {
    const modal = document.getElementById('cover-picker-modal');
    if (!modal) return;

    const folders = Array.from(this.selectedFolderPaths);
    if (folders.length === 0) {
      Utils.showToast('Please select at least one folder above first to pick a cover image');
      return;
    }

    const searchInput = document.getElementById('cover-picker-search');
    if (searchInput) searchInput.value = '';

    const countBadge = document.getElementById('cover-picker-count-badge');
    if (countBadge) countBadge.textContent = 'Loading photos...';

    const grid = document.getElementById('modal-cover-photos-grid');
    if (grid) {
      grid.innerHTML = '<div style="grid-column: 1 / -1; padding: 28px; text-align: center; color: var(--text-muted); font-size: 13px;">Loading photos from selected folders...</div>';
    }

    modal.classList.add('show');

    try {
      const res = await window.api.getAlbumPhotos(folders);
      this.coverPickerPhotos = (res && res.photos) ? res.photos : [];

      if (countBadge) {
        countBadge.textContent = `${this.coverPickerPhotos.length} photo${this.coverPickerPhotos.length === 1 ? '' : 's'}`;
      }

      this.renderModalCoverGrid(this.coverPickerPhotos);
      if (searchInput) setTimeout(() => searchInput.focus(), 60);
    } catch (err) {
      console.error('Failed to load photos for cover picker:', err);
      if (grid) {
        grid.innerHTML = '<div style="grid-column: 1 / -1; padding: 28px; text-align: center; color: var(--danger); font-size: 13px;">Failed to load photos from folders.</div>';
      }
    }
  }

  closeCoverPickerModal() {
    const modal = document.getElementById('cover-picker-modal');
    if (modal) modal.classList.remove('show');
  }

  filterCoverPickerPhotos(query = '') {
    if (!this.coverPickerPhotos) return;
    const filtered = query
      ? this.coverPickerPhotos.filter(p => p.name.toLowerCase().includes(query))
      : this.coverPickerPhotos;

    const countBadge = document.getElementById('cover-picker-count-badge');
    if (countBadge) {
      if (query) {
        countBadge.textContent = `${filtered.length} of ${this.coverPickerPhotos.length} photos`;
      } else {
        countBadge.textContent = `${this.coverPickerPhotos.length} photo${this.coverPickerPhotos.length === 1 ? '' : 's'}`;
      }
    }
    this.renderModalCoverGrid(filtered);
  }

  renderModalCoverGrid(photos) {
    const grid = document.getElementById('modal-cover-photos-grid');
    if (!grid) return;

    if (!photos || photos.length === 0) {
      grid.innerHTML = '<div style="grid-column: 1 / -1; padding: 36px; text-align: center; color: var(--text-muted); font-size: 13px;">No matching photos found.</div>';
      return;
    }

    grid.innerHTML = '';
    photos.forEach((p, idx) => {
      const item = document.createElement('div');
      item.className = 'cover-photo-thumb-item';

      const isSelected = (this.selectedCoverPhoto === p.path) || (!this.selectedCoverPhoto && idx === 0);
      if (isSelected) item.classList.add('selected');

      item.title = p.name;
      item.innerHTML = `
        <img class="cover-photo-thumb-img" loading="lazy" src="photo://${p.path}" alt="${p.name}" />
        <div class="cover-photo-thumb-name">${p.name}</div>
        ${isSelected ? `<div class="cover-photo-thumb-badge">${Icons.check}</div>` : ''}
      `;

      item.onclick = () => {
        this.selectedCoverPhoto = p.path;
        this.updateCoverPreview();
        this.closeCoverPickerModal();
        Utils.showToast(`Selected "${p.name}" as album cover!`);
      };

      grid.appendChild(item);
    });
  }

  async setAlbumCover(albumId, photoPath) {
    const album = window.appStore.getAlbum(albumId);
    if (!album) return;
    album.coverPhoto = photoPath;
    await window.appStore.saveAlbum(album);
    Utils.showToast(`Album cover updated for "${album.name}"`);
    this.renderAlbums(this.searchQuery);
  }

  showHome() {
    this.closeModal();
    const galleryContainer = document.getElementById('gallery-container');
    if (galleryContainer) galleryContainer.style.display = 'none';
    if (this.view) {
      this.view.classList.remove('hidden');
      this.view.style.display = 'flex';
    }

    if (this.breadcrumbBar) {
      this.breadcrumbBar.classList.remove('show');
    }

    const titlebarSearch = document.getElementById('search-input');
    if (titlebarSearch) {
      titlebarSearch.placeholder = 'Search albums or photos...';
    }

    document.querySelectorAll('.sidebar .nav-item').forEach(item => {
      item.classList.remove('active');
    });
    const homeNav = document.getElementById('nav-home');
    if (homeNav) homeNav.classList.add('active');

    document.title = 'Albums - P-gallery';
    this.renderAlbums(this.searchQuery);
  }

  hideHome() {
    if (this.view) {
      this.view.classList.add('hidden');
      this.view.style.display = 'none';
    }
    const galleryContainer = document.getElementById('gallery-container');
    if (galleryContainer) galleryContainer.style.display = 'flex';
  }

  renderAlbums(filterQuery = '') {
    if (!this.grid) return;
    this.allAlbums = window.appStore.getAlbums();

    let albumsToDisplay = [...this.allAlbums];
    if (filterQuery) {
      albumsToDisplay = albumsToDisplay.filter(a => a.name.toLowerCase().includes(filterQuery));
    }

    this.grid.innerHTML = '';

    // Update count in header
    const subtitleEl = document.getElementById('albums-subtitle');
    if (subtitleEl) {
      subtitleEl.textContent = `${this.allAlbums.length} album${this.allAlbums.length === 1 ? '' : 's'} in your collection`;
    }

    const homeBadge = document.getElementById('albums-badge-count');
    if (homeBadge) {
      homeBadge.textContent = this.allAlbums.length;
      homeBadge.style.display = this.allAlbums.length > 0 ? 'inline-block' : 'none';
    }

    if (albumsToDisplay.length === 0 && this.allAlbums.length === 0) {
      if (this.emptyState) this.emptyState.classList.add('show');
    } else {
      if (this.emptyState) this.emptyState.classList.remove('show');
    }

    // Render depending on groupBy mode
    if (this.groupBy === 'none') {
      this.grid.classList.remove('grouped');
      albumsToDisplay.forEach(album => {
        const card = this.createAlbumCard(album);
        this.grid.appendChild(card);
      });

      const createCard = document.createElement('div');
      createCard.className = 'album-card-create';
      createCard.innerHTML = `
        <div class="album-card-create-icon">${Icons.plus}</div>
        <div class="album-card-create-text">Create New Album</div>
      `;
      createCard.onclick = () => this.openAlbumModal();
      this.grid.appendChild(createCard);
    } else {
      this.grid.classList.add('grouped');
      const groupsMap = this.groupAlbums(albumsToDisplay, this.groupBy);

      groupsMap.forEach((albumsInGroup, groupName) => {
        // Skip empty group if we are actively searching
        if (filterQuery && albumsInGroup.length === 0) return;

        const section = this.createGroupSection(groupName, albumsInGroup);
        this.grid.appendChild(section);
      });
    }
  }

  groupAlbums(albums, mode) {
    const map = new Map();

    if (mode === 'group') {
      const knownGroups = window.appStore.getAlbumGroups();
      knownGroups.forEach(g => map.set(g, []));
      map.set('Ungrouped', []);

      albums.forEach(album => {
        const g = album.group && album.group.trim() ? album.group.trim() : 'Ungrouped';
        if (!map.has(g)) map.set(g, []);
        map.get(g).push(album);
      });

      // Remove empty custom groups only if none were ever added, but keep groups user defined
      // If "Ungrouped" is empty, remove it
      if (map.get('Ungrouped') && map.get('Ungrouped').length === 0) {
        map.delete('Ungrouped');
      }
    } else if (mode === 'date') {
      map.set('This Month', []);
      map.set('Last Month', []);
      map.set('Earlier This Year', []);
      map.set('Older', []);

      const now = Date.now();
      const oneMonth = 30 * 24 * 60 * 60 * 1000;
      const twoMonths = 60 * 24 * 60 * 60 * 1000;
      const oneYear = 365 * 24 * 60 * 60 * 1000;

      albums.forEach(album => {
        const t = album.createdAt || album.updatedAt || now;
        const diff = now - t;
        if (diff < oneMonth) {
          map.get('This Month').push(album);
        } else if (diff < twoMonths) {
          map.get('Last Month').push(album);
        } else if (diff < oneYear) {
          map.get('Earlier This Year').push(album);
        } else {
          map.get('Older').push(album);
        }
      });

      // Remove empty date buckets
      for (const [key, val] of Array.from(map.entries())) {
        if (val.length === 0) map.delete(key);
      }
    } else if (mode === 'folders') {
      map.set('Single Folder', []);
      map.set('2 to 4 Folders', []);
      map.set('5+ Folders', []);

      albums.forEach(album => {
        const count = (album.folders || []).length;
        if (count <= 1) {
          map.get('Single Folder').push(album);
        } else if (count <= 4) {
          map.get('2 to 4 Folders').push(album);
        } else {
          map.get('5+ Folders').push(album);
        }
      });

      for (const [key, val] of Array.from(map.entries())) {
        if (val.length === 0) map.delete(key);
      }
    }

    return map;
  }

  createGroupSection(groupName, albumsInGroup) {
    const section = document.createElement('div');
    section.className = 'album-group-section';
    const isCollapsed = this.collapsedGroups.has(groupName);
    if (isCollapsed) section.classList.add('collapsed');

    // Header
    const header = document.createElement('div');
    header.className = 'album-group-header';

    const left = document.createElement('div');
    left.className = 'album-group-header-left';
    left.innerHTML = `
      <button type="button" class="album-group-toggle" title="Toggle collapse">
        ${Icons.chevronDown}
      </button>
      <span class="album-group-icon">${Icons.folderFilled}</span>
      <h2 class="album-group-title">${groupName}</h2>
      <span class="album-group-badge">${albumsInGroup.length} album${albumsInGroup.length === 1 ? '' : 's'}</span>
    `;

    left.onclick = () => {
      if (this.collapsedGroups.has(groupName)) {
        this.collapsedGroups.delete(groupName);
        section.classList.remove('collapsed');
      } else {
        this.collapsedGroups.add(groupName);
        section.classList.add('collapsed');
      }
    };

    header.appendChild(left);

    // Right Actions
    const actions = document.createElement('div');
    actions.className = 'album-group-actions';

    // "+ Add Album" button for this group
    const addBtn = document.createElement('button');
    addBtn.className = 'album-group-action-btn';
    addBtn.innerHTML = `${Icons.plus} <span>Add Album</span>`;
    addBtn.title = `Create album in group "${groupName}"`;
    addBtn.onclick = (e) => {
      e.stopPropagation();
      this.openAlbumModal(null, groupName === 'Ungrouped' ? '' : groupName);
    };
    actions.appendChild(addBtn);

    // If Custom Group mode and not "Ungrouped", allow Rename and Delete Group
    if (this.groupBy === 'group' && groupName !== 'Ungrouped') {
      const renameBtn = document.createElement('button');
      renameBtn.className = 'album-group-action-btn';
      renameBtn.innerHTML = Icons.edit;
      renameBtn.title = `Rename group "${groupName}"`;
      renameBtn.onclick = (e) => {
        e.stopPropagation();
        this.openGroupModal(groupName);
      };
      actions.appendChild(renameBtn);

      const deleteBtn = document.createElement('button');
      deleteBtn.className = 'album-group-action-btn btn-delete';
      deleteBtn.innerHTML = Icons.trash;
      deleteBtn.title = `Delete group "${groupName}"`;
      deleteBtn.onclick = async (e) => {
        e.stopPropagation();
        if (confirm(`Delete the group "${groupName}"?\n(Albums in this group will not be deleted, they will become ungrouped)`)) {
          await window.appStore.deleteAlbumGroup(groupName);
          Utils.showToast(`Deleted group "${groupName}"`);
          this.renderAlbums(this.searchQuery);
        }
      };
      actions.appendChild(deleteBtn);
    }

    header.appendChild(actions);
    section.appendChild(header);

    // Grid of cards
    const grid = document.createElement('div');
    grid.className = 'album-group-grid';

    albumsInGroup.forEach(album => {
      const card = this.createAlbumCard(album);
      grid.appendChild(card);
    });

    // "+ Add to [GroupName]" quick card at the end of each group
    const createCard = document.createElement('div');
    createCard.className = 'album-card-create';
    createCard.innerHTML = `
      <div class="album-card-create-icon">${Icons.plus}</div>
      <div class="album-card-create-text">Add to ${groupName}</div>
    `;
    createCard.onclick = () => this.openAlbumModal(null, groupName === 'Ungrouped' ? '' : groupName);
    grid.appendChild(createCard);

    section.appendChild(grid);
    return section;
  }

  createAlbumCard(album) {
    const card = document.createElement('div');
    card.className = 'album-card';
    card.dataset.id = album.id;
    if (this.isSelectMode) card.classList.add('is-select-mode');
    if (this.selectedAlbumIds.has(album.id)) card.classList.add('selected');

    // Multi-Select Checkbox
    const cb = document.createElement('div');
    cb.className = 'album-card-checkbox';
    cb.innerHTML = Icons.check;
    cb.onclick = (e) => {
      e.stopPropagation();
      this.toggleAlbumSelection(album.id, card);
    };
    card.appendChild(cb);

    // Cover Wrap
    const coverWrap = document.createElement('div');
    coverWrap.className = 'album-cover-wrap';

    if (album.coverPhoto) {
      const img = document.createElement('img');
      img.className = 'album-cover-img';
      img.loading = 'lazy';
      img.alt = album.name;
      img.src = `photo://${album.coverPhoto}`;
      coverWrap.appendChild(img);
    } else {
      const placeholder = document.createElement('div');
      placeholder.className = 'album-cover-placeholder';
      placeholder.innerHTML = `
        <div style="transform:scale(1.5); color:var(--text-muted);">${Icons.albums}</div>
        <span style="font-size:12px; margin-top:8px;">No Photos</span>
      `;
      coverWrap.appendChild(placeholder);
    }

    // Photo count badge
    const badge = document.createElement('div');
    badge.className = 'album-photo-badge';
    badge.innerHTML = `${Icons.gallery} <span>${album.photoCount || 0}</span>`;
    coverWrap.appendChild(badge);

    // Hover Action Buttons: Play, Move to Group, Edit, Delete
    const overlayActions = document.createElement('div');
    overlayActions.className = 'album-overlay-actions';

    // Play Slideshow button
    const playBtn = document.createElement('button');
    playBtn.className = 'album-action-icon-btn';
    playBtn.title = 'Play Slideshow';
    playBtn.innerHTML = Icons.play;
    playBtn.onclick = async (e) => {
      e.stopPropagation();
      await this.playAlbumSlideshow(album);
    };
    overlayActions.appendChild(playBtn);

    // Move to Group button
    const moveBtn = document.createElement('button');
    moveBtn.className = 'album-action-icon-btn btn-move-group';
    moveBtn.title = 'Move to Group...';
    moveBtn.innerHTML = Icons.folderMove;
    moveBtn.onclick = (e) => {
      e.stopPropagation();
      this.openMoveToGroupFlyout(album.id, moveBtn);
    };
    overlayActions.appendChild(moveBtn);

    // Edit button
    const editBtn = document.createElement('button');
    editBtn.className = 'album-action-icon-btn';
    editBtn.title = 'Edit Album';
    editBtn.innerHTML = Icons.edit;
    editBtn.onclick = (e) => {
      e.stopPropagation();
      this.openAlbumModal(album.id);
    };
    overlayActions.appendChild(editBtn);

    // Delete button
    const delBtn = document.createElement('button');
    delBtn.className = 'album-action-icon-btn btn-delete';
    delBtn.title = 'Delete Album';
    delBtn.innerHTML = Icons.trash;
    delBtn.onclick = (e) => {
      e.stopPropagation();
      this.confirmDeleteAlbum(album);
    };
    overlayActions.appendChild(delBtn);

    coverWrap.appendChild(overlayActions);
    card.appendChild(coverWrap);

    // Info section
    const info = document.createElement('div');
    info.className = 'album-card-info';

    const title = document.createElement('h3');
    title.className = 'album-card-title';
    title.textContent = album.name;
    info.appendChild(title);

    const meta = document.createElement('div');
    meta.className = 'album-card-meta';
    const folderCount = (album.folders || []).length;
    const photoCount = album.photoCount || 0;
    meta.textContent = `${folderCount} folder${folderCount === 1 ? '' : 's'} • ${photoCount} photo${photoCount === 1 ? '' : 's'}`;
    info.appendChild(meta);

    // If album has a group and not currently grouped by custom group, show group tag
    if (album.group && album.group.trim()) {
      const tag = document.createElement('span');
      tag.className = 'album-card-group-tag';
      tag.innerHTML = `${Icons.tag} ${album.group.trim()}`;
      info.appendChild(tag);
    }

    card.appendChild(info);

    // Click on card: either select in multi-select mode, or open album
    card.onclick = () => {
      if (this.isSelectMode) {
        this.toggleAlbumSelection(album.id, card);
      } else {
        this.openAlbum(album.id);
      }
    };

    return card;
  }

  async openAlbum(albumId) {
    this.closeModal();
    const album = window.appStore.getAlbum(albumId);
    if (!album) return;

    this.hideHome();

    // Show breadcrumb in gallery
    if (this.breadcrumbBar) {
      this.breadcrumbBar.classList.add('show');
      const breadcrumbName = document.getElementById('album-breadcrumb-name');
      if (breadcrumbName) breadcrumbName.textContent = album.name;
    }

    // Render in Gallery
    if (window.galleryView) {
      await window.galleryView.loadAlbum(album);
    }
  }

  async playAlbumSlideshow(album) {
    if (!album || !album.folders || album.folders.length === 0) return;
    const res = await window.api.getAlbumPhotos(album.folders);
    if (res && res.photos && res.photos.length > 0) {
      window.photoViewer.open(res.photos, 0);
      window.photoViewer.startSlideshow();
    }
  }

  async openAlbumModal(albumId = null, prefillGroup = '') {
    this.editingAlbumId = albumId;
    this.selectedFolderPaths.clear();

    const titleEl = document.getElementById('album-modal-title');
    const nameInput = document.getElementById('album-name-input');
    const groupInput = document.getElementById('album-group-input');
    const groupDatalist = document.getElementById('album-groups-datalist');
    const groupChipsContainer = document.getElementById('album-group-quick-chips');
    const filterInput = document.getElementById('album-folder-filter');
    const saveBtn = document.getElementById('album-modal-save-btn');

    if (filterInput) filterInput.value = '';

    // Populate Datalist & Quick Chips for Groups
    const availableGroups = window.appStore.getAlbumGroups();
    if (groupDatalist) {
      groupDatalist.innerHTML = '';
      availableGroups.forEach(g => {
        const opt = document.createElement('option');
        opt.value = g;
        groupDatalist.appendChild(opt);
      });
    }

    if (groupChipsContainer) {
      groupChipsContainer.innerHTML = '';
      availableGroups.forEach(g => {
        const chip = document.createElement('div');
        chip.className = 'album-group-chip';
        chip.innerHTML = `${Icons.tag} <span>${g}</span>`;
        chip.onclick = () => {
          if (groupInput) {
            groupInput.value = g;
            groupChipsContainer.querySelectorAll('.album-group-chip').forEach(c => c.classList.remove('active'));
            chip.classList.add('active');
          }
        };
        groupChipsContainer.appendChild(chip);
      });
    }

    // Load available image folders from Pictures directory
    this.allFolders = await window.api.listImageFolders();

    if (albumId) {
      const album = window.appStore.getAlbum(albumId);
      if (album) {
        if (titleEl) titleEl.textContent = 'Edit Album';
        if (nameInput) nameInput.value = album.name;
        if (groupInput) groupInput.value = album.group || '';
        if (saveBtn) saveBtn.textContent = 'Save Changes';
        (album.folders || []).forEach(f => this.selectedFolderPaths.add(f));
        this.selectedCoverPhoto = album.coverPhoto || null;
      }
    } else {
      if (titleEl) titleEl.textContent = 'Create New Album';
      if (nameInput) nameInput.value = '';
      if (groupInput) groupInput.value = prefillGroup || '';
      if (saveBtn) saveBtn.textContent = 'Create Album';
      this.selectedCoverPhoto = null;
    }

    // Update active chip state
    if (groupChipsContainer && groupInput && groupInput.value) {
      groupChipsContainer.querySelectorAll('.album-group-chip').forEach(c => {
        if (c.textContent.trim() === groupInput.value.trim()) {
          c.classList.add('active');
        }
      });
    }

    const drawer = document.getElementById('cover-photos-drawer');
    if (drawer) drawer.style.display = 'none';

    this.renderFolderChecklist();
    this.updateModalStats();
    this.updateCoverPreview();

    if (this.modal) {
      this.modal.classList.add('show');
      if (nameInput) setTimeout(() => nameInput.focus(), 50);
    }
  }

  renderFolderChecklist(filter = '') {
    const listEl = document.getElementById('album-folder-checklist');
    if (!listEl) return;
    listEl.innerHTML = '';

    const filtered = this.allFolders.filter(f => {
      if (!filter) return true;
      return f.name.toLowerCase().includes(filter) || f.relPath.toLowerCase().includes(filter);
    });

    if (filtered.length === 0) {
      const emptyItem = document.createElement('div');
      emptyItem.style.cssText = 'padding:16px; text-align:center; color:var(--text-muted); font-size:12px;';
      emptyItem.textContent = 'No matching folders found in Pictures.';
      listEl.appendChild(emptyItem);
      return;
    }

    filtered.forEach(folder => {
      const row = document.createElement('div');
      row.className = 'folder-check-item';

      const isChecked = this.selectedFolderPaths.has(folder.path);

      row.innerHTML = `
        <div class="folder-check-left">
          <input type="checkbox" class="folder-check-cb" ${isChecked ? 'checked' : ''} />
          <span class="folder-check-icon">${Icons.folderFilled}</span>
          <span class="folder-check-name" title="${folder.relPath}">${folder.relPath}</span>
        </div>
        <span class="folder-check-count">${folder.count} photos</span>
      `;

      const cb = row.querySelector('.folder-check-cb');
      const toggle = () => {
        if (this.selectedFolderPaths.has(folder.path)) {
          this.selectedFolderPaths.delete(folder.path);
          cb.checked = false;
        } else {
          this.selectedFolderPaths.add(folder.path);
          cb.checked = true;
        }
        this.updateModalStats();
        this.updateCoverPreview();
        const drawer = document.getElementById('cover-photos-drawer');
        if (drawer && drawer.style.display !== 'none') {
          this.renderCoverPhotosGrid();
        }
      };

      cb.onchange = (e) => {
        e.stopPropagation();
        if (cb.checked) {
          this.selectedFolderPaths.add(folder.path);
        } else {
          this.selectedFolderPaths.delete(folder.path);
        }
        this.updateModalStats();
        this.updateCoverPreview();
        const drawer = document.getElementById('cover-photos-drawer');
        if (drawer && drawer.style.display !== 'none') {
          this.renderCoverPhotosGrid();
        }
      };

      row.onclick = (e) => {
        if (e.target !== cb) toggle();
      };

      listEl.appendChild(row);
    });
  }

  updateModalStats() {
    const statsEl = document.getElementById('album-modal-stats');
    if (!statsEl) return;

    const count = this.selectedFolderPaths.size;
    let totalPhotos = 0;
    this.allFolders.forEach(f => {
      if (this.selectedFolderPaths.has(f.path)) {
        totalPhotos += f.count || 0;
      }
    });

    statsEl.textContent = `${count} folder${count === 1 ? '' : 's'} selected (${totalPhotos} photo${totalPhotos === 1 ? '' : 's'})`;
  }

  async saveAlbumFromModal() {
    const nameInput = document.getElementById('album-name-input');
    const groupInput = document.getElementById('album-group-input');

    const name = nameInput ? nameInput.value.trim() : '';
    const group = groupInput ? groupInput.value.trim() : '';

    if (!name) {
      if (nameInput) {
        nameInput.focus();
        nameInput.style.borderColor = 'var(--danger)';
      }
      return;
    }

    const folders = Array.from(this.selectedFolderPaths);
    let totalPhotos = 0;
    let coverPhoto = this.selectedCoverPhoto;

    for (const f of this.allFolders) {
      if (this.selectedFolderPaths.has(f.path)) {
        totalPhotos += f.count || 0;
        if (!coverPhoto && f.firstPhoto) {
          coverPhoto = f.firstPhoto;
        }
      }
    }

    const albumData = {
      name,
      group,
      folders,
      photoCount: totalPhotos,
      coverPhoto
    };

    if (this.editingAlbumId) {
      albumData.id = this.editingAlbumId;
    }

    if (group) {
      await window.appStore.addAlbumGroup(group);
    }

    await window.appStore.saveAlbum(albumData);
    this.closeModal();
    this.renderAlbums(this.searchQuery);
    Utils.showToast(`Saved album "${name}"`);
  }

  async confirmDeleteAlbum(album) {
    if (confirm(`Are you sure you want to delete the album "${album.name}"?\n(Your actual image files and folders will not be deleted)`)) {
      await window.appStore.deleteAlbum(album.id);
      this.renderAlbums(this.searchQuery);
      Utils.showToast(`Deleted album "${album.name}"`);
    }
  }

  closeModal() {
    if (this.modal) {
      this.modal.classList.remove('show');
    }
    this.closeCoverPickerModal();
    const drawer = document.getElementById('cover-photos-drawer');
    if (drawer) drawer.style.display = 'none';
    this.editingAlbumId = null;
    this.selectedCoverPhoto = null;
    this.selectedFolderPaths.clear();
  }
}

document.addEventListener('DOMContentLoaded', () => {
  window.albumsManager = new AlbumsManager();
});
