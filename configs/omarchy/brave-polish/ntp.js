// Omarchy Brave Polish — NTP logic: clock, date, search, top sites.
//
// Works in two modes:
// - chrome-extension:// (extension loaded): dynamic topSites + theme detector.
// - file:// (NewTabPageLocation policy): curated static tiles, no chrome.*
//   APIs. ntp.css still re-reads from disk per load, so theme changes
//   hot-apply on every new tab in both modes.
(() => {
  // Footer guard (DOM half): remove any node Brave-Origin injects into the
  // NTP (attribution footer, customize pill, promos). Only Omarchy's own
  // elements survive. The CSS half in ntp.css hides them even before JS runs.
  const OURS = [".omarchy-clock", ".omarchy-date", ".omarchy-search", ".omarchy-topsites"];
  const isOurs = (el) =>
    el.nodeType !== 1 ||
    OURS.some((sel) => el.matches(sel) || el.closest(sel)) ||
    /^(SCRIPT|STYLE|LINK)$/.test(el.tagName);
  const sweep = () => {
    document.querySelectorAll("body > *").forEach((el) => {
      if (!isOurs(el)) el.remove();
    });
  };
  sweep();
  try {
    new MutationObserver((mutations) => {
      for (const m of mutations) {
        m.addedNodes.forEach((n) => {
          if (n.nodeType === 1 && !isOurs(n)) n.remove();
        });
      }
      // Late async injection: sweep again in case nodes landed deeper.
      sweep();
    }).observe(document.documentElement, {childList: true, subtree: true});
  } catch (_) {}
  // One delayed sweep for sluggish injections.
  setTimeout(sweep, 3000);

  const hasChrome = typeof chrome !== "undefined" && chrome.runtime && chrome.runtime.getURL;

  // Theme-change detector (extension mode only): theme.json is re-read from
  // disk on every new tab, so the first new tab after `omarchy theme set`
  // reloads the extension once and the toolbar/tabs re-theme.
  // file:// mode needs nothing: ntp.css re-reads per load by itself.
  if (hasChrome) {
    try {
      fetch(chrome.runtime.getURL("theme.json"))
        .then((r) => (r.ok ? r.text() : ""))
        .then((text) => {
          if (!text) return;
          let prev = null;
          try {
            prev = localStorage.getItem("omarchy-theme-json");
          } catch (_) {}
          if (prev && prev !== text) {
            try {
              localStorage.setItem("omarchy-theme-json", text);
            } catch (_) {}
            chrome.runtime.reload();
          } else if (!prev) {
            try {
              localStorage.setItem("omarchy-theme-json", text);
            } catch (_) {}
          }
        })
        .catch(() => {});
    } catch (_) {}
  }

  const clockEl = document.getElementById("clock");
  const dateEl = document.getElementById("date");

  const tick = () => {
    const now = new Date();
    clockEl.textContent =
      String(now.getHours()).padStart(2, "0") +
      ":" +
      String(now.getMinutes()).padStart(2, "0");
    dateEl.textContent = now.toLocaleDateString(undefined, {
      weekday: "long",
      month: "long",
      day: "numeric",
    });
  };
  tick();
  setInterval(tick, 10000);

  document.getElementById("search").addEventListener("submit", (e) => {
    e.preventDefault();
    const q = document.getElementById("q").value.trim();
    if (!q) return;
    // URLs navigate directly; everything else goes to Brave Search.
    const isUrl = /^(https?:\/\/|[\w-]+\.[\w]{2,})/.test(q);
    location.href = isUrl
      ? (q.startsWith("http") ? q : "https://" + q)
      : "https://search.brave.com/search?q=" + encodeURIComponent(q);
  });

  function letter(host) {
    const d = document.createElement("div");
    d.className = "tile-letter";
    d.textContent = (host || "?").charAt(0).toUpperCase();
    return d;
  }

  function addTile(url, title) {
    const box = document.getElementById("topsites");
    let host = "";
    try {
      host = new URL(url).hostname.replace(/^www\./, "");
    } catch (_) {}
    const a = document.createElement("a");
    a.className = "omarchy-top";
    a.href = url;
    a.title = title || url;
    const fav = document.createElement("img");
    fav.alt = "";
    fav.src = "https://www.google.com/s2/favicons?domain=" + host + "&sz=64";
    fav.onerror = () => {
      fav.replaceWith(letter(host));
    };
    a.appendChild(fav);
    const label = document.createElement("span");
    label.textContent = title || host || url;
    a.appendChild(label);
    box.appendChild(a);
  }

  // Curated fallback for file:// mode (no chrome.topSites there).
  const STATIC_TILES = [
    ["https://www.youtube.com/", "YouTube"],
    ["https://github.com/", "GitHub"],
    ["https://developers.google.com/", "Google for Developers"],
    ["https://search.brave.com/", "Brave Search"],
  ];

  // Top sites via chrome.topSites (needs "topSites" permission).
  if (hasChrome && chrome.topSites && chrome.topSites.get) {
    try {
      chrome.topSites.get((sites) => {
        if (sites && sites.length) {
          sites.slice(0, 8).forEach((s) => addTile(s.url, s.title));
        } else {
          STATIC_TILES.forEach(([url, title]) => addTile(url, title));
        }
      });
    } catch (_) {
      STATIC_TILES.forEach(([url, title]) => addTile(url, title));
    }
  } else {
    STATIC_TILES.forEach(([url, title]) => addTile(url, title));
  }
})();
