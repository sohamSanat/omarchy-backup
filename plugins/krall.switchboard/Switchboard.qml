import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
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

  function open(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }

    if (payload.fontFamily) root.fontFamily = payload.fontFamily

    if (payload.mode === "select" || payload.mode === "input") {
      root.openDmenu(payload)
    } else {
      root.openRoute(payload.initialMenu || payload.menu || "root")
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
  property string mode: "menu"
  readonly property bool dmenuActive: mode === "select" || mode === "input"
  property string dmenuPrompt: ""
  property var dmenuOptions: []
  property string selectionFile: ""
  property string doneFile: ""
  property int dmenuWidth: 300
  property int dmenuMaxHeight: 0
  property bool requestActive: false
  property bool rowsLoaded: false
  property string activeMenu: "root"
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

  // ---------------------------------------------------------------- metrics

  property int contentMargin: Style.spacing.panelPadding + Style.space(6)
  property int contentSpacing: Style.space(10)
  property int headerHeight: Math.max(Style.space(24), Style.font.title + Style.space(6))
  property int searchHeight: Math.max(Style.space(38), Style.font.heading + Style.spacing.inputPaddingY * 2 + Style.space(6))
  property int footerHeight: Math.max(Style.space(16), Style.font.caption + Style.space(4))
  property int baseTileHeight: Math.max(Style.space(36), Style.font.body + Style.spacing.rowPaddingX * 2 - Style.space(4))
  property int detailTileHeight: Math.max(Style.space(50), Style.font.body + Style.font.caption + Style.spacing.rowPaddingX * 2 - Style.space(4))
  property int tileGap: Style.space(4)
  property int dividerHeight: Style.space(28)
  property int emptyHeight: Style.space(96)

  readonly property bool detailRows: root.dmenuActive ? root.dmenuHasDetail : root.filterText.trim().length > 0
  property bool dmenuHasDetail: false
  readonly property int tileHeight: root.detailRows ? root.detailTileHeight : root.baseTileHeight

  property int cardWidth: Math.min(root.dmenuActive ? Style.space(root.dmenuWidth) : Style.space(680), panel.width - Style.gapsOut * 2)
  readonly property int chromeHeight: contentMargin * 2 + headerHeight + contentSpacing + searchHeight
    + (root.mode === "input" ? 0 : contentSpacing) + contentSpacing + footerHeight
  readonly property int gridHeight: root.mode === "input" ? 0
    : (displayModel.count === 0 ? root.emptyHeight : Math.min(root.gridContentHeight, root.availableGridHeight))
  readonly property int availableGridHeight: {
    var serial = root.layoutSerial
    // Symmetric: a full-height card leaves the same gap below as above.
    var available = panel.height - panel.cardTop * 2 - root.chromeHeight
    if (root.dmenuActive && root.dmenuMaxHeight > 0) available = Math.min(available, Style.space(root.dmenuMaxHeight))
    return Math.max(root.baseTileHeight, available)
  }
  readonly property int cardHeight: root.chromeHeight + root.gridHeight

  // ---------------------------------------------------------------- helpers

  function finishRequest(selection) {
    if (!root.requestActive || !root.doneFile) {
      root.opened = false
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
    if (root.opened) {
      root.ensureAppRows()
      root.rebuildDisplay()
      if (!root.dmenuActive) {
        if (root.filterText.trim()) root.loadProvidersForSearch()
        else root.loadProviderForMenu(root.activeMenu)
      }
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
      appRows.push({
        id: "apps." + appId,
        parent: "apps",
        kind: "app",
        icon: "",
        appIcon: String(entry.icon || ""),
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
    root.rebuildAppShortcuts()
    if (root.opened) root.rebuildDisplay()
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
  function isVisible(entry) { return MenuModel.isVisible(root.items, root.itemOrder, root.whenResults, entry) }
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

  function applyKeybinds(text) {
    var parsed = Keybinds.parseRecords(text)
    root.binds = parsed.binds
    root.bindDefaults = parsed.defaults
    root.rebuildShortcutIndexes()
    root.pickTip()
    if (root.opened) root.rebuildDisplay()
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

  // Two columns everywhere, so the card never changes width between menus;
  // select/input payloads are a single list.
  function columnsFor() {
    return root.dmenuActive ? 1 : 2
  }

  function sectionTitle(section) {
    return ""
  }

  // Assigns shortcut hints, then lays the rows out on a grid. Sections
  // (main / drilldown search hits)
  // each start on a fresh row with a divider above them, so a section never
  // shares a row.
  function decorateRows(rows) {
    var cols = root.columnsFor()
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

  function rebuildDisplay() {
    if (root.dmenuActive) {
      root.rebuildDmenuDisplay()
      return
    }

    displayModel.clear()
    if (!root.rowsLoaded) return

    var active = root.item(root.activeMenu) ? root.activeMenu : "root"
    root.activeMenu = active
    var rows = []
    var query = root.filterText.trim()

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
        if (!entry || entry.id === "root") continue
        if (!root.isDescendantOf(entry.id, active)) continue
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
      for (var j = 0; j < root.itemOrder.length; j++) {
        var child = root.item(root.itemOrder[j])
        if (!child || child.parent !== active) continue
        if (!root.isVisible(child)) continue
        rows.push(root.displayRow(child, child.description, child.order))
      }

      if (active === "apps") {
        rows.sort(function(a, b) {
          var aLabel = String(a.label || "").toLowerCase()
          var bLabel = String(b.label || "").toLowerCase()
          if (aLabel < bLabel) return -1
          if (aLabel > bLabel) return 1
          return String(a.itemId || "").localeCompare(String(b.itemId || ""))
        })
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
    opened = false
    filterText = ""
    if (kind === "run") {
      Util.execDetached("omarchy-launch-terminal bash -c " + Util.shellQuote('eval "$1"; exec "${SHELL:-bash}"') + " _ " + Util.shellQuote(action))
    } else {
      var path = String(action)
      if (path === "~" || path.indexOf("~/") === 0) path = Quickshell.env("HOME") + path.slice(1)
      Util.execDetached("xdg-open " + Util.shellQuote(path))
    }
  }

  function openUrl(url) {
    applySerial = requestSerial
    opened = false
    filterText = ""
    Util.execDetached("xdg-open " + Util.shellQuote(url))
  }

  function copyToClipboard(text, label, detail, icon) {
    applySerial = requestSerial
    opened = false
    filterText = ""
    Util.execDetached("printf %s " + Util.shellQuote(text) + " | wl-copy")
    var glyph = (icon && icon.length > 0) ? icon : "󰃬"
    var title = "Copied to clipboard"
    var msg = (label && label.length > 0) ? label : text
    Util.execDetached("omarchy-notification-send -g " + Util.shellQuote(glyph) + " " + Util.shellQuote(title) + " " + Util.shellQuote(msg))
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
    // Keep a sliver of the neighbouring row visible so the fold reads as one.
    var reach = Math.round(root.tileHeight * 0.4)
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
    if (root.activeMenu === "root") return false
    if (root.navStack.length > 0) {
      var previous = root.navStack[root.navStack.length - 1]
      root.navStack = root.navStack.slice(0, root.navStack.length - 1)
      root.setActiveMenu(previous, false)
      return true
    }
    var active = root.item(root.activeMenu)
    root.setActiveMenu((active && active.parent) ? active.parent : "root", false)
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
      opened = false
      filterText = ""
      if (root.appLibrary) root.appLibrary.launch(appId, label)
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
    opened = false
    filterText = ""
    root.finishRequest(value)
  }

  function applySelected(id, action) {
    if (!id) { cancel(); return }
    applySerial = requestSerial
    opened = false
    filterText = ""
    root.runAction(action)
  }

  function cancel() {
    if (root.dmenuActive) root.finishRequest(null)
    opened = false
    filterText = ""
  }

  function openExistingMenu(initialMenu) {
    requestSerial += 1
    mode = "menu"
    requestActive = false
    selectionFile = ""
    doneFile = ""
    activeMenu = root.item(initialMenu) ? initialMenu : "root"
    navStack = []
    filterText = ""
    selectedIndex = 0
    cursorActive = true
    gridFlick.contentY = 0
    root.disarmPointer()
    root.evaluateGuards()
    root.ensureAppRows()
    root.pickTip()
    root.loadQuickLinks()
    root.loadExchangeRates()
    opened = true
    rebuildDisplay()
    invalidateVolatileProvider(activeMenu)
    loadProviderForMenu(activeMenu)
    if (root.appLibrary) root.appLibrary.refreshIcons()
    root.loadKeybinds(false)
    root.loadStatus()

    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
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

  function footerHint() {
    if (root.mode === "input") return "⏎ confirm   esc cancel"
    if (root.dmenuActive) return "type to filter   ↑↓ move   ⏎ select   esc cancel"
    if (root.filterText.charAt(0) === "!") return "⏎ run in terminal   esc clear"
    if (root.isMathMode) {
      var isCopyable = displayModel.count > 0 && displayModel.get(0).kind === "copy"
      if (isCopyable) {
        return "←→ cursor   ⏎ copy to clipboard   esc clear"
      }
      return "←→ cursor   esc clear"
    }
    if (displayModel.count > 0 && root.cursorActive) {
      var sel = displayModel.get(root.selectedIndex)
      if (sel) {
        if (sel.kind === "copy") return "↑↓←→ move   ⏎ copy to clipboard   esc clear"
        if (sel.kind === "url") return "↑↓←→ move   ⏎ open in browser   esc clear"
        if (sel.kind === "fill") return "↑↓←→ move   ⏎ select   esc clear"
        if (sel.kind === "fmhy-deck") return "↑↓←→ move   ⏎ open FMHY Deck   esc clear"
      }
    }
    if (root.filterText) return "↑↓←→ move   ⏎ open   esc clear"
    var hint = "type to search   ↑↓←→ move   ⏎ open"
    return hint + "   esc " + (root.activeMenu === "root" ? "close" : "back")
  }

  function tipText() {
    if (root.dmenuActive || !root.tip) return ""
    return "󰛨 " + root.tip.pretty + " → " + root.tip.description
  }

  function searchPlaceholder() {
    if (root.mode === "input") return root.dmenuPrompt + "…"
    if (root.dmenuActive) return "Filter " + root.dmenuPrompt.toLowerCase() + "…"
    var active = root.item(root.activeMenu)
    return (root.activeMenu === "root" || !active) ? "Search" : "Search " + (active.title || active.label)
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
        root.opened = false
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
    if (!root.pluginDir || statusProc.running) return
    statusProc.command = [root.pluginDir + "/scripts/status"]
    statusProc.running = true
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
    referenceItem: card
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
    opened = false
    filterText = ""
    var q = (action === "fmhy-panel" || !action) ? "" : action
    Util.execDetached("qs ipc -n -p /usr/share/omarchy/shell call io.github.i12bp8.fmhy-deck search " + Util.shellQuote(q))
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
    guardProc.command = ["bash", "-lc", script]
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
      root.whenResults = nextWhen
      root.checkedResults = nextChecked
      if (root.opened) root.rebuildDisplay()
      if (root.guardsPending) Qt.callLater(function() { root.evaluateGuards() })
    }
  }

  // --------------------------------------------------------------- surface

  PanelWindow {
    id: panel
    visible: root.opened && root.rowsLoaded
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // The card hangs from a fixed line in the upper part of the screen and
    // grows downward, so moving between menus never makes it jump.
    readonly property int cardTop: Math.max(Style.gapsOut, Math.round(height * 0.20))

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(root.cardHeight, panel.height - Style.gapsOut - panel.cardTop)
      radius: root.cornerRadius
      anchors.horizontalCenter: parent.horizontalCenter
      y: panel.cardTop
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

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
            if (root.dmenuActive) root.cancel()
            else if (root.filterText) root.setFilter("")
            else if (!root.goBack()) root.cancel()
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
          } else if (root.isMathMode && event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier)) {
            var prevPosW = root.prevTokenPos(root.filterText, root.textCursorPos)
            var beforeW = root.filterText.slice(0, prevPosW)
            var afterW = root.filterText.slice(root.textCursorPos)
            root.setFilter(beforeW + afterW, prevPosW)
            event.accepted = true
          } else if (root.isMathMode && event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) {
            root.setFilter(root.filterText.slice(0, root.textCursorPos), root.textCursorPos)
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
      }

      Column {
        id: content
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        // ---- header: logo, title / breadcrumb, status
        Item {
          width: parent.width
          height: root.headerHeight

          Text {
            id: logo
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            font.family: "omarchy"
            font.pixelSize: Style.font.icon
            color: root.selectedText
          }

          Text {
            anchors.left: logo.right
            anchors.leftMargin: Style.space(8)
            anchors.right: statusLabel.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: root.headerTitle()
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.weight: Font.Medium
            elide: Text.ElideLeft
          }

          Text {
            id: statusLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width * 0.55)
            text: root.statusText()
            color: root.foreground
            opacity: root.mutedOpacity
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideLeft
            horizontalAlignment: Text.AlignRight
          }
        }

        // ---- search box
        BorderSurface {
          id: searchBox
          width: parent.width
          height: root.searchHeight
          radius: root.tileRadius
          readonly property bool active: root.filterText.length > 0
          color: Util.alpha(root.foreground, active ? 0.06 : 0.03)
          borderSpec: Border.flat(active ? root.selectedText : Util.alpha(root.foreground, 0.22), Math.max(1, Style.normalBorderWidth))

          Text {
            id: searchGlyph
            anchors.left: parent.left
            anchors.leftMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentSearchGlyph()
            color: searchBox.active ? root.selectedText : root.foreground
            opacity: searchBox.active ? 1 : 0.6
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
          }

          Text {
            id: searchText
            anchors.left: searchGlyph.right
            anchors.leftMargin: Style.space(10)
            anchors.right: searchBox.active ? clearHint.left : parent.right
            anchors.rightMargin: Style.space(12)
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
            SequentialAnimation on opacity {
              id: caretAnim
              running: caret.visible
              loops: Animation.Infinite
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

          Text {
            id: clearHint
            visible: searchBox.active
            anchors.right: parent.right
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: "esc"
            color: root.foreground
            opacity: root.mutedOpacity
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          MouseArea {
            anchors.fill: clearHint
            anchors.margins: -Style.space(6)
            visible: clearHint.visible
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setFilter("")
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

        // ---- grid
        Item {
          id: gridArea
          width: parent.width
          height: root.gridHeight
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
              delegate: BorderSurface {
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

                x: tile.col * (gridArea.cellWidth + root.tileGap)
                y: tile.cellY
                width: gridArea.cellWidth
                height: root.tileHeight
                radius: root.tileRadius
                color: tile.hasCursor ? root.selectedBackground : "transparent"
                borderSpec: tile.hasCursor ? root.selectedBorderSpec : Border.none()

                Text {
                  id: iconText
                  visible: tile.hasIcon && !tile.isApp
                  text: tile.icon
                  color: tile.textColor
                  font.family: tile.iconFont.length > 0 ? tile.iconFont : root.fontFamily
                  font.pixelSize: Style.font.icon
                  width: Style.space(24)
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(10)
                  anchors.verticalCenter: parent.verticalCenter
                }

                Image {
                  visible: tile.isApp
                  width: Style.font.iconLarge
                  height: Style.font.iconLarge
                  fillMode: Image.PreserveAspectFit
                  sourceSize.width: width * Screen.devicePixelRatio
                  sourceSize.height: height * Screen.devicePixelRatio
                  source: tile.isApp && root.appLibrary ? root.appLibrary.iconSource(tile.appIcon) : ""
                  asynchronous: true
                  anchors.left: iconText.left
                  anchors.leftMargin: (Style.space(24) - width) / 2
                  anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                  id: labelColumn
                  anchors.left: tile.hasIcon ? iconText.right : parent.left
                  anchors.leftMargin: tile.hasIcon ? Style.space(6) : Style.space(10)
                  anchors.right: trail.left
                  anchors.rightMargin: Style.space(6)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(2)

                  Text {
                    width: parent.width
                    text: tile.label
                    color: tile.textColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    visible: root.detailRows && tile.detail.length > 0
                    text: tile.detail
                    color: root.foreground
                    opacity: root.mutedOpacity
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }

                Row {
                  id: trail
                  anchors.right: parent.right
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(6)

                  Text {
                    visible: tile.shortcut.length > 0
                    text: tile.shortcut
                    // The label comes first; a hint that would eat it gets clipped.
                    width: Math.min(implicitWidth, Math.floor(tile.width * 0.45))
                    elide: Text.ElideRight
                    color: tile.textColor
                    opacity: tile.hasCursor ? 0.8 : root.mutedOpacity
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    visible: tile.isMenu
                    text: "›"
                    color: tile.textColor
                    opacity: tile.hasCursor ? 0.8 : 0.36
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.heading
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                MouseArea {
                  id: mouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selectFromPointer(tile.index, tile, { x: mouseArea.mouseX, y: mouseArea.mouseY })
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

          // Fold scrims: fade the clipped edge once content hides past it.
          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.min(Style.space(24), parent.height / 2)
            visible: opacity > 0
            opacity: gridFlick.contentHeight > gridFlick.height ? Math.max(0, Math.min(1, gridFlick.contentY / height)) : 0
            gradient: Gradient {
              GradientStop { position: 0; color: root.background }
              GradientStop { position: 1; color: Util.alpha(root.background, 0) }
            }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(Style.space(24), parent.height / 2)
            visible: opacity > 0
            opacity: gridFlick.contentHeight > gridFlick.height
              ? Math.max(0, Math.min(1, (gridFlick.contentHeight - gridFlick.height - gridFlick.contentY) / height))
              : 0
            gradient: Gradient {
              GradientStop { position: 0; color: Util.alpha(root.background, 0) }
              GradientStop { position: 1; color: root.background }
            }
          }

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

        // ---- footer: key hints and a shortcut worth learning
        Item {
          width: parent.width
          height: root.footerHeight

          Text {
            id: hintLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: tipLabel.visible ? tipLabel.left : parent.right
            anchors.rightMargin: Style.space(12)
            text: root.footerHint()
            color: root.foreground
            opacity: root.mutedOpacity
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          Text {
            id: tipLabel
            visible: text.length > 0
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width * 0.5)
            text: root.tipText()
            color: root.selectedText
            opacity: 0.8
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
          }
        }
      }
    }
  }
}
