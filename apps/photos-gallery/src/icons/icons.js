// Fluent UI & Windows 11 style SVG Icons
const Icons = {
  photosLogo: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="photoGrad1" x1="2" y1="2" x2="20" y2="20" gradientUnits="userSpaceOnUse">
        <stop stop-color="#0078D4"/>
        <stop offset="1" stop-color="#00BCF2"/>
      </linearGradient>
      <linearGradient id="photoGrad2" x1="6" y1="6" x2="22" y2="22" gradientUnits="userSpaceOnUse">
        <stop stop-color="#E3008C"/>
        <stop offset="1" stop-color="#FF8C00"/>
      </linearGradient>
    </defs>
    <rect x="2" y="3" width="16" height="15" rx="3" fill="url(#photoGrad1)" opacity="0.9"/>
    <rect x="6" y="6" width="16" height="15" rx="3" fill="url(#photoGrad2)" opacity="0.85"/>
    <circle cx="11" cy="11" r="2" fill="#FFFFFF"/>
    <path d="M7 19L12 14L15 17L18 13L21 17V19C21 19.5523 20.5523 20 20 20H8C7.44772 20 7 19.5523 7 19Z" fill="#FFFFFF" fill-opacity="0.9"/>
  </svg>`,

  hamburger: `<svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor">
    <path fill-rule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd" />
  </svg>`,

  search: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="9" cy="9" r="6"/>
    <line x1="13.5" y1="13.5" x2="18" y2="18"/>
  </svg>`,

  clear: `<svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
  </svg>`,

  import: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
    <path d="M4 14v2a2 2 0 002 2h8a2 2 0 002-2v-2"/>
    <polyline points="7 10 10 13 13 10"/>
    <line x1="10" y1="3" x2="10" y2="13"/>
  </svg>`,

  settings: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="10" cy="10" r="3"/>
    <path d="M16.2 12.2a1.4 1.4 0 00.3 1.5l.1.1a1.7 1.7 0 01-2.4 2.4l-.1-.1a1.4 1.4 0 00-1.5-.3 1.4 1.4 0 00-.9 1.3v.2a1.7 1.7 0 01-3.4 0v-.2a1.4 1.4 0 00-.9-1.3 1.4 1.4 0 00-1.5.3l-.1.1a1.7 1.7 0 01-2.4-2.4l.1-.1a1.4 1.4 0 00.3-1.5 1.4 1.4 0 00-1.3-.9H2.8a1.7 1.7 0 010-3.4h.2a1.4 1.4 0 001.3-.9 1.4 1.4 0 00-.3-1.5l-.1-.1a1.7 1.7 0 012.4-2.4l.1.1a1.4 1.4 0 001.5.3h.1a1.4 1.4 0 00.8-1.3v-.2a1.7 1.7 0 013.4 0v.2a1.4 1.4 0 00.9 1.3 1.4 1.4 0 001.5-.3l.1-.1a1.7 1.7 0 012.4 2.4l-.1.1a1.4 1.4 0 00-.3 1.5v.1a1.4 1.4 0 001.3.8h.2a1.7 1.7 0 010 3.4h-.2a1.4 1.4 0 00-1.3.9z"/>
  </svg>`,

  minimize: `<svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor">
    <rect y="5" width="12" height="1.5" rx="0.5"/>
  </svg>`,

  maximize: `<svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.3">
    <rect x="1" y="1" width="10" height="10" rx="1"/>
  </svg>`,

  restore: `<svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.2">
    <rect x="3" y="1" width="8" height="8" rx="1"/>
    <path d="M1 4v7h7" stroke-linejoin="round"/>
  </svg>`,

  close: `<svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round">
    <line x1="2" y1="2" x2="10" y2="10"/>
    <line x1="10" y1="2" x2="2" y2="10"/>
  </svg>`,

  gallery: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <rect x="2.5" y="2.5" width="15" height="15" rx="2.5"/>
    <circle cx="7.5" cy="7.5" r="1.5"/>
    <path d="M17.5 13.5l-4-4-7 7.5"/>
  </svg>`,

  addFolder: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 5a2 2 0 012-2h4l2 2h6a2 2 0 012 2v2H3V5z"/>
    <path d="M3 9v7a2 2 0 002 2h7"/>
    <line x1="16" y1="13" x2="16" y2="19"/>
    <line x1="13" y1="16" x2="19" y2="16"/>
  </svg>`,

  heart: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M10 17.25s-6.75-4.25-8.25-8.5C.25 4.5 3 2 6 3.25 7.75 4 10 6 10 6s2.25-2 4-2.75c3-1.25 5.75 1.25 4.25 5.5-1.5 4.25-8.25 8.5-8.25 8.5z"/>
  </svg>`,

  heartFilled: `<svg width="18" height="18" viewBox="0 0 20 20" fill="#E81123" stroke="#E81123" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M10 17.25s-6.75-4.25-8.25-8.5C.25 4.5 3 2 6 3.25 7.75 4 10 6 10 6s2.25-2 4-2.75c3-1.25 5.75 1.25 4.25 5.5-1.5 4.25-8.25 8.5-8.25 8.5z"/>
  </svg>`,

  chevronRight: `<svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor">
    <path fill-rule="evenodd" d="M6.293 3.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L9.586 8 6.293 4.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
  </svg>`,

  chevronDown: `<svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor">
    <path fill-rule="evenodd" d="M3.293 6.293a1 1 0 011.414 0L8 9.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/>
  </svg>`,

  chevronUp: `<svg width="12" height="12" viewBox="0 0 16 16" fill="currentColor">
    <path fill-rule="evenodd" d="M3.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L8 6.414 4.707 9.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
  </svg>`,

  folder: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 5a2 2 0 012-2h3.5a2 2 0 011.4.6L12 5.5H15a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V5z"/>
  </svg>`,

  folderFilled: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path d="M3 6C3 4.89543 3.89543 4 5 4H9.58579C10.1162 4 10.6249 4.21071 11 4.58579L12.4142 6H19C20.1046 6 21 6.89543 21 8V18C21 19.1046 20.1046 20 19 20H5C3.89543 20 3 19.1046 3 18V6Z" fill="#F4B400" fill-opacity="0.9" stroke="#E09E00" stroke-width="1.2"/>
    <path d="M3 9H21V18C21 19.1046 20.1046 20 19 20H5C3.89543 20 3 19.1046 3 18V9Z" fill="#FDD663"/>
  </svg>`,

  folderOpen: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 5a2 2 0 012-2h3.5a2 2 0 011.4.6L12 5.5H15a2 2 0 012 2v2H3V5z"/>
    <path d="M2.5 9.5h15l-1.8 7.2a2 2 0 01-1.9 1.3H4.2a2 2 0 01-1.9-1.3L2.5 9.5z"/>
  </svg>`,

  pc: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <rect x="2.5" y="3" width="15" height="10" rx="1.5"/>
    <path d="M7 17h6M10 13v4"/>
  </svg>`,

  user: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="10" cy="6.5" r="3.5"/>
    <path d="M3.5 17c0-3.5 3-6 6.5-6s6.5 2.5 6.5 6"/>
  </svg>`,

  memories: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <rect x="4" y="5" width="13" height="11" rx="2"/>
    <rect x="2.5" y="3" width="13" height="11" rx="2" stroke-dasharray="2 2"/>
  </svg>`,

  cloud: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M6 16.5h8.5a4 4 0 001.5-7.7A5 5 0 006.5 7 4 4 0 006 16.5z"/>
  </svg>`,

  select: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <rect x="3" y="3" width="14" height="14" rx="2"/>
    <polyline points="7 10 9.5 12.5 14 7"/>
  </svg>`,

  slideshow: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <rect x="2.5" y="2.5" width="15" height="15" rx="3"/>
    <polygon points="8.5 7 13.5 10 8.5 13" fill="currentColor" stroke="none"/>
  </svg>`,

  sort: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M7 4v12M4 7l3-3 3 3M13 16V4M10 13l3 3 3-3"/>
  </svg>`,

  filter: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <polygon points="3 4 17 4 11.5 11 11.5 16 8.5 17.5 8.5 11 3 4"/>
  </svg>`,

  viewGrid: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <rect x="3" y="3" width="5.5" height="5.5" rx="1"/>
    <rect x="11.5" y="3" width="5.5" height="5.5" rx="1"/>
    <rect x="3" y="11.5" width="5.5" height="5.5" rx="1"/>
    <rect x="11.5" y="11.5" width="5.5" height="5.5" rx="1"/>
  </svg>`,

  more: `<svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
    <circle cx="5" cy="10" r="1.5"/>
    <circle cx="10" cy="10" r="1.5"/>
    <circle cx="15" cy="10" r="1.5"/>
  </svg>`,

  back: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
    <line x1="16" y1="10" x2="4" y2="10"/>
    <polyline points="9 5 4 10 9 15"/>
  </svg>`,

  zoomIn: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="9" cy="9" r="6"/>
    <line x1="13.5" y1="13.5" x2="18" y2="18"/>
    <line x1="9" y1="6.5" x2="9" y2="11.5"/>
    <line x1="6.5" y1="9" x2="11.5" y2="9"/>
  </svg>`,

  zoomOut: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="9" cy="9" r="6"/>
    <line x1="13.5" y1="13.5" x2="18" y2="18"/>
    <line x1="6.5" y1="9" x2="11.5" y2="9"/>
  </svg>`,

  fitScreen: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 7V4a1 1 0 011-1h3M13 3h3a1 1 0 011 1v3M17 13v3a1 1 0 01-1 1h-3M7 17H4a1 1 0 01-1-1v-3"/>
  </svg>`,

  actualSize: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <rect x="4" y="4" width="12" height="12" rx="2"/>
    <text x="10" y="13" font-size="8" font-weight="bold" fill="currentColor" text-anchor="middle">1:1</text>
  </svg>`,

  rotateLeft: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M4 8.5a6 6 0 111.8 4.2"/>
    <polyline points="4 4 4 9 9 9"/>
  </svg>`,

  rotateRight: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M16 8.5a6 6 0 10-1.8 4.2"/>
    <polyline points="16 4 16 9 11 9"/>
  </svg>`,

  trash: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <polyline points="3 5 5 5 17 5"/>
    <path d="M6 5v11a2 2 0 002 2h4a2 2 0 002-2V5"/>
    <path d="M8 5V3a1 1 0 011-1h2a1 1 0 011 1v2"/>
    <line x1="9" y1="9" x2="9" y2="14"/>
    <line x1="11" y1="9" x2="11" y2="14"/>
  </svg>`,

  info: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="10" cy="10" r="7"/>
    <line x1="10" y1="9" x2="10" y2="14"/>
    <circle cx="10" cy="6.5" r="0.8" fill="currentColor"/>
  </svg>`,

  fullscreen: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <polyline points="14 3 17 3 17 6"/>
    <polyline points="6 17 3 17 3 14"/>
    <polyline points="17 14 17 17 14 17"/>
    <polyline points="3 6 3 3 6 3"/>
  </svg>`,

  prev: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <polyline points="15 18 9 12 15 6"/>
  </svg>`,

  next: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <polyline points="9 18 15 12 9 6"/>
  </svg>`,

  check: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
    <path fill-rule="evenodd" d="M13.854 3.646a.5.5 0 010 .708l-7 7a.5.5 0 01-.708 0l-3.5-3.5a.5.5 0 11.708-.708L6.5 10.293l6.646-6.647a.5.5 0 01.708 0z" clip-rule="evenodd"/>
  </svg>`,

  filmstrip: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <rect x="2" y="4" width="16" height="12" rx="2"/>
    <line x1="2" y1="7" x2="18" y2="7"/>
    <line x1="2" y1="13" x2="18" y2="13"/>
    <line x1="6" y1="4" x2="6" y2="7"/>
    <line x1="10" y1="4" x2="10" y2="7"/>
    <line x1="14" y1="4" x2="14" y2="7"/>
    <line x1="6" y1="13" x2="6" y2="16"/>
    <line x1="10" y1="13" x2="10" y2="16"/>
    <line x1="14" y1="13" x2="14" y2="16"/>
  </svg>`,

  pause: `<svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
    <rect x="5" y="4" width="3.5" height="12" rx="1"/>
    <rect x="11.5" y="4" width="3.5" height="12" rx="1"/>
  </svg>`,

  play: `<svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
    <polygon points="6 4 16 10 6 16"/>
  </svg>`,

  refresh: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M17 10a7 7 0 11-2-4.9"/>
    <polyline points="17 4 17 9 12 9"/>
  </svg>`,

  openExternal: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M15 11v5a1 1 0 01-1 1H4a1 1 0 01-1-1V6a1 1 0 011-1h5"/>
    <polyline points="13 3 17 3 17 7"/>
    <line x1="9" y1="11" x2="17" y2="3"/>
  </svg>`,

  copy: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <rect x="7" y="7" width="10" height="10" rx="1.5"/>
    <path d="M4 13V4a1 1 0 011-1h9"/>
  </svg>`,

  home: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 9.5L10 3l7 6.5v7.5a1 1 0 01-1 1H4a1 1 0 01-1-1V9.5z"/>
    <path d="M7.5 18V11h5v7"/>
  </svg>`,

  albums: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <rect x="5" y="4" width="12" height="13" rx="2"/>
    <path d="M3 7v9a2 2 0 002 2h9"/>
  </svg>`,

  plus: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
    <line x1="10" y1="4" x2="10" y2="16"/>
    <line x1="4" y1="10" x2="16" y2="10"/>
  </svg>`,

  edit: `<svg width="15" height="15" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M11 4H4a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-7"/>
    <path d="M14.5 2.5a2.121 2.121 0 013 3L9 14l-4 1 1-4 8.5-8.5z"/>
  </svg>`,

  group: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 6h14M3 10h14M3 14h14"/>
    <rect x="2" y="3" width="16" height="14" rx="2"/>
  </svg>`,

  folderMove: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 5a2 2 0 012-2h4l2 2h6a2 2 0 012 2v2H3V5z"/>
    <path d="M3 9v7a2 2 0 002 2h6"/>
    <path d="M13 14l4 0"/>
    <path d="M15 12l2 2-2 2"/>
  </svg>`,

  folderAdd: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 5a2 2 0 012-2h4l2 2h6a2 2 0 012 2v2H3V5z"/>
    <path d="M3 9v7a2 2 0 002 2h7"/>
    <line x1="16" y1="13" x2="16" y2="19"/>
    <line x1="13" y1="16" x2="19" y2="16"/>
  </svg>`,

  tag: `<svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M3 3h6l9 9-6 6-9-9V3z"/>
    <circle cx="7" cy="7" r="1.5" fill="currentColor"/>
  </svg>`,

  lock: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <rect x="3.5" y="8" width="13" height="10" rx="2.5"/>
    <path d="M6.5 8V5.5a3.5 3.5 0 017 0V8"/>
    <circle cx="10" cy="13" r="1.5" fill="currentColor"/>
  </svg>`,

  unlock: `<svg width="18" height="18" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <rect x="3.5" y="8" width="13" height="10" rx="2.5"/>
    <path d="M6.5 8V5.5a3.5 3.5 0 017 0"/>
    <circle cx="10" cy="13" r="1.5" fill="currentColor"/>
  </svg>`,

  fingerprint: `<svg width="34" height="34" viewBox="0 0 16 16" fill="currentColor">
    <path d="m 8.074219 0 c -1.203125 -0.0117188 -2.40625 0.285156 -3.492188 0.890625 c -0.480469 0.269531 -0.652343 0.878906 -0.382812 1.359375 c 0.269531 0.484375 0.878906 0.65625 1.359375 0.386719 c 1.550781 -0.867188 3.4375 -0.847657 4.972656 0.050781 c 1.53125 0.898438 2.46875 2.535156 2.46875 4.3125 v 1 c 0 0.550781 0.449219 1 1 1 s 1 -0.449219 1 -1 v -1 c 0 -0.019531 0 -0.039062 -0.003906 -0.054688 c -0.019532 -2.460937 -1.332032 -4.738281 -3.457032 -5.984374 c -1.070312 -0.628907 -2.265624 -0.9492192 -3.46875 -0.960938 z m -5.199219 2.832031 c -0.066406 0 -0.132812 0.007813 -0.195312 0.023438 c -0.257813 0.058593 -0.484376 0.21875 -0.625 0.445312 c -0.6875 1.109375 -1.054688 2.390625 -1.054688 3.699219 v 5.0625 c 0 0.550781 0.449219 1 1 1 s 1 -0.449219 1 -1 v -5.0625 c 0 -0.933594 0.261719 -1.851562 0.753906 -2.644531 c 0.292969 -0.46875 0.148438 -1.082031 -0.320312 -1.375 c -0.167969 -0.105469 -0.363282 -0.15625 -0.558594 -0.148438 z m 5.125 0.167969 c -2.199219 0 -4 1.800781 -4 4 v 1 c 0 0.550781 0.449219 1 1 1 s 1 -0.449219 1 -1 v -1 c 0 -1.117188 0.882812 -2 2 -2 s 2 0.882812 2 2 v 5 s 0.007812 0.441406 0.175781 0.941406 s 0.5 1.148438 1.117188 1.765625 c 0.390625 0.390625 1.023437 0.390625 1.414062 0 s 0.390625 -1.023437 0 -1.414062 c -0.382812 -0.382813 -0.550781 -0.734375 -0.632812 -0.984375 s -0.074219 -0.308594 -0.074219 -0.308594 v -5 c 0 -2.199219 -1.800781 -4 -4 -4 z m 0 3 c -0.550781 0 -1 0.449219 -1 1 v 5 s 0 0.59375 0.144531 1.320312 c 0.144531 0.726563 0.414063 1.652344 1.148438 2.386719 c 0.390625 0.390625 1.023437 0.390625 1.414062 0 s 0.390625 -1.023437 0 -1.414062 c -0.265625 -0.265625 -0.496093 -0.839844 -0.601562 -1.363281 c -0.105469 -0.523438 -0.105469 -0.929688 -0.105469 -0.929688 v -5 c 0 -0.550781 -0.449219 -1 -1 -1 z m -3 4 c -0.550781 0 -1 0.449219 -1 1 v 3 c 0 0.550781 0.449219 1 1 1 s 1 -0.449219 1 -1 v -3 c 0 -0.550781 -0.449219 -1 -1 -1 z m 9 0 c -0.550781 0 -1 0.449219 -1 1 s 0.449219 1 1 1 s 1 -0.449219 1 -1 s -0.449219 -1 -1 -1 z"/>
  </svg>`,

  shield: `<svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
    <path d="M10 2s6 2.5 6 7c0 5-6 9-6 9s-6-4-6-9c0-4.5 6-7 6-7z"/>
    <polyline points="7.5 9.5 9 11 12.5 7.5"/>
  </svg>`,

  eye: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M1.5 10S5 4.5 10 4.5s8.5 5.5 8.5 5.5-3.5 5.5-8.5 5.5S1.5 10 1.5 10z"/>
    <circle cx="10" cy="10" r="3"/>
  </svg>`,

  eyeOff: `<svg width="16" height="16" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
    <path d="M17.94 17.94A10.07 10.07 0 0110 15.5C5 15.5 1.5 10 1.5 10a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0110 4.5c5 0 8.5 5.5 8.5 5.5a18.5 18.5 0 01-2.16 3.19"/>
    <line x1="2" y1="2" x2="18" y2="18"/>
  </svg>`,

  arrowRight: `<svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
    <path fill-rule="evenodd" d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"/>
  </svg>`
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = Icons;
}
