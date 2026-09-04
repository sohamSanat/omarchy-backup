import QtQuick
import Quickshell
import Quickshell.Io
import "NightlightModel.js" as NightlightModel

Item {
  id: root

  property var shell: null

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/settings"
  readonly property string statePath: stateDir + "/nightlight.json"
  readonly property string weatherPath: stateDir + "/weather.json"

  property bool stateLoaded: false
  property bool settingsLoaded: false
  property bool hydrating: false
  property var temperature: null
  property int lastAppliedTemperature: -1

  property string mode: "auto"
  property int dayTemperature: NightlightModel.DEFAULT_DAY_TEMPERATURE
  property int nightTemperature: NightlightModel.DEFAULT_NIGHT_TEMPERATURE
  property int manualTemperature: NightlightModel.TOGGLE_NIGHT_TEMPERATURE
  property int transitionMinutes: NightlightModel.DEFAULT_TRANSITION_MINUTES
  property var pauseUntil: null
  property var latitude: null
  property var longitude: null
  property string locationName: ""

  property var sunriseMinutes: null
  property var sunsetMinutes: null
  property date clockDate: new Date()

  property bool hasPendingTemperature: false
  property int pendingTemperature: 0
  property bool applyingLive: false
  property bool geocodeAttempted: false

  readonly property bool enabled: stateLoaded && NightlightModel.isNightlight(temperature)
  readonly property bool hasLocation: NightlightModel.hasCoordinates(latitude, longitude)
  readonly property bool paused: NightlightModel.pauseActive(pauseUntil, Date.now())
  readonly property real nowMinutes: NightlightModel.minutesOfDay(clockDate)
  readonly property bool transitioning: NightlightModel.inTransition(scheduleOpts())

  readonly property string warmthLabel: NightlightModel.warmthName(displayTemperature)
  readonly property int displayTemperature: {
    if (applyingLive && hasPendingTemperature) return pendingTemperature
    if (temperature !== null && temperature !== undefined) return temperature
    return desiredTemperature
  }

  readonly property int desiredTemperature: NightlightModel.targetTemperature(scheduleOpts())

  readonly property string statusText: NightlightModel.scheduleStatus({
    mode: mode,
    manualTemperature: manualTemperature,
    dayTemperature: dayTemperature,
    nightTemperature: nightTemperature,
    transitionMinutes: transitionMinutes,
    pauseUntil: pauseUntil,
    nowMs: Date.now(),
    nowMinutes: nowMinutes,
    sunriseMinutes: sunriseMinutes,
    sunsetMinutes: sunsetMinutes,
    latitude: latitude,
    longitude: longitude
  })

  function scheduleOpts() {
    return {
      mode: mode,
      manualTemperature: manualTemperature,
      dayTemperature: dayTemperature,
      nightTemperature: nightTemperature,
      transitionMinutes: transitionMinutes,
      pauseUntil: pauseUntil,
      nowMs: Date.now(),
      nowMinutes: nowMinutes,
      sunriseMinutes: sunriseMinutes,
      sunsetMinutes: sunsetMinutes,
      latitude: latitude,
      longitude: longitude
    }
  }

  function recomputeSun() {
    clockDate = new Date()
    if (!hasLocation) {
      sunriseMinutes = null
      sunsetMinutes = null
      return
    }
    var times = NightlightModel.sunTimes(latitude, longitude, clockDate)
    sunriseMinutes = times.sunrise
    sunsetMinutes = times.sunset
  }

  function persistableState() {
    return {
      mode: mode,
      manualTemperature: manualTemperature,
      dayTemperature: dayTemperature,
      nightTemperature: nightTemperature,
      transitionMinutes: transitionMinutes,
      pauseUntil: pauseUntil,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName
    }
  }

  function applyLoadedState(state) {
    hydrating = true
    mode = state.mode
    manualTemperature = state.manualTemperature
    dayTemperature = state.dayTemperature
    nightTemperature = state.nightTemperature
    transitionMinutes = state.transitionMinutes
    pauseUntil = state.pauseUntil
    latitude = state.latitude
    longitude = state.longitude
    locationName = state.locationName
    hydrating = false
    recomputeSun()
    tick()
    if (!hasLocation) maybeGeocode()
  }

  function loadSettings(raw) {
    applyLoadedState(NightlightModel.parseState(raw))
    settingsLoaded = true
    weatherFile.reload()
  }

  function scheduleSettingsSave() {
    if (!settingsLoaded || hydrating) return
    settingsSaveTimer.restart()
  }

  function flushSettings() {
    if (!settingsLoaded || hydrating) return
    settingsFile.setText(NightlightModel.serializeState(persistableState()))
  }

  function setLocation(lat, lon, name) {
    latitude = lat
    longitude = lon
    if (name) locationName = name
    recomputeSun()
    scheduleSettingsSave()
    tick()
  }

  function adoptWeatherLocation(raw) {
    var loc = NightlightModel.parseWeatherLocation(raw)
    if (NightlightModel.hasCoordinates(loc.latitude, loc.longitude)) {
      setLocation(loc.latitude, loc.longitude, loc.name || locationName)
      return
    }
    if (!hasLocation && loc.name) {
      locationName = loc.name
      maybeGeocode()
    }
  }

  function maybeGeocode() {
    if (hasLocation || geocodeProc.running) return
    var query = locationName
    if (!query) {
      weatherFile.reload()
      return
    }
    geocodeAttempted = true
    geocodeProc.command = ["curl", "-fsS", "--max-time", "5",
      "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=1&language=en&format=json"]
    geocodeProc.running = true
  }

  function refresh() {
    if (!statusProbe.running) statusProbe.running = true
  }

  function setNightlight(value) {
    pauseUntil = null
    mode = "manual"
    var temp = value ? nightTemperature : dayTemperature
    manualTemperature = temp
    scheduleSettingsSave()
    applyTemperature(temp)
  }

  function toggle() {
    setNightlight(!enabled)
  }

  function setManualTemperature(temp) {
    pauseUntil = null
    mode = "manual"
    manualTemperature = NightlightModel.clampTemperature(temp, manualTemperature)
    scheduleSettingsSave()
    applyTemperature(manualTemperature)
  }

  function setMode(value) {
    mode = value === "manual" ? "manual" : "auto"
    if (mode === "auto") pauseUntil = null
    scheduleSettingsSave()
    tick()
  }

  function setDayTemperature(temp) {
    dayTemperature = NightlightModel.clampTemperature(temp, dayTemperature)
    scheduleSettingsSave()
    tick()
  }

  function setNightTemperature(temp) {
    nightTemperature = NightlightModel.clampTemperature(temp, nightTemperature)
    scheduleSettingsSave()
    tick()
  }

  function pauseFor(seconds) {
    var secs = Number(seconds)
    if (!isFinite(secs) || secs <= 0) {
      pauseUntil = null
    } else {
      pauseUntil = Date.now() + Math.round(secs) * 1000
      mode = "auto"
    }
    scheduleSettingsSave()
    tick()
  }

  function pauseUntilSunrise() {
    recomputeSun()
    var until = NightlightModel.nextPauseUntilSunrise({
      sunriseMinutes: sunriseMinutes,
      date: clockDate
    })
    pauseUntil = until
    mode = "auto"
    scheduleSettingsSave()
    tick()
  }

  function applyPreset(name) {
    var presets = NightlightModel.PRESETS
    for (var i = 0; i < presets.length; i++) {
      if (presets[i].value === name) {
        setManualTemperature(presets[i].temperature)
        return
      }
    }
  }

  function applyTemperature(temp) {
    var next = NightlightModel.clampTemperature(temp, dayTemperature)
    root.temperature = next
    root.stateLoaded = true

    if (applyProcess.running) {
      root.pendingTemperature = next
      root.hasPendingTemperature = true
      return
    }

    runApply(next)
  }

  function runApply(temp) {
    root.pendingTemperature = temp
    applyProcess.command = ["bash", "-lc",
      "pgrep -x hyprsunset >/dev/null || { setsid uwsm-app -- hyprsunset >/dev/null 2>&1 & sleep 1; }; " +
      "hyprctl hyprsunset temperature " + Number(temp)]
    applyProcess.running = true
  }

  function tick() {
    if (pauseUntil !== null && Date.now() >= pauseUntil) {
      pauseUntil = null
      scheduleSettingsSave()
    }
    recomputeSun()
    if (mode === "auto" && !NightlightModel.pauseActive(pauseUntil) && (sunriseMinutes === null || sunsetMinutes === null))
      return
    applyTemperature(desiredTemperature)
  }

  function statusPayload() {
    return {
      enabled: enabled,
      mode: mode,
      temperature: displayTemperature,
      dayTemperature: dayTemperature,
      nightTemperature: nightTemperature,
      sunrise: sunriseMinutes,
      sunset: sunsetMinutes,
      pauseUntil: pauseUntil,
      locationName: locationName,
      statusText: statusText
    }
  }

  Timer {
    id: settingsSaveTimer
    interval: 200
    repeat: false
    onTriggered: root.flushSettings()
  }

  Timer {
    id: scheduler
    interval: root.transitioning || root.applyingLive ? 2000 : 30000
    running: true
    repeat: true
    onTriggered: root.tick()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: {
      root.clockDate = date
      root.tick()
    }
  }

  FileView {
    id: settingsFile
    path: root.statePath
    watchChanges: false
    atomicWrites: true
    printErrors: false
    onLoaded: if (!root.settingsLoaded) root.loadSettings(text())
    onLoadFailed: if (!root.settingsLoaded) root.loadSettings("")
  }

  FileView {
    id: weatherFile
    path: root.weatherPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.adoptWeatherLocation(text())
    onLoadFailed: root.adoptWeatherLocation("")
  }

  Process {
    id: ensureDirsProc
    command: ["mkdir", "-p", root.stateDir]
    onExited: {
      settingsFile.reload()
      weatherFile.reload()
    }
  }

  Process {
    id: statusProbe
    command: ["hyprctl", "hyprsunset", "temperature"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.temperature = NightlightModel.temperatureFromOutput(text)
        root.stateLoaded = true
        if (root.temperature !== null) root.lastAppliedTemperature = root.temperature
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.temperature = null
        root.stateLoaded = true
      }
    }
  }

  Process {
    id: applyProcess
    onExited: function() {
      root.lastAppliedTemperature = root.pendingTemperature
      root.temperature = root.pendingTemperature
      root.stateLoaded = true
      if (root.hasPendingTemperature) {
        root.hasPendingTemperature = false
        root.runApply(root.pendingTemperature)
        return
      }
      root.refresh()
    }
  }

  Process {
    id: geocodeProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var loc = NightlightModel.parseGeocode(text)
        if (loc) root.setLocation(loc.latitude, loc.longitude, loc.locationName)
      }
    }
  }

  Component.onCompleted: {
    ensureDirsProc.running = true
    refresh()
    Qt.callLater(function() {
      if (!settingsLoaded) settingsFile.reload()
    })
  }

  IpcHandler {
    target: "nightlight"

    function status(): string {
      return JSON.stringify(root.statusPayload())
    }

    function refresh(): void {
      root.refresh()
      root.tick()
    }

    function enable(): string {
      root.setNightlight(true)
      return "enabled"
    }

    function disable(): string {
      root.setNightlight(false)
      return "disabled"
    }

    function toggle(): string {
      var enabling = !root.enabled
      root.setNightlight(enabling)
      return enabling ? "enabled" : "disabled"
    }

    function setTemperature(temp: string): string {
      root.setManualTemperature(Number(temp))
      return "ok"
    }

    function setMode(value: string): string {
      root.setMode(value)
      return root.mode
    }

    function pause(seconds: string): string {
      if (seconds === "sunrise") root.pauseUntilSunrise()
      else if (seconds === "clear" || seconds === "0") root.pauseFor(0)
      else root.pauseFor(Number(seconds))
      return "ok"
    }

    function setDayTemperature(temp: string): string {
      root.setDayTemperature(Number(temp))
      return "ok"
    }

    function setNightTemperature(temp: string): string {
      root.setNightTemperature(Number(temp))
      return "ok"
    }

    function preset(name: string): string {
      root.applyPreset(name)
      return "ok"
    }
  }
}
