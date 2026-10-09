// Wallpaper Flare integration helpers for the Omagen wallpaper browser.
//
// These run inside the WebEngine page context and communicate back to QML via
// console messages with the [[OMAGEN]] prefix (captured through
// WebEngineView.javaScriptConsoleMessage).

function injectSource() {
    return "(function () {" +
        " if (window.__omagenWallpaperHook) return;" +
        " window.__omagenWallpaperHook = true;" +
        " var badge = document.createElement('div');" +
        " badge.id = '__omagen_badge';" +
        " badge.textContent = '\u2b07 Use in Omagen';" +
        " badge.style.cssText = 'position:fixed;z-index:2147483647;display:none;background:#101216;color:#f5f7fb;padding:6px 12px;border-radius:999px;font:600 13px/1 system-ui,sans-serif;box-shadow:0 2px 12px rgba(0,0,0,.4);cursor:pointer;border:1px solid rgba(255,255,255,.16);';" +
        " document.documentElement.appendChild(badge);" +
        " var target = null;" +
        " var hideTimer = null;" +
        " function show(img) {" +
        "  target = img;" +
        "  var r = img.getBoundingClientRect();" +
        "  badge.style.display = 'block';" +
        "  var chipWidth = badge.offsetWidth || 140;" +
        "  badge.style.left = Math.max(8, Math.min(r.right - chipWidth - 8, window.innerWidth - chipWidth - 8)) + 'px';" +
        "  badge.style.top = Math.max(8, Math.min(r.top + 8, window.innerHeight - 40)) + 'px';" +
        " }" +
        " function hideSoon() {" +
        "  clearTimeout(hideTimer);" +
        "  hideTimer = setTimeout(function () { badge.style.display = 'none'; }, 600);" +
        " }" +
        " document.addEventListener('mouseover', function (e) {" +
        "  var t = e.target;" +
        "  if (t === badge) { clearTimeout(hideTimer); return; }" +
        "  if (t && t.tagName === 'IMG') {" +
        "   var w = t.naturalWidth || t.width;" +
        "   if (w >= 120) show(t);" +
        "  }" +
        " }, true);" +
        " document.addEventListener('mouseout', function (e) {" +
        "  if (e.target === badge || (e.target && e.target.tagName === 'IMG')) hideSoon();" +
        " }, true);" +
        " badge.addEventListener('click', function () {" +
        "  if (target) {" +
        "   var src = target.currentSrc || target.src;" +
        "   console.log('[[OMAGEN]] image:' + src);" +
        "   badge.style.display = 'none';" +
        "  }" +
        " });" +
        "})();";
}

function downloadViaHref(url, filename) {
    var quotedUrl = JSON.stringify(url);
    var quotedName = JSON.stringify(filename || "omagen-wallpaper.jpg");
    return "(function(){var a=document.createElement('a');a.href=" + quotedUrl +
        ";a.download=" + quotedName + ";document.body.appendChild(a);a.click();a.remove();})();";
}

function filenameFor(url) {
    try {
        var path = new URL(url).pathname;
        var segments = path.split('/');
        var name = segments[segments.length - 1];
        return name === "" ? "omagen-wallpaper.jpg" : name;
    } catch (error) {
        return "omagen-wallpaper.jpg";
    }
}
