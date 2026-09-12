import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "wordlist.js" as Wordlist

// Dictionary search panel. The bar widget owns a magnify glyph that toggles
// this popup; everything user-facing lives here — the search field, the
// fetch lifecycle, and the rendered entry.
//
// Layout: a search field pinned to the top, a meaning stack beneath that
// grows from the entry's parts of speech. The entry is treated as a
// read-out rather than a picker, so there's no per-row cursor — arrows move
// the field caret instead, Enter fires search, Esc closes the panel.
Panel {
  id: root
  moduleName: "tristonarmstrong.dictionary"
  ipcTarget: "tristonarmstrong.dictionary"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // ---- Panel lifecycle. Stays in the bar's popout coordinator so adjacent
  //      panels can swap with TAB without leaving the bar that owns this
  //      slot. Setting opened = false (or close()) is the canonical way out.
  function open() {
    root.controller.show()
    root.refreshFocus()
  }

  function openFromHotkey() {
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) refreshFocus()
    })
  }

  function close() {
    if (root.status === "loading") lookupProc.running = false
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  // ---- Look up a word. Called both by Enter / clicking Search and from
  //      the IPC bridge so external tools can preload an entry before the
  //      panel is even opened.
  function search(word) {
    var q = String(word || "").trim()
    root.query = q
    if (searchField.text !== q) searchField.text = q
    // Make the panel visible. No-op if already open (controller.show() is
    // idempotent). Without this the hotkey path would silently populate
    // the search field on an invisible panel.
    root.open()
    if (q === "") {
      lookupProc.running = false
      root.resetResults()
      return
    }
    runLookup()
  }

  // ---- Search state. status drives which body section (hero + list) the
  //      panel shows; entry holds the parsed response on success.
  property string query: ""
  property var entry: null
  property string status: "idle"        // "idle" | "loading" | "ok" | "notfound" | "error" | "suggestions"
  property string statusMessage: ""
  property int variants: 0               // > 1 when the API returned more than one entry object

  // Target language for lookups. Driven by the dropdown in the popup
  // header; default comes from Model.defaultLanguage so the panel and
  // data layer stay in sync.
  property string language: Model.defaultLanguage ? Model.defaultLanguage() : "en"

  // ---- Spelling suggestions state (AI-supercharged + local fallback).
  //      When a query is misspelled (Wiktionary 404), AI suggests the 5 closest
  //      words, ordered closest first.
  property var suggestions: []
  property string originalQuery: ""
  property bool isAutoMatched: false

  property var aiSuggestions: []
  property string aiStatus: "idle"        // "idle" | "loading" | "ok" | "error" | "missing-key"
  property string aiError: ""
  property string configGeminiKey: ""
  property string configFastModel: ""
  property string configDictModel: ""
  property bool aiTriedFallback: false
  property var aiCache: ({})

  readonly property string homeDir: Quickshell.env("HOME") || "/home/soham"
  readonly property string effectiveGeminiKey: {
    var envKey = Quickshell.env("GEMINI_API_KEY") || ""
    if (envKey.trim() !== "") return envKey.trim()
    if (root.configGeminiKey.trim() !== "") return root.configGeminiKey.trim()
    return ""
  }
  readonly property string geminiKey: effectiveGeminiKey
  readonly property string effectiveModel: {
    var envModel = Quickshell.env("GEMINI_DICT_MODEL") || ""
    if (envModel.trim() !== "") return envModel.trim()
    if (root.configDictModel.trim() !== "") return root.configDictModel.trim()
    return Model.GEMINI_MODEL
  }
  readonly property string fallbackModel: {
    var envModel = Quickshell.env("GEMINI_MODEL") || ""
    if (envModel.trim() !== "") return envModel.trim()
    if (root.configFastModel.trim() !== "") return root.configFastModel.trim()
    return Model.GEMINI_FALLBACK_MODEL
  }
  readonly property string closestWord: {
    if (root.aiSuggestions && root.aiSuggestions.length > 0) return String(root.aiSuggestions[0] || "")
    if (root.suggestions && root.suggestions.length > 0) return String(root.suggestions[0] || "")
    return ""
  }

  // Load configuration from ~/.config/omagent/config.json for GEMINI_API_KEY and fast_model
  FileView {
    id: omagentConfigFile
    path: root.homeDir + "/.config/omagent/config.json"
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        if (parsed && typeof parsed === "object") {
          if (parsed.gemini_api_key) root.configGeminiKey = String(parsed.gemini_api_key).trim()
          if (parsed.fast_model) root.configFastModel = String(parsed.fast_model).trim()
          if (parsed.dict_model) root.configDictModel = String(parsed.dict_model).trim()
          if (parsed.gemini_dict_model) root.configDictModel = String(parsed.gemini_dict_model).trim()
        }
      } catch (e) {
        // ignore bad config
      }
    }
    onFileChanged: reload()
    onLoadFailed: {
      root.configGeminiKey = ""
      root.configFastModel = ""
      root.configDictModel = ""
    }
  }

  // Suppress the user-edit reset in applyEdited when the *plugin itself*
  // rewrites the search field (auto-match path: we set searchField.text to
  // the chosen candidate, and the resulting onTextChanged would otherwise
  // clobber isAutoMatched and originalQuery mid-fetch).
  property bool programmaticEdit: false

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string heroSummary: entry ? Model.summaryLabel(entry) : ""
  readonly property int panelWidth: Style.space(420)
  readonly property int panelMaxHeight: Style.space(620)
  readonly property int searchDelayMs: 250

  // ---- Reset all result-related state back to idle.
  function resetResults(preserveCorrection) {
    root.entry = null
    root.variants = 0
    root.status = "idle"
    root.statusMessage = ""
    root.suggestions = []
    if (!preserveCorrection) {
      root.originalQuery = ""
      root.isAutoMatched = false
    }
    root.aiSuggestions = []
    root.aiStatus = "idle"
    root.aiError = ""
    aiProc.running = false
  }

  // Inject the bundled wordlist into Model.js so fuzzyMatch() can use it.
  Component.onCompleted: {
    if (typeof Model.setWordlist === "function" && typeof Wordlist.ENGLISH_WORDLIST !== "undefined")
      Model.setWordlist(Wordlist.ENGLISH_WORDLIST)
  }

  // ---- Bindings need the source data checked before any property
  //      access; pulling the wording into functions lets the body
  //      short-circuit cleanly when entry is null mid-fetch (the
  //      auto-match recovery path blanks entry briefly between lookups).
  function autoMatchedNote() {
    if (!root.entry || !root.originalQuery) return ""
    return "Showing \"" + root.entry.word + "\" (closest match for \"" + root.originalQuery + "\")."
  }
  function entryWord() {
    return root.entry ? String(root.entry.word || "") : ""
  }
  function entryPhonetic() {
    return root.entry ? String(root.entry.phonetic || "") : ""
  }

  // ---- Focus handling. The field owns initial focus; Esc redirects to close.
  function refreshFocus() {
    if (!root.opened) return
    Qt.callLater(function() {
      if (searchField) {
        searchField.forceActiveFocus()
        if (String(searchField.text || "").length > 0) searchField.selectAll()
      }
    })
  }

  // ---- Lookup. The active query is the one in the field; if it changes
  //      while a request is in flight we kill the running process so a
  //      stale response can't overwrite the newer one. Curl writes JSON to
  //      stdout; we parse it once on completion.
  function searchSuggestion(word) {
    var chosen = String(word || "").trim()
    if (chosen === "") return
    var prev = root.originalQuery || root.query
    root.originalQuery = prev
    root.isAutoMatched = true
    root.programmaticEdit = true
    searchField.text = chosen
    root.query = chosen
    root.programmaticEdit = false
    runLookup(true)
  }

  // ---- Lookup. The active query is the one in the field; if it changes
  //      while a request is in flight we kill the running process so a
  //      stale response can't overwrite the newer one. Curl writes JSON to
  //      stdout; we parse it once on completion.
  function runLookup(preserveCorrection) {
    var q = String(searchField.text || "").trim()
    root.query = q
    lookupProc.running = false
    aiProc.running = false
    root.aiSuggestions = []
    root.aiStatus = "idle"
    root.aiError = ""
    if (q === "") {
      lookupProc.running = false
      root.resetResults(false)
      return
    }
    var args = Model.lookupArgs(q, root.language)
    if (args.length === 0) return

    root.status = "loading"
    root.statusMessage = ""
    root.resetResults(preserveCorrection === true)
    root.status = "loading"
    if (lookupProc.running) lookupProc.running = false
    lookupProc.command = args
    lookupProc.running = true
  }

  // The grammar of "search" — Enter fires immediately; typing clears any
  // pending debounce and resets state so a stale response can't surprise
  // the user. Esc routes to the panel close (the keyCatcher handles it).
  // When programmaticEdit is true we skip the user-reset clauses so the
  // isAutoMatched flag survives.
  function applyEdited() {
    if (root.programmaticEdit) return
    var q = String(searchField.text || "").trim()
    root.query = q
    if (q === "") {
      lookupProc.running = false
      root.resetResults(false)
      return
    }
    if (searchDebounce.running) searchDebounce.stop()
    if (root.status === "ok" || root.status === "notfound" || root.status === "error" || root.status === "suggestions") {
      root.resetResults(false)
    }
  }

  // Fallback to local dictionary wordlist when AI is offline or without an API key
  function fallbackToLocalFuzzy() {
    var fuzzy = Model.fuzzyMatch(root.originalQuery || root.query)
    var alts = []
    if (fuzzy) {
      if (fuzzy.autoMatch) alts.push(fuzzy.autoMatch)
      if (fuzzy.alternatives && fuzzy.alternatives.length > 0) {
        for (var i = 0; i < fuzzy.alternatives.length; i++) {
          if (alts.indexOf(fuzzy.alternatives[i]) === -1) {
            alts.push(fuzzy.alternatives[i])
          }
        }
      }
    }
    root.suggestions = alts.slice(0, 5)
  }

  // ---- AI word suggestions (Gemini fast model with fallback).
  //      When Wiktionary doesn't find a word, ask Gemini (gemini-3.5-flash-lite)
  //      to suggest the 5 closest words. Ordered with closest word first.
  function runAiSuggest(useFallback) {
    var target = String(root.originalQuery || root.query || "").trim()
    if (target === "") return

    var cacheKey = (root.language || "en") + ":" + target.toLowerCase()
    if (!useFallback && root.aiCache && root.aiCache[cacheKey] && root.aiCache[cacheKey].length > 0) {
      var cached = root.aiCache[cacheKey]
      root.aiSuggestions = cached
      root.suggestions = cached
      root.aiStatus = "ok"
      root.aiError = ""
      return
    }

    var key = root.effectiveGeminiKey
    if (key === "") {
      root.aiStatus = "missing-key"
      fallbackToLocalFuzzy()
      return
    }

    var chosenModel = useFallback ? root.fallbackModel : root.effectiveModel
    var args = Model.geminiSuggestArgs(target, key, Model.langLabel(root.language), chosenModel)
    if (args.length === 0) {
      root.aiStatus = "error"
      root.aiError = "could not build the AI request"
      fallbackToLocalFuzzy()
      return
    }

    if (!useFallback) {
      root.aiSuggestions = []
      root.aiTriedFallback = false
    }
    root.aiError = ""
    root.aiStatus = "loading"
    // Keep local fallback visible while AI is loading
    fallbackToLocalFuzzy()
    if (aiProc.running) aiProc.running = false
    aiProc.command = args
    aiProc.running = true
  }

  Process {
    id: aiProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.aiStatus !== "loading") return
        var words = Model.parseGeminiSuggestions(text)
        if (words.length > 0) {
          var target = String(root.originalQuery || root.query || "").trim()
          var cacheKey = (root.language || "en") + ":" + target.toLowerCase()
          if (!root.aiCache) root.aiCache = ({})
          root.aiCache[cacheKey] = words
          root.aiSuggestions = words
          root.suggestions = words
          root.aiStatus = "ok"
          root.aiError = ""
        } else {
          // If primary model failed (e.g. rate limit / empty parse), try fallback model once
          if (!root.aiTriedFallback && root.fallbackModel !== root.effectiveModel) {
            root.aiTriedFallback = true
            root.runAiSuggest(true)
          } else {
            fallbackToLocalFuzzy()
            root.aiStatus = "error"
            root.aiError = "AI suggestions unavailable"
          }
        }
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (root.aiStatus !== "loading") return
      if (!root.aiTriedFallback && root.fallbackModel !== root.effectiveModel) {
        root.aiTriedFallback = true
        root.runAiSuggest(true)
      } else {
        fallbackToLocalFuzzy()
        root.aiStatus = "error"
        root.aiError = exitCode === 28 ? "AI request timed out" : "AI suggestions unavailable"
      }
    }
  }

  // Curl process. Curl exits 22 on the not-found path (HTTP 404), which
  // is not a network error from the user's perspective; the response body
  // carries the API's own message, so we always try to parse it.
  Process {
    id: lookupProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.status !== "loading") return
        var result = Model.parseResponse(text, root.language)
        if (result && result.ok) {
          root.entry = result.entry
          root.variants = result.variants || 0
          root.status = "ok"
          root.statusMessage = ""
        } else if (result && (result.kind === "notfound" || result.kind === "invalid" || result.kind === "empty")) {
          root.entry = null
          if (root.isAutoMatched) {
            root.isAutoMatched = false
            root.status = "notfound"
            root.statusMessage = "no definition found for \"" + (root.originalQuery || root.query) + "\""
            return
          }
          root.originalQuery = root.query
          root.status = "suggestions"
          root.statusMessage = "no definition found for \"" + root.originalQuery + "\""
          root.runAiSuggest(false)
        } else {
          root.entry = null
          root.status = "error"
          root.statusMessage = (result && result.error) || "could not look up the word"
        }
      }
    }
    stderr: StdioCollector {
      id: lookupStderr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (root.status !== "loading") return
      root.entry = null
      root.status = "error"
      root.statusMessage = "could not reach the dictionary service"
    }
  }

  // Debounce kept as a Timer in case auto-search is enabled later — for now
  // it's only used to dedupe rapid Enter presses during a request.
  Timer {
    id: searchDebounce
    interval: root.searchDelayMs
    repeat: false
    onTriggered: runLookup()
  }

  onOpenedChanged: if (opened) refreshFocus()

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.panelWidth)
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, root.panelMaxHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: searchField.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      // Type to search shortcuts when the field isn't focused: "/" focuses
      // and selects the search field (fuzzy launcher convention); "Esc"
      // arrives here only when the field does not own focus.
      onTextKey: function(t) {
        if (t === "/") {
          root.refreshFocus()
        }
      }

Column {
      id: panelColumn
      width: parent.width
      spacing: Style.space(14)

        // ---------- Hero: title + entry summary (parts of speech) + lang dropdown
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, languageDropdown.implicitHeight)

          Text {
            id: heroIcon
            text: "󰗚"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: languageDropdown.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Dictionary"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              text: {
                if (root.status === "ok" && root.entry) {
                  var parts = root.heroSummary
                  var suffix = root.variants > 1 ? " · " + root.variants + " entries" : ""
                  return (parts === "" ? "found" : parts) + suffix
                }
                if (root.status === "loading") return "looking up…"
                if (root.status === "suggestions") {
                  if (root.aiStatus === "loading") return "AI finding closest words…"
                  if (root.aiStatus === "ok") return "AI spelling suggestions"
                  return "did you mean"
                }
                if (root.status === "notfound") return "no definition"
                if (root.status === "error") return "couldn't reach the API"
                return "look up a word"
              }
              textFormat: Text.PlainText
              color: Qt.darker(root.contentForeground, 1.4)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          // Language switcher in the top right of the popup. Data-driven
          // from Model.languages() (sorted alphabetically by English
          // label in JS) so adding a language is a one-entry edit.
          // Picking one kicks off a fresh lookup when there's already a
          // query, so changing language doesn't require retyping the
          // word.
          Dropdown {
            id: languageDropdown
            value: root.language
            options: Model.languages()
            showLabel: false
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Style.space(120)
            onChanged: function(newValue) {
              if (newValue === root.language) return
              root.language = newValue
              // The previously-shown entry (or in-flight lookup) was for
              // the prior language and is no longer meaningful under the
              // new one. Cancel any in-flight proc, clear the entry,
              // empty the search field, and reset to idle so the user
              // starts fresh with the new language.
              if (lookupProc.running) lookupProc.running = false
              var hadResult = root.status === "ok" || root.status === "notfound" ||
                              root.status === "error" || root.status === "suggestions" ||
                              root.status === "loading"
              if (hadResult) {
                root.resetResults()
                root.programmaticEdit = true
                searchField.text = ""
                root.programmaticEdit = false
                root.query = ""
              }
            }
          }
        }

        // ---------- Search field ----------
        PanelSeparator {
          foreground: root.contentForeground
        }

        Item {
          width: parent.width
          implicitHeight: Style.space(46)

          Rectangle {
            anchors.fill: parent
            radius: Style.cornerRadius
            color: "transparent"
            border.width: Style.spacing.hairline
            border.color: searchField.activeFocus
              ? Color.accent
              : Qt.darker(root.contentForeground, 1.7)

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(6)
              spacing: Style.space(10)

              Text {
                text: "󰍉"
                color: Qt.darker(root.contentForeground, 1.3)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.title
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(22)
                horizontalAlignment: Text.AlignHCenter
              }

              TextField {
                id: searchField
                width: parent.width - clearRow.width - iconText.width - Style.space(10) * 2
                height: parent.height
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                color: root.contentForeground
                placeholderText: "Search a word…"
                placeholderTextColor: Qt.darker(root.contentForeground, 2.0)
                background: null
                selectByMouse: true
                clip: true
                onTextChanged: root.applyEdited()
                Keys.onEscapePressed: function(event) {
                  // Esc with empty field → close; Esc with text → clear the text.
                  if (String(searchField.text || "").length > 0) {
                    searchField.text = ""
                  } else {
                    root.close()
                    event.accepted = true
                    return
                  }
                  event.accepted = true
                }
              }

              Row {
                id: clearRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(4)

                Button {
                  id: clearButton
                  visible: String(searchField.text || "") !== ""
                  text: "✕"
                  onClicked: {
                    searchField.text = ""
                    root.refreshFocus()
                  }
                  foreground: root.contentForeground
                }

                Button {
                  id: searchButton
                  text: "→"
                  enabled: String(searchField.text || "").trim() !== "" && root.status !== "loading"
                  onClicked: {
                    searchDebounce.stop()
                    if (root.status === "suggestions" && root.closestWord !== "" &&
                        String(searchField.text || "").trim() === (root.originalQuery || root.query)) {
                      root.searchSuggestion(root.closestWord)
                    } else {
                      root.runLookup(false)
                    }
                  }
                  foreground: root.contentForeground
                }
              }
            }

            // Tag the pressed-Enter inside the TextField to the lookup. The
            // field handles onAccepted, but Quickshell's TextField wraps its
            // keys, so onAccepted plus the explicit returnPressed below give
            // a single firing path regardless of focus holder quirks.
            Item {
              id: iconText
              width: Style.space(22)
              height: Style.space(22)
              visible: false
            }
          }
        }

        Keys.onReturnPressed: function(event) {
          if (root.status === "suggestions" && root.closestWord !== "" &&
              String(searchField.text || "").trim() === (root.originalQuery || root.query)) {
            searchDebounce.stop()
            root.searchSuggestion(root.closestWord)
            event.accepted = true
            return
          }
          if (String(searchField.text || "").trim() !== "") {
            searchDebounce.stop()
            root.runLookup(false)
            event.accepted = true
          }
        }
        Keys.onEnterPressed: function(event) {
          if (root.status === "suggestions" && root.closestWord !== "" &&
              String(searchField.text || "").trim() === (root.originalQuery || root.query)) {
            searchDebounce.stop()
            root.searchSuggestion(root.closestWord)
            event.accepted = true
            return
          }
          if (String(searchField.text || "").trim() !== "") {
            searchDebounce.stop()
            root.runLookup(false)
            event.accepted = true
          }
        }

        // ---------- Body ----------
        PanelSeparator {
          foreground: root.contentForeground
        }

        // Body container — one slot per response state, only the active one
        // is visible. Pinned at top-left, full column width. Each branch
        // carries its own spacing/typography so swapping them doesn't
        // shift adjacent layout.
        Item {
          id: body
          width: parent.width
          implicitHeight: bodyColumn.implicitHeight

          Column {
            id: bodyColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Style.space(8)

            // Idle — no query yet.
            Column {
              width: parent.width
              visible: root.status === "idle"
              spacing: Style.space(6)

              Text {
                width: parent.width
                text: "Type a word in the field above, then press Enter to look it up."
                color: Qt.darker(root.contentForeground, 1.3)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }

              Text {
                width: parent.width
                text: "Definitions come from *.wiktionary.org/w/api.php* — no account or key required."
                color: Qt.darker(root.contentForeground, 1.7)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            // Loading. The Omarchy UI kit doesn't ship a spinner component,
            // so the magnify glyph is reused and rotated indefinitely while
            // a fetch is in flight.
            Row {
              visible: root.status === "loading"
              spacing: Style.space(10)
              width: parent.width

              Item {
                width: Style.space(18)
                height: Style.space(18)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  anchors.centerIn: parent
                  text: "󰗚"
                  color: Color.accent
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.title
                  transformOrigin: Item.Center

                  NumberAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                    running: root.status === "loading"
                  }
                }
              }

              Text {
                text: "Looking up \"" + root.query + "\"…"
                textFormat: Text.PlainText
                color: Qt.darker(root.contentForeground, 1.3)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            // Suggestions (AI-powered 5 closest words + robust local fallback)
            Column {
              id: suggestionsSection
              width: parent.width
              visible: root.status === "suggestions"
              spacing: Style.space(10)

              // Query status message
              Column {
                width: parent.width
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: "No definition for \"" + (root.originalQuery || root.query) + "\"."
                  textFormat: Text.PlainText
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  wrapMode: Text.WordWrap
                }

                Text {
                  width: parent.width
                  text: {
                    if (root.aiStatus === "loading") return "✨ Finding closest words with AI…"
                    if (root.aiStatus === "ok" && root.aiSuggestions.length > 0) return "AI found the 5 closest words for your query:"
                    if (root.suggestions.length > 0) return "Did you mean:"
                    return "No close matches found. Check your spelling or language."
                  }
                  textFormat: Text.PlainText
                  color: Qt.darker(root.contentForeground, 1.4)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                }
              }

              // AI loading spinner / shimmer indicator
              Row {
                width: parent.width
                visible: root.aiStatus === "loading"
                spacing: Style.space(8)

                Item {
                  width: Style.space(18)
                  height: Style.space(18)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    anchors.centerIn: parent
                    text: "✨"
                    color: Color.accent
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.body
                    transformOrigin: Item.Center

                    NumberAnimation on rotation {
                      from: 0
                      to: 360
                      duration: 1200
                      loops: Animation.Infinite
                      running: root.aiStatus === "loading"
                    }
                  }
                }

                Text {
                  text: "Asking AI for closest words…"
                  textFormat: Text.PlainText
                  color: Color.accent
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  font.italic: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              // Featured Closest Match Card (shown once closest word is determined)
              Rectangle {
                id: closestCard
                width: parent.width
                implicitHeight: Style.space(52)
                radius: Style.cornerRadius
                visible: root.closestWord !== ""
                color: Style.selectedFillFor(root.contentForeground, Color.accent)
                border.width: Style.spacing.hairline
                border.color: Color.accent

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.searchSuggestion(root.closestWord)

                  Row {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space(12)
                    anchors.rightMargin: Style.space(10)
                    spacing: Style.space(10)

                    Text {
                      text: "✨"
                      color: Color.accent
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.title
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: Style.space(1)
                      width: parent.width - Style.space(120)

                      Text {
                        text: root.aiStatus === "ok" ? "✨ AI RECOMMENDED CLOSEST MATCH" : "CLOSEST MATCH"
                        color: Color.accent
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 1.2
                      }

                      Text {
                        text: root.closestWord
                        textFormat: Text.PlainText
                        color: root.contentForeground
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.body
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width
                      }
                    }

                    Item {
                      width: Style.space(4)
                      height: 1
                    }

                    Button {
                      text: "Look up →"
                      foreground: Color.accent
                      anchors.verticalCenter: parent.verticalCenter
                      onClicked: root.searchSuggestion(root.closestWord)
                    }
                  }
                }
              }

              // Suggested words row (5 closest words as interactive chips)
              Column {
                width: parent.width
                visible: (root.aiSuggestions.length > 0 || root.suggestions.length > 0)
                spacing: Style.space(6)

                Text {
                  width: parent.width
                  text: root.aiStatus === "ok" ? "✨ AI Top 5 closest words:" : "Suggestions:"
                  color: Qt.darker(root.contentForeground, 1.4)
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.letterSpacing: 1.0
                }

                Flow {
                  width: parent.width
                  spacing: Style.space(6)

                  Repeater {
                    model: root.aiSuggestions.length > 0 ? root.aiSuggestions : root.suggestions

                    Button {
                      required property string modelData
                      required property int index
                      text: (index + 1) + ". " + modelData
                      foreground: index === 0 ? Color.accent : root.contentForeground
                      onClicked: root.searchSuggestion(modelData)
                    }
                  }
                }
              }

              // Footnote for status
              Text {
                width: parent.width
                visible: root.aiStatus === "ok" || root.aiStatus === "missing-key" || root.aiStatus === "error"
                text: {
                  if (root.aiStatus === "ok") return "✨ AI spelling assistance powered by Gemini"
                  if (root.aiStatus === "missing-key") return "💡 Tip: Configure GEMINI_API_KEY in ~/.config/omagent/config.json for AI-powered suggestions."
                  return "💡 AI suggestions offline · showing local dictionary suggestions."
                }
                textFormat: Text.PlainText
                color: root.aiStatus === "ok" ? Color.accent : Qt.darker(root.contentForeground, 1.6)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.italic: true
                wrapMode: Text.WordWrap
              }
            }

            // Not found (only visible when no suggestions exist at all)
            Column {
              width: parent.width
              visible: root.status === "notfound"
              spacing: Style.space(8)

              Text {
                width: parent.width
                text: "No definition for \"" + root.query + "\"."
                textFormat: Text.PlainText
                color: Qt.darker(root.contentForeground, 1.0)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }

              Text {
                width: parent.width
                visible: root.statusMessage !== ""
                text: root.statusMessage
                textFormat: Text.PlainText
                color: Qt.darker(root.contentForeground, 1.5)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }

            // Error.
            Column {
              width: parent.width
              visible: root.status === "error"
              spacing: Style.space(4)

              Text {
                width: parent.width
                text: "Couldn't look up \"" + root.query + "\"."
                textFormat: Text.PlainText
                color: Qt.darker(root.contentForeground, 1.0)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                wrapMode: Text.WordWrap
              }

              Text {
                width: parent.width
                text: root.statusMessage
                textFormat: Text.PlainText
                color: Qt.darker(root.contentForeground, 1.5)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }
        }

        // ---------- Results: word header + scrollable meaning list ----------
        Column {
          width: parent.width
          spacing: Style.space(10)
          visible: root.status === "ok" && root.entry !== null

          // Auto-match note. Only rendered when the user's original query
          // was misspelled and we silently fetched the closest match.
          // The text body is computed by a JS function so the ternary
          // doesn't evaluate the .word property on a null entry — that
          // pattern raises "Cannot read property 'word' of null" in QML
          // because it pre-evaluates both sides of `?:`.
          Text {
            width: parent.width
            visible: root.isAutoMatched && root.originalQuery !== "" && root.entry !== null
            text: root.autoMatchedNote()
            textFormat: Text.PlainText
            color: Qt.darker(root.contentForeground, 1.4)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            font.italic: true
            wrapMode: Text.WordWrap
          }

          Row {
            width: parent.width
            spacing: Style.space(10)

            Text {
              id: wordText
              text: root.entryWord()
              textFormat: Text.PlainText
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
              font.bold: true
              elide: Text.ElideRight
              width: parent.width - phoneticLabel.width - sourceTag.width - Style.space(20)
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: phoneticLabel
              text: root.entryPhonetic()
              textFormat: Text.PlainText
              color: Qt.darker(root.contentForeground, 1.3)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              font.italic: true
              anchors.verticalCenter: parent.verticalCenter
              visible: text !== ""
            }

            // Small muted source tag (e.g. "Wiktionary") to make it obvious
            // which data source filled the panel.
            Text {
              id: sourceTag
              text: root.entry ? Model.sourceLabel(entry) : ""
              textFormat: Text.PlainText
              color: Qt.darker(root.contentForeground, 1.55)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.italic: true
              anchors.verticalCenter: parent.verticalCenter
              visible: text !== ""
            }
          }

          Flickable {
            id: resultScroll
            width: parent.width
            height: Math.min(
              root.panelMaxHeight - Style.space(320),
              Math.max(Style.space(160), root.entry
                ? Math.min(Style.space(540), meaningStack.implicitHeight + Style.space(16))
                : Style.space(160))
            )
            contentWidth: width
            contentHeight: meaningStack.implicitHeight + Style.space(16)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
              id: meaningStack
              width: resultScroll.width
              spacing: Style.space(14)

              Repeater {
                model: root.entry ? root.entry.meanings : []

                Column {
                  required property var modelData
                  required property int index
                  width: parent.width
                  spacing: Style.space(6)

                  Row {
                    width: parent.width
                    spacing: Style.space(8)

                    Text {
                      text: modelData.partOfSpeech
                      textFormat: Text.PlainText
                      color: Color.accent
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      font.letterSpacing: 1.4
                      font.italic: true
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                      width: parent.width - implicitWidth - Style.space(8)
                      height: Style.spacing.hairline
                      color: Qt.darker(root.contentForeground, 1.9)
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }

                  Repeater {
                    model: modelData.definitions

                    Column {
                      required property var modelData
                      required property int index
                      width: parent.width
                      spacing: Style.space(2)

                      Row {
                        width: parent.width
                        spacing: Style.space(8)

                        Text {
                          text: (index + 1) + "."
                          color: Qt.darker(root.contentForeground, 1.5)
                          font.family: root.contentFontFamily
                          font.pixelSize: Style.font.body
                          width: Style.space(20)
                          horizontalAlignment: Text.AlignRight
                          anchors.top: parent.top
                          anchors.topMargin: 2
                        }

                        Text {
                          width: parent.width - Style.space(20) - Style.space(8)
                          text: modelData.definition
                          textFormat: Text.PlainText
                          color: root.contentForeground
                          font.family: root.contentFontFamily
                          font.pixelSize: Style.font.body
                          wrapMode: Text.WordWrap
                        }
                      }

                      Text {
                        width: parent.width - Style.space(20) - Style.space(8)
                        x: Style.space(20) + Style.space(8)
                        visible: modelData.example !== ""
                        text: "\"" + modelData.example + "\""
                        textFormat: Text.PlainText
                        color: Qt.darker(root.contentForeground, 1.3)
                        font.family: root.contentFontFamily
                        font.pixelSize: Style.font.caption
                        font.italic: true
                        wrapMode: Text.WordWrap
                      }
                    }
                  }

                  Text {
                    visible: modelData.synonyms.length > 0
                    width: parent.width
                    text: "synonyms: " + modelData.synonyms.join(", ")
                    textFormat: Text.PlainText
                    color: Qt.darker(root.contentForeground, 1.5)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }

                  Text {
                    visible: modelData.antonyms.length > 0
                    width: parent.width
                    text: "antonyms: " + modelData.antonyms.join(", ")
                    textFormat: Text.PlainText
                    color: Qt.darker(root.contentForeground, 1.5)
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    wrapMode: Text.WordWrap
                  }
                }
              }

              Item {
                width: parent.width
                height: Style.space(4)
              }
            }
          }
        }
      }
    }
  }
}
