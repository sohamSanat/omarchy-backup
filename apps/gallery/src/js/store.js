class Store {
  constructor() {
    this.data = {
      theme: 'dark',
      gridSize: 'medium',
      sort: 'date-desc',
      sources: [],
      favorites: [],
      albums: [],
      albumGroups: ['Favorites', 'Series', 'General'],
      albumGroupBy: 'group',
      sidebarWidth: 260,
      lastOpenedFolder: null
    };
    this.listeners = new Set();
  }

  async init() {
    try {
      const stored = await window.api.getStore();
      if (stored) {
        this.data = { ...this.data, ...stored };
      }
    } catch (e) {
      console.warn('Store init warning:', e);
    }
    this.notify('init', this.data);
    this.notify('albums', this.data.albums || []);
    this.notify('albumGroups', this.data.albumGroups || []);
    return this.data;
  }

  get(key) {
    return this.data[key];
  }

  async set(key, value) {
    this.data[key] = value;
    await window.api.saveStore(this.data);
    this.notify(key, value);
  }

  async toggleFavorite(filePath) {
    let favs = this.data.favorites || [];
    if (favs.includes(filePath)) {
      favs = favs.filter(p => p !== filePath);
    } else {
      favs.push(filePath);
    }
    await this.set('favorites', favs);
    return favs.includes(filePath);
  }

  isFavorite(filePath) {
    return (this.data.favorites || []).includes(filePath);
  }

  async addSource(folderPath) {
    const sources = this.data.sources || [];
    if (!sources.includes(folderPath)) {
      sources.push(folderPath);
      await this.set('sources', sources);
    }
  }

  async removeSource(folderPath) {
    let sources = this.data.sources || [];
    sources = sources.filter(p => p !== folderPath);
    await this.set('sources', sources);
  }

  getAlbums() {
    return this.data.albums || [];
  }

  getAlbum(id) {
    return (this.data.albums || []).find(a => a.id === id);
  }

  async saveAlbum(albumData) {
    const albums = [...(this.data.albums || [])];
    if (albumData.id) {
      const idx = albums.findIndex(a => a.id === albumData.id);
      if (idx !== -1) {
        albums[idx] = { ...albums[idx], ...albumData, updatedAt: Date.now() };
      } else {
        albums.push(albumData);
      }
    } else {
      const newAlbum = {
        ...albumData,
        id: 'album-' + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      albums.unshift(newAlbum);
    }
    await this.set('albums', albums);
    return albums;
  }

  async deleteAlbum(id) {
    let albums = this.data.albums || [];
    albums = albums.filter(a => a.id !== id);
    await this.set('albums', albums);
    return albums;
  }

  getAlbumGroups() {
    const defaultGroups = ['Favorites', 'Series', 'General'];
    const groups = new Set(this.data.albumGroups && this.data.albumGroups.length > 0 ? this.data.albumGroups : defaultGroups);
    (this.data.albums || []).forEach(a => {
      if (a.group && a.group.trim()) {
        groups.add(a.group.trim());
      }
    });
    return Array.from(groups);
  }

  async addAlbumGroup(groupName) {
    if (!groupName || !groupName.trim()) return;
    const name = groupName.trim();
    const groups = this.getAlbumGroups();
    if (!groups.includes(name)) {
      groups.push(name);
      await this.set('albumGroups', groups);
    }
    return groups;
  }

  async renameAlbumGroup(oldName, newName) {
    if (!oldName || !newName || !newName.trim() || oldName === newName.trim()) return;
    const trimmedNew = newName.trim();
    let groups = this.getAlbumGroups();
    const idx = groups.indexOf(oldName);
    if (idx !== -1) {
      groups[idx] = trimmedNew;
    } else {
      groups.push(trimmedNew);
    }
    const albums = (this.data.albums || []).map(a => {
      if (a.group === oldName) {
        return { ...a, group: trimmedNew, updatedAt: Date.now() };
      }
      return a;
    });
    this.data.albumGroups = groups;
    this.data.albums = albums;
    await window.api.saveStore(this.data);
    this.notify('albumGroups', groups);
    this.notify('albums', albums);
  }

  async deleteAlbumGroup(groupName) {
    if (!groupName) return;
    let groups = this.getAlbumGroups().filter(g => g !== groupName);
    const albums = (this.data.albums || []).map(a => {
      if (a.group === groupName) {
        return { ...a, group: '', updatedAt: Date.now() };
      }
      return a;
    });
    this.data.albumGroups = groups;
    this.data.albums = albums;
    await window.api.saveStore(this.data);
    this.notify('albumGroups', groups);
    this.notify('albums', albums);
  }

  async setAlbumGroup(albumId, groupName) {
    const albums = [...(this.data.albums || [])];
    const idx = albums.findIndex(a => a.id === albumId);
    if (idx !== -1) {
      albums[idx] = { ...albums[idx], group: (groupName || '').trim(), updatedAt: Date.now() };
      await this.set('albums', albums);
      if (groupName && groupName.trim()) {
        await this.addAlbumGroup(groupName.trim());
      }
    }
  }

  async setAlbumsGroup(albumIds, groupName) {
    const idSet = new Set(albumIds);
    const albums = (this.data.albums || []).map(a => {
      if (idSet.has(a.id)) {
        return { ...a, group: (groupName || '').trim(), updatedAt: Date.now() };
      }
      return a;
    });
    await this.set('albums', albums);
    if (groupName && groupName.trim()) {
      await this.addAlbumGroup(groupName.trim());
    }
  }

  subscribe(fn) {
    this.listeners.add(fn);
    return () => this.listeners.delete(fn);
  }

  notify(key, value) {
    for (const fn of this.listeners) {
      fn(key, value, this.data);
    }
  }
}

window.appStore = new Store();

