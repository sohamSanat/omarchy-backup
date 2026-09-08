// Omarchy Brave Polish — universal loader (runs on ALL websites).
//
// Same hot-apply pattern as loader.js: re-fetch global.css from disk on every
// navigation and inject inline. Keeps every site on the Omarchy background,
// follows the theme color-scheme, and themes selection/scrollbars/focus.
// Site-specific deep polish (YouTube/GitHub/Reddit) is layered by loader.js.
(async () => {
  try {
    const css = await fetch(chrome.runtime.getURL("global.css")).then((r) => {
      if (!r.ok) throw new Error("global.css missing");
      return r.text();
    });
    const style = document.createElement("style");
    style.id = "omarchy-brave-global";
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);
  } catch (e) {
    // Theme not compiled yet (omarchy-sync-brave --sync fixes it). Fail silent.
  }
})();
