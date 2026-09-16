// Omarchy Brave Polish — Zen-aesthetic New Tab Page Controller
(() => {
  // Update live clock
  const updateClock = () => {
    const clockEl = document.getElementById("clock");
    if (!clockEl) return;
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, "0");
    const minutes = String(now.getMinutes()).padStart(2, "0");
    clockEl.textContent = `${hours}:${minutes}`;
  };

  let currentThemeName = "";
  const syncTheme = async () => {
    try {
      const res = await fetch(`theme.json?_t=${Date.now()}`);
      if (res.ok) {
        const data = await res.json();
        const themeEl = document.getElementById("theme-name");
        if (themeEl && data.name) {
          const cap = data.name.charAt(0).toUpperCase() + data.name.slice(1);
          themeEl.textContent = cap;
        }
        if (currentThemeName && data.name && data.name !== currentThemeName) {
          // Theme changed! Reload ntp stylesheet dynamically
          const link = document.querySelector('link[href*="ntp.css"]');
          if (link) {
            link.href = `ntp.css?_t=${Date.now()}`;
          }
        }
        if (data.name) currentThemeName = data.name;
      }
    } catch (_) {}
  };

  // Handle Search input and navigation
  const setupSearch = () => {
    const form = document.getElementById("search-form");
    const input = document.getElementById("search-input");
    if (!form || !input) return;

    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const raw = (input.value || "").trim();
      if (!raw) return;

      // Detect URLs vs search terms
      if (/^https?:\/\//i.test(raw)) {
        window.location.href = raw;
      } else if (/^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+/i.test(raw) && !raw.includes(" ")) {
        window.location.href = "https://" + raw;
      } else {
        window.location.href = "https://www.google.com/search?q=" + encodeURIComponent(raw);
      }
    });

    // Keyboard shortcuts: '/' or 'Ctrl+K' focuses the search input
    window.addEventListener("keydown", (e) => {
      if (e.key === "/" && document.activeElement !== input) {
        e.preventDefault();
        input.focus();
        input.select();
      } else if ((e.ctrlKey || e.metaKey) && (e.key === "k" || e.key === "K")) {
        e.preventDefault();
        input.focus();
        input.select();
      } else if (e.key === "Escape" && document.activeElement === input) {
        input.blur();
      }
    });

    // Autofocus input
    setTimeout(() => {
      input.focus();
    }, 50);
  };

  // Guard against Brave injected third-party widgets without touching our own markup
  const cleanupExternalInjections = () => {
    const allowed = new Set(["NTP-HEADER", "NTP-CENTER", "NTP-FOOTER", "SCRIPT", "STYLE", "LINK"]);
    document.querySelectorAll("body > *").forEach((el) => {
      const tag = el.tagName.toUpperCase();
      const cls = (el.className || "").toString().toUpperCase();
      const isOurNode = allowed.has(tag) || 
                        cls.includes("NTP-HEADER") || 
                        cls.includes("NTP-CENTER") || 
                        cls.includes("NTP-FOOTER");
      if (!isOurNode && el.nodeType === 1) {
        el.remove();
      }
    });
  };

  document.addEventListener("DOMContentLoaded", () => {
    updateClock();
    setInterval(updateClock, 1000);
    syncTheme();
    setInterval(syncTheme, 2500);
    window.addEventListener("focus", syncTheme);
    setupSearch();
    cleanupExternalInjections();
  });

  // If DOM is already ready
  if (document.readyState === "complete" || document.readyState === "interactive") {
    updateClock();
    setInterval(updateClock, 1000);
    syncTheme();
    setInterval(syncTheme, 2500);
    window.addEventListener("focus", syncTheme);
    setupSearch();
    cleanupExternalInjections();
  }
})();
