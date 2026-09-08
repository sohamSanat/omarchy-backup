// Omarchy Brave Polish — per-site loader.
//
// Runs at document_start on YouTube/GitHub/Reddit. Fetches the compiled
// brave-polish.css (regenerated on every `omarchy theme set`) from disk on
// each navigation and injects it as an inline <style> element.
//
// Because the CSS is re-read from the unpacked extension directory on every
// page load, theme changes hot-apply on next navigation — no browser restart,
// no extension reload, no Dark Reader patching.
(async () => {
  const host = location.hostname;

  // Scope marker lets brave-polish.css target each site precisely.
  // Unrelated websites never match content_scripts, so they stay untouched.
  if (host.includes("youtube.com")) {
    document.documentElement.setAttribute("youtube-omarchy", "");
  } else if (host === "github.com" || host.endsWith(".github.com")) {
    document.documentElement.setAttribute("github-omarchy", "");
  } else if (host.endsWith("reddit.com")) {
    document.documentElement.setAttribute("reddit-omarchy", "");
  } else {
    return;
  }

  try {
    const css = await fetch(chrome.runtime.getURL("polish.css")).then((r) => {
      if (!r.ok) throw new Error("polish.css missing");
      return r.text();
    });
    const style = document.createElement("style");
    style.id = "omarchy-brave-polish";
    style.textContent = css;
    (document.head || document.documentElement).appendChild(style);
  } catch (e) {
    // Theme not compiled yet (omarchy-sync-brave --sync fixes it). Fail silent.
  }
})();
