class PhotoViewer {
  constructor() {
    this.overlay = document.getElementById('photo-viewer-overlay');
    this.viewport = document.getElementById('viewer-viewport');
    this.toolbar = document.getElementById('viewer-toolbar');
    this.filmstrip = document.getElementById('viewer-filmstrip');
    this.infoPanel = document.getElementById('viewer-info-panel');

    this.photos = [];
    this.currentIndex = 0;
    this.isOpen = false;
    this.rotation = 0;
    this.zoom = 1;
    this.panX = 0;
    this.panY = 0;
    this.isPanning = false;
    this.panStartX = 0;
    this.panStartY = 0;

    this.isSlideshow = false;
    this.slideshowTimer = null;

    this.initElements();
    this.initKeyboard();
    this.initMousePanZoom();
  }

  initElements() {
    this.overlay.innerHTML = `
      <!-- Top Floating Toolbar -->
      <div class="viewer-toolbar" id="viewer-toolbar">
        <button class="viewer-tool-btn" id="viewer-btn-back" title="Back to Gallery (Esc)">${Icons.back}</button>
        <div class="viewer-divider"></div>
        <div class="viewer-title-info">
          <span class="viewer-filename" id="viewer-filename"></span>
          <span class="viewer-counter" id="viewer-counter"></span>
        </div>
        <div class="viewer-divider"></div>
        <button class="viewer-tool-btn" id="viewer-btn-zoom-out" title="Zoom Out (-)">${Icons.zoomOut}</button>
        <span class="zoom-level-text" id="viewer-zoom-text">100%</span>
        <button class="viewer-tool-btn" id="viewer-btn-zoom-in" title="Zoom In (+)">${Icons.zoomIn}</button>
        <button class="viewer-tool-btn" id="viewer-btn-fit" title="Fit to Screen / 1:1">${Icons.fitScreen}</button>
        <div class="viewer-divider"></div>
        <button class="viewer-tool-btn" id="viewer-btn-rot-left" title="Rotate Counterclockwise">${Icons.rotateLeft}</button>
        <button class="viewer-tool-btn" id="viewer-btn-rot-right" title="Rotate Clockwise">${Icons.rotateRight}</button>
        <div class="viewer-divider"></div>
        <button class="viewer-tool-btn danger" id="viewer-btn-delete" title="Delete Photo (Del)">${Icons.trash}</button>
        <button class="viewer-tool-btn" id="viewer-btn-fav" title="Add to Favourites (F)">${Icons.heart}</button>
        <button class="viewer-tool-btn" id="viewer-btn-set-cover" title="Set as Album Cover" style="display:none;">${Icons.albums}</button>
        <button class="viewer-tool-btn" id="viewer-btn-info" title="File Info (I)">${Icons.info}</button>
        <button class="viewer-tool-btn" id="viewer-btn-slideshow" title="Start Slideshow (Space)">${Icons.slideshow}</button>
        <button class="viewer-tool-btn" id="viewer-btn-fullscreen" title="Fullscreen (F11)">${Icons.fullscreen}</button>
      </div>

      <!-- Main Viewport -->
      <div class="viewer-viewport" id="viewer-viewport">
        <button class="viewer-nav-btn viewer-nav-prev" id="viewer-btn-prev" title="Previous (Left Arrow)">${Icons.prev}</button>
        <img class="viewer-main-image" id="viewer-main-image" alt="Full Image" />
        <button class="viewer-nav-btn viewer-nav-next" id="viewer-btn-next" title="Next (Right Arrow)">${Icons.next}</button>
      </div>

      <!-- Bottom Filmstrip -->
      <div class="viewer-filmstrip" id="viewer-filmstrip"></div>

      <!-- Info Drawer / EXIF Panel -->
      <div class="viewer-info-panel" id="viewer-info-panel">
        <div class="info-header">
          <span class="info-title">File Information</span>
          <button class="info-close-btn" id="info-btn-close">${Icons.close}</button>
        </div>
        <div class="info-row">
          <span class="info-label">File Name</span>
          <span class="info-val" id="info-val-name"></span>
        </div>
        <div class="info-row">
          <span class="info-label">Dimensions</span>
          <span class="info-val" id="info-val-dimensions">-</span>
        </div>
        <div class="info-row">
          <span class="info-label">File Size</span>
          <span class="info-val" id="info-val-size"></span>
        </div>
        <div class="info-row">
          <span class="info-label">Date Taken / Modified</span>
          <span class="info-val" id="info-val-date"></span>
        </div>
        <div class="info-row">
          <span class="info-label">Location / Path</span>
          <span class="info-val" id="info-val-path" style="font-size:12px; font-family:monospace;"></span>
        </div>
        <div style="margin-top:16px;">
          <button class="btn btn-primary" id="info-btn-reveal" style="width:100%; gap:8px;">
            ${Icons.openExternal} Reveal in Nautilus
          </button>
        </div>
      </div>
    `;

    // Wire Toolbar Buttons
    document.getElementById('viewer-btn-back').onclick = () => this.close();
    document.getElementById('viewer-btn-prev').onclick = () => this.prev();
    document.getElementById('viewer-btn-next').onclick = () => this.next();

    document.getElementById('viewer-btn-zoom-in').onclick = () => this.zoomBy(0.25);
    document.getElementById('viewer-btn-zoom-out').onclick = () => this.zoomBy(-0.25);
    document.getElementById('viewer-btn-fit').onclick = () => this.toggleFit();

    document.getElementById('viewer-btn-rot-left').onclick = () => this.rotateBy(-90);
    document.getElementById('viewer-btn-rot-right').onclick = () => this.rotateBy(90);

    document.getElementById('viewer-btn-fav').onclick = () => this.toggleFavorite();
    document.getElementById('viewer-btn-set-cover').onclick = async () => {
      const current = this.photos[this.currentIndex];
      if (current && window.albumsManager && window.galleryView?.currentAlbum) {
        await window.albumsManager.setAlbumCover(window.galleryView.currentAlbum.id, current.path);
        window.galleryView.currentAlbum.coverPhoto = current.path;
        this.loadCurrentPhoto();
      }
    };
    document.getElementById('viewer-btn-delete').onclick = () => this.deleteCurrent();
    document.getElementById('viewer-btn-info').onclick = () => this.toggleInfo();
    document.getElementById('info-btn-close').onclick = () => this.toggleInfo(false);

    document.getElementById('viewer-btn-slideshow').onclick = () => this.toggleSlideshow();
    document.getElementById('viewer-btn-fullscreen').onclick = () => this.toggleFullscreen();

    document.getElementById('info-btn-reveal').onclick = () => {
      const current = this.photos[this.currentIndex];
      if (current) window.api.revealInFileManager(current.path);
    };

    // Cache element references
    this.mainImage = document.getElementById('viewer-main-image');
    this.filenameEl = document.getElementById('viewer-filename');
    this.counterEl = document.getElementById('viewer-counter');
    this.zoomTextEl = document.getElementById('viewer-zoom-text');
    this.favBtn = document.getElementById('viewer-btn-fav');
    this.infoPanel = document.getElementById('viewer-info-panel');
    this.filmstrip = document.getElementById('viewer-filmstrip');
  }

  open(photos, startIndex = 0) {
    if (!photos || photos.length === 0) return;
    this.photos = photos;
    this.currentIndex = Math.max(0, Math.min(startIndex, photos.length - 1));
    this.isOpen = true;
    this.rotation = 0;
    this.zoom = 1;
    this.panX = 0;
    this.panY = 0;

    this.overlay.classList.add('active');
    this.renderFilmstrip();
    this.loadCurrentPhoto();
  }

  close() {
    this.isOpen = false;
    this.stopSlideshow();
    this.overlay.classList.remove('active');
    this.infoPanel.classList.remove('open');
  }

  loadCurrentPhoto() {
    const photo = this.photos[this.currentIndex];
    if (!photo) return;

    this.rotation = 0;
    this.zoom = 1;
    this.panX = 0;
    this.panY = 0;
    this.updateTransform();

    // Update Image Source
    this.mainImage.src = `photo://${photo.path}`;

    // Update Filename & Counter
    this.filenameEl.textContent = photo.name;
    this.counterEl.textContent = `(${this.currentIndex + 1} / ${this.photos.length})`;

    // Update Favorite Icon
    const isFav = window.appStore.isFavorite(photo.path);
    this.favBtn.innerHTML = isFav ? Icons.heartFilled : Icons.heart;
    this.favBtn.classList.toggle('active', isFav);

    // Update Album Cover Button if viewing an album
    const setCoverBtn = document.getElementById('viewer-btn-set-cover');
    if (setCoverBtn) {
      if (window.galleryView && window.galleryView.currentAlbum) {
        setCoverBtn.style.display = 'inline-flex';
        const isCover = window.galleryView.currentAlbum.coverPhoto === photo.path;
        setCoverBtn.classList.toggle('active', isCover);
        setCoverBtn.title = isCover ? 'Current Album Cover' : 'Set as Album Cover';
        setCoverBtn.style.color = isCover ? 'var(--accent-pill)' : '';
      } else {
        setCoverBtn.style.display = 'none';
      }
    }

    // Update Filmstrip selection
    this.updateFilmstripActive();

    // Update Info panel if open
    this.updateInfoData();
  }

  updateTransform() {
    this.mainImage.style.transform = `translate(${this.panX}px, ${this.panY}px) scale(${this.zoom}) rotate(${this.rotation}deg)`;
    this.zoomTextEl.textContent = `${Math.round(this.zoom * 100)}%`;
  }

  prev() {
    if (this.photos.length === 0) return;
    this.currentIndex = (this.currentIndex - 1 + this.photos.length) % this.photos.length;
    this.loadCurrentPhoto();
  }

  next() {
    if (this.photos.length === 0) return;
    this.currentIndex = (this.currentIndex + 1) % this.photos.length;
    this.loadCurrentPhoto();
  }

  zoomBy(delta) {
    let newZoom = this.zoom + delta;
    if (newZoom < 0.2) newZoom = 0.2;
    if (newZoom > 6) newZoom = 6;
    this.zoom = newZoom;
    if (this.zoom === 1) {
      this.panX = 0;
      this.panY = 0;
    }
    this.updateTransform();
  }

  toggleFit() {
    if (this.zoom !== 1 || this.panX !== 0 || this.panY !== 0) {
      this.zoom = 1;
      this.panX = 0;
      this.panY = 0;
    } else {
      this.zoom = 2;
    }
    this.updateTransform();
  }

  rotateBy(degrees) {
    this.rotation = (this.rotation + degrees) % 360;
    this.updateTransform();
  }

  async toggleFavorite() {
    const photo = this.photos[this.currentIndex];
    if (!photo) return;
    const isFav = await window.appStore.toggleFavorite(photo.path);
    this.favBtn.innerHTML = isFav ? Icons.heartFilled : Icons.heart;
    this.favBtn.classList.toggle('active', isFav);
  }

  async deleteCurrent() {
    const photo = this.photos[this.currentIndex];
    if (!photo) return;
    if (confirm(`Move "${photo.name}" to trash?`)) {
      await window.api.trashFile(photo.path);
      this.photos.splice(this.currentIndex, 1);
      if (this.photos.length === 0) {
        this.close();
        if (window.galleryView.currentFolder) {
          window.galleryView.loadFolder(window.galleryView.currentFolder, window.galleryView.currentTitle);
        }
      } else {
        if (this.currentIndex >= this.photos.length) {
          this.currentIndex = this.photos.length - 1;
        }
        this.renderFilmstrip();
        this.loadCurrentPhoto();
      }
    }
  }

  toggleInfo(forceState) {
    const shouldOpen = forceState !== undefined ? forceState : !this.infoPanel.classList.contains('open');
    this.infoPanel.classList.toggle('open', shouldOpen);
    if (shouldOpen) this.updateInfoData();
  }

  updateInfoData() {
    const photo = this.photos[this.currentIndex];
    if (!photo) return;

    document.getElementById('info-val-name').textContent = photo.name;
    document.getElementById('info-val-size').textContent = Utils.formatBytes(photo.size);
    document.getElementById('info-val-date').textContent = Utils.formatDate(photo.mtime);
    document.getElementById('info-val-path').textContent = photo.path;

    // Dimensions
    const dimsEl = document.getElementById('info-val-dimensions');
    if (this.mainImage.naturalWidth) {
      dimsEl.textContent = `${this.mainImage.naturalWidth} × ${this.mainImage.naturalHeight} px`;
    } else {
      this.mainImage.onload = () => {
        dimsEl.textContent = `${this.mainImage.naturalWidth} × ${this.mainImage.naturalHeight} px`;
      };
    }
  }

  renderFilmstrip() {
    this.filmstrip.innerHTML = '';
    this.photos.forEach((photo, idx) => {
      const thumb = document.createElement('div');
      thumb.className = 'filmstrip-thumb';
      if (idx === this.currentIndex) thumb.classList.add('active');

      const img = document.createElement('img');
      img.src = `photo://${photo.path}`;
      img.loading = 'lazy';
      thumb.appendChild(img);

      thumb.onclick = () => {
        this.currentIndex = idx;
        this.loadCurrentPhoto();
      };

      this.filmstrip.appendChild(thumb);
    });
  }

  updateFilmstripActive() {
    const thumbs = this.filmstrip.querySelectorAll('.filmstrip-thumb');
    thumbs.forEach((t, idx) => {
      t.classList.toggle('active', idx === this.currentIndex);
      if (idx === this.currentIndex) {
        t.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
      }
    });
  }

  toggleSlideshow() {
    if (this.isSlideshow) {
      this.stopSlideshow();
    } else {
      this.startSlideshow();
    }
  }

  startSlideshow() {
    this.isSlideshow = true;
    const btn = document.getElementById('viewer-btn-slideshow');
    if (btn) btn.innerHTML = Icons.pause;

    this.slideshowTimer = setInterval(() => {
      this.next();
    }, 3800);
  }

  stopSlideshow() {
    this.isSlideshow = false;
    if (this.slideshowTimer) {
      clearInterval(this.slideshowTimer);
      this.slideshowTimer = null;
    }
    const btn = document.getElementById('viewer-btn-slideshow');
    if (btn) btn.innerHTML = Icons.slideshow;
  }

  toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    } else {
      document.exitFullscreen().catch(() => {});
    }
  }

  initMousePanZoom() {
    const vp = document.getElementById('viewer-viewport');

    vp.addEventListener('wheel', (e) => {
      e.preventDefault();
      const delta = e.deltaY < 0 ? 0.2 : -0.2;
      this.zoomBy(delta);
    });

    vp.addEventListener('mousedown', (e) => {
      if (e.target.closest('.viewer-nav-btn')) return;
      this.isPanning = true;
      this.panStartX = e.clientX - this.panX;
      this.panStartY = e.clientY - this.panY;
      vp.classList.add('panning');
    });

    window.addEventListener('mousemove', (e) => {
      if (!this.isPanning) return;
      this.panX = e.clientX - this.panStartX;
      this.panY = e.clientY - this.panStartY;
      this.updateTransform();
    });

    window.addEventListener('mouseup', () => {
      if (this.isPanning) {
        this.isPanning = false;
        vp.classList.remove('panning');
      }
    });

    // Double click to toggle zoom
    this.mainImage.addEventListener('dblclick', () => {
      this.toggleFit();
    });
  }

  initKeyboard() {
    window.addEventListener('keydown', (e) => {
      if (!this.isOpen) return;

      if (e.key === 'Escape') {
        if (this.infoPanel.classList.contains('open')) {
          this.toggleInfo(false);
        } else {
          this.close();
        }
      } else if (e.key === 'ArrowLeft') {
        this.prev();
      } else if (e.key === 'ArrowRight') {
        this.next();
      } else if (e.key === ' ' || e.key === 'Spacebar') {
        e.preventDefault();
        this.toggleSlideshow();
      } else if (e.key === 'f' || e.key === 'F') {
        this.toggleFavorite();
      } else if (e.key === 'i' || e.key === 'I') {
        this.toggleInfo();
      } else if (e.key === 'Delete') {
        this.deleteCurrent();
      } else if (e.key === '+' || e.key === '=') {
        this.zoomBy(0.25);
      } else if (e.key === '-' || e.key === '_') {
        this.zoomBy(-0.25);
      } else if (e.key === '0') {
        this.zoom = 1;
        this.panX = 0;
        this.panY = 0;
        this.updateTransform();
      } else if (e.key === 'r' || e.key === 'R') {
        this.rotateBy(90);
      }
    });
  }
}

window.photoViewer = new PhotoViewer();
