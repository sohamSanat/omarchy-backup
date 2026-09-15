const { app, BrowserWindow, ipcMain, protocol, net, dialog, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { execSync, spawn } = require('child_process');

app.setName('Gallery');

// Register custom photo:// scheme for hardware-accelerated local image serving
protocol.registerSchemesAsPrivileged([
  {
    scheme: 'photo',
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true,
      stream: true,
      corsEnabled: true
    }
  }
]);

const SUPPORTED_EXTS = new Set([
  '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.avif', '.svg', '.tiff', '.ico',
  '.mp4', '.webm', '.mkv'
]);

const VIDEO_EXTS = new Set(['.mp4', '.webm', '.mkv']);

const CONFIG_DIR = path.join(os.homedir(), '.config', 'omarchy-gallery');
const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');
const ROOT_GALLERY_DIR = path.join(os.homedir(), 'Pictures', 'normal-gallery-section');

function ensureConfigDir() {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }
  if (!fs.existsSync(ROOT_GALLERY_DIR)) {
    fs.mkdirSync(ROOT_GALLERY_DIR, { recursive: true });
  }
}

function generateDefaultAlbums(picturesDir) {
  const albums = [];
  const mDir = path.join(picturesDir, 'm');
  const scanDirs = fs.existsSync(mDir) ? [mDir, picturesDir] : [picturesDir];

  try {
    for (const base of scanDirs) {
      if (!fs.existsSync(base)) continue;
      const entries = fs.readdirSync(base, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.name.startsWith('.') || entry.name === 'm') continue;
        if (entry.isDirectory()) {
          const fullDir = path.join(base, entry.name);
          const folderPaths = [];
          let firstCover = null;
          let totalCount = 0;

          function scanSub(cur) {
            try {
              const subs = fs.readdirSync(cur, { withFileTypes: true });
              let hasImg = false;
              for (const s of subs) {
                if (s.name.startsWith('.')) continue;
                const sp = path.join(cur, s.name);
                if (s.isDirectory()) {
                  scanSub(sp);
                } else if (s.isFile()) {
                  const ext = path.extname(s.name).toLowerCase();
                  if (SUPPORTED_EXTS.has(ext)) {
                    hasImg = true;
                    totalCount++;
                    if (!firstCover) firstCover = sp;
                  }
                }
              }
              if (hasImg) folderPaths.push(cur);
            } catch (e) {}
          }

          scanSub(fullDir);

          if (folderPaths.length > 0) {
            const cleanName = entry.name.replace(/^\d+\.\s*/, '');
            if (!albums.some(a => a.name.toLowerCase() === cleanName.toLowerCase())) {
              albums.push({
                id: 'album-' + Buffer.from(entry.name).toString('hex').slice(0, 10),
                name: cleanName,
                folders: folderPaths,
                coverPhoto: firstCover,
                photoCount: totalCount,
                createdAt: Date.now()
              });
            }
          }
        }
      }
    }
  } catch (e) {
    console.error('Error auto-generating default albums:', e);
  }

  albums.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }));
  return albums;
}

function loadConfig() {
  ensureConfigDir();
  const picturesDir = ROOT_GALLERY_DIR;
  let initialFolder = picturesDir;

  const defaults = {
    theme: 'dark', // 'dark', 'light', 'omarchy'
    gridSize: 'medium', // 'compact', 'medium', 'large'
    sort: 'date-desc',
    sources: [picturesDir],
    favorites: [],
    albums: [],
    albumGroups: ['Favorites', 'Series', 'General'],
    albumGroupBy: 'group',
    sidebarWidth: 260,
    lastOpenedFolder: initialFolder,
    currentView: 'albums'
  };

  if (fs.existsSync(CONFIG_FILE)) {
    try {
      const data = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
      const albums = Array.isArray(data.albums) ? data.albums : [];
      const albumGroups = Array.isArray(data.albumGroups) && data.albumGroups.length > 0 ? data.albumGroups : defaults.albumGroups;
      const albumGroupBy = data.albumGroupBy || defaults.albumGroupBy;
      return { ...defaults, ...data, sources: [picturesDir], albums, albumGroups, albumGroupBy };
    } catch (e) {
      console.error('Error reading config file:', e);
    }
  }
  return defaults;
}

function saveConfig(data) {
  try {
    ensureConfigDir();
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(data, null, 2), 'utf8');
    return true;
  } catch (e) {
    console.error('Error saving config:', e);
    return false;
  }
}

let mainWindow = null;
let targetPathFromArgv = null;

// Parse command line arguments for opened files or directories
function parseArgv(argv) {
  for (let i = 1; i < argv.length; i++) {
    const arg = argv[i];
    if (!arg) continue;
    if (arg === '--home' || arg === '--modal' || arg === '--collapsed' || arg.startsWith('--album:')) {
      return arg;
    }
    if (arg.startsWith('-')) continue;
    const resolved = path.resolve(arg);
    if (resolved === __dirname || resolved === process.cwd() || resolved === path.join(__dirname, 'main.js')) {
      continue;
    }
    if (fs.existsSync(resolved)) {
      return resolved;
    }
  }
  return null;
}

targetPathFromArgv = parseArgv(process.argv);

const gotTheLock = app.requestSingleInstanceLock();
if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', (event, commandLine) => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
      const target = parseArgv(commandLine);
      if (target) {
        mainWindow.webContents.send('open-target', target);
      }
    }
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    title: 'Gallery',
    width: 1340,
    height: 880,
    minWidth: 840,
    minHeight: 540,
    frame: false, // Windows 11 custom titlebar & controls
    backgroundColor: '#1c1c1c',
    icon: path.join(__dirname, 'assets', 'icon.png'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      sandbox: false,
      nodeIntegration: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'src', 'index.html'));

  mainWindow.on('maximize', () => {
    mainWindow.webContents.send('window-maximize-changed', true);
  });
  mainWindow.on('unmaximize', () => {
    mainWindow.webContents.send('window-maximize-changed', false);
  });

  mainWindow.webContents.on('console-message', (event, level, message, line, sourceId) => {
    console.log(`[Renderer] ${message} (${sourceId}:${line})`);
  });

  mainWindow.webContents.on('render-process-gone', (event, details) => {
    console.error('Render process gone:', details);
  });

  mainWindow.on('close', (e) => {
    console.log('Main window close event triggered');
  });

  mainWindow.webContents.once('did-finish-load', () => {
    console.log('Renderer did-finish-load');
  });
}

const { pathToFileURL } = require('url');

app.whenReady().then(() => {
  // Handle custom photo:// protocol
  protocol.handle('photo', (request) => {
    try {
      const rawUrl = request.url;
      let cleanPath = decodeURIComponent(rawUrl.replace(/^photo:\/\//, ''));
      if (!cleanPath.startsWith('/')) {
        cleanPath = '/' + cleanPath;
      }
      const fileUrl = pathToFileURL(cleanPath).href;
      return net.fetch(fileUrl);
    } catch (err) {
      console.error('Failed to handle photo protocol:', err);
      return new Response('File not found', { status: 404 });
    }
  });

  ipcMain.handle('get-target-arg', () => {
    const t = targetPathFromArgv;
    targetPathFromArgv = null;
    return t;
  });

  ipcMain.handle('get-initial-data', async () => {
    const config = loadConfig();
    return {
      homeDir: os.homedir(),
      config,
      isTestCollapsed: process.env.TEST_COLLAPSED === '1'
    };
  });

  ipcMain.handle('get-store', async () => {
    return loadConfig();
  });

  ipcMain.handle('save-store', async (event, data) => {
    return saveConfig(data);
  });

  ipcMain.handle('read-dir', async (event, dirPath) => {
    try {
      if (!fs.existsSync(dirPath)) return { error: 'Path does not exist' };
      const entries = await fs.promises.readdir(dirPath, { withFileTypes: true });
      const subdirs = [];
      const files = [];

      for (const entry of entries) {
        if (entry.name.startsWith('.')) continue; // skip hidden
        const fullPath = path.join(dirPath, entry.name);
        try {
          if (entry.isDirectory()) {
            subdirs.push({
              name: entry.name,
              path: fullPath,
              isDirectory: true
            });
          } else if (entry.isFile()) {
            const ext = path.extname(entry.name).toLowerCase();
            if (SUPPORTED_EXTS.has(ext)) {
              const stat = await fs.promises.stat(fullPath);
              files.push({
                name: entry.name,
                path: fullPath,
                isDirectory: false,
                isVideo: VIDEO_EXTS.has(ext),
                size: stat.size,
                mtime: stat.mtimeMs,
                birthtime: stat.birthtimeMs
              });
            }
          }
        } catch (e) {
          // ignore inaccessible item
        }
      }

      // Sort subdirectories alphabetically
      subdirs.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' }));

      return { subdirs, files };
    } catch (err) {
      return { error: err.message };
    }
  });

  ipcMain.handle('scan-folder', async (event, dirPath, recursive = true) => {
    try {
      if (!fs.existsSync(dirPath)) return { totalPhotos: 0, photos: [] };
      const photos = [];
      let totalPhotos = 0;

      async function traverse(currentDir, depth = 0) {
        if (depth > 6) return; // Prevent excessive recursion
        try {
          const entries = await fs.promises.readdir(currentDir, { withFileTypes: true });
          for (const entry of entries) {
            if (entry.name.startsWith('.')) continue;
            const fullPath = path.join(currentDir, entry.name);
            if (entry.isDirectory() && recursive) {
              await traverse(fullPath, depth + 1);
            } else if (entry.isFile()) {
              const ext = path.extname(entry.name).toLowerCase();
              if (SUPPORTED_EXTS.has(ext)) {
                totalPhotos++;
                // If it's direct child or we need the list:
                if (!recursive || depth === 0 || photos.length < 5000) {
                  try {
                    const stat = await fs.promises.stat(fullPath);
                    photos.push({
                      name: entry.name,
                      path: fullPath,
                      isDirectory: false,
                      isVideo: VIDEO_EXTS.has(ext),
                      size: stat.size,
                      mtime: stat.mtimeMs,
                      birthtime: stat.birthtimeMs
                    });
                  } catch (e) {}
                }
              }
            }
          }
        } catch (e) {}
      }

      await traverse(dirPath, 0);
      return { totalPhotos, photos };
    } catch (err) {
      return { totalPhotos: 0, photos: [], error: err.message };
    }
  });

  ipcMain.handle('list-image-folders', async (event, baseDir) => {
    const root = baseDir || ROOT_GALLERY_DIR;
    const result = [];

    async function walk(dir) {
      try {
        const entries = await fs.promises.readdir(dir, { withFileTypes: true });
        let imgCount = 0;
        let firstPhoto = null;
        const subdirs = [];

        for (const e of entries) {
          if (e.name.startsWith('.')) continue;
          const full = path.join(dir, e.name);
          if (e.isDirectory()) {
            subdirs.push(full);
          } else if (e.isFile()) {
            const ext = path.extname(e.name).toLowerCase();
            if (SUPPORTED_EXTS.has(ext)) {
              imgCount++;
              if (!firstPhoto) firstPhoto = full;
            }
          }
        }

        if (imgCount > 0) {
          result.push({
            name: path.basename(dir),
            path: dir,
            relPath: path.relative(root, dir) || path.basename(dir),
            count: imgCount,
            firstPhoto
          });
        }

        for (const sub of subdirs) {
          await walk(sub);
        }
      } catch (err) {}
    }

    await walk(root);
    result.sort((a, b) => a.relPath.localeCompare(b.relPath, undefined, { numeric: true, sensitivity: 'base' }));
    return result;
  });

  ipcMain.handle('get-album-photos', async (event, folderPaths) => {
    try {
      const photos = [];
      const seenPaths = new Set();

      async function walkFolder(curDir, topFolderName) {
        if (!fs.existsSync(curDir)) return;
        const entries = await fs.promises.readdir(curDir, { withFileTypes: true });
        for (const entry of entries) {
          if (entry.name.startsWith('.')) continue;
          const fullPath = path.join(curDir, entry.name);
          if (entry.isDirectory()) {
            await walkFolder(fullPath, topFolderName);
          } else if (entry.isFile()) {
            const ext = path.extname(entry.name).toLowerCase();
            if (SUPPORTED_EXTS.has(ext)) {
              if (seenPaths.has(fullPath)) continue;
              seenPaths.add(fullPath);
              try {
                const stat = await fs.promises.stat(fullPath);
                photos.push({
                  name: entry.name,
                  path: fullPath,
                  isDirectory: false,
                  isVideo: VIDEO_EXTS.has(ext),
                  size: stat.size,
                  mtime: stat.mtimeMs,
                  birthtime: stat.birthtimeMs,
                  folderName: topFolderName
                });
              } catch (e) {}
            }
          }
        }
      }

      for (const folder of (folderPaths || [])) {
        await walkFolder(folder, path.basename(folder));
      }
      return { totalPhotos: photos.length, photos };
    } catch (err) {
      return { totalPhotos: 0, photos: [], error: err.message };
    }
  });

  ipcMain.handle('choose-image-file', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      title: 'Select Album Cover Image',
      properties: ['openFile'],
      filters: [
        { name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'avif', 'svg'] }
      ]
    });
    if (!result.canceled && result.filePaths && result.filePaths.length > 0) {
      return {
        filePath: result.filePaths[0],
        fileName: path.basename(result.filePaths[0])
      };
    }
    return null;
  });

  ipcMain.handle('add-custom-folder', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      title: 'Select Folder to Add to Photos',
      properties: ['openDirectory']
    });
    if (!result.canceled && result.filePaths.length > 0) {
      return result.filePaths[0];
    }
    return null;
  });

  ipcMain.handle('trash-file', async (event, filePath) => {
    try {
      await shell.trashItem(filePath);
      return { success: true };
    } catch (err) {
      return { success: false, error: err.message };
    }
  });

  ipcMain.handle('reveal-in-file-manager', async (event, filePath) => {
    try {
      shell.showItemInFolder(filePath);
      return { success: true };
    } catch (err) {
      return { success: false, error: err.message };
    }
  });

  ipcMain.handle('open-external', async (event, filePath) => {
    try {
      await shell.openPath(filePath);
      return { success: true };
    } catch (err) {
      return { success: false, error: err.message };
    }
  });

  ipcMain.handle('get-omarchy-theme', async () => {
    try {
      const output = execSync('omarchy-theme-env --json', { encoding: 'utf8', timeout: 2000 });
      return JSON.parse(output.trim());
    } catch (e) {
      return {
        name: 'default',
        mode: process.env.OMARCHY_THEME_MODE || 'dark',
        is_dark: process.env.OMARCHY_THEME_MODE !== 'light',
        is_light: process.env.OMARCHY_THEME_MODE === 'light',
        foreground: '#ffffff',
        background: '#181818',
        accent: '#0078D4'
      };
    }
  });

  // Window controls
  ipcMain.handle('window-minimize', () => mainWindow?.minimize());
  ipcMain.handle('window-maximize', () => {
    if (!mainWindow) return;
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  });
  ipcMain.handle('window-close', () => {
    mainWindow?.close();
  });
  ipcMain.handle('window-is-maximized', () => mainWindow?.isMaximized());

  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
