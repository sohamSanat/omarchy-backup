const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getTargetArg: () => ipcRenderer.invoke('get-target-arg'),
  getInitialData: () => ipcRenderer.invoke('get-initial-data'),
  readDir: (dirPath) => ipcRenderer.invoke('read-dir', dirPath),
  scanFolder: (dirPath, recursive) => ipcRenderer.invoke('scan-folder', dirPath, recursive),
  addCustomFolder: () => ipcRenderer.invoke('add-custom-folder'),
  trashFile: (filePath) => ipcRenderer.invoke('trash-file', filePath),
  revealInFileManager: (filePath) => ipcRenderer.invoke('reveal-in-file-manager', filePath),
  openExternal: (filePath) => ipcRenderer.invoke('open-external', filePath),
  getOmarchyTheme: () => ipcRenderer.invoke('get-omarchy-theme'),
  saveStore: (data) => ipcRenderer.invoke('save-store', data),
  getStore: () => ipcRenderer.invoke('get-store'),
  listImageFolders: (baseDir) => ipcRenderer.invoke('list-image-folders', baseDir),
  getAlbumPhotos: (folderPaths) => ipcRenderer.invoke('get-album-photos', folderPaths),
  chooseImageFile: () => ipcRenderer.invoke('choose-image-file'),
  
  // Window controls
  minimize: () => ipcRenderer.invoke('window-minimize'),
  maximize: () => ipcRenderer.invoke('window-maximize'),
  close: () => ipcRenderer.invoke('window-close'),
  isMaximized: () => ipcRenderer.invoke('window-is-maximized'),
  onMaximizeChange: (callback) => {
    ipcRenderer.on('window-maximize-changed', (e, isMax) => callback(isMax));
  },
  onOpenTarget: (callback) => {
    ipcRenderer.on('open-target', (e, targetPath) => callback(targetPath));
  },

  // Biometric & Sudo Password Authentication
  startFingerprintAuth: () => ipcRenderer.invoke('auth-start-fingerprint'),
  stopFingerprintAuth: () => ipcRenderer.invoke('auth-stop-fingerprint'),
  verifyPassword: (pwd) => ipcRenderer.invoke('auth-verify-password', pwd),
  getUserInfo: () => ipcRenderer.invoke('get-user-info'),
  onFingerprintStatus: (callback) => {
    ipcRenderer.on('auth-fingerprint-status', (e, msg) => callback(msg));
  },
  onFingerprintSuccess: (callback) => {
    ipcRenderer.on('auth-fingerprint-success', (e) => callback());
  }
});
