import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui
import "MenuModel.js" as MenuModel
import "Keybinds.js" as Keybinds
import "AppSearch.js" as AppSearch
import "RaycastSearch.js" as RaycastSearch

// Switchboard — a grid launcher for Omarchy.
//
// Same menu definition as the built-in menu (default + user
// omarchy-menu.jsonc, guards, providers, apps), different surface:
//
//   * items sit in a grid; typing always searches the current menu and its
//     children, arrows move, Enter opens, Escape clears / goes up / closes
//   * tiles show the global Hyprland shortcut that opens the same thing
//   * `!cmd` runs a shell command in a new terminal; `~/path` or `/path`
//     opens it with xdg-open
//   * the footer shows a rotating shortcut tip
//
// It also serves the `select` / `input` payloads that `omarchy-menu-select`
// and friends send to `omarchy.menu`, since enabling this plugin routes that
// id here (see manifest `omarchy.clonedFrom`).
Item {
  id: root

  // Injected by omarchy-shell when this plugin is summoned.
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null
  readonly property string pluginDir: (manifest && manifest.__sourceDir)
    ? String(manifest.__sourceDir)
    : (manifest && manifest.id ? Quickshell.env("HOME") + "/.config/omarchy/plugins/" + manifest.id : Quickshell.env("HOME") + "/.config/omarchy/plugins/krall.switchboard")

  // --------------------------------------------------------------- lifecycle

  function resetToCleanState() {
    root.filterText = ""
    root.textCursorPos = 0
    root.activeMenu = "apps"
    root.navStack = []
    root.selectedIndex = 0
    root.cursorActive = true
    if (typeof gridFlick !== "undefined" && gridFlick) gridFlick.contentY = 0
    root.mode = "menu"
    root.dmenuPrompt = ""
    root.dmenuOptions = []
    root.selectionFile = ""
    root.doneFile = ""
    root.deleteConfirmOpen = false
    root.deleteTarget = null
    root.ensureAppRows()
    root.rebuildDisplay(true)
  }

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }

    if (payload.fontFamily) root.fontFamily = payload.fontFamily

    if (payload.mode === "select" || payload.mode === "input") {
      root.openDmenu(payload)
    } else {
      root.resetToCleanState()
      var initial = payload.initialMenu || payload.menu
      if (initial && initial !== "root" && initial !== "apps") {
        if (initial === "control" || initial === "settings") initial = "root"
        root.openRoute(initial)
      } else {
        root.openExistingMenu("apps")
      }
      if (payload.query || payload.filter) {
        root.setFilter(String(payload.query || payload.filter))
      }
    }
  }

  function close() {
    root.cancel()
  }

  function refresh() {
    try {
      root.loadMenuFile(defaultMenuProc, root.defaultMenuPath)
      root.loadMenuFile(userMenuProc, root.userMenuPath)
      root.loadKeybinds(true)
      root.loadStatus()
      root.loadQuickLinks()
      root.loadExchangeRates()
      return "ok"
    } catch (e) {
      return "error: " + e
    }
  }

  function ping() { return "ok" }

  function statusReport() {
    return JSON.stringify({
      opened: root.opened,
      isClosing: root.isClosing,
      openProgress: root.openProgress,
      rowsLoaded: root.rowsLoaded,
      activeMenu: root.activeMenu,
      filterText: root.filterText,
      selectedIndex: root.selectedIndex,
      textCursorPos: root.textCursorPos,
      navStackCount: root.navStack ? root.navStack.length : 0,
      displayCount: displayModel.count,
      itemOrderCount: root.itemOrder ? root.itemOrder.length : 0,
      cardWidth: root.cardWidth,
      cardHeight: root.cardHeight,
      panelWidth: panel ? panel.width : -1,
      panelHeight: panel ? panel.height : -1,
      pluginDir: root.pluginDir
    })
  }

  function appCount() {
    return root.appLibrary ? root.appLibrary.sortedEntries("").length : 0
  }

  function testSearch(query) {
    var q = String(query || "")
    var smart = RaycastSearch.getSmartRows(q, {
      quickLinks: root.quickLinksList,
      exchangeRates: root.exchangeRates,
      localOffsetMin: root.localTzOffsetMin,
      fmhyResults: root.currentFmhyResults,
      fmhySearching: root.fmhySearching
    })
    var glyph = RaycastSearch.detectSearchGlyph(q, root.quickLinksList)
    return JSON.stringify({
      query: q,
      glyph: glyph,
      count: smart.length,
      first: smart.length > 0 ? {
        label: smart[0].label,
        detail: smart[0].detail,
        action: smart[0].action,
        kind: smart[0].kind,
        icon: smart[0].icon
      } : null
    })
  }

  // ---------------------------------------------------------------- tunables

  readonly property int keybindRefreshSeconds: 30

  // Input bounds. Everything the launcher parses comes from a helper script,
  // a provider, a guard batch, or a menu file — all producer-controlled — so
  // nothing is retained past these caps and no producer can hold the shell.
  readonly property int maxProcessChars: 256 * 1024   // per process output (UTF-16 units; ≤ 1 MiB of UTF-8)
  readonly property int maxProcessRecords: 4000       // lines kept per process
  readonly property int maxMenuFileBytes: 1024 * 1024 // per omarchy-menu.jsonc
  readonly property int providerTimeoutMs: 10 * 1000
  readonly property int guardTimeoutMs: 10 * 1000
  readonly property int helperTimeoutMs: 15 * 1000
  readonly property int updatesTimeoutMs: 120 * 1000
  readonly property int updateCheckMinutes: 30

  // ------------------------------------------------------------------- state

  property string fontFamily: Style.font.menuFamily
  property string defaultMenuPath: omarchyPath + "/default/omarchy/omarchy-menu.jsonc"
  property string userMenuPath: Quickshell.env("HOME") + "/.config/omarchy/extensions/omarchy-menu.jsonc"
  property string quickLinksPath: Quickshell.env("HOME") + "/.config/omarchy/quicklinks.json"
  property var quickLinksList: RaycastSearch.DEFAULT_QUICKLINKS
  property var exchangeRates: null
  property int localTzOffsetMin: -new Date().getTimezoneOffset()
  property var fmhyCache: ({})
  property var currentFmhyResults: []
  property bool fmhySearching: false
  property int textCursorPos: 0
  readonly property bool isMathMode: {
    if (!root.filterText) return false
    var q = root.filterText.trim()
    if (q.charAt(0) === "=") return true
    var lower = q.toLowerCase()
    if (lower === "calc" || lower === "math" || lower.indexOf("calc ") === 0 || lower.indexOf("math ") === 0) return true
    if (RaycastSearch.isMathQuery && RaycastSearch.isMathQuery(q)) return true
    if (RaycastSearch.evaluateMath(q) !== null) return true
    if (displayModel.count > 0) {
      var first = displayModel.get(0)
      if (first && (first.type === "calc" || (first.itemId && String(first.itemId).indexOf("!calc.") === 0))) return true
    }
    return false
  }

  onFilterTextChanged: {
    if (root.textCursorPos > root.filterText.length) {
      root.textCursorPos = root.filterText.length
    }
  }
  property var defaultMenuItems: []
  property var userMenuItems: []
  property bool opened: false
  property bool isClosing: false
  property real openProgress: 0.0

  readonly property real offscreenDistance: (panel && panel.height > 200)
    ? Math.round((panel.height + root.cardHeight + Style.space(12)) / 2 + Style.space(72))
    : Style.space(900)

  readonly property real slideOffsetY: Math.round(root.offscreenDistance * (1.0 - root.openProgress))

  NumberAnimation {
    id: openSlideAnim
    target: root
    property: "openProgress"
    to: 1.0
    duration: 360
    easing.type: Easing.OutCubic
    onFinished: {
      root.isClosing = false
    }
  }

  NumberAnimation {
    id: closeSlideAnim
    target: root
    property: "openProgress"
    to: 0.0
    duration: 250
    easing.type: Easing.InQuad
    onFinished: {
      root.isClosing = false
      root.finishDismiss()
    }
  }

  Timer {
    id: deferredRefreshTimer
    interval: 420
    repeat: false
    onTriggered: {
      if (!root.opened) return
      if (root.activeMenu !== "apps") root.evaluateGuards()
      root.pickTip()
      root.loadQuickLinks()
      root.loadExchangeRates()
      root.invalidateVolatileProvider(root.activeMenu)
      root.loadProviderForMenu(root.activeMenu)
      root.loadKeybinds(false)
      root.loadStatus()
    }
  }

  function startOpenAnimation() {
    closeSlideAnim.stop()
    root.isClosing = false
    if (root.openProgress >= 0.999 && !openSlideAnim.running) {
      root.openProgress = 1.0
      return
    }
    openSlideAnim.stop()
    openSlideAnim.from = root.openProgress
    openSlideAnim.to = 1.0
    var distanceRemaining = Math.max(0.0, 1.0 - root.openProgress)
    openSlideAnim.duration = Math.max(120, Math.round(360 * distanceRemaining))
    openSlideAnim.start()
  }

  function startCloseAnimation() {
    deferredRefreshTimer.stop()
    openSlideAnim.stop()
    root.isClosing = true
    if (root.openProgress <= 0.001 && !closeSlideAnim.running) {
      root.openProgress = 0.0
      root.isClosing = false
      root.finishDismiss()
      return
    }
    closeSlideAnim.stop()
    closeSlideAnim.from = root.openProgress
    closeSlideAnim.to = 0.0
    var distanceRemaining = Math.max(0.0, root.openProgress)
    closeSlideAnim.duration = Math.max(100, Math.round(250 * distanceRemaining))
    closeSlideAnim.start()
  }

  function finishDismiss() {
    root.resetToCleanState()
  }

  function dismissMenu() {
    if (!root.opened && !root.isClosing) return
    root.opened = false
    if (root.dmenuActive) root.finishRequest(null)
    root.startCloseAnimation()
  }
  property string mode: "menu"
  readonly property bool dmenuActive: mode === "select" || mode === "input"
  readonly property bool isPhoneMode: root.dmenuActive || (root.activeMenu !== "apps" && root.activeMenu !== "root")
  onIsPhoneModeChanged: {
    root.rebuildDisplay()
  }
  property string dmenuPrompt: ""
  property var dmenuOptions: []
  property string selectionFile: ""
  property string doneFile: ""
  property int dmenuWidth: 300
  property int dmenuMaxHeight: 0
  property bool requestActive: false
  property bool rowsLoaded: false
  property string activeMenu: "apps"
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property int requestSerial: 0
  property int applySerial: 0
  property var items: ({})
  property var itemOrder: []
  property var navStack: []
  property var providersLoaded: ({})
  property var providerQueue: []
  property int providerRevision: 0
  property int layoutSerial: 0

  // Grid geometry produced by decorateRows(); read by the view.
  property int columns: 2
  property int rowCount: 0
  property int gridContentHeight: 0

  // Global shortcut hints and the footer tip.
  property var binds: []
  property var bindDefaults: ({})
  property var menuShortcuts: ({})
  property var appShortcuts: ({})
  property var tip: null
  property double keybindsLoadedAt: 0

  // Header facts.
  property string themeName: ""
  property string versionText: ""
  property int updateCount: 0

  QtObject {
    id: fallbackAppLibrary

    signal appsChanged()

    function entryName(entry) {
      return AppSearch.entryName(entry)
    }

    function entrySubtext(entry) {
      return AppSearch.entrySubtext(entry)
    }

    function sortedEntries(query) {
      var values = (typeof DesktopEntries !== "undefined" && DesktopEntries.applications && DesktopEntries.applications.values) ? DesktopEntries.applications.values : []
      return AppSearch.sortedEntries(values, query, function(entry) {
        return !!(entry && entry.noDisplay)
      })
    }

    function iconSource(icon) {
      var value = String(icon || "")
      if (value.length === 0) return Quickshell.iconPath("application-x-executable", true)
      if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
      if (value.charAt(0) === "/") return Util.fileUrl(value)
      var themed = Quickshell.iconPath(value, true)
      if (themed.length > 0) return themed
      return Quickshell.iconPath("application-x-executable", true)
    }

    function refreshIcons() {}

    function launch(desktopId, name) {
      var id = String(desktopId || "")
      if (!id) return
      Util.execDetached("uwsm-app -- gtk-launch " + Util.shellQuote(id + ".desktop"))
    }

    function remove(desktopId, name) {
      var id = String(desktopId || "")
      if (!id) return
      Util.execDetached(Util.shellQuote(root.omarchyPath + "/bin/omarchy-remove-launcher-entry") + " " + Util.shellQuote(id) + " " + Util.shellQuote(String(name || id)))
    }
  }

  Connections {
    target: typeof DesktopEntries !== "undefined" && DesktopEntries.applications ? DesktopEntries.applications : null
    function onValuesChanged() {
      fallbackAppLibrary.appsChanged()
    }
  }

  readonly property var appLibrary: (root.shell && root.shell.appLibrary) ? root.shell.appLibrary : fallbackAppLibrary
  property var iconUrlCache: ({})
  property string lastRenderedMenu: ""
  property string lastRenderedFilter: ""
  property var cachedAppDefaultRows: []

  function resolveIconCached(rawIcon) {
    if (!rawIcon) return ""
    var cached = root.iconUrlCache[rawIcon]
    if (cached !== undefined) return cached
    var resolved = root.appLibrary ? root.appLibrary.iconSource(rawIcon) : ""
    root.iconUrlCache[rawIcon] = resolved
    return resolved
  }

  property bool deleteConfirmOpen: false
  property var deleteTarget: null
  onOpenedChanged: {
    if (!opened) {
      deleteConfirmOpen = false
      deleteTarget = null
    } else {
      root.textCursorPos = root.filterText.length
    }
  }

  // ------------------------------------------------------------------ theme
  //
  // Everything visual comes from the theme's [menu] section in shell.toml,
  // exactly like the built-in menu, so a theme that styles one styles both.

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color selectedBorder: Color.menu.selectedBorder
  property var selectedBorderSpec: Border.surfaceSpec("menu", "selected-border", selectedBorder, 0)
  readonly property int cornerRadius: Style.cornerRadius
  readonly property int tileRadius: Math.min(Style.cornerRadius, Style.space(10))
  readonly property real mutedOpacity: 0.5
  readonly property string currentBackgroundPath: Quickshell.env("HOME") + "/.local/state/omarchy/current/background"

  // ---------------------------------------------------------------- metrics

  property int contentMargin: Style.space(12)
  property int contentSpacing: Style.space(8)
  readonly property int tabletBarHeight: Style.space(26)
  property int headerHeight: Math.max(Style.space(24), Style.font.title + Style.space(4))
  property int searchHeight: Math.max(Style.space(42), Style.font.heading + Style.spacing.inputPaddingY * 2 + Style.space(4))
  property int footerHeight: Math.max(Style.space(16), Style.font.caption + Style.space(4))
  property int baseTileHeight: Math.max(Style.space(36), Style.font.body + Style.spacing.rowPaddingX * 2 - Style.space(4))
  property int detailTileHeight: Math.max(Style.space(50), Style.font.body + Style.font.caption + Style.spacing.rowPaddingX * 2 - Style.space(4))
  property int dividerHeight: Style.space(26)
  property int emptyHeight: Style.space(96)

  property string clockString: Qt.formatDateTime(new Date(), "HH:mm • ddd, MMM d")
  property string batteryText: "󰁹 100%"
  property string wifiText: "ONLINE"

  Timer {
    interval: 1000
    running: root.opened && !openSlideAnim.running && !closeSlideAnim.running
    repeat: true
    onTriggered: root.clockString = Qt.formatDateTime(new Date(), "HH:mm • ddd, MMM d")
  }

  readonly property bool detailRows: root.dmenuActive ? root.dmenuHasDetail : root.filterText.trim().length > 0
  property bool dmenuHasDetail: false
  readonly property int tileHeight: {
    if (root.isPhoneMode) return root.detailRows ? Style.space(64) : Style.space(56)
    if (root.dmenuActive) return root.detailRows ? root.detailTileHeight : root.baseTileHeight
    if (root.activeMenu === "apps" && !root.filterText.trim()) return Style.space(80)
    if (root.activeMenu === "root" && !root.filterText.trim()) return Style.space(64)
    if (root.filterText.trim().length > 0) return Style.space(68)
    return root.detailRows ? Style.space(68) : Style.space(52)
  }
  readonly property int tileGap: {
    if (root.isPhoneMode) return Style.space(8)
    if (root.activeMenu === "apps" && !root.filterText.trim()) return Style.space(8)
    if (root.activeMenu === "root" && !root.filterText.trim()) return Style.space(12)
    return Style.space(10)
  }

  readonly property int targetCardWidth: root.isPhoneMode
    ? Math.min(Style.space(390), (panel && panel.width > 300 ? panel.width : 1280) - Style.gapsOut * 2)
    : Math.min(Style.space(940), (panel && panel.width > 300 ? panel.width : 1280) - Style.gapsOut * 2)

  readonly property int targetCardHeight: root.isPhoneMode
    ? Math.min(Style.space(690), (panel && panel.height > 300 ? panel.height : 800) - Style.space(40))
    : Math.min(Style.space(590), (panel && panel.height > 300 ? panel.height : 800) - Style.gapsOut * 2)

  property int cardWidth: targetCardWidth
  property int cardHeight: targetCardHeight

  Behavior on cardWidth {
    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
  }
  Behavior on cardHeight {
    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
  }

  readonly property int chromeHeight: contentMargin * 2 + tabletBarHeight + contentSpacing + headerHeight + contentSpacing + searchHeight
    + (root.mode === "input" ? 0 : contentSpacing) + contentSpacing + footerHeight
  readonly property int availableGridHeight: Math.max(root.baseTileHeight, root.cardHeight - root.chromeHeight - (contentMargin * 2))
  readonly property int gridHeight: root.mode === "input" ? 0
    : (displayModel.count === 0 ? root.emptyHeight : Math.min(root.gridContentHeight, root.availableGridHeight))

  // ---------------------------------------------------------------- helpers

  function finishRequest(selection) {
    if (!root.requestActive || !root.doneFile) {
      root.dismissMenu()
      return
    }

    var activeSelectionFile = root.selectionFile
    var activeDoneFile = root.doneFile
    root.requestActive = false
    root.selectionFile = ""
    root.doneFile = ""

    if (selection === null || selection === undefined) {
      resultProc.command = ["bash", "-c", ": > " + Util.shellQuote(activeDoneFile)]
    } else {
      resultProc.command = ["bash", "-c", "printf '%s\\n' " + Util.shellQuote(selection) + " > " + Util.shellQuote(activeSelectionFile) + "; : > " + Util.shellQuote(activeDoneFile)]
    }
    resultProc.running = true
  }

  function runAction(action) {
    var command = String(action || "")
    if (!command) return
    Util.execDetached(command)
  }

  function item(id) {
    return root.items[id] || null
  }

  function parseMenuJsonc(raw) {
    return MenuModel.parseMenuJsonc(raw)
  }

  function rebuildItemsFromSources() {
    var mergedMenu = MenuModel.mergeMenuSources(root.defaultMenuItems, root.userMenuItems)
    root.providerRevision += 1
    root.providersLoaded = ({})
    root.providerQueue = []
    root.items = mergedMenu.items
    root.itemOrder = mergedMenu.itemOrder
    root.rowsLoaded = true
    root.evaluateGuards()
    root.rebuildShortcutIndexes()
    root.ensureAppRows()
    if (root.opened) {
      root.rebuildDisplay(true)
      if (!root.dmenuActive) {
        if (root.filterText.trim()) root.loadProvidersForSearch()
        else root.loadProviderForMenu(root.activeMenu)
      }
    } else {
      root.rebuildDisplay(true)
    }
  }

  // ------------------------------------------------------------- providers
  //
  // Identical to the built-in menu: bash enumerators for fonts and power
  // profiles, and the shared AppLibrary for applications.

  readonly property var providers: ({
    "fonts": {
      script: "current=$(omarchy-font-current 2>/dev/null); omarchy-font-list 2>/dev/null | while read -r f; do [[ -z $f ]] && continue; printf '%s\\t%s\\t%s\\n' \"$f\" \"$f\" \"$current\"; done",
      icon: "",
      volatile: true,
      actionFor: function(value) { return "omarchy-font-set " + Util.shellQuote(value) }
    },
    "power-profiles": {
      script: "current=$(powerprofilesctl get 2>/dev/null); omarchy-powerprofiles-list 2>/dev/null | while read -r p; do [[ -z $p ]] && continue; printf '%s\\t%s\\t%s\\n' \"$p\" \"$p\" \"$current\"; done",
      icon: "󰐋",
      actionFor: function(value) { return "omarchy-powerprofiles-set autodetect " + Util.shellQuote(value) }
    }
  })

  function mergeAppRows() {
    if (!root.appLibrary) return

    var rows = root.appLibrary.sortedEntries("")
    var appRows = []
    for (var j = 0; j < rows.length; j++) {
      var entry = rows[j].entry
      var appId = String(entry.id || "")
      if (!appId) continue
      var subtext = root.appLibrary.entrySubtext(entry)
      var aliases = subtext ? [subtext] : []
      try {
        if (entry.keywords && typeof entry.keywords.join === "function") aliases = aliases.concat(entry.keywords)
      } catch (e) { }

      var rawIcon = String(entry.icon || "")
      var resolvedIcon = root.resolveIconCached(rawIcon)

      appRows.push({
        id: "apps." + appId,
        parent: "apps",
        kind: "app",
        icon: "",
        appIcon: resolvedIcon,
        appId: appId,
        label: root.appLibrary.entryName(entry),
        title: "",
        target: "",
        description: subtext,
        action: "",
        provider: "",
        aliases: aliases,
        when: "",
        checked: "",
        order: 0
      })
    }

    var merged = MenuModel.mergeAppRows(root.items, root.itemOrder, appRows)
    root.items = merged.items
    root.itemOrder = merged.itemOrder
    root.cachedAppDefaultRows = []
    root.rebuildAppShortcuts()
    root.rebuildDisplay(true)
  }

  // Searching from the root spans Apps, so app rows are needed before the
  // user ever enters Apps. Loading them is a one-time in-memory merge.
  function ensureAppRows() {
    if (root.providersLoaded["apps"]) return
    root.providersLoaded["apps"] = true
    root.mergeAppRows()
  }

  function startProviderForMenu(id) {
    var entry = root.item(id)
    if (!entry || !entry.provider || root.providersLoaded[id]) return
    if (entry.provider === "apps") {
      root.providersLoaded[id] = true
      root.mergeAppRows()
      return
    }
    var spec = root.providers[entry.provider]
    if (!spec) return

    root.providersLoaded[id] = true
    providerProc.menuId = id
    providerProc.providerKey = entry.provider
    providerProc.revision = root.providerRevision
    providerProc.command = ["bash", "-lc", spec.script]
    providerProc.running = true
  }

  function mergeProviderRows(rows, menuId, providerKey) {
    var spec = root.providers[providerKey]
    if (!spec) return
    var lines = String(rows || "").split("\n")
    var providerRows = []
    var takenIds = ({})
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line) continue
      var parts = line.split("\t")
      var label = parts[0] || ""
      var value = parts[1] || parts[0] || ""
      var current = parts[2] || ""
      if (!label) continue
      var rowId = menuId + "." + MenuModel.slugify(value)
      while (takenIds[rowId]) rowId += "-"
      takenIds[rowId] = true

      providerRows.push({
        id: rowId,
        parent: menuId,
        kind: "action",
        icon: (value === current) ? "✓" : (spec.icon || ""),
        label: label,
        title: "",
        target: "",
        description: "",
        action: spec.actionFor(value),
        provider: "",
        aliases: [],
        when: "",
        checked: "",
        order: 0
      })
    }
    var merged = MenuModel.swapProviderRows(root.items, root.itemOrder, menuId, providerRows)
    root.items = merged.items
    root.itemOrder = merged.itemOrder
    if (root.opened) root.rebuildDisplay()
  }

  function startNextProvider() {
    if (providerProc.running) return
    while (root.providerQueue.length > 0) {
      var id = root.providerQueue.shift()
      var entry = root.item(id)
      if (!entry || !entry.provider || root.providersLoaded[id]) continue
      root.startProviderForMenu(id)
      return
    }
  }

  function invalidateVolatileProvider(id) {
    var entry = root.item(id)
    var spec = entry && entry.provider ? root.providers[entry.provider] : null
    if (spec && spec.volatile) root.providersLoaded[id] = false
  }

  function loadProviderForMenu(id) {
    var entry = root.item(id)
    if (!entry || !entry.provider || root.providersLoaded[id]) return
    if (entry.provider === "apps") {
      root.startProviderForMenu(id)
      return
    }
    if (providerProc.running) {
      if (root.providerQueue.indexOf(id) < 0) root.providerQueue = root.providerQueue.concat([id])
      return
    }
    root.startProviderForMenu(id)
  }

  function loadProvidersForSearch() {
    var active = root.item(root.activeMenu) ? root.activeMenu : "root"
    for (var i = 0; i < root.itemOrder.length; i++) {
      var entry = root.item(root.itemOrder[i])
      if (!entry || !entry.provider || root.providersLoaded[entry.id]) continue
      if (active !== "root" && entry.id !== active && !root.isDescendantOf(entry.id, active)) continue
      root.loadProviderForMenu(entry.id)
    }
  }

  function pathFor(id) { return MenuModel.pathFor(root.items, id) }
  function parentPathFor(id) { return MenuModel.parentPathFor(root.items, id) }
  function isDescendantOf(id, ancestorId) { return MenuModel.isDescendantOf(root.items, id, ancestorId) }
  function isVisible(entry) {
    if (!entry) return false
    // Remove "learn" category and any "learn.*" documentation/wiki items
    if (entry.id === "learn" || (entry.id && entry.id.indexOf("learn.") === 0)) return false
    // Remove "apps" category from Omarchy Control view / general menu tree since dedicated application section exists
    if (entry.id === "apps") return false
    return MenuModel.isVisible(root.items, root.itemOrder, root.whenResults, entry)
  }
  function matchesQuery(entry, query) { return MenuModel.matchesQuery(entry, query, root.isVisible(entry)) }
  function searchScore(entry, query) { return MenuModel.searchScore(root.items, entry, query) }
  function displayRow(entry, detail, score, section) {
    return MenuModel.displayRow(root.items, root.itemOrder, root.checkedResults, entry, detail, score, section)
  }
  function resolveRoute(input) { return MenuModel.resolveRoute(root.items, root.itemOrder, input) }

  // ---------------------------------------------------------- shortcut hints

  function loadKeybinds(force) {
    if (!root.pluginDir || keybindsProc.running) return
    var now = Date.now()
    if (!force && root.keybindsLoadedAt && now - root.keybindsLoadedAt < root.keybindRefreshSeconds * 1000) return
    root.keybindsLoadedAt = now
    keybindsProc.command = [root.pluginDir + "/scripts/keybinds"]
    keybindsProc.running = true
  }

  property string lastKeybindsRaw: ""

  function applyKeybinds(text) {
    if (text === root.lastKeybindsRaw) return
    root.lastKeybindsRaw = text
    var parsed = Keybinds.parseRecords(text)
    root.binds = parsed.binds
    root.bindDefaults = parsed.defaults
    root.rebuildShortcutIndexes()
    root.pickTip()
    if (root.opened && root.activeMenu !== "apps") root.rebuildDisplay()
  }

  function rebuildShortcutIndexes() {
    if (!root.binds.length || !root.rowsLoaded) return
    root.menuShortcuts = Keybinds.menuIndex(root.items, root.itemOrder, root.binds, root.resolveRoute)
    root.rebuildAppShortcuts()
  }

  function rebuildAppShortcuts() {
    if (!root.binds.length || !root.appLibrary) return
    var rows = root.appLibrary.sortedEntries("")
    var entries = []
    for (var i = 0; i < rows.length; i++) {
      var entry = rows[i].entry
      entries.push({ id: String(entry.id || ""), name: String(entry.name || ""), execString: String(entry.execString || "") })
    }
    root.appShortcuts = Keybinds.appIndex(entries, root.binds, root.bindDefaults)
  }

  function pickTip() {
    root.tip = Keybinds.randomTip(root.binds, null)
  }

  function shortcutFor(row) {
    if (row.kind === "app") return root.appShortcuts[row.appId] || ""
    return root.menuShortcuts[row.itemId] || ""
  }

  // ---------------------------------------------------------------- display

  ListModel { id: displayModel }
  ListModel { id: dividerModel }

  function columnsFor(rows) {
    if (root.isPhoneMode) return 1
    if (root.dmenuActive) return 1
    if (root.mode === "input") return 1
    if (root.activeMenu === "apps" && !root.filterText.trim()) return 6
    if (root.activeMenu === "root" && !root.filterText.trim()) return 2
    if (root.filterText.trim().length > 0) {
      if (rows && rows.length === 1) return 1
      return 2
    }
    return 2
  }

  function sectionTitle(section) {
    if (section === "drilldown") return "More Results"
    return ""
  }

  // Assigns shortcut hints, then lays the rows out on a grid. Sections
  // (main / drilldown search hits)
  // each start on a fresh row with a divider above them, so a section never
  // shares a row.
  function decorateRows(rows) {
    var cols = root.columnsFor(rows)
    var tileH = root.tileHeight
    var gap = root.tileGap
    dividerModel.clear()

    var y = 0
    var row = 0
    var col = 0
    var previousSection = null

    for (var i = 0; i < rows.length; i++) {
      var r = rows[i]
      var section = r.section || ""
      var titled = root.sectionTitle(section).length > 0
      if ((previousSection !== null && section !== previousSection) || (previousSection === null && titled)) {
        if (col > 0) { col = 0; row += 1; y += tileH + gap }
        dividerModel.append({ offsetY: y, label: root.sectionTitle(section) })
        y += root.dividerHeight
      }
      r.row = row
      r.col = col
      r.cellY = y
      r.shortcut = root.shortcutFor(r)
      col += 1
      if (col >= cols) { col = 0; row += 1; y += tileH + gap }
      previousSection = section
    }

    root.columns = cols
    root.rowCount = col > 0 ? row + 1 : row
    root.gridContentHeight = rows.length === 0 ? 0 : (col > 0 ? y + tileH : y - gap)
  }

  function appendRows(rows) {
    root.decorateRows(rows)
    for (var k = 0; k < rows.length; k++) {
      var r = rows[k]
      displayModel.append({
        itemId: String(r.itemId || ""),
        kind: String(r.kind || ""),
        icon: String(r.icon || ""),
        iconFont: String(r.iconFont || ""),
        appIcon: String(r.appIcon || ""),
        appId: String(r.appId || ""),
        label: String(r.label || ""),
        target: String(r.target || ""),
        detail: String(r.detail || ""),
        path: String(r.path || ""),
        action: String(r.action || ""),
        childCount: Number(r.childCount || 0),
        section: String(r.section || ""),
        shortcut: String(r.shortcut || ""),
        row: Number(r.row || 0),
        col: Number(r.col || 0),
        cellY: Number(r.cellY || 0)
      })
    }
    root.layoutSerial += 1

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0

    Qt.callLater(function() {
      if (displayModel.count > 0) root.revealCursor()
    })
  }

  function rebuildDmenuDisplay() {
    displayModel.clear()
    if (root.mode === "input") {
      dividerModel.clear()
      root.gridContentHeight = 0
      root.layoutSerial += 1
      return
    }

    var query = root.filterText.trim().toLowerCase()
    var rows = []
    var anyDetail = false
    for (var i = 0; i < root.dmenuOptions.length; i++) {
      var parts = String(root.dmenuOptions[i] || "").split("\t")
      var icon = parts.length > 1 ? parts.shift() : ""
      var label = parts.shift() || ""
      var detail = parts.join("\t")
      if (query && label.toLowerCase().indexOf(query) < 0
          && detail.toLowerCase().indexOf(query) < 0) continue
      if (detail) anyDetail = true
      rows.push({
        itemId: "dmenu." + i,
        kind: "dmenu",
        icon: icon,
        iconFont: "",
        appIcon: "",
        appId: "",
        label: label,
        target: "",
        detail: detail,
        path: "",
        childCount: 0,
        action: "",
        provider: "",
        score: i,
        section: ""
      })
    }
    root.dmenuHasDetail = anyDetail
    root.appendRows(rows)
  }

  function rebuildDisplay(force) {
    if (root.dmenuActive) {
      root.rebuildDmenuDisplay()
      return
    }

    if (!root.rowsLoaded) return

    var active = root.item(root.activeMenu) ? root.activeMenu : "apps"
    root.activeMenu = active
    var query = root.filterText.trim()

    if (!force && root.lastRenderedMenu === active && root.lastRenderedFilter === query && displayModel.count > 0) {
      return
    }

    displayModel.clear()
    root.lastRenderedMenu = active
    root.lastRenderedFilter = query
    var rows = []

    var command = root.commandRow(query)
    if (command) {
      root.appendRows([command])
      return
    }

    if (query) {
      var lowerQuery = query.toLowerCase()
      var isFmhyMode = lowerQuery === "fmhy" || lowerQuery.indexOf("fmhy ") === 0 || (lowerQuery.indexOf("f ") === 0)

      if (isFmhyMode) {
        var fmhySub = query.replace(/^(?:fmhy|f)\s+/i, "").trim()
        if (fmhySub) {
          if (root.fmhyCache[fmhySub]) {
            root.currentFmhyResults = root.fmhyCache[fmhySub]
            root.fmhySearching = false
          } else {
            root.currentFmhyResults = []
            root.fmhySearching = true
            root.dispatchFmhySearch(fmhySub)
          }
        } else {
          root.currentFmhyResults = []
          root.fmhySearching = false
        }
      }

      var smartRows = RaycastSearch.getSmartRows(query, {
        quickLinks: root.quickLinksList,
        exchangeRates: root.exchangeRates,
        localOffsetMin: root.localTzOffsetMin,
        fmhyResults: root.currentFmhyResults,
        fmhySearching: root.fmhySearching
      })

      var isExclusiveSmart = smartRows.length > 0 && (
        query.charAt(0) === "=" ||
        (smartRows.length === 1 && smartRows[0].type === "calc") ||
        lowerQuery === "ql" || lowerQuery === "quicklinks" || lowerQuery === "quicklink" || lowerQuery === "links" ||
        lowerQuery === "tz" || lowerQuery === "timezone" || lowerQuery === "timezones" || lowerQuery === "world clock" ||
        lowerQuery === "currency" || lowerQuery === "fx" ||
        lowerQuery === "calc" || lowerQuery === "math" ||
        isFmhyMode
      )

      if (isExclusiveSmart) {
        root.appendRows(smartRows)
        return
      }

      var currentRows = []
      var drilldownRows = []

      for (var i = 0; i < root.itemOrder.length; i++) {
        var entry = root.item(root.itemOrder[i])
        if (active !== "root" && active !== "apps" && !root.isDescendantOf(entry.id, active)) continue
        if (!root.matchesQuery(entry, query)) continue

        var detail = root.parentPathFor(entry.id)
        var row = root.displayRow(entry, detail, root.searchScore(entry, query))
        if (entry.parent === active) currentRows.push(row)
        else drilldownRows.push(row)
      }

      var searchSort = function(a, b) {
        if (a.score !== b.score) return a.score - b.score
        return a.path.localeCompare(b.path)
      }
      currentRows.sort(searchSort)
      drilldownRows.sort(searchSort)
      if (currentRows.length > 0 && drilldownRows.length > 0) {
        for (var d = 0; d < drilldownRows.length; d++) drilldownRows[d].section = "drilldown"
      }
      rows = currentRows.concat(drilldownRows)

      var topSmart = []
      var bottomSmart = []
      for (var s = 0; s < smartRows.length; s++) {
        if (smartRows[s].type === "fmhy-suggest") {
          bottomSmart.push(smartRows[s])
        } else {
          topSmart.push(smartRows[s])
        }
      }

      if (topSmart.length > 0) {
        rows = topSmart.concat(rows)
      }
      if (bottomSmart.length > 0) {
        rows = rows.concat(bottomSmart)
      }
    } else {
      if (active === "apps") {
        if (root.cachedAppDefaultRows.length > 0) {
          rows = root.cachedAppDefaultRows.slice()
        } else {
          for (var j = 0; j < root.itemOrder.length; j++) {
            var child = root.item(root.itemOrder[j])
            if (!child || child.parent !== "apps") continue
            if (!root.isVisible(child)) continue
            rows.push(root.displayRow(child, child.description || "", child.order))
          }
          rows.sort(function(a, b) {
            var aLabel = String(a.label || "").toLowerCase()
            var bLabel = String(b.label || "").toLowerCase()
            if (aLabel < bLabel) return -1
            if (aLabel > bLabel) return 1
            return String(a.itemId || "").localeCompare(String(b.itemId || ""))
          })
          root.cachedAppDefaultRows = rows.slice()
        }
      } else {
        for (var j2 = 0; j2 < root.itemOrder.length; j2++) {
          var child2 = root.item(root.itemOrder[j2])
          if (!child2 || child2.parent !== active) continue
          if (!root.isVisible(child2)) continue
          var detailText = child2.description || ""
          if (!detailText && active === "root") {
            if (child2.id === "trigger") detailText = "Hardware toggles & quick switches"
            else if (child2.id === "style") detailText = "Themes, fonts & visual style"
            else if (child2.id === "setup") detailText = "System settings, security & devices"
            else if (child2.id === "install") detailText = "Packages, AUR & applications"
            else if (child2.id === "remove") detailText = "Uninstall software & packages"
            else if (child2.id === "update") detailText = "System & package updates"
            else if (child2.id === "about") detailText = "Hardware info & system specs"
            else if (child2.id === "system") detailText = "Power, session, lock & logout"
          }
          rows.push(root.displayRow(child2, detailText, child2.order))
        }
      }
    }

    root.appendRows(rows)
  }

  // ---------------------------------------------------------------- commands

  // Two typed escapes, both single tiles that replace the search results:
  //   !cmd    run `cmd` in a new terminal (in the active terminal's directory,
  //           the shell stays open afterwards so the output is readable)
  //   ~/path  open the path with xdg-open (also /path)
  function commandRow(query) {
    if (query.charAt(0) === "!") {
      var cmd = query.slice(1).trim()
      if (!cmd) return null
      return { itemId: "!run", kind: "run", icon: "", label: cmd, detail: "Run in terminal", action: cmd }
    }
    if (query === "~" || query.indexOf("~/") === 0 || query.charAt(0) === "/") {
      return { itemId: "!open", kind: "open", icon: "", label: query, detail: "Open", action: query }
    }
    return null
  }

  function runCommand(kind, action) {
    applySerial = requestSerial
    if (kind === "run") {
      Util.execDetached("omarchy-launch-terminal bash -c " + Util.shellQuote('eval "$1"; exec "${SHELL:-bash}"') + " _ " + Util.shellQuote(action))
    } else {
      var path = String(action)
      if (path === "~" || path.indexOf("~/") === 0) path = Quickshell.env("HOME") + path.slice(1)
      Util.execDetached("xdg-open " + Util.shellQuote(path))
    }
    root.dismissMenu()
  }

  function openUrl(url) {
    applySerial = requestSerial
    Util.execDetached("xdg-open " + Util.shellQuote(url))
    root.dismissMenu()
  }

  function copyToClipboard(text, label, detail, icon) {
    applySerial = requestSerial
    Util.execDetached("printf %s " + Util.shellQuote(text) + " | wl-copy")
    var glyph = (icon && icon.length > 0) ? icon : "󰃬"
    var title = "Copied to clipboard"
    var msg = (label && label.length > 0) ? label : text
    Util.execDetached("omarchy-notification-send -g " + Util.shellQuote(glyph) + " " + Util.shellQuote(title) + " " + Util.shellQuote(msg))
    root.dismissMenu()
  }

  function currentSearchGlyph() {
    return RaycastSearch.detectSearchGlyph(root.filterText, root.quickLinksList)
  }

  // ------------------------------------------------------------- navigation

  function revealCursor() {
    if (displayModel.count === 0) return
    if (root.selectedIndex < 0 || root.selectedIndex >= displayModel.count) return
    var r = displayModel.get(root.selectedIndex)
    var top = r.cellY
    var bottom = r.cellY + root.tileHeight
    // Keep a sliver of the neighbouring row visible so the fold reads as one (in lists only).
    var reach = (root.columns > 2) ? 0 : Math.round(root.tileHeight * 0.4)
    var maxY = Math.max(0, gridFlick.contentHeight - gridFlick.height)
    if (bottom + reach > gridFlick.contentY + gridFlick.height)
      gridFlick.contentY = Math.min(bottom + reach - gridFlick.height, maxY)
    if (top - reach < gridFlick.contentY)
      gridFlick.contentY = Math.max(top - reach, 0)
  }

  function moveHorizontal(delta) {
    delta = Number(delta) || 0
    if (displayModel.count === 0) return
    root.disarmPointer()
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    }
    revealCursor()
  }

  function moveVertical(delta) {
    delta = Number(delta) || 0
    if (displayModel.count === 0) return
    root.disarmPointer()
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
      revealCursor()
      return
    }
    if (root.rowCount <= 1) return
    var current = displayModel.get(selectedIndex)
    var targetRow = (current.row + delta + root.rowCount) % root.rowCount
    // Same column if the row has one, else the closest column to the left.
    var best = -1
    var bestCol = -1
    var first = -1
    for (var i = 0; i < displayModel.count; i++) {
      var r = displayModel.get(i)
      if (r.row !== targetRow) continue
      if (first < 0) first = i
      if (r.col === current.col) { best = i; break }
      if (r.col < current.col && r.col > bestCol) { best = i; bestCol = r.col }
    }
    if (best < 0) best = first
    if (best >= 0) selectedIndex = best
    revealCursor()
  }

  function setFilter(nextFilter, newCursorPos) {
    root.filterText = nextFilter
    if (typeof newCursorPos === "number") {
      root.textCursorPos = Math.max(0, Math.min(nextFilter.length, newCursorPos))
    } else {
      root.textCursorPos = nextFilter.length
    }
    root.selectedIndex = 0
    root.cursorActive = root.mode !== "input"
    root.disarmPointer()
    if (!root.dmenuActive && root.filterText.trim()) root.loadProvidersForSearch()
    root.rebuildDisplay()
  }

  function prevTokenPos(text, pos) {
    if (!text || pos <= 0) return 0
    var p = pos
    while (p > 0 && /\s/.test(text.charAt(p - 1))) p--
    if (p === 0) return 0
    var isWord = /[a-zA-Z0-9_.]/.test(text.charAt(p - 1))
    if (isWord) {
      while (p > 0 && /[a-zA-Z0-9_.]/.test(text.charAt(p - 1))) p--
    } else {
      while (p > 0 && !/[a-zA-Z0-9_.\s]/.test(text.charAt(p - 1))) p--
    }
    return p
  }

  function nextTokenPos(text, pos) {
    if (!text || pos >= text.length) return text ? text.length : 0
    var p = pos
    while (p < text.length && /\s/.test(text.charAt(p))) p++
    if (p >= text.length) return text.length
    var isWord = /[a-zA-Z0-9_.]/.test(text.charAt(p))
    if (isWord) {
      while (p < text.length && /[a-zA-Z0-9_.]/.test(text.charAt(p))) p++
    } else {
      while (p < text.length && !/[a-zA-Z0-9_.\s]/.test(text.charAt(p))) p++
    }
    return p
  }

  function cursorPosFromX(clickX) {
    if (!root.filterText || clickX <= 0) return 0
    var bestPos = 0
    var bestDist = Math.abs(clickX)
    for (var i = 1; i <= root.filterText.length; i++) {
      probeMetrics.text = root.filterText.slice(0, i)
      var dist = Math.abs(clickX - probeMetrics.width)
      if (dist < bestDist) {
        bestDist = dist
        bestPos = i
      }
    }
    return bestPos
  }

  function setActiveMenu(id, pushHistory, fromPointer) {
    if (!root.item(id)) id = "root"
    if (pushHistory && id !== root.activeMenu) root.navStack = root.navStack.concat([root.activeMenu])
    root.activeMenu = id
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    gridFlick.contentY = 0
    if (fromPointer) pointerGate.allowInitialSample()
    else root.disarmPointer()
    root.rebuildDisplay()
    root.invalidateVolatileProvider(id)
    root.loadProviderForMenu(id)
  }

  function goBack() {
    if (root.activeMenu === "root" || root.activeMenu === "apps") return false
    if (root.navStack.length > 0) {
      var previous = root.navStack[root.navStack.length - 1]
      root.navStack = root.navStack.slice(0, root.navStack.length - 1)
      root.setActiveMenu(previous, false)
      return true
    }
    var active = root.item(root.activeMenu)
    root.setActiveMenu((active && active.parent) ? active.parent : "apps", false)
    return true
  }

  function activateIndex(index, fromPointer) {
    if (root.deleteConfirmOpen) return
    if (root.dmenuActive) {
      if (root.mode === "input") {
        root.applyDmenuSelection(root.filterText)
        return
      }
      if (index < 0 || index >= displayModel.count) return
      var picked = displayModel.get(index)
      root.applyDmenuSelection(picked.detail ? picked.label + "\t" + picked.detail : picked.label)
      return
    }

    if (index < 0 || index >= displayModel.count) return

    var row = displayModel.get(index)
    if (row.kind === "menu" || row.kind === "link") {
      root.setActiveMenu(row.target || row.itemId, true, fromPointer)
    } else if (row.kind === "run" || row.kind === "open") {
      root.runCommand(row.kind, row.action)
    } else if (row.kind === "app") {
      var appId = row.appId
      var label = row.label
      applySerial = requestSerial
      if (root.appLibrary) root.appLibrary.launch(appId, label)
      root.dismissMenu()
    } else if (row.kind === "url") {
      root.openUrl(row.action)
    } else if (row.kind === "copy") {
      root.copyToClipboard(row.action, row.label, row.detail, row.icon)
    } else if (row.kind === "fill") {
      root.setFilter(row.action)
    } else if (row.kind === "fmhy-deck") {
      root.summonFmhyDeck(row.action)
    } else if (row.kind === "noop") {
      // placeholder row
    } else {
      root.applySelected(row.itemId, row.action)
    }
  }

  function requestDeleteSelected() {
    if (!root.cursorActive || root.selectedIndex < 0 || root.selectedIndex >= displayModel.count) return
    var row = displayModel.get(root.selectedIndex)
    if (!row || row.kind !== "app") return
    root.deleteTarget = { appId: row.appId, label: row.label }
    deleteConfirm.selectedIndex = 1
    root.deleteConfirmOpen = true
  }

  function cancelDelete() {
    root.deleteConfirmOpen = false
    root.deleteTarget = null
    deleteConfirm.selectedIndex = 1
    root.disarmPointer()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function confirmDelete() {
    var target = root.deleteTarget
    root.deleteConfirmOpen = false
    root.deleteTarget = null
    if (!target) return
    root.cancel()
    if (root.appLibrary) root.appLibrary.remove(target.appId, target.label)
  }

  function applyDmenuSelection(value) {
    applySerial = requestSerial
    root.finishRequest(value)
    root.dismissMenu()
  }

  function applySelected(id, action) {
    if (!id) { cancel(); return }
    applySerial = requestSerial
    root.runAction(action)
    root.dismissMenu()
  }

  function cancel() {
    if (root.dmenuActive) root.finishRequest(null)
    root.dismissMenu()
  }

  function openExistingMenu(initialMenu) {
    requestSerial += 1
    mode = "menu"
    requestActive = false
    selectionFile = ""
    doneFile = ""
    var targetMenu = root.item(initialMenu) ? initialMenu : "apps"
    activeMenu = targetMenu
    navStack = []
    filterText = ""
    textCursorPos = 0
    selectedIndex = 0
    cursorActive = true
    if (typeof gridFlick !== "undefined" && gridFlick) gridFlick.contentY = 0
    root.ensureAppRows()
    opened = true
    keyCatcher.forceActiveFocus()
    root.startOpenAnimation()

    rebuildDisplay(true)

    deferredRefreshTimer.restart()
  }

  function openDmenu(payload) {
    requestSerial += 1
    mode = payload.mode === "input" ? "input" : "select"
    dmenuPrompt = String(payload.prompt || (mode === "input" ? "Input" : "Select"))
    dmenuOptions = Array.isArray(payload.options) ? payload.options : []
    selectionFile = String(payload.selectionFile || "")
    doneFile = String(payload.doneFile || "")
    requestActive = !!doneFile
    dmenuWidth = Math.max(1, Number(payload.width || 300))
    dmenuMaxHeight = Math.max(0, Number(payload.maxHeight || 0))
    activeMenu = "root"
    navStack = []
    filterText = ""
    selectedIndex = 0
    cursorActive = mode !== "input"
    gridFlick.contentY = 0
    root.disarmPointer()
    opened = true
    rebuildDisplay()
    root.startOpenAnimation()

    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function openRoute(initialMenu) {
    var id = root.resolveRoute(initialMenu)
    var entry = root.items[id]
    if (entry && entry.kind === "action" && entry.action) {
      root.cancel()
      root.runAction(entry.action)
      return "ok"
    }
    if (entry && entry.kind === "link" && entry.target) id = entry.target
    root.openExistingMenu(id)
    return "ok"
  }

  function disarmPointer() {
    pointerGate.reset()
  }

  function selectFromPointer(index, item, mouse) {
    if (!pointerGate.moved(item, mouse)) return
    root.cursorActive = true
    root.selectedIndex = index
  }

  function headerTitle() {
    if (root.dmenuActive) return root.dmenuPrompt
    if (root.activeMenu === "root" || !root.item(root.activeMenu)) return "Omarchy"
    return root.pathFor(root.activeMenu)
  }

  function statusText() {
    if (root.dmenuActive) return ""
    var parts = []
    if (root.themeName) parts.push(root.themeName)
    if (root.versionText) parts.push("v" + root.versionText)
    if (root.updateCount > 0) parts.push("󰚰 " + root.updateCount + (root.updateCount === 1 ? " update" : " updates"))
    return parts.join("  ·  ")
  }

  function launchDockApp(appId) {
    if (appId === "menus") {
      root.openRoute("root")
      return
    }
    root.cancel()
    if (appId === "terminal") {
      Util.execDetached("omarchy-launch-terminal")
    } else if (appId === "browser") {
      Util.execDetached("uwsm-app -- gtk-launch zen.desktop || xdg-open https://google.com")
    } else if (appId === "files") {
      Util.execDetached("uwsm-app -- gtk-launch io.github.lgse.Strata.desktop || xdg-open " + Util.shellQuote(Quickshell.env("HOME")))
    } else if (appId === "editor") {
      Util.execDetached("omarchy-launch-terminal bash -c 'nvim; exec \"${SHELL:-bash}\"'")
    }
  }

  function footerHint() {
    if (root.mode === "input") return "⏎ confirm   esc cancel"
    if (root.dmenuActive) return "↑↓ move   ⏎ select   esc cancel"
    if (root.isPhoneMode) return "↑↓ move   ⏎ select   esc back"
    if (root.filterText.charAt(0) === "!") return "⏎ run in terminal   esc clear"
    if (root.isMathMode) return "←→ cursor   ⏎ copy to clipboard   esc clear"
    if (root.filterText) return "↑↓←→ move   ⏎ open   esc clear"
    if (root.activeMenu === "apps") return "↑↓←→ move   ⏎ open   tab switch view   esc close"
    if (root.activeMenu === "root") return "↑↓←→ move   ⏎ open   tab switch view   esc close"
    return "↑↓←→ move   ⏎ open   esc back"
  }

  function tipText() {
    if (root.isPhoneMode || root.dmenuActive || !root.tip) return ""
    return "󰛨 " + root.tip.pretty + " → " + root.tip.description
  }

  function searchPlaceholder() {
    if (root.mode === "input") return root.dmenuPrompt + "…"
    if (root.dmenuActive) return "Filter " + root.dmenuPrompt.toLowerCase() + "…"
    if (root.activeMenu === "apps") return "Search applications, files (~), commands (!)..."
    var active = root.item(root.activeMenu)
    if (root.isPhoneMode) return active ? "Filter " + (active.title || active.label).toLowerCase() + "…" : "Filter items…"
    return (root.activeMenu === "root" || !active) ? "Search applications & system menus..." : "Search " + (active.title || active.label)
  }

  // -------------------------------------------------------------- processes

  // Every producer runs through this. Output is kept line by line only up to
  // maxProcessChars / maxProcessRecords; past either cap the producer is
  // killed and its output dropped. A deadline kills producers that never
  // exit. Consumers read `collected` only when `ok` is true.
  component BoundedProcess: Process {
    id: proc
    property int deadlineMs: root.helperTimeoutMs
    property string collected: ""
    property int records: 0
    property bool overflow: false
    property bool timedOut: false
    readonly property bool ok: !overflow && !timedOut

    stdout: SplitParser {
      onRead: function(data) {
        if (proc.overflow || proc.timedOut) return
        if (proc.records >= root.maxProcessRecords || proc.collected.length + data.length + 1 > root.maxProcessChars) {
          proc.overflow = true
          proc.collected = ""
          proc.running = false
          return
        }
        proc.collected += data + "\n"
        proc.records += 1
      }
    }

    onRunningChanged: {
      if (running) {
        collected = ""
        records = 0
        overflow = false
        timedOut = false
        deadline.restart()
      } else {
        deadline.stop()
      }
    }

    // A typed property rather than a child: Process has no default property.
    property Timer deadline: Timer {
      interval: proc.deadlineMs
      onTriggered: {
        proc.timedOut = true
        proc.collected = ""
        proc.running = false
      }
    }
  }

  BoundedProcess {
    id: providerProc
    deadlineMs: root.providerTimeoutMs
    property string menuId: ""
    property string providerKey: ""
    property int revision: 0
    onExited: {
      if (providerProc.ok && providerProc.revision === root.providerRevision) {
        root.mergeProviderRows(providerProc.collected, providerProc.menuId, providerProc.providerKey)
        if (root.filterText.trim()) root.loadProvidersForSearch()
      }
      providerProc.collected = ""
      root.startNextProvider()
    }
  }

  Process {
    id: resultProc
    onExited: {
      if (root.applySerial === root.requestSerial)
        root.dismissMenu()
    }
  }

  BoundedProcess {
    id: keybindsProc
    onExited: {
      if (keybindsProc.ok) root.applyKeybinds(keybindsProc.collected)
      keybindsProc.collected = ""
    }
  }

  BoundedProcess {
    id: statusProc
    onExited: {
      if (!statusProc.ok) return
      var lines = statusProc.collected.split("\n")
      statusProc.collected = ""
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split("\t")
        if (parts[0] === "theme") root.themeName = String(parts[1] || "").trim().slice(0, 80)
        else if (parts[0] === "version") root.versionText = String(parts[1] || "").trim().slice(0, 40)
      }
    }
  }

  BoundedProcess {
    id: tabletStatusProc
    onExited: {
      if (!tabletStatusProc.ok) return
      var lines = tabletStatusProc.collected.split("\n")
      tabletStatusProc.collected = ""
      for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split("\t")
        if (parts[0] === "battery") root.batteryText = String(parts[1] || "").trim()
        else if (parts[0] === "wifi") root.wifiText = String(parts[1] || "").trim()
      }
    }
  }

  BoundedProcess {
    id: updatesProc
    deadlineMs: root.updatesTimeoutMs
    onExited: {
      if (!updatesProc.ok) return
      var n = parseInt(updatesProc.collected.trim(), 10)
      updatesProc.collected = ""
      root.updateCount = isFinite(n) && n >= 0 ? Math.min(n, 9999) : 0
    }
  }

  // Menu definitions are read through scripts/read-file, which refuses
  // symlinks, non-regular files, and anything over maxMenuFileBytes, and
  // opens with O_NOFOLLOW. The FileViews below only watch for changes; they
  // never load the file themselves (preload: false).
  function loadMenuFile(proc, path) {
    if (!root.pluginDir || !path) return
    if (proc.running) { proc.reloadPending = true; return }
    proc.reloadPending = false
    proc.command = [root.pluginDir + "/scripts/read-file", path, String(root.maxMenuFileBytes)]
    proc.running = true
  }

  BoundedProcess {
    id: defaultMenuProc
    property bool reloadPending: false
    onExited: function(exitCode) {
      root.defaultMenuItems = (defaultMenuProc.ok && exitCode === 0) ? root.parseMenuJsonc(defaultMenuProc.collected) : []
      defaultMenuProc.collected = ""
      root.rebuildItemsFromSources()
      if (defaultMenuProc.reloadPending) Qt.callLater(function() { root.loadMenuFile(defaultMenuProc, root.defaultMenuPath) })
    }
  }

  BoundedProcess {
    id: userMenuProc
    property bool reloadPending: false
    onExited: function(exitCode) {
      root.userMenuItems = (userMenuProc.ok && exitCode === 0) ? root.parseMenuJsonc(userMenuProc.collected) : []
      userMenuProc.collected = ""
      root.rebuildItemsFromSources()
      if (userMenuProc.reloadPending) Qt.callLater(function() { root.loadMenuFile(userMenuProc, root.userMenuPath) })
    }
  }

  // The bar already checks for updates at startup; wait a bit so two
  // `checkupdates` runs don't race, then keep the count fresh.
  Timer {
    id: updatesTimer
    interval: 90 * 1000
    repeat: true
    running: root.pluginDir !== ""
    onTriggered: {
      root.loadUpdates()
      interval = root.updateCheckMinutes * 60 * 1000
    }
  }

  function loadStatus() {
    if (!root.pluginDir) return
    if (!statusProc.running) {
      statusProc.command = [root.pluginDir + "/scripts/status"]
      statusProc.running = true
    }
    if (!tabletStatusProc.running) {
      tabletStatusProc.command = [root.pluginDir + "/scripts/tablet-status"]
      tabletStatusProc.running = true
    }
  }

  function loadUpdates() {
    if (!root.pluginDir || updatesProc.running) return
    updatesProc.command = [root.pluginDir + "/scripts/updates"]
    updatesProc.running = true
  }

  // Give the shell a beat after (re)loading the plugin before spawning the
  // helper scripts; starting them inside the load itself fails intermittently.
  Timer {
    id: bootTimer
    interval: 250
    onTriggered: {
      root.loadMenuFile(defaultMenuProc, root.defaultMenuPath)
      root.loadMenuFile(userMenuProc, root.userMenuPath)
      root.loadKeybinds(true)
      root.loadStatus()
      root.loadQuickLinks()
      root.loadExchangeRates()
    }
  }
  onPluginDirChanged: if (root.pluginDir) bootTimer.restart()

  PointerMoveGate {
    id: pointerGate
    referenceItem: tabletChassis
  }

  Connections {
    target: root.appLibrary
    function onAppsChanged() {
      if (root.providersLoaded["apps"]) root.mergeAppRows()
      else root.rebuildAppShortcuts()
    }
  }

  FileView {
    id: defaultMenuWatch
    path: root.defaultMenuPath
    preload: false
    watchChanges: true
    printErrors: false
    onFileChanged: root.loadMenuFile(defaultMenuProc, root.defaultMenuPath)
  }

  FileView {
    id: userMenuWatch
    path: root.userMenuPath
    preload: false
    watchChanges: true
    printErrors: false
    onFileChanged: root.loadMenuFile(userMenuProc, root.userMenuPath)
  }

  FileView {
    id: quickLinksWatch
    path: root.quickLinksPath
    preload: false
    watchChanges: true
    printErrors: false
    onFileChanged: root.loadQuickLinks()
  }

  BoundedProcess {
    id: quickLinksProc
    onExited: function(code) {
      if (code === 0 && quickLinksProc.ok && quickLinksProc.collected.length > 0) {
        try {
          var parsed = JSON.parse(quickLinksProc.collected)
          if (Array.isArray(parsed) && parsed.length > 0) {
            root.quickLinksList = parsed
            if (root.opened && root.filterText.trim()) root.rebuildDisplay()
          }
        } catch (e) {}
      }
    }
  }

  function loadQuickLinks() {
    if (!root.pluginDir) return
    quickLinksProc.deadlineMs = root.helperTimeoutMs
    quickLinksProc.command = [root.pluginDir + "/scripts/read-file", root.quickLinksPath, String(root.maxMenuFileBytes)]
    quickLinksProc.running = true
  }

  BoundedProcess {
    id: exchangeRatesProc
    onExited: function(code) {
      if (code === 0 && exchangeRatesProc.ok && exchangeRatesProc.collected.length > 0) {
        try {
          var parsed = JSON.parse(exchangeRatesProc.collected)
          if (parsed && parsed.rates) {
            root.exchangeRates = parsed.rates
            if (root.opened && root.filterText.trim()) root.rebuildDisplay()
          }
        } catch (e) {}
      }
    }
  }

  function loadExchangeRates() {
    exchangeRatesProc.deadlineMs = 15000
    exchangeRatesProc.command = ["bash", "-c", "cache=\"$HOME/.cache/omarchy/exchange_rates.json\"; if [[ ! -f \"$cache\" || $(find \"$cache\" -mtime +1 2>/dev/null) ]]; then mkdir -p \"$HOME/.cache/omarchy\" && curl -fsSL --max-time 4 https://open.er-api.com/v6/latest/USD -o \"$cache\" 2>/dev/null; fi; cat \"$cache\" 2>/dev/null || true"]
    exchangeRatesProc.running = true
  }

  BoundedProcess {
    id: fmhyProc
    property string targetQuery: ""
    onExited: function(code) {
      root.fmhySearching = false
      if (code === 0 && fmhyProc.ok && fmhyProc.collected.length > 0) {
        try {
          var parsed = JSON.parse(fmhyProc.collected)
          if (Array.isArray(parsed)) {
            var cache = Object.assign({}, root.fmhyCache)
            cache[fmhyProc.targetQuery] = parsed
            root.fmhyCache = cache
            if (root.opened && root.filterText.trim()) {
              var currSub = root.filterText.trim().replace(/^(?:fmhy|f)\s+/i, "").trim()
              if (currSub === fmhyProc.targetQuery) {
                root.currentFmhyResults = parsed
                root.rebuildDisplay()
              }
            }
          }
        } catch (e) {}
      }
    }
  }

  function dispatchFmhySearch(subQuery) {
    if (!root.pluginDir || !subQuery) return
    if (fmhyProc.running && fmhyProc.targetQuery === subQuery) return
    fmhyProc.running = false
    fmhyProc.deadlineMs = 5000
    fmhyProc.targetQuery = subQuery
    fmhyProc.command = [root.pluginDir + "/scripts/fmhy-search", subQuery]
    fmhyProc.running = true
  }

  function summonFmhyDeck(action) {
    applySerial = requestSerial
    var q = (action === "fmhy-panel" || !action) ? "" : action
    Util.execDetached("qs ipc -n -p /usr/share/omarchy/shell call io.github.i12bp8.fmhy-deck search " + Util.shellQuote(q))
    root.dismissMenu()
  }

  // ------------------------------------------------------------------ guards
  //
  // `when:` / `checked:` are batched into one bash run, same as the built-in
  // menu. See MenuModel.guardScript for the details.

  property var whenResults: ({})
  property var checkedResults: ({})
  property bool guardsPending: false

  function evaluateGuards() {
    if (guardProc.running) {
      root.guardsPending = true
      return
    }
    root.guardsPending = false

    var script = MenuModel.guardScript(root.items)
    if (!script) {
      root.whenResults = ({})
      root.checkedResults = ({})
      return
    }
    guardProc.command = ["bash", "-c", script]
    guardProc.running = true
  }

  BoundedProcess {
    id: guardProc
    deadlineMs: root.guardTimeoutMs
    onExited: function(exitCode, exitStatus) {
      if (!guardProc.ok || exitCode !== 0 || exitStatus !== 0) {
        guardProc.collected = ""
        if (root.guardsPending) Qt.callLater(function() { root.evaluateGuards() })
        return
      }

      var nextWhen = ({})
      var nextChecked = ({})
      var lines = guardProc.collected.split("\n")
      guardProc.collected = ""
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        var colon = line.lastIndexOf(":")
        if (colon < 0) continue
        var value = line.substring(colon + 1) === "1"
        var rest = line.substring(0, colon)
        var tagAt = rest.lastIndexOf(":")
        if (tagAt < 0) continue
        var id = rest.substring(0, tagAt)
        var tag = rest.substring(tagAt + 1)
        if (tag === "w") nextWhen[id] = value
        else if (tag === "c") nextChecked[id] = value
      }
      var changed = false
      for (var kw in nextWhen) {
        if (root.whenResults[kw] !== nextWhen[kw]) { changed = true; break }
      }
      if (!changed) {
        for (var kc in nextChecked) {
          if (root.checkedResults[kc] !== nextChecked[kc]) { changed = true; break }
        }
      }
      root.whenResults = nextWhen
      root.checkedResults = nextChecked
      if (changed && root.opened && root.activeMenu !== "apps") {
        root.rebuildDisplay()
      }
      if (root.guardsPending) Qt.callLater(function() { root.evaluateGuards() })
    }
  }

  // Permanent icon memory cache: pre-warms all app icon textures in background threads
  // so they are NEVER evicted from RAM/GPU cache even after 10+ minutes of idle.
  Item {
    visible: false
    width: 0
    height: 0
    Repeater {
      model: root.cachedAppDefaultRows
      delegate: Image {
        required property var modelData
        source: modelData && modelData.appIcon ? (modelData.appIcon.indexOf("://") >= 0 ? modelData.appIcon : (root.appLibrary ? root.appLibrary.iconSource(modelData.appIcon) : "")) : ""
        sourceSize.width: Style.space(32) * Screen.devicePixelRatio
        sourceSize.height: Style.space(32) * Screen.devicePixelRatio
        cache: true
        asynchronous: true
      }
    }
  }

  // --------------------------------------------------------------- surface

  PanelWindow {
    id: panel
    visible: (root.opened || root.isClosing || root.openProgress > 0.001) && root.rowsLoaded
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Dimmed desktop scrim
    Rectangle {
      anchors.fill: parent
      color: root.scrim
      opacity: root.openProgress
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.opened && !root.isClosing
      onClicked: root.cancel()
    }

    // Tablet / Phone Device Container
    Item {
      id: tabletContainer
      readonly property int targetChassisDepthX: root.isPhoneMode ? Style.space(8) : Style.space(18)
      readonly property int targetChassisDepthY: root.isPhoneMode ? Style.space(6) : Style.space(12)
      readonly property int targetChassisRadius: root.isPhoneMode ? Style.space(36) : Style.space(26)

      property int chassisDepthX: targetChassisDepthX
      property int chassisDepthY: targetChassisDepthY
      property int chassisRadius: targetChassisRadius

      Behavior on chassisDepthX { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on chassisDepthY { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on chassisRadius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

      readonly property int frontWidth: root.cardWidth
      readonly property int frontHeight: Math.min(root.cardHeight, panel.height - Style.gapsOut * 2)

      // Dynamic theme-adaptive physical device materials
      readonly property color chassisBaseColor: Qt.tint(root.background, Util.alpha(root.foreground, 0.18))
      readonly property color chassisSideWallColor: Qt.tint(root.background, Util.alpha(root.foreground, 0.28))
      readonly property color chassisShadeColor: Qt.tint(root.background, Util.alpha(root.foreground, 0.08))
      readonly property color chassisChamfer: Util.alpha(root.foreground, 0.48)

      width: frontWidth + chassisDepthX
      height: frontHeight + chassisDepthY
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.round((panel.height - height) / 2) + root.slideOffsetY

      // Organic depth scale: subtle 4% elevation lift as it glides from bottom to center
      scale: 0.96 + (0.04 * root.openProgress)
      transformOrigin: Item.Center

      // Seamless edge dissolve from 0.0 at threshold to 1.0 solid by mid-flight
      opacity: Math.min(1.0, root.openProgress * 2.0)

      // Hardware-accelerated GPU offscreen layer caching
      layer.enabled: true
      layer.smooth: true

      // Dynamic 3D Gadget Orientation (adapts between landscape tablet and vertical phone)
      readonly property real targetAngleX: root.isPhoneMode ? 3.0 : 4.5
      readonly property real targetAngleY: root.isPhoneMode ? -4.5 : -8.0
      readonly property real targetAngleZ: root.isPhoneMode ? -2.0 : -5.5

      property real rotAngleX: targetAngleX
      property real rotAngleY: targetAngleY
      property real rotAngleZ: targetAngleZ

      Behavior on rotAngleX { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on rotAngleY { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
      Behavior on rotAngleZ { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

      // 3D Perspective Rotation Transform
      transform: [
        Rotation {
          origin.x: tabletContainer.width / 2
          origin.y: tabletContainer.height / 2
          axis.x: 1; axis.y: 0; axis.z: 0
          angle: tabletContainer.rotAngleX
        },
        Rotation {
          origin.x: tabletContainer.width / 2
          origin.y: tabletContainer.height / 2
          axis.x: 0; axis.y: 1; axis.z: 0
          angle: tabletContainer.rotAngleY
        },
        Rotation {
          origin.x: tabletContainer.width / 2
          origin.y: tabletContainer.height / 2
          axis.x: 0; axis.y: 0; axis.z: 1
          angle: tabletContainer.rotAngleZ
        }
      ]

      // Prevent clicks inside the tablet container from dismissing
      MouseArea {
        anchors.fill: parent
        enabled: root.opened && !root.isClosing
        onClicked: {}
      }

      // -------------------------------------------------------------
      // 1. 3D Floating Ambient Drop Shadows (Multi-stage Depth Occlusion)
      // -------------------------------------------------------------
      // Deep diffuse ambient blur (floating suspension)
      Rectangle {
        x: tabletContainer.chassisDepthX + (root.isPhoneMode ? Style.space(2) : Style.space(14))
        y: tabletContainer.chassisDepthY + (root.isPhoneMode ? Style.space(3) : Style.space(20))
        width: tabletContainer.frontWidth
        height: tabletContainer.frontHeight
        radius: tabletContainer.chassisRadius + (root.isPhoneMode ? Style.space(2) : Style.space(12))
        color: "#000000"
        opacity: root.isPhoneMode ? 0.35 : 0.62
        z: -3
      }

      // Medium direct projection shadow
      Rectangle {
        x: tabletContainer.chassisDepthX + (root.isPhoneMode ? Style.space(1) : Style.space(6))
        y: tabletContainer.chassisDepthY + (root.isPhoneMode ? Style.space(1) : Style.space(9))
        width: tabletContainer.frontWidth
        height: tabletContainer.frontHeight
        radius: tabletContainer.chassisRadius + (root.isPhoneMode ? Style.space(1) : Style.space(6))
        color: "#000000"
        opacity: root.isPhoneMode ? 0.40 : 0.70
        z: -2
      }

      // Close contact occlusion shadow under chassis edge
      Rectangle {
        x: tabletContainer.chassisDepthX + (root.isPhoneMode ? 0 : Style.space(2))
        y: tabletContainer.chassisDepthY + (root.isPhoneMode ? 0 : Style.space(3))
        width: tabletContainer.frontWidth
        height: tabletContainer.frontHeight
        radius: tabletContainer.chassisRadius + (root.isPhoneMode ? 0 : Style.space(2))
        color: "#000000"
        opacity: root.isPhoneMode ? 0.50 : 0.80
        z: -1
      }

      // -------------------------------------------------------------
      // 2. 3D Extruded Unibody Chassis Body (Concentric Precision Extrusion)
      // -------------------------------------------------------------
      // 24 concentric slices stacked from back to front along the 3D extrusion vector.
      // Every slice shares the exact same frontWidth, frontHeight, and chassisRadius.
      // This mathematically guarantees 100% continuous curvature across all 4 corners,
      // eliminating any bulging, seams, or mismatched corner radii.
      Item {
        id: unibodyChassisExtrusion
        anchors.fill: parent
        z: 2
        layer.enabled: true
        layer.smooth: true

        Repeater {
          model: 48
          Rectangle {
            // index 0 is deepest back slice (t = 1.0), index 47 is closest front slice (t = 0.0)
            readonly property real t: (47 - index) / 47.0
            x: tabletContainer.chassisDepthX * t
            y: tabletContainer.chassisDepthY * t
            width: tabletContainer.frontWidth
            height: tabletContainer.frontHeight
            radius: tabletContainer.chassisRadius

            gradient: Gradient {
              orientation: Gradient.Horizontal
              // Left side / bottom-left: ambient shadow
              GradientStop {
                position: 0.0
                color: Qt.tint(tabletContainer.chassisShadeColor, Util.alpha("#000000", 0.60))
              }
              // Center bottom: smooth metallic midtone
              GradientStop {
                position: 0.70
                color: Qt.tint(tabletContainer.chassisSideWallColor, Util.alpha(tabletContainer.chassisShadeColor, 0.35))
              }
              // Right side / bottom-right: crisp metallic highlight catching key light
              GradientStop {
                position: 1.0
                color: Qt.lighter(tabletContainer.chassisSideWallColor, 1.15)
              }
            }

            // Precision CNC rear chamfer outline on the deepest back slice (index 0)
            border.color: index === 0 ? Util.alpha(tabletContainer.chassisChamfer, 0.45) : "transparent"
            border.width: index === 0 ? 1.0 : 0
          }
        }
      }

      // -------------------------------------------------------------
      // 3. Bottom Wall Hardware Features (Volume, Power, Dock)
      // -------------------------------------------------------------
      Item {
        id: bottomHardwareFeatures
        visible: !root.isPhoneMode
        x: 0
        y: tabletContainer.frontHeight
        width: tabletContainer.frontWidth
        height: tabletContainer.chassisDepthY
        z: 6

        // 3a. Smart Connector / Magnetic Accessory Dock (Center)
        Rectangle {
          id: bottomSmartDock
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(88)
          height: Style.space(3.2)
          radius: Style.space(1.6)
          color: Util.alpha(root.foreground, 0.12)
          border.color: Util.alpha(root.foreground, 0.24)
          border.width: 0.6

          Row {
            anchors.centerIn: parent
            spacing: Style.space(14)
            Repeater {
              model: 3
              Rectangle {
                width: Style.space(3.6)
                height: Style.space(3.6)
                radius: Style.space(1.8)
                color: Util.alpha(root.selectedText, 0.95)
                border.color: "#05070a"
                border.width: 0.6
              }
            }
          }
        }

        // 3b. Volume Rocker Button (Volume Up / Down)
        Rectangle {
          id: bottomVolumeRocker
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: bottomPowerButton.left
          anchors.rightMargin: Style.space(22)
          width: Style.space(68)
          height: Style.space(4.2)
          radius: Style.space(2.1)
          color: Qt.tint(root.background, Util.alpha(root.foreground, 0.36))
          border.color: Util.alpha(root.foreground, 0.52)
          border.width: 0.8

          // Center separation slit between + and -
          Rectangle {
            anchors.centerIn: parent
            width: 1
            height: parent.height * 0.7
            color: Util.alpha(root.foreground, 0.40)
          }

          // Volume Plus (+) indicator bar
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Style.space(14)
            width: Style.space(6)
            height: 1.2
            radius: 0.6
            color: Util.alpha(root.foreground, 0.65)
          }

          // Volume Minus (-) indicator bar
          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Style.space(14)
            width: Style.space(6)
            height: 1.2
            radius: 0.6
            color: Util.alpha(root.foreground, 0.65)
          }
        }

        // 3c. Power / Sleep Button
        Rectangle {
          id: bottomPowerButton
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: parent.right
          anchors.rightMargin: Style.space(120)
          width: Style.space(38)
          height: Style.space(4.2)
          radius: Style.space(2.1)
          color: Qt.tint(root.background, Util.alpha(root.foreground, 0.36))
          border.color: Util.alpha(root.foreground, 0.52)
          border.width: 0.8

          // Tactile ridge highlight
          Rectangle {
            anchors.centerIn: parent
            width: Style.space(8)
            height: 1.2
            radius: 0.6
            color: Util.alpha(root.foreground, 0.75)
          }
        }

        // 3d. SIM / Tray Eject Pinhole
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          x: Style.space(120)
          width: Style.space(2.8)
          height: Style.space(2.8)
          radius: Style.space(1.4)
          color: "#020305"
          border.color: Util.alpha(root.foreground, 0.35)
          border.width: 0.7
        }

        // 3e. Bottom Antenna Band Polymer Isolation Seams
        Rectangle {
          x: Style.space(70)
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 1.5
          color: Util.alpha(root.foreground, 0.35)
        }
        Rectangle {
          x: parent.width - Style.space(70)
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          width: 1.5
          color: Util.alpha(root.foreground, 0.35)
        }
      }

      // -------------------------------------------------------------
      // 4. Tablet Right Side Wall Hardware Features (Charging Port & Speakers)
      // -------------------------------------------------------------
      Item {
        id: rightHardwareFeatures
        visible: !root.isPhoneMode
        x: tabletContainer.frontWidth
        y: 0
        width: tabletContainer.chassisDepthX
        height: tabletContainer.frontHeight
        z: 6

        // 4a. Precision Center USB-C / Thunderbolt Port (Vertical)
        Rectangle {
          id: rightUsbPort
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(7.2)
          height: Style.space(34)
          radius: Style.space(3.6)
          color: "#030407"
          border.color: Util.alpha(tabletContainer.chassisChamfer, 0.90)
          border.width: 1.0

          // Inner rim chamfer highlight
          Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height * 0.65
            color: Util.alpha(root.foreground, 0.40)
          }

          // Port interior depth cavity
          Rectangle {
            anchors.fill: parent
            anchors.margins: 1.0
            radius: Style.space(2.6)
            color: "#010204"

            // Central metallic contact tongue (vertical gold/titanium)
            Rectangle {
              anchors.centerIn: parent
              width: Style.space(2.2)
              height: Style.space(18)
              radius: 1.1
              color: Util.alpha(root.selectedText, 0.95)

              // Micro contact pin stripes
              Column {
                anchors.centerIn: parent
                spacing: Style.space(2.4)
                Repeater {
                  model: 5
                  Rectangle {
                    width: Style.space(1.4)
                    height: Style.space(1.1)
                    color: "#241804"
                  }
                }
              }
            }
          }
        }

        // 4b. Precision Pentalobe / Torx Security Chassis Screws
        // Top Screw
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: rightUsbPort.top
          anchors.bottomMargin: Style.space(16)
          width: Style.space(4.2)
          height: Style.space(4.2)
          radius: Style.space(2.1)
          color: "#05070a"
          border.color: Util.alpha(root.foreground, 0.48)
          border.width: 0.8

          Rectangle {
            anchors.centerIn: parent
            width: 1.4
            height: 1.4
            radius: 0.7
            color: Util.alpha(root.foreground, 0.85)
          }
        }

        // Bottom Screw
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: rightUsbPort.bottom
          anchors.topMargin: Style.space(16)
          width: Style.space(4.2)
          height: Style.space(4.2)
          radius: Style.space(2.1)
          color: "#05070a"
          border.color: Util.alpha(root.foreground, 0.48)
          border.width: 0.8

          Rectangle {
            anchors.centerIn: parent
            width: 1.4
            height: 1.4
            radius: 0.7
            color: Util.alpha(root.foreground, 0.85)
          }
        }

        // 4c. Top Stereo Acoustic Speaker Array (Vertical Circular Grill Holes)
        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: rightUsbPort.top
          anchors.bottomMargin: Style.space(38)
          spacing: Style.space(5.5)

          Repeater {
            model: 5
            Rectangle {
              width: Style.space(4.5)
              height: Style.space(4.5)
              radius: Style.space(2.25)
              color: "#030406"
              border.color: Util.alpha(root.foreground, 0.40)
              border.width: 0.7

              Rectangle {
                anchors.centerIn: parent
                width: Style.space(2.2)
                height: Style.space(2.2)
                radius: 1.1
                color: "#06090e"
              }
            }
          }
        }

        // 4d. Bottom Stereo Acoustic Speaker Array (Vertical Circular Grill Holes)
        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: rightUsbPort.bottom
          anchors.topMargin: Style.space(38)
          spacing: Style.space(5.5)

          Repeater {
            model: 5
            Rectangle {
              width: Style.space(4.5)
              height: Style.space(4.5)
              radius: Style.space(2.25)
              color: "#030406"
              border.color: Util.alpha(root.foreground, 0.40)
              border.width: 0.7

              Rectangle {
                anchors.centerIn: parent
                width: Style.space(2.2)
                height: Style.space(2.2)
                radius: 1.1
                color: "#06090e"
              }
            }
          }
        }

        // 4e. Studio Mic Pinhole
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: Style.space(110)
          width: Style.space(2.8)
          height: Style.space(2.8)
          radius: Style.space(1.4)
          color: "#020305"
          border.color: Util.alpha(root.foreground, 0.35)
          border.width: 0.7
        }

        // 4f. Right Antenna Band Polymer Isolation Seams
        Rectangle {
          y: Style.space(56)
          anchors.left: parent.left
          anchors.right: parent.right
          height: 1.5
          color: Util.alpha(root.foreground, 0.35)
        }
        Rectangle {
          y: parent.height - Style.space(56)
          anchors.left: parent.left
          anchors.right: parent.right
          height: 1.5
          color: Util.alpha(root.foreground, 0.35)
        }
      }

      // -------------------------------------------------------------
      // 4b. Phone Bottom Wall Hardware (USB-C & Stereo Speakers)
      // -------------------------------------------------------------
      Item {
        id: phoneBottomHardwareFeatures
        visible: root.isPhoneMode
        x: 0
        y: tabletContainer.frontHeight
        width: tabletContainer.frontWidth
        height: tabletContainer.chassisDepthY
        z: 6

        // Phone Center USB-C Port
        Rectangle {
          id: phoneUsbPort
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(20)
          height: Style.space(3.2)
          radius: Style.space(1.6)
          color: "#030407"
          border.color: Util.alpha(tabletContainer.chassisChamfer, 0.90)
          border.width: 0.8

          // Metallic tongue
          Rectangle {
            anchors.centerIn: parent
            width: Style.space(10)
            height: Style.space(1.2)
            radius: 0.6
            color: Util.alpha(root.selectedText, 0.90)
          }
        }

        // Left Speaker Array
        Row {
          anchors.verticalCenter: parent.verticalCenter
          anchors.right: phoneUsbPort.left
          anchors.rightMargin: Style.space(16)
          spacing: Style.space(4)

          Repeater {
            model: 3
            Rectangle {
              width: Style.space(2.6)
              height: Style.space(2.6)
              radius: Style.space(1.3)
              color: "#030406"
              border.color: Util.alpha(root.foreground, 0.38)
              border.width: 0.6
            }
          }
        }

        // Right Speaker Array
        Row {
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: phoneUsbPort.right
          anchors.leftMargin: Style.space(16)
          spacing: Style.space(4)

          Repeater {
            model: 3
            Rectangle {
              width: Style.space(2.6)
              height: Style.space(2.6)
              radius: Style.space(1.3)
              color: "#030406"
              border.color: Util.alpha(root.foreground, 0.38)
              border.width: 0.6
            }
          }
        }

        // Mic Pinhole
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          x: Style.space(32)
          width: Style.space(2.4)
          height: Style.space(2.4)
          radius: Style.space(1.2)
          color: "#020305"
          border.color: Util.alpha(root.foreground, 0.30)
          border.width: 0.6
        }
      }

      // -------------------------------------------------------------
      // 4c. Phone Right Side Wall Hardware (Power / Side Button)
      // -------------------------------------------------------------
      Item {
        id: phoneRightHardwareFeatures
        visible: root.isPhoneMode
        x: tabletContainer.frontWidth
        y: 0
        width: tabletContainer.chassisDepthX
        height: tabletContainer.frontHeight
        z: 6

        // Power / Lock button
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: Style.space(140)
          width: Style.space(4.0)
          height: Style.space(62)
          radius: Style.space(2.0)
          color: Qt.tint(root.background, Util.alpha(root.foreground, 0.38))
          border.color: Util.alpha(root.foreground, 0.52)
          border.width: 0.8

          Rectangle {
            anchors.centerIn: parent
            width: 1.2
            height: Style.space(16)
            radius: 0.6
            color: Util.alpha(root.foreground, 0.65)
          }
        }

        // SIM Tray Pinhole
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: Style.space(240)
          width: Style.space(2.4)
          height: Style.space(2.4)
          radius: Style.space(1.2)
          color: "#020305"
          border.color: Util.alpha(root.foreground, 0.32)
          border.width: 0.6
        }

        // Antenna Bands
        Rectangle {
          y: Style.space(55)
          anchors.left: parent.left
          anchors.right: parent.right
          height: 1.4
          color: Util.alpha(root.foreground, 0.32)
        }
        Rectangle {
          y: parent.height - Style.space(55)
          anchors.left: parent.left
          anchors.right: parent.right
          height: 1.4
          color: Util.alpha(root.foreground, 0.32)
        }
      }

      // -------------------------------------------------------------
      // 4d. Phone Left Side Rail Hardware (Action & Volume Buttons)
      // -------------------------------------------------------------
      Item {
        id: phoneLeftHardwareFeatures
        visible: root.isPhoneMode
        x: 0
        y: 0
        width: 1
        height: tabletContainer.frontHeight
        z: 6

        // Action Button
        Rectangle {
          anchors.right: parent.left
          anchors.rightMargin: -1
          y: Style.space(96)
          width: Style.space(3.2)
          height: Style.space(22)
          radius: Style.space(1.6)
          color: Qt.tint(root.background, Util.alpha(root.foreground, 0.36))
          border.color: Util.alpha(root.foreground, 0.50)
          border.width: 0.8
        }

        // Volume Up Button
        Rectangle {
          anchors.right: parent.left
          anchors.rightMargin: -1
          y: Style.space(132)
          width: Style.space(3.2)
          height: Style.space(42)
          radius: Style.space(1.6)
          color: Qt.tint(root.background, Util.alpha(root.foreground, 0.36))
          border.color: Util.alpha(root.foreground, 0.50)
          border.width: 0.8
        }

        // Volume Down Button
        Rectangle {
          anchors.right: parent.left
          anchors.rightMargin: -1
          y: Style.space(186)
          width: Style.space(3.2)
          height: Style.space(42)
          radius: Style.space(1.6)
          color: Qt.tint(root.background, Util.alpha(root.foreground, 0.36))
          border.color: Util.alpha(root.foreground, 0.50)
          border.width: 0.8
        }
      }

      // -------------------------------------------------------------
      // 5. Tablet Titanium Chassis (Front Face)
      // -------------------------------------------------------------
      Rectangle {
        id: tabletChassis
        x: 0
        y: 0
        width: tabletContainer.frontWidth
        height: tabletContainer.frontHeight
        radius: tabletContainer.chassisRadius
        color: tabletContainer.chassisBaseColor
        border.color: tabletContainer.chassisChamfer
        border.width: 1.5
        z: 10

        // Inner metallic chamfer line
        Rectangle {
          anchors.fill: parent
          anchors.margins: 1
          radius: tabletContainer.chassisRadius - 1
          color: "transparent"
          border.color: Util.alpha(root.foreground, 0.15)
          border.width: 1
        }

        // Phone Top Bezel Earpiece Speaker Slit
        Rectangle {
          id: phoneEarpieceSpeaker
          visible: root.isPhoneMode
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(4.2)
          width: Style.space(52)
          height: Style.space(3.2)
          radius: Style.space(1.6)
          color: "#05070a"
          border.color: Util.alpha(root.foreground, 0.25)
          border.width: 0.6
          z: 25
        }

        // -----------------------------------------------------------
        // 6. Uniform Tablet Display Bezel (Obsidian Glass)
        // -----------------------------------------------------------
        Rectangle {
          id: tabletBezel
          anchors.fill: parent
          anchors.margins: root.isPhoneMode ? Style.space(9) : Style.space(13)
          radius: tabletContainer.chassisRadius - (root.isPhoneMode ? Style.space(9) : Style.space(13))
          color: Qt.darker(root.background, 1.55)

          // ---------------------------------------------------------
          // Landscape Camera Notch / Dynamic Island on Left Bezel Edge
          // Protrudes into the screen like modern tablets/smartphones
          // ---------------------------------------------------------
          Item {
            id: cameraModule
            visible: !root.isPhoneMode
            width: Style.space(18)
            height: Style.space(62)
            anchors.left: parent.left
            anchors.leftMargin: Style.space(4)
            anchors.verticalCenter: parent.verticalCenter
            z: 40

            // Notch Housing
            Rectangle {
              anchors.fill: parent
              radius: Style.space(9)
              color: "#080b10"
              border.color: Util.alpha(root.foreground, 0.28)
              border.width: 1.2

              Column {
                anchors.centerIn: parent
                spacing: Style.space(6)

                // Front camera sensor
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: Style.space(9)
                  height: Style.space(9)
                  radius: Style.space(4.5)
                  color: "#0c1322"
                  border.color: Util.alpha(root.foreground, 0.24)
                  border.width: 0.8

                  // Sapphire lens reflection
                  Rectangle {
                    anchors.centerIn: parent
                    width: Style.space(5)
                    height: Style.space(5)
                    radius: Style.space(2.5)
                    color: "#162842"

                    // Specular glint
                    Rectangle {
                      x: 0.8; y: 0.8
                      width: Style.space(1.6)
                      height: Style.space(1.6)
                      radius: 0.8
                      color: Util.alpha(root.selectedText, 0.85)
                    }
                  }
                }

                // Ambient light sensor pinhole
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: Style.space(3.5)
                  height: Style.space(3.5)
                  radius: Style.space(1.75)
                  color: "#05070a"
                }

                // Acoustic mic / speaker slit
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: Style.space(2.6)
                  height: Style.space(16)
                  radius: Style.space(1.3)
                  color: "#05070a"
                  border.color: Util.alpha(root.foreground, 0.16)
                  border.width: 0.5
                }
              }
            }
          }

          // 5. Tablet Display Screen (Inside Bezel)
          Rectangle {
            id: tabletScreen
            anchors.fill: parent
            radius: tabletBezel.radius
            color: Qt.darker(root.background, 1.45)
            border.color: Util.alpha(root.foreground, 0.14)
            border.width: 1

            // 5a. Masked Screen Surface Layer (clips wallpaper, gradient & glows cleanly to screen corners)
            Item {
              id: screenBackgroundLayer
              anchors.fill: parent
              layer.enabled: true
              layer.smooth: true
              layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: screenCornerMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 0.02
              }

              // Authentic Desktop Wallpaper from Omarchy Theme (hardware downscaled)
              Image {
                id: tabletWallpaper
                anchors.fill: parent
                source: Util.fileUrl(root.currentBackgroundPath)
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 1024
                sourceSize.height: 640
                asynchronous: true
                cache: true
                smooth: true
                opacity: 0.35
              }

              // Theme-Matched Glass Vignette & Depth Gradient
              Rectangle {
                anchors.fill: parent
                radius: tabletScreen.radius
                gradient: Gradient {
                  GradientStop { position: 0.0; color: Util.alpha(root.background, 0.75) }
                  GradientStop { position: 0.50; color: Util.alpha(root.background, 0.88) }
                  GradientStop { position: 1.0; color: Util.alpha(root.background, 0.95) }
                }
              }

              // Theme Ambient Accent Glows (e.g. Warm Coral in Harbordark)
              Rectangle {
                width: Style.space(420)
                height: Style.space(420)
                radius: Style.space(210)
                x: parent.width - Style.space(260)
                y: -Style.space(160)
                color: Util.alpha(root.selectedText, 0.08)
              }

              Rectangle {
                width: Style.space(320)
                height: Style.space(320)
                radius: Style.space(160)
                x: -Style.space(120)
                y: parent.height - Style.space(200)
                color: Util.alpha(root.selectedText, 0.04)
              }
            }

            // Screen Corner Precision Mask (Alpha stencil for MultiEffect)
            Item {
              id: screenCornerMask
              anchors.fill: parent
              visible: false
              layer.enabled: true
              layer.smooth: true

              Rectangle {
                anchors.fill: parent
                radius: tabletScreen.radius
                color: "#ffffff"
              }
            }

            // Keyboard Catcher
            Item {
              id: keyCatcher
              anchors.fill: parent
              z: root.deleteConfirmOpen ? 20 : 0
              focus: true

              Keys.priority: Keys.BeforeItem
              Keys.onPressed: function(event) {
                if (root.deleteConfirmOpen) {
                  if (deleteConfirm.handleKey(event)) event.accepted = true
                  return
                }

                if (event.key === Qt.Key_Escape) {
                  root.cancel()
                  event.accepted = true
                } else if (event.key === Qt.Key_Tab && !root.filterText && !root.dmenuActive) {
                  if (root.activeMenu === "apps") root.setActiveMenu("root", false)
                  else root.setActiveMenu("apps", false)
                  event.accepted = true
                } else if (event.key === Qt.Key_Delete || (root.isMathMode && event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier))) {
                  if (root.isMathMode && root.filterText) {
                    if (root.textCursorPos < root.filterText.length) {
                      var beforeDel = root.filterText.slice(0, root.textCursorPos)
                      var afterDel = root.filterText.slice(root.textCursorPos + 1)
                      root.setFilter(beforeDel + afterDel, root.textCursorPos)
                    }
                    event.accepted = true
                  } else if (!root.filterText) {
                    root.requestDeleteSelected()
                    event.accepted = true
                  }
                } else if (event.key === Qt.Key_Backspace && root.isMathMode && root.filterText) {
                  if (event.modifiers & Qt.ControlModifier) {
                    var prevPos = root.prevTokenPos(root.filterText, root.textCursorPos)
                    var beforeCtrl = root.filterText.slice(0, prevPos)
                    var afterCtrl = root.filterText.slice(root.textCursorPos)
                    root.setFilter(beforeCtrl + afterCtrl, prevPos)
                  } else if (root.textCursorPos > 0) {
                    var beforeChar = root.filterText.slice(0, root.textCursorPos - 1)
                    var afterChar = root.filterText.slice(root.textCursorPos)
                    root.setFilter(beforeChar + afterChar, root.textCursorPos - 1)
                  }
                  event.accepted = true
                } else if (Util.editsFilter(event, root.filterText)) {
                  root.setFilter(Util.editedFilter(event, root.filterText))
                  event.accepted = true
                } else if (event.key === Qt.Key_Backspace) {
                  if (!root.dmenuActive) root.goBack()
                  event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                  root.moveVertical(-1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                  root.moveVertical(1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                  if (root.isMathMode && root.filterText) {
                    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) {
                      root.textCursorPos = root.prevTokenPos(root.filterText, root.textCursorPos)
                    } else {
                      root.textCursorPos = Math.max(0, root.textCursorPos - 1)
                    }
                    event.accepted = true
                  } else {
                    root.moveHorizontal(-1)
                    event.accepted = true
                  }
                } else if (event.key === Qt.Key_Right) {
                  if (root.isMathMode && root.filterText) {
                    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) {
                      root.textCursorPos = root.nextTokenPos(root.filterText, root.textCursorPos)
                    } else {
                      root.textCursorPos = Math.min(root.filterText.length, root.textCursorPos + 1)
                    }
                    event.accepted = true
                  } else {
                    root.moveHorizontal(1)
                    event.accepted = true
                  }
                } else if (event.key === Qt.Key_Tab) {
                  root.moveHorizontal(1)
                  event.accepted = true
                } else if (event.key === Qt.Key_Backtab) {
                  root.moveHorizontal(-1)
                  event.accepted = true
                } else if (event.key === Qt.Key_PageUp) {
                  root.moveVertical(-3)
                  event.accepted = true
                } else if (event.key === Qt.Key_PageDown) {
                  root.moveVertical(3)
                  event.accepted = true
                } else if (event.key === Qt.Key_Home || (root.isMathMode && event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier))) {
                  if (root.isMathMode && root.filterText) {
                    root.textCursorPos = 0
                    event.accepted = true
                  } else if (!root.filterText) {
                    root.cursorActive = true; root.selectedIndex = 0; root.revealCursor()
                    event.accepted = true
                  }
                } else if (event.key === Qt.Key_End || (root.isMathMode && event.key === Qt.Key_E && (event.modifiers & Qt.ControlModifier))) {
                  if (root.isMathMode && root.filterText) {
                    root.textCursorPos = root.filterText.length
                    event.accepted = true
                  } else if (!root.filterText) {
                    root.cursorActive = true; root.selectedIndex = Math.max(0, displayModel.count - 1); root.revealCursor()
                    event.accepted = true
                  }
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  if (root.mode === "input") root.applyDmenuSelection(root.filterText)
                  else if (root.cursorActive) root.activateIndex(root.selectedIndex)
                  else if (displayModel.count > 0) root.activateIndex(0)
                  event.accepted = true
                } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
                  if (!root.filterText && event.text === " ") {
                    event.accepted = true
                    return
                  }
                  if (root.isMathMode && root.filterText && root.textCursorPos < root.filterText.length) {
                    var beforeText = root.filterText.slice(0, root.textCursorPos)
                    var afterText = root.filterText.slice(root.textCursorPos)
                    root.setFilter(beforeText + event.text + afterText, root.textCursorPos + 1)
                  } else {
                    root.setFilter(root.filterText + event.text, root.filterText.length + 1)
                  }
                  event.accepted = true
                }
              }
            }

            // Uninstall Confirm Dialog
            ConfirmDialog {
              id: deleteConfirm
              anchors.fill: parent
              opened: root.deleteConfirmOpen
              z: 10
              message: "Do you want to uninstall " + ((root.deleteTarget && root.deleteTarget.label) || "") + "?"
              confirmText: "Uninstall"
              background: root.background
              foreground: root.foreground
              scrim: root.scrim
              selectedBackground: root.selectedBackground
              selectedText: root.selectedText
              fontFamily: root.fontFamily
              cornerRadius: root.cornerRadius
              onCanceled: root.cancelDelete()
              onConfirmed: root.confirmDelete()
            }

            // ---------------- Inner Screen Content
            Column {
              id: contentTopColumn
              anchors.top: parent.top
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.margins: Style.space(12)
              spacing: Style.space(8)

              // ---- tablet / phone status bar
              Rectangle {
                id: tabletStatusBar
                width: parent.width
                height: root.isPhoneMode ? Style.space(34) : root.tabletBarHeight
                radius: root.isPhoneMode ? Style.space(12) : Style.space(8)
                color: Util.alpha(root.background, 0.60)
                border.color: Util.alpha(root.foreground, 0.10)
                border.width: 1

                // 1. Tablet Status Bar Elements
                Item {
                  id: tabletStatusRow
                  visible: !root.isPhoneMode
                  anchors.fill: parent

                  Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space(12)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(6)

                    Rectangle {
                      width: Style.space(6)
                      height: Style.space(6)
                      radius: Style.space(3)
                      color: root.selectedText
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: root.clockString
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.weight: Font.DemiBold
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space(12)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(12)

                    Text {
                      text: root.wifiText
                      color: root.foreground
                      opacity: 0.85
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: root.batteryText
                      color: root.foreground
                      opacity: 0.85
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                      width: 1
                      height: Style.space(12)
                      color: Util.alpha(root.foreground, 0.20)
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: "󰣇 Omarchy"
                      color: root.selectedText
                      opacity: 0.90
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.weight: Font.Medium
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }

                // 2. Phone Status Bar Elements (with Dynamic Island in Center)
                Item {
                  id: phoneStatusRow
                  visible: root.isPhoneMode
                  anchors.fill: parent

                  // Time on Left
                  Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(5)

                    Rectangle {
                      width: Style.space(5)
                      height: Style.space(5)
                      radius: Style.space(2.5)
                      color: root.selectedText
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: Qt.formatDateTime(new Date(), "HH:mm")
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.weight: Font.DemiBold
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  // Center Dynamic Island Pill
                  Item {
                    id: phoneDynamicIsland
                    anchors.centerIn: parent
                    width: Style.space(98)
                    height: Style.space(22)

                    Rectangle {
                      anchors.fill: parent
                      radius: Style.space(11)
                      color: "#030406"
                      border.color: Util.alpha(root.foreground, 0.28)
                      border.width: 1.0

                      Row {
                        anchors.centerIn: parent
                        spacing: Style.space(20)

                        // Ambient sensor
                        Rectangle {
                          width: Style.space(3.6)
                          height: Style.space(3.6)
                          radius: Style.space(1.8)
                          color: "#0c1322"
                          anchors.verticalCenter: parent.verticalCenter
                        }

                        // Micro speaker receiver
                        Rectangle {
                          width: Style.space(12)
                          height: Style.space(2.2)
                          radius: Style.space(1.1)
                          color: "#080c14"
                          border.color: Util.alpha(root.foreground, 0.15)
                          border.width: 0.5
                          anchors.verticalCenter: parent.verticalCenter
                        }

                        // Front camera sensor
                        Rectangle {
                          width: Style.space(8)
                          height: Style.space(8)
                          radius: Style.space(4)
                          color: "#09101d"
                          border.color: Util.alpha(root.foreground, 0.25)
                          border.width: 0.8
                          anchors.verticalCenter: parent.verticalCenter

                          Rectangle {
                            anchors.centerIn: parent
                            width: Style.space(4.2)
                            height: Style.space(4.2)
                            radius: Style.space(2.1)
                            color: "#162842"

                            Rectangle {
                              x: 0.7; y: 0.7
                              width: Style.space(1.4)
                              height: Style.space(1.4)
                              radius: 0.7
                              color: Util.alpha(root.selectedText, 0.85)
                            }
                          }
                        }
                      }
                    }
                  }

                  // Wi-Fi + Battery on Right
                  Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space(14)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(8)

                    Text {
                      text: "󰤨"
                      color: root.foreground
                      opacity: 0.85
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                      text: root.batteryText
                      color: root.foreground
                      opacity: 0.85
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }
              }

              // ---- tablet nav bar: segmented tabs (Apps vs Omarchy) or breadcrumb
              Item {
                id: tabletNavBar
                visible: !root.isPhoneMode
                width: parent.width
                height: Style.space(32)

                // 1. Segmented Control when at Root or Apps level
                Row {
                  visible: root.activeMenu === "apps" || root.activeMenu === "root"
                  anchors.centerIn: parent
                  spacing: Style.space(8)

                  // Tab: Applications
                  Rectangle {
                    id: tabAppsBtn
                    height: Style.space(28)
                    width: tabAppsContent.implicitWidth + Style.space(20)
                    radius: Style.space(14)
                    color: root.activeMenu === "apps" ? Util.alpha(root.selectedText, 0.22) : (tabAppsMa.containsMouse ? Util.alpha(root.foreground, 0.10) : Util.alpha(root.foreground, 0.05))
                    border.color: root.activeMenu === "apps" ? root.selectedText : (tabAppsMa.containsMouse ? Util.alpha(root.foreground, 0.20) : Util.alpha(root.foreground, 0.10))
                    border.width: 1
                    scale: (tabAppsMa.containsMouse && root.activeMenu !== "apps") ? 1.02 : 1.0

                    Row {
                      id: tabAppsContent
                      anchors.centerIn: parent
                      spacing: Style.space(6)

                      Text {
                        text: "󰀻"
                        color: root.activeMenu === "apps" ? root.selectedText : root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.icon
                        anchors.verticalCenter: parent.verticalCenter
                      }
                      Text {
                        text: "Applications (" + root.appCount() + ")"
                        color: root.activeMenu === "apps" ? root.selectedText : root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.weight: root.activeMenu === "apps" ? Font.Bold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }

                    MouseArea {
                      id: tabAppsMa
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.setActiveMenu("apps", false)
                    }
                  }

                  // Tab: Omarchy Menus
                  Rectangle {
                    id: tabMenusBtn
                    height: Style.space(28)
                    width: tabMenusContent.implicitWidth + Style.space(20)
                    radius: Style.space(14)
                    color: root.activeMenu === "root" ? Util.alpha(root.selectedText, 0.22) : (tabMenusMa.containsMouse ? Util.alpha(root.foreground, 0.10) : Util.alpha(root.foreground, 0.05))
                    border.color: root.activeMenu === "root" ? root.selectedText : (tabMenusMa.containsMouse ? Util.alpha(root.foreground, 0.20) : Util.alpha(root.foreground, 0.10))
                    border.width: 1
                    scale: (tabMenusMa.containsMouse && root.activeMenu !== "root") ? 1.02 : 1.0

                    Row {
                      id: tabMenusContent
                      anchors.centerIn: parent
                      spacing: Style.space(6)

                      Text {
                        text: "󰒓"
                        color: root.activeMenu === "root" ? root.selectedText : root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.icon
                        anchors.verticalCenter: parent.verticalCenter
                      }
                      Text {
                        text: "Omarchy Control"
                        color: root.activeMenu === "root" ? root.selectedText : root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.weight: root.activeMenu === "root" ? Font.Bold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }

                    MouseArea {
                      id: tabMenusMa
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.setActiveMenu("root", false)
                    }
                  }
                }

                // 2. Submenu Breadcrumb & Back Button
                Row {
                  visible: root.activeMenu !== "apps" && root.activeMenu !== "root"
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(10)

                  Rectangle {
                    height: Style.space(26)
                    width: backBtnRow.implicitWidth + Style.space(16)
                    radius: Style.space(13)
                    color: Util.alpha(root.foreground, 0.08)
                    border.color: Util.alpha(root.foreground, 0.16)
                    border.width: 1

                    Row {
                      id: backBtnRow
                      anchors.centerIn: parent
                      spacing: Style.space(4)

                      Text {
                        text: "‹"
                        color: root.selectedText
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.heading
                        anchors.verticalCenter: parent.verticalCenter
                      }
                      Text {
                        text: "Back"
                        color: root.foreground
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.goBack()
                    }
                  }

                  Text {
                    text: "Omarchy › " + root.pathFor(root.activeMenu)
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }

              // ---- phone nav bar: header with Back / Cancel, Section Title, and Esc
              Item {
                id: phoneNavBar
                visible: root.isPhoneMode
                width: parent.width
                height: Style.space(32)

                // Back / Cancel button on Left
                Rectangle {
                  id: phoneBackBtn
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  height: Style.space(26)
                  width: phoneBackContent.implicitWidth + Style.space(16)
                  radius: Style.space(13)
                  color: phoneBackMa.containsMouse ? Util.alpha(root.foreground, 0.14) : Util.alpha(root.foreground, 0.08)
                  border.color: phoneBackMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.16)
                  border.width: 1
                  scale: phoneBackMa.pressed ? 0.94 : (phoneBackMa.containsMouse ? 1.04 : 1.0)
                  Behavior on scale { NumberAnimation { duration: 120 } }
                  Behavior on color { ColorAnimation { duration: 120 } }

                  Row {
                    id: phoneBackContent
                    anchors.centerIn: parent
                    spacing: Style.space(4)

                    Text {
                      text: "‹"
                      color: root.selectedText
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.heading
                      font.weight: Font.Bold
                      anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                      text: root.dmenuActive ? "Cancel" : (root.navStack.length > 0 ? "Back" : "Omarchy")
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.weight: Font.DemiBold
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  MouseArea {
                    id: phoneBackMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.dmenuActive) root.cancel()
                      else root.goBack()
                    }
                  }
                }

                // Section Title in Center
                Text {
                  anchors.centerIn: parent
                  width: Math.min(implicitWidth, parent.width - Style.space(160))
                  text: root.dmenuActive ? root.dmenuPrompt : (root.item(root.activeMenu) ? (root.item(root.activeMenu).label || root.item(root.activeMenu).title || "Section") : "Section")
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.weight: Font.Bold
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignHCenter
                }

                // Close Pill on Right
                Rectangle {
                  id: phoneCloseBtn
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  height: Style.space(24)
                  width: phoneCloseContent.implicitWidth + Style.space(14)
                  radius: Style.space(12)
                  color: phoneCloseMa.containsMouse ? Util.alpha(root.selectedText, 0.22) : Util.alpha(root.foreground, 0.08)
                  border.color: phoneCloseMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.16)
                  border.width: 1
                  scale: phoneCloseMa.pressed ? 0.94 : (phoneCloseMa.containsMouse ? 1.04 : 1.0)
                  Behavior on scale { NumberAnimation { duration: 120 } }
                  Behavior on color { ColorAnimation { duration: 120 } }

                  Row {
                    id: phoneCloseContent
                    anchors.centerIn: parent
                    spacing: Style.space(3)

                    Text {
                      text: "esc ✕"
                      color: phoneCloseMa.containsMouse ? root.selectedText : root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.weight: Font.Medium
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  MouseArea {
                    id: phoneCloseMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancel()
                  }
                }
              }

              // ---- search box
              Rectangle {
                id: searchBox
                width: parent.width
                height: root.searchHeight
                radius: Style.space(21)
                readonly property bool active: root.filterText.length > 0
                color: active ? Util.alpha(root.background, 0.85) : Util.alpha(root.background, 0.65)
                border.color: active ? root.selectedText : Util.alpha(root.foreground, 0.16)
                border.width: active ? 1.5 : 1

                Text {
                  id: searchGlyph
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(14)
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.currentSearchGlyph()
                  color: searchBox.active ? root.selectedText : root.foreground
                  opacity: searchBox.active ? 1 : 0.6
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.iconLarge
                }

                Text {
                  id: searchText
                  anchors.left: searchGlyph.right
                  anchors.leftMargin: Style.space(10)
                  anchors.right: searchBox.active ? clearHint.left : parent.right
                  anchors.rightMargin: Style.space(14)
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.filterText || root.searchPlaceholder()
                  color: root.foreground
                  opacity: root.filterText ? 1 : 0.45
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  elide: Text.ElideRight
                }

                TextMetrics {
                  id: cursorMetrics
                  font.family: searchText.font.family
                  font.pixelSize: searchText.font.pixelSize
                  font.weight: searchText.font.weight
                  text: root.filterText ? root.filterText.slice(0, Math.min(root.textCursorPos, root.filterText.length)) : ""
                }

                TextMetrics {
                  id: probeMetrics
                  font.family: searchText.font.family
                  font.pixelSize: searchText.font.pixelSize
                  font.weight: searchText.font.weight
                }

                Rectangle {
                  id: caret
                  visible: true
                  x: searchText.x + (root.filterText ? Math.min(cursorMetrics.width, searchText.width) + Style.space(2) : 0)
                  width: Math.max(1, Style.space(2))
                  height: Style.font.heading + Style.space(4)
                  anchors.verticalCenter: parent.verticalCenter
                  color: root.selectedText
                  opacity: 1.0
                  SequentialAnimation on opacity {
                    id: caretAnim
                    running: root.opened && caret.visible && !openSlideAnim.running && !closeSlideAnim.running
                    loops: Animation.Infinite
                    onRunningChanged: {
                      if (!running) caret.opacity = 1.0
                    }
                    NumberAnimation { to: 0; duration: 500 }
                    NumberAnimation { to: 1; duration: 500 }
                  }
                }

                Connections {
                  target: root
                  function onTextCursorPosChanged() {
                    caret.opacity = 1
                    caretAnim.restart()
                  }
                }

                Rectangle {
                  id: clearHint
                  visible: searchBox.active
                  anchors.right: parent.right
                  anchors.rightMargin: Style.space(12)
                  anchors.verticalCenter: parent.verticalCenter
                  width: clearHintText.implicitWidth + Style.space(14)
                  height: Style.space(22)
                  radius: Style.space(11)
                  scale: clearHintMa.pressed ? 0.92 : (clearHintMa.containsMouse ? 1.05 : 1.0)
                  color: clearHintMa.containsMouse ? Util.alpha(root.selectedText, 0.22) : Util.alpha(root.foreground, 0.08)
                  border.color: clearHintMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.16)
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                  Behavior on color { ColorAnimation { duration: 120 } }
                  Behavior on border.color { ColorAnimation { duration: 120 } }

                  Text {
                    id: clearHintText
                    anchors.centerIn: parent
                    text: "esc ✕"
                    color: clearHintMa.containsMouse ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.weight: Font.Medium
                  }

                  MouseArea {
                    id: clearHintMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.setFilter("")
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.IBeamCursor
                  onClicked: function(mouse) {
                    keyCatcher.forceActiveFocus()
                    if (root.isMathMode && root.filterText) {
                      var clickX = mouse.x - searchText.x
                      root.textCursorPos = root.cursorPosFromX(clickX)
                    }
                  }
                }
              }
            }

            // ---- main grid area
            Item {
              id: gridArea
              anchors.top: contentTopColumn.bottom
              anchors.topMargin: Style.space(4)
              anchors.left: parent.left
              anchors.leftMargin: Style.space(14)
              anchors.right: parent.right
              anchors.rightMargin: Style.space(14)
              anchors.bottom: tabletDock.visible ? tabletDock.top : homeBarArea.top
              anchors.bottomMargin: Style.space(10)
              visible: root.mode !== "input"

              readonly property int cellWidth: Math.max(1, Math.floor((width - (root.columns - 1) * root.tileGap) / root.columns))

              Flickable {
                id: gridFlick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: root.gridContentHeight
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                pixelAligned: true

                Repeater {
                  model: dividerModel
                  delegate: Item {
                    required property int offsetY
                    required property string label

                    y: offsetY
                    width: gridFlick.width
                    height: root.dividerHeight

                    Rectangle {
                      anchors.left: parent.left
                      anchors.right: dividerLabel.visible ? dividerLabel.left : parent.right
                      anchors.rightMargin: dividerLabel.visible ? Style.space(10) : 0
                      anchors.verticalCenter: parent.verticalCenter
                      height: Style.spacing.hairline
                      color: Util.alpha(root.foreground, 0.18)
                    }

                    Text {
                      id: dividerLabel
                      visible: label.length > 0
                      anchors.right: parent.right
                      anchors.rightMargin: Style.space(6)
                      anchors.verticalCenter: parent.verticalCenter
                      text: label
                      color: root.foreground
                      opacity: root.mutedOpacity
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.letterSpacing: 1
                      font.capitalization: Font.AllUppercase
                    }
                  }
                }

                Repeater {
                  model: displayModel
                  delegate: Item {
                    id: tile
                    required property int index
                    required property string itemId
                    required property string kind
                    required property string icon
                    required property string iconFont
                    required property string appIcon
                    required property string appId
                    required property string label
                    required property string detail
                    required property string shortcut
                    required property int col
                    required property int cellY

                    readonly property bool hasCursor: root.cursorActive && tile.index === root.selectedIndex
                    readonly property bool isApp: tile.kind === "app"
                    readonly property bool isMenu: tile.kind === "menu" || tile.kind === "link"
                    readonly property bool hasIcon: tile.icon.length > 0 || tile.isApp
                    readonly property color textColor: hasCursor ? root.selectedText : root.foreground

                    readonly property bool isVerticalAppTile: root.activeMenu === "apps" && !root.filterText.trim() && !root.isPhoneMode
                    readonly property bool isMenuCardTile: root.activeMenu === "root" && !root.filterText.trim() && !root.isPhoneMode

                    x: tile.col * (gridArea.cellWidth + root.tileGap)
                    y: tile.cellY
                    width: gridArea.cellWidth
                    height: root.tileHeight

                    // 1. Vertical App Tile (Tablet App Grid)
                    Item {
                      id: verticalAppLayout
                      visible: tile.isVerticalAppTile
                      anchors.fill: parent

                      Rectangle {
                        id: squircle
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Style.space(48)
                        height: Style.space(48)
                        radius: Style.space(13)
                        scale: tile.hasCursor ? 1.05 : 1.0
                        color: tile.hasCursor ? Util.alpha(root.selectedText, 0.22) : Util.alpha(root.foreground, 0.06)
                        border.color: tile.hasCursor ? root.selectedText : Util.alpha(root.foreground, 0.10)
                        border.width: tile.hasCursor ? 1.5 : 1

                        Behavior on scale {
                          NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on color {
                          ColorAnimation { duration: 130 }
                        }
                        Behavior on border.color {
                          ColorAnimation { duration: 130 }
                        }

                        Image {
                          id: appIconImage
                          visible: tile.isApp
                          anchors.centerIn: parent
                          width: Style.space(32)
                          height: Style.space(32)
                          fillMode: Image.PreserveAspectFit
                          sourceSize.width: Style.space(32) * Screen.devicePixelRatio
                          sourceSize.height: Style.space(32) * Screen.devicePixelRatio
                          source: (verticalAppLayout.visible && tile.isApp) ? (tile.appIcon.indexOf("://") >= 0 ? tile.appIcon : (root.appLibrary ? root.appLibrary.iconSource(tile.appIcon) : "")) : ""
                          cache: true
                          asynchronous: true
                        }

                        Text {
                          visible: tile.isApp && (appIconImage.status === Image.Error || !tile.appIcon)
                          anchors.centerIn: parent
                          text: tile.label ? tile.label.charAt(0).toUpperCase() : ""
                          color: tile.textColor
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.heading
                          font.weight: Font.Bold
                        }

                        Text {
                          visible: !tile.isApp && tile.hasIcon
                          anchors.centerIn: parent
                          text: tile.icon
                          color: tile.textColor
                          font.family: tile.iconFont.length > 0 ? tile.iconFont : root.fontFamily
                          font.pixelSize: Style.font.iconLarge
                        }
                      }

                      Text {
                        id: appLabel
                        anchors.top: squircle.bottom
                        anchors.topMargin: Style.space(5)
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - Style.space(4)
                        text: tile.label
                        color: tile.textColor
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                      }

                      Rectangle {
                        visible: tile.hasCursor && tile.shortcut.length > 0
                        anchors.top: appLabel.bottom
                        anchors.topMargin: Style.space(2)
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: Style.space(14)
                        width: shortcutBadgeText.implicitWidth + Style.space(8)
                        radius: Style.space(4)
                        color: Util.alpha(root.selectedText, 0.20)
                        border.color: root.selectedText
                        border.width: 1

                        Text {
                          id: shortcutBadgeText
                          anchors.centerIn: parent
                          text: tile.shortcut
                          color: root.selectedText
                          font.family: root.fontFamily
                          font.pixelSize: Math.max(8, Style.font.caption - Style.space(2))
                          font.weight: Font.Medium
                        }
                      }
                    }

                    // 2. Control Card Tile (Omarchy Control View)
                    Rectangle {
                      id: menuCardLayout
                      visible: tile.isMenuCardTile
                      anchors.fill: parent
                      radius: Style.space(12)
                      color: tile.hasCursor ? Util.alpha(root.selectedText, 0.18) : Util.alpha(root.background, 0.70)
                      border.color: tile.hasCursor ? root.selectedText : Util.alpha(root.foreground, 0.10)
                      border.width: tile.hasCursor ? 1.5 : 1

                      Behavior on color { ColorAnimation { duration: 130 } }
                      Behavior on border.color { ColorAnimation { duration: 130 } }

                      // Left Accent Focus Bar when selected
                      Rectangle {
                        visible: tile.hasCursor
                        width: Style.space(3.5)
                        height: parent.height - Style.space(20)
                        radius: Style.space(2)
                        color: root.selectedText
                        anchors.left: parent.left
                        anchors.leftMargin: Style.space(4)
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      Rectangle {
                        id: menuIconBadge
                        anchors.left: parent.left
                        anchors.leftMargin: tile.hasCursor ? Style.space(14) : Style.space(12)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Style.space(42)
                        height: Style.space(42)
                        radius: Style.space(11)
                        color: tile.hasCursor ? Util.alpha(root.selectedText, 0.25) : Util.alpha(root.foreground, 0.08)
                        border.color: tile.hasCursor ? root.selectedText : Util.alpha(root.foreground, 0.14)
                        border.width: 1

                        Text {
                          anchors.centerIn: parent
                          text: tile.icon
                          color: tile.textColor
                          font.family: tile.iconFont.length > 0 ? tile.iconFont : root.fontFamily
                          font.pixelSize: Style.font.icon
                        }
                      }

                      Column {
                        anchors.left: menuIconBadge.right
                        anchors.leftMargin: Style.space(12)
                        anchors.right: menuChevron.left
                        anchors.rightMargin: Style.space(8)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(3)

                        Text {
                          width: parent.width
                          text: tile.label
                          color: tile.textColor
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.body
                          font.weight: Font.DemiBold
                          elide: Text.ElideRight
                        }

                        Text {
                          width: parent.width
                          visible: tile.detail.length > 0
                          text: tile.detail
                          color: root.foreground
                          opacity: root.mutedOpacity
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          elide: Text.ElideRight
                        }
                      }

                      Text {
                        id: menuChevron
                        anchors.right: parent.right
                        anchors.rightMargin: Style.space(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "›"
                        color: tile.textColor
                        opacity: tile.hasCursor ? 0.9 : 0.4
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.heading
                      }
                    }

                    // 3. Prominent Search / Dmenu Result Card
                    Rectangle {
                      id: standardListLayout
                      visible: !tile.isVerticalAppTile && !tile.isMenuCardTile
                      anchors.fill: parent
                      radius: Style.space(14)
                      color: tile.hasCursor ? Util.alpha(root.selectedText, 0.20) : Util.alpha(root.background, 0.72)
                      border.color: tile.hasCursor ? root.selectedText : Util.alpha(root.foreground, 0.10)
                      border.width: tile.hasCursor ? 1.5 : 1

                      Behavior on color { ColorAnimation { duration: 130 } }
                      Behavior on border.color { ColorAnimation { duration: 130 } }

                      // Left Accent Focus Bar when selected
                      Rectangle {
                        visible: tile.hasCursor
                        width: Style.space(3.5)
                        height: parent.height - Style.space(20)
                        radius: Style.space(2)
                        color: root.selectedText
                        anchors.left: parent.left
                        anchors.leftMargin: Style.space(4)
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      // Dedicated Prominent Squircle Icon Container
                      Rectangle {
                        id: resultIconSquircle
                        anchors.left: parent.left
                        anchors.leftMargin: tile.hasCursor ? Style.space(14) : Style.space(12)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Style.space(44)
                        height: Style.space(44)
                        radius: Style.space(12)
                        color: tile.hasCursor ? Util.alpha(root.selectedText, 0.28) : Util.alpha(root.foreground, 0.08)
                        border.color: tile.hasCursor ? root.selectedText : Util.alpha(root.foreground, 0.12)
                        border.width: 1

                        Image {
                          id: resultAppIcon
                          visible: tile.isApp
                          width: Style.space(30)
                          height: Style.space(30)
                          anchors.centerIn: parent
                          fillMode: Image.PreserveAspectFit
                          sourceSize.width: Style.space(32) * Screen.devicePixelRatio
                          sourceSize.height: Style.space(32) * Screen.devicePixelRatio
                          source: (standardListLayout.visible && tile.isApp) ? (tile.appIcon.indexOf("://") >= 0 ? tile.appIcon : (root.appLibrary ? root.appLibrary.iconSource(tile.appIcon) : "")) : ""
                          cache: true
                          asynchronous: true
                        }

                        Text {
                          visible: tile.isApp && (resultAppIcon.status === Image.Error || !tile.appIcon)
                          anchors.centerIn: parent
                          text: tile.label ? tile.label.charAt(0).toUpperCase() : ""
                          color: tile.textColor
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.heading
                          font.weight: Font.Bold
                        }

                        Text {
                          visible: !tile.isApp && tile.hasIcon
                          anchors.centerIn: parent
                          text: tile.icon
                          color: tile.textColor
                          font.family: tile.iconFont.length > 0 ? tile.iconFont : root.fontFamily
                          font.pixelSize: Style.space(20)
                        }
                      }

                      // Prominent 2-Row Typography
                      Column {
                        anchors.left: resultIconSquircle.right
                        anchors.leftMargin: Style.space(12)
                        anchors.right: resultTrail.left
                        anchors.rightMargin: Style.space(10)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(2)

                        Text {
                          width: parent.width
                          text: tile.label
                          color: tile.textColor
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.heading
                          font.weight: Font.DemiBold
                          elide: Text.ElideRight
                        }

                        Text {
                          width: parent.width
                          visible: tile.detail.length > 0
                          text: tile.detail
                          color: tile.hasCursor ? Util.alpha(root.selectedText, 0.85) : Util.alpha(root.foreground, 0.65)
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.caption
                          elide: Text.ElideRight
                        }
                      }

                      // Right-side Trail (Global Shortcut Pill + Action Pill)
                      Row {
                        id: resultTrail
                        anchors.right: parent.right
                        anchors.rightMargin: Style.space(12)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.space(8)

                        // Global Hyprland shortcut badge
                        Rectangle {
                          visible: tile.shortcut.length > 0
                          anchors.verticalCenter: parent.verticalCenter
                          height: Style.space(22)
                          width: resultShortcutBadgeText.implicitWidth + Style.space(12)
                          radius: Style.space(6)
                          color: Util.alpha(root.foreground, 0.08)
                          border.color: Util.alpha(root.foreground, 0.16)
                          border.width: 1

                          Text {
                            id: resultShortcutBadgeText
                            anchors.centerIn: parent
                            text: tile.shortcut
                            color: tile.textColor
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            font.weight: Font.Medium
                          }
                        }

                        // Active Enter pill badge
                        Rectangle {
                          visible: tile.hasCursor
                          anchors.verticalCenter: parent.verticalCenter
                          height: Style.space(22)
                          width: enterBadgeText.implicitWidth + Style.space(12)
                          radius: Style.space(6)
                          color: Util.alpha(root.selectedText, 0.28)
                          border.color: root.selectedText
                          border.width: 1

                          Text {
                            id: enterBadgeText
                            anchors.centerIn: parent
                            text: "↵"
                            color: root.selectedText
                            font.family: root.fontFamily
                            font.pixelSize: Style.font.caption
                            font.weight: Font.Bold
                          }
                        }

                        // Submenu Chevron
                        Text {
                          visible: tile.isMenu
                          text: "›"
                          color: tile.textColor
                          opacity: tile.hasCursor ? 0.9 : 0.4
                          font.family: root.fontFamily
                          font.pixelSize: Style.font.heading
                          anchors.verticalCenter: parent.verticalCenter
                        }
                      }
                    }

                    MouseArea {
                      id: tileMa
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onEntered: root.selectFromPointer(tile.index, tile, { x: tileMa.mouseX, y: tileMa.mouseY })
                      onPositionChanged: function(mouse) { root.selectFromPointer(tile.index, tile, mouse) }
                      onClicked: {
                        root.cursorActive = true
                        root.selectedIndex = tile.index
                        root.activateIndex(tile.index, true)
                      }
                    }
                  }
                }
              }

              // Fold scrims
              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.min(Style.space(20), parent.height / 2)
                visible: opacity > 0
                opacity: gridFlick.contentHeight > gridFlick.height ? Math.max(0, Math.min(1, gridFlick.contentY / height)) : 0
                gradient: Gradient {
                  GradientStop { position: 0; color: "#11141c" }
                  GradientStop { position: 1; color: "transparent" }
                }
              }

              Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.min(Style.space(20), parent.height / 2)
                visible: opacity > 0
                opacity: gridFlick.contentHeight > gridFlick.height
                  ? Math.max(0, Math.min(1, (gridFlick.contentHeight - gridFlick.height - gridFlick.contentY) / height))
                  : 0
                gradient: Gradient {
                  GradientStop { position: 0; color: "transparent" }
                  GradientStop { position: 1; color: Util.alpha(root.background, 0.90) }
                }
              }

              // Empty Search Results State
              Column {
                anchors.centerIn: parent
                spacing: Style.space(6)
                visible: displayModel.count === 0

                Text {
                  text: "󰈉"
                  color: root.selectedText
                  opacity: 0.8
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.displayLarge
                  horizontalAlignment: Text.AlignHCenter
                  width: gridArea.width
                }

                Text {
                  text: root.filterText ? "No matches for “" + root.filterText + "”" : "Nothing here yet"
                  color: root.foreground
                  opacity: 0.7
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  horizontalAlignment: Text.AlignHCenter
                  width: gridArea.width
                }
              }
            }

            // ---- bottom dock shelf gradient backing (smoothly dissolves scrolled tiles)
            Rectangle {
              id: bottomShelfBacking
              visible: !root.isPhoneMode && !root.filterText.trim()
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: Style.space(92)
              radius: tabletScreen.radius
              z: 8
              gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.35; color: Util.alpha(root.background, 0.88) }
                GradientStop { position: 1.0; color: Util.alpha(root.background, 0.98) }
              }
            }

            // ---- floating glass tablet dock
            Rectangle {
              id: tabletDock
              visible: !root.isPhoneMode && !root.filterText.trim()
              anchors.bottom: homeBarArea.top
              anchors.bottomMargin: Style.space(6)
              anchors.horizontalCenter: parent.horizontalCenter
              height: Style.space(48)
              width: dockRow.implicitWidth + Style.space(24)
              radius: Style.space(20)
              color: Util.alpha(root.background, 0.75)
              border.color: Util.alpha(root.foreground, 0.15)
              border.width: 1
              z: 10

              Row {
                id: dockRow
                anchors.centerIn: parent
                spacing: Style.space(12)

                // 1. Terminal
                Rectangle {
                  width: Style.space(36)
                  height: Style.space(36)
                  radius: Style.space(11)
                  scale: dockTermMa.pressed ? 0.90 : (dockTermMa.containsMouse ? 1.10 : 1.0)
                  color: dockTermMa.containsMouse ? Util.alpha(root.selectedText, 0.28) : Util.alpha(root.foreground, 0.08)
                  border.color: dockTermMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.14)
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                  Behavior on color { ColorAnimation { duration: 130 } }
                  Behavior on border.color { ColorAnimation { duration: 130 } }

                  Text {
                    anchors.centerIn: parent
                    text: ""
                    color: dockTermMa.containsMouse ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.icon
                  }

                  MouseArea {
                    id: dockTermMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchDockApp("terminal")
                  }
                }

                // 2. Browser
                Rectangle {
                  width: Style.space(36)
                  height: Style.space(36)
                  radius: Style.space(11)
                  scale: dockBrowserMa.pressed ? 0.90 : (dockBrowserMa.containsMouse ? 1.10 : 1.0)
                  color: dockBrowserMa.containsMouse ? Util.alpha(root.selectedText, 0.28) : Util.alpha(root.foreground, 0.08)
                  border.color: dockBrowserMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.14)
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                  Behavior on color { ColorAnimation { duration: 130 } }
                  Behavior on border.color { ColorAnimation { duration: 130 } }

                  Text {
                    anchors.centerIn: parent
                    text: "󰖟"
                    color: dockBrowserMa.containsMouse ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.icon
                  }

                  MouseArea {
                    id: dockBrowserMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchDockApp("browser")
                  }
                }

                // 3. Files
                Rectangle {
                  width: Style.space(36)
                  height: Style.space(36)
                  radius: Style.space(11)
                  scale: dockFilesMa.pressed ? 0.90 : (dockFilesMa.containsMouse ? 1.10 : 1.0)
                  color: dockFilesMa.containsMouse ? Util.alpha(root.selectedText, 0.28) : Util.alpha(root.foreground, 0.08)
                  border.color: dockFilesMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.14)
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                  Behavior on color { ColorAnimation { duration: 130 } }
                  Behavior on border.color { ColorAnimation { duration: 130 } }

                  Text {
                    anchors.centerIn: parent
                    text: "󰉋"
                    color: dockFilesMa.containsMouse ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.icon
                  }

                  MouseArea {
                    id: dockFilesMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchDockApp("files")
                  }
                }

                // 4. Editor
                Rectangle {
                  width: Style.space(36)
                  height: Style.space(36)
                  radius: Style.space(11)
                  scale: dockEditorMa.pressed ? 0.90 : (dockEditorMa.containsMouse ? 1.10 : 1.0)
                  color: dockEditorMa.containsMouse ? Util.alpha(root.selectedText, 0.28) : Util.alpha(root.foreground, 0.08)
                  border.color: dockEditorMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.14)
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                  Behavior on color { ColorAnimation { duration: 130 } }
                  Behavior on border.color { ColorAnimation { duration: 130 } }

                  Text {
                    anchors.centerIn: parent
                    text: "󰅩"
                    color: dockEditorMa.containsMouse ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.icon
                  }

                  MouseArea {
                    id: dockEditorMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchDockApp("editor")
                  }
                }

                // Divider line in dock
                Rectangle {
                  width: 1
                  height: Style.space(24)
                  anchors.verticalCenter: parent.verticalCenter
                  color: Util.alpha(root.foreground, 0.20)
                }

                // 5. Omarchy Menus / Settings
                Rectangle {
                  width: Style.space(36)
                  height: Style.space(36)
                  radius: Style.space(11)
                  scale: dockMenusMa.pressed ? 0.90 : (dockMenusMa.containsMouse ? 1.10 : 1.0)
                  color: (root.activeMenu === "root" || dockMenusMa.containsMouse) ? Util.alpha(root.selectedText, 0.28) : Util.alpha(root.foreground, 0.08)
                  border.color: (root.activeMenu === "root" || dockMenusMa.containsMouse) ? root.selectedText : Util.alpha(root.foreground, 0.14)
                  border.width: 1

                  Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                  Behavior on color { ColorAnimation { duration: 130 } }
                  Behavior on border.color { ColorAnimation { duration: 130 } }

                  Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: (root.activeMenu === "root" || dockMenusMa.containsMouse) ? root.selectedText : root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.icon
                  }

                  MouseArea {
                    id: dockMenusMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (root.activeMenu === "root") root.setActiveMenu("apps", false)
                      else root.setActiveMenu("root", false)
                    }
                  }
                }
              }
            }

            // ---- tablet / phone home indicator bar
            Item {
              id: homeBarArea
              anchors.bottom: parent.bottom
              anchors.bottomMargin: Style.space(6)
              anchors.horizontalCenter: parent.horizontalCenter
              width: root.isPhoneMode ? Style.space(220) : Style.space(140)
              height: root.isPhoneMode ? Style.space(28) : Style.space(10)
              z: 10

              // Action Hint in Phone Mode
              Text {
                visible: root.isPhoneMode
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "↑↓ move  •  ⏎ select  •  esc back"
                color: root.foreground
                opacity: 0.50
                font.family: root.fontFamily
                font.pixelSize: Math.max(9, Style.font.caption - 2)
              }

              // Pill Home Bar
              Rectangle {
                id: homeBarPill
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.isPhoneMode ? Style.space(2) : 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.isPhoneMode ? Style.space(118) : Style.space(130)
                height: Style.space(4)
                radius: Style.space(2)
                scale: homeBarMa.pressed ? 0.94 : (homeBarMa.containsMouse ? 1.04 : 1.0)
                color: homeBarMa.containsMouse ? root.selectedText : Util.alpha(root.foreground, 0.40)
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 130 } }
              }

              MouseArea {
                id: homeBarMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.dmenuActive) root.cancel()
                  else if (root.isPhoneMode) root.goBack()
                  else root.cancel()
                }
              }
            }

            // ---- subtle 3D glass specular sheen across display surface
            Rectangle {
              anchors.fill: parent
              radius: Style.space(15)
              enabled: false
              z: 25
              gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.18; color: Util.alpha(root.foreground, 0.02) }
                GradientStop { position: 0.32; color: Util.alpha(root.foreground, 0.055) }
                GradientStop { position: 0.46; color: Util.alpha(root.foreground, 0.02) }
                GradientStop { position: 0.65; color: "transparent" }
                GradientStop { position: 1.0; color: "transparent" }
              }
            }
          }
        }
      }
    }
  }
}
