// ==============================================================================
// Omarchy Dynamic Search & Quick Access for Brave-Origin New Tab Page
// ------------------------------------------------------------------------------
// Consumed by: ~/.config/omarchy/brave-polish/ntp.html
// Replicates the exact feel, keyboard navigation, and theme matching of Zen Browser.
// ==============================================================================

(() => {
  // 1. Guard against unexpected browser-injected elements outside our root
  const sweep = () => {
    document.querySelectorAll("body > *").forEach((el) => {
      if (
        el.nodeType === 1 &&
        !/^(SCRIPT|STYLE|LINK)$/.test(el.tagName) &&
        el.id !== "omarchy-ntp-root"
      ) {
        el.remove();
      }
    });
  };
  sweep();
  try {
    new MutationObserver((mutations) => {
      for (const m of mutations) {
        m.addedNodes.forEach((n) => {
          if (
            n.nodeType === 1 &&
            !/^(SCRIPT|STYLE|LINK)$/.test(n.tagName) &&
            n.id !== "omarchy-ntp-root"
          ) {
            n.remove();
          }
        });
      }
    }).observe(document.documentElement, { childList: true, subtree: true });
  } catch (_) {}

  // 2. Default Curated Shortcuts
  const DEFAULT_SHORTCUTS = [
    { title: "YouTube", url: "https://www.youtube.com", tag: "Video", icon: "youtube" },
    { title: "GitHub", url: "https://github.com", tag: "Code", icon: "github" },
    { title: "Reddit", url: "https://www.reddit.com", tag: "Community", icon: "reddit" },
    { title: "Claude", url: "https://claude.ai", tag: "AI", icon: "ai" },
    { title: "ChatGPT", url: "https://chatgpt.com", tag: "AI", icon: "ai" }
  ];

  // SVG Icons
  const ICONS = {
    search: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>`,
    globe: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="2" y1="12" x2="22" y2="12"></line><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path></svg>`,
    youtube: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>`,
    github: `<svg viewBox="0 0 24 24" fill="currentColor"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"/></svg>`,
    reddit: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0zm5.01 4.744c.688 0 1.25.561 1.25 1.249a1.25 1.25 0 0 1-2.498.056l-2.597-.547-.8 3.747c1.824.07 3.48.632 4.674 1.488.308-.309.73-.491 1.207-.491.968 0 1.754.786 1.754 1.754 0 .716-.435 1.333-1.01 1.614a3.111 3.111 0 0 1 .042.52c0 2.694-3.13 4.87-7.004 4.87-3.874 0-7.004-2.176-7.004-4.87 0-.183.015-.366.043-.534A1.748 1.748 0 0 1 4.028 12c0-.968.786-1.754 1.754-1.754.463 0 .868.182 1.17.472 1.192-.857 2.842-1.42 4.66-1.492l.983-4.606 3.415.724a1.248 1.248 0 0 1 1.01-.6zM8.38 12.02a1.24 1.24 0 0 0-1.24 1.24c0 .684.556 1.24 1.24 1.24.685 0 1.24-.556 1.24-1.24 0-.684-.555-1.24-1.24-1.24zm7.24 0a1.24 1.24 0 0 0-1.24 1.24c0 .684.556 1.24 1.24 1.24.685 0 1.24-.556 1.24-1.24 0-.684-.555-1.24-1.24-1.24zm-3.62 3.62c-.75 0-1.45.2-1.98.54a.434.434 0 0 0 .47.73c.4-.26.96-.41 1.51-.41.55 0 1.11.15 1.51.41a.434.434 0 1 0 .47-.73c-.53-.34-1.23-.54-1.98-.54z"/></svg>`,
    ai: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/></svg>`
  };

  let activeShortcuts = [...DEFAULT_SHORTCUTS];
  let selectedIndex = 0;
  let currentRows = [];

  // Load top sites from chrome API if available
  if (typeof chrome !== "undefined" && chrome.topSites && chrome.topSites.get) {
    chrome.topSites.get((sites) => {
      if (sites && sites.length > 0) {
        const mapped = sites.slice(0, 7).map((s) => {
          let host = "";
          try {
            host = new URL(s.url).hostname.replace(/^www\./, "");
          } catch (_) {
            host = s.url;
          }
          let icon = "globe";
          if (host.includes("youtube")) icon = "youtube";
          else if (host.includes("github")) icon = "github";
          else if (host.includes("reddit")) icon = "reddit";
          else if (host.includes("claude") || host.includes("chatgpt") || host.includes("openai")) icon = "ai";

          return {
            title: s.title || host,
            url: s.url,
            tag: host,
            icon: icon
          };
        });

        // Merge without duplicate URLs
        const urls = new Set(mapped.map((m) => m.url));
        DEFAULT_SHORTCUTS.forEach((d) => {
          if (!urls.has(d.url)) mapped.push(d);
        });
        activeShortcuts = mapped.slice(0, 8);
        render();
      }
    });
  }

  // 3. Elements
  const input = document.getElementById("omarchy-search-input");
  const clearBtn = document.getElementById("omarchy-search-clear");
  const resultsList = document.getElementById("omarchy-results-list");

  // URL resolution helpers
  const isUrl = (str) => {
    str = str.trim();
    if (/^(https?:\/\/|file:\/\/|chrome:\/\/|chrome-extension:\/\/)/i.test(str)) return true;
    if (/^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(:\d+)?(\/.*)?$/i.test(str)) return true;
    if (/^localhost(:\d+)?(\/.*)?$/i.test(str)) return true;
    if (/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?(\/.*)?$/i.test(str)) return true;
    return false;
  };

  const resolveTarget = (query) => {
    const trimmed = query.trim();
    if (!trimmed) return "";
    if (isUrl(trimmed)) {
      if (!/^[a-zA-Z]+:\/\//i.test(trimmed)) {
        return "https://" + trimmed;
      }
      return trimmed;
    }
    return `https://www.google.com/search?q=${encodeURIComponent(trimmed)}`;
  };

  const navigate = (url) => {
    if (!url) return;
    window.location.href = url;
  };

  // 4. Render Results
  const render = () => {
    const query = input.value.trim();
    resultsList.innerHTML = "";
    currentRows = [];

    if (!query) {
      // Empty input: render quick access shortcuts
      clearBtn.style.display = "none";
      currentRows = activeShortcuts;
    } else {
      // Input has text: render search action + filtered shortcuts
      clearBtn.style.display = "flex";
      const target = resolveTarget(query);
      const isDirect = isUrl(query);

      const actionRow = {
        title: isDirect ? `Open ${query}` : `Search Google for "${query}"`,
        url: target,
        tag: isDirect ? "Jump" : "Search",
        icon: isDirect ? "globe" : "search"
      };

      const lower = query.toLowerCase();
      const matchedShortcuts = activeShortcuts.filter(
        (s) => s.title.toLowerCase().includes(lower) || s.url.toLowerCase().includes(lower)
      );

      currentRows = [actionRow, ...matchedShortcuts];
    }

    if (selectedIndex >= currentRows.length) {
      selectedIndex = Math.max(0, currentRows.length - 1);
    }

    currentRows.forEach((item, index) => {
      const row = document.createElement("div");
      row.className = `omarchy-result-row ${index === selectedIndex ? "selected" : ""}`;
      row.dataset.url = item.url;
      row.dataset.index = index;

      const iconContainer = document.createElement("div");
      iconContainer.className = "omarchy-result-icon";
      iconContainer.innerHTML = ICONS[item.icon] || ICONS.globe;

      const content = document.createElement("div");
      content.className = "omarchy-result-content";

      const title = document.createElement("div");
      title.className = "omarchy-result-title";
      title.textContent = item.title;

      const url = document.createElement("div");
      url.className = "omarchy-result-url";
      try {
        const u = new URL(item.url);
        url.textContent = u.hostname.replace(/^www\./, "") + (u.pathname !== "/" ? u.pathname : "");
      } catch (_) {
        url.textContent = item.url;
      }

      content.appendChild(title);
      content.appendChild(url);

      const tag = document.createElement("div");
      tag.className = "omarchy-result-tag";
      tag.textContent = item.tag;

      row.appendChild(iconContainer);
      row.appendChild(content);
      row.appendChild(tag);

      row.addEventListener("click", () => navigate(item.url));
      row.addEventListener("mouseenter", () => {
        selectedIndex = index;
        updateSelection();
      });

      resultsList.appendChild(row);
    });
  };

  const updateSelection = () => {
    const rows = resultsList.querySelectorAll(".omarchy-result-row");
    rows.forEach((r, idx) => {
      if (idx === selectedIndex) {
        r.classList.add("selected");
        r.scrollIntoView({ block: "nearest", behavior: "smooth" });
      } else {
        r.classList.remove("selected");
      }
    });
  };

  // 5. Input and Keyboard Event Listeners
  input.addEventListener("input", () => {
    selectedIndex = 0;
    render();
  });

  input.addEventListener("keydown", (e) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (currentRows.length > 0) {
        selectedIndex = (selectedIndex + 1) % currentRows.length;
        updateSelection();
      }
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      if (currentRows.length > 0) {
        selectedIndex = (selectedIndex - 1 + currentRows.length) % currentRows.length;
        updateSelection();
      }
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (currentRows.length > 0 && selectedIndex >= 0 && selectedIndex < currentRows.length) {
        navigate(currentRows[selectedIndex].url);
      } else if (input.value.trim()) {
        navigate(resolveTarget(input.value));
      }
    } else if (e.key === "Escape") {
      if (input.value) {
        input.value = "";
        selectedIndex = 0;
        render();
      } else {
        input.blur();
      }
    }
  });

  clearBtn.addEventListener("click", () => {
    input.value = "";
    selectedIndex = 0;
    render();
    input.focus();
  });

  // Keep input focused when user returns to tab
  window.addEventListener("focus", () => {
    if (document.activeElement !== input) {
      input.focus();
    }
  });

  // Initial render & focus
  render();
  setTimeout(() => input.focus(), 50);

  // 6. Dynamic Theme Live Adaptation (Polling + Event-driven)
  let cachedTheme = null;

  const applyThemeTokens = (t) => {
    const root = document.documentElement;
    root.style.setProperty("--omarchy-bg", t.background);
    root.style.setProperty("--omarchy-fg", t.foreground);
    root.style.setProperty("--omarchy-accent", t.accent);
    root.style.setProperty("--omarchy-muted", t.muted);
    root.style.setProperty("--omarchy-selection-bg", t.selectionBackground);
    root.style.setProperty("--omarchy-selection-fg", t.selectionForeground);

    // Dynamic surfaces
    root.style.setProperty(
      "--omarchy-surface",
      `color-mix(in srgb, ${t.foreground} 7%, ${t.background})`
    );
    root.style.setProperty(
      "--omarchy-surface-hover",
      `color-mix(in srgb, ${t.foreground} 13%, ${t.background})`
    );
    root.style.setProperty(
      "--omarchy-surface-active",
      `color-mix(in srgb, ${t.foreground} 20%, ${t.background})`
    );
    root.style.setProperty(
      "--omarchy-border",
      `color-mix(in srgb, ${t.foreground} 16%, transparent)`
    );
    root.style.setProperty(
      "--omarchy-border-subtle",
      `color-mix(in srgb, ${t.foreground} 10%, transparent)`
    );
    root.style.setProperty(
      "--omarchy-card-bg",
      `color-mix(in srgb, ${t.background} 94%, ${t.foreground} 6%)`
    );

    // Refresh stylesheet link timestamp
    const styleLink = document.getElementById("omarchy-ntp-style");
    if (styleLink) {
      styleLink.href = `ntp.css?t=${Date.now()}`;
    }
  };

  const checkTheme = async () => {
    try {
      const res = await fetch(`theme.json?t=${Date.now()}`);
      if (!res.ok) return;
      const theme = await res.json();
      if (!cachedTheme) {
        cachedTheme = theme;
        return;
      }
      if (
        theme.background !== cachedTheme.background ||
        theme.accent !== cachedTheme.accent ||
        theme.foreground !== cachedTheme.foreground ||
        theme.mode !== cachedTheme.mode
      ) {
        cachedTheme = theme;
        applyThemeTokens(theme);
      }
    } catch (_) {}
  };

  // Poll every 1.5 seconds for instant theme sync
  setInterval(checkTheme, 1500);
  window.addEventListener("focus", checkTheme);
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") checkTheme();
  });
})();
