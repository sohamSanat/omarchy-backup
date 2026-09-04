// Night-light math shared by the service and panel.
// Temperatures below the identity point count as night light. Keep in sync
// with bin/omarchy-toggle-nightlight, which applies the same threshold.

var IDENTITY_TEMPERATURE = 6000
var MIN_TEMPERATURE = 1000
var MAX_TEMPERATURE = 6500
var DEFAULT_DAY_TEMPERATURE = 6500
var DEFAULT_NIGHT_TEMPERATURE = 3400
var DEFAULT_TRANSITION_MINUTES = 60
var TOGGLE_NIGHT_TEMPERATURE = 4000
var TOGGLE_DAY_TEMPERATURE = 6500

var PRESETS = [
  { value: "day", label: "Day", temperature: 6500 },
  { value: "evening", label: "Evening", temperature: 4000 },
  { value: "night", label: "Night", temperature: 3400 },
  { value: "candle", label: "Candle", temperature: 1900 }
]

function temperatureFromOutput(output) {
  var match = String(output === undefined || output === null ? "" : output).match(/[0-9]+/)
  return match ? Number(match[0]) : null
}

function isNightlight(temperature) {
  return temperature !== null && temperature !== undefined && temperature < IDENTITY_TEMPERATURE
}

function clampTemperature(value, fallback) {
  var n = Number(value)
  if (!isFinite(n)) return fallback
  return Math.max(MIN_TEMPERATURE, Math.min(MAX_TEMPERATURE, Math.round(n)))
}

function lerp(a, b, t) {
  t = Math.max(0, Math.min(1, t))
  return a + (b - a) * t
}

function minutesOfDay(date) {
  if (!date) date = new Date()
  return date.getHours() * 60 + date.getMinutes() + date.getSeconds() / 60
}

function wrapMinutes(mins) {
  var n = Math.round(Number(mins) || 0)
  return ((n % 1440) + 1440) % 1440
}

function formatMinutes(mins) {
  mins = wrapMinutes(mins)
  var h = Math.floor(mins / 60)
  var m = mins % 60
  var suffix = h < 12 ? "AM" : "PM"
  var h12 = h % 12
  if (h12 === 0) h12 = 12
  return h12 + ":" + (m < 10 ? "0" : "") + m + " " + suffix
}

function warmthName(temperature) {
  var t = Number(temperature)
  if (!isFinite(t)) return "Unknown"
  if (t >= 6000) return "Day"
  if (t >= 4500) return "Neutral"
  if (t >= 3700) return "Evening"
  if (t >= 3000) return "Night"
  if (t >= 2300) return "Tungsten"
  if (t >= 1600) return "Candle"
  return "Ember"
}

function presetForTemperature(temperature) {
  var t = clampTemperature(temperature, NaN)
  if (!isFinite(t)) return ""
  for (var i = 0; i < PRESETS.length; i++) {
    if (PRESETS[i].temperature === t) return PRESETS[i].value
  }
  return ""
}

function defaultState() {
  return {
    mode: "auto",
    manualTemperature: TOGGLE_NIGHT_TEMPERATURE,
    dayTemperature: DEFAULT_DAY_TEMPERATURE,
    nightTemperature: DEFAULT_NIGHT_TEMPERATURE,
    transitionMinutes: DEFAULT_TRANSITION_MINUTES,
    pauseUntil: null,
    latitude: null,
    longitude: null,
    locationName: ""
  }
}

function parseFiniteNumber(value) {
  if (value === null || value === undefined || value === "") return null
  var n = Number(value)
  return isFinite(n) ? n : null
}

function parseState(raw) {
  var state = defaultState()
  if (!raw) return state
  var parsed
  try {
    parsed = JSON.parse(String(raw))
  } catch (error) {
    return state
  }
  if (!parsed || typeof parsed !== "object") return state

  if (parsed.mode === "manual" || parsed.mode === "auto") state.mode = parsed.mode
  state.manualTemperature = clampTemperature(parsed.manualTemperature, state.manualTemperature)
  state.dayTemperature = clampTemperature(parsed.dayTemperature, state.dayTemperature)
  state.nightTemperature = clampTemperature(parsed.nightTemperature, state.nightTemperature)
  var trans = parseFiniteNumber(parsed.transitionMinutes)
  if (trans !== null) state.transitionMinutes = Math.max(1, Math.min(240, Math.round(trans)))
  var pause = parseFiniteNumber(parsed.pauseUntil)
  state.pauseUntil = pause !== null && pause > 0 ? Math.round(pause) : null
  state.latitude = parseFiniteNumber(parsed.latitude)
  state.longitude = parseFiniteNumber(parsed.longitude)
  if (typeof parsed.locationName === "string") state.locationName = parsed.locationName
  return state
}

function serializeState(state) {
  var s = state || defaultState()
  return JSON.stringify({
    mode: s.mode === "manual" ? "manual" : "auto",
    manualTemperature: clampTemperature(s.manualTemperature, TOGGLE_NIGHT_TEMPERATURE),
    dayTemperature: clampTemperature(s.dayTemperature, DEFAULT_DAY_TEMPERATURE),
    nightTemperature: clampTemperature(s.nightTemperature, DEFAULT_NIGHT_TEMPERATURE),
    transitionMinutes: Math.max(1, Math.min(240, Math.round(Number(s.transitionMinutes) || DEFAULT_TRANSITION_MINUTES))),
    pauseUntil: parseFiniteNumber(s.pauseUntil),
    latitude: parseFiniteNumber(s.latitude),
    longitude: parseFiniteNumber(s.longitude),
    locationName: typeof s.locationName === "string" ? s.locationName : ""
  }, null, 2) + "\n"
}

function parseWeatherLocation(raw) {
  if (!raw) return { name: "", latitude: null, longitude: null }
  try {
    var parsed = JSON.parse(String(raw))
    return {
      name: typeof parsed.name === "string" ? parsed.name : "",
      latitude: parseFiniteNumber(parsed.latitude),
      longitude: parseFiniteNumber(parsed.longitude)
    }
  } catch (error) {
    return { name: "", latitude: null, longitude: null }
  }
}

function parseGeocode(raw) {
  try {
    var parsed = JSON.parse(String(raw))
    var results = parsed && parsed.results
    if (!results || !results.length) return null
    var first = results[0]
    var lat = parseFiniteNumber(first.latitude)
    var lon = parseFiniteNumber(first.longitude)
    if (lat === null || lon === null) return null
    var parts = []
    if (first.name) parts.push(String(first.name))
    if (first.admin1) parts.push(String(first.admin1))
    return { latitude: lat, longitude: lon, locationName: parts.join(", ") }
  } catch (error) {
    return null
  }
}

function hasCoordinates(lat, lon) {
  return parseFiniteNumber(lat) !== null && parseFiniteNumber(lon) !== null
}

// NOAA / USNO sunrise-sunset algorithm. Returns UTC hours, or null when the
// sun does not rise or set (polar day/night).
function utcSunEventHours(lat, lon, date, rising) {
  var D2R = Math.PI / 180
  var R2D = 180 / Math.PI
  var zenith = 90.833
  var day = Math.floor((Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) - Date.UTC(date.getFullYear(), 0, 0)) / 86400000)
  var lngHour = lon / 15
  var t = rising ? day + ((6 - lngHour) / 24) : day + ((18 - lngHour) / 24)
  var M = (0.9856 * t) - 3.289
  var L = M + (1.916 * Math.sin(M * D2R)) + (0.020 * Math.sin(2 * M * D2R)) + 282.634
  L = ((L % 360) + 360) % 360
  var RA = R2D * Math.atan(0.91764 * Math.tan(L * D2R))
  RA = ((RA % 360) + 360) % 360
  var Lquadrant = Math.floor(L / 90) * 90
  var RAquadrant = Math.floor(RA / 90) * 90
  RA = (RA + (Lquadrant - RAquadrant)) / 15
  var sinDec = 0.39782 * Math.sin(L * D2R)
  var cosDec = Math.cos(Math.asin(sinDec))
  var cosH = (Math.cos(zenith * D2R) - (sinDec * Math.sin(lat * D2R))) / (cosDec * Math.cos(lat * D2R))
  if (cosH > 1 || cosH < -1) return null
  var H = rising ? 360 - R2D * Math.acos(cosH) : R2D * Math.acos(cosH)
  H = H / 15
  var T = H + RA - (0.06571 * t) - 6.622
  var UT = T - lngHour
  return ((UT % 24) + 24) % 24
}

function utcHoursToLocalMinutes(utcHours, date) {
  if (utcHours === null || utcHours === undefined) return null
  var noon = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 12, 0, 0)
  var localMin = Math.round(utcHours * 60 - noon.getTimezoneOffset())
  return wrapMinutes(localMin)
}

function sunTimes(lat, lon, date) {
  if (!hasCoordinates(lat, lon)) return { sunrise: null, sunset: null }
  if (!date) date = new Date()
  var rise = utcSunEventHours(lat, lon, date, true)
  var set = utcSunEventHours(lat, lon, date, false)
  return {
    sunrise: utcHoursToLocalMinutes(rise, date),
    sunset: utcHoursToLocalMinutes(set, date)
  }
}

function scheduledTemperature(opts) {
  var day = clampTemperature(opts.dayTemperature, DEFAULT_DAY_TEMPERATURE)
  var night = clampTemperature(opts.nightTemperature, DEFAULT_NIGHT_TEMPERATURE)
  var now = Number(opts.nowMinutes)
  var sunrise = opts.sunriseMinutes
  var sunset = opts.sunsetMinutes
  var trans = Math.max(1, Math.round(Number(opts.transitionMinutes) || DEFAULT_TRANSITION_MINUTES))
  if (!isFinite(now) || sunrise === null || sunrise === undefined || sunset === null || sunset === undefined)
    return day

  var sunriseStart = sunrise - trans
  var sunsetEnd = sunset + trans

  function between(start, end) {
    if (start === end) return false
    if (start < end) return now >= start && now < end
    return now >= start || now < end
  }

  function progress(start, end) {
    var span = end - start
    if (span <= 0) span += 1440
    var delta = now - start
    if (delta < 0) delta += 1440
    return delta / span
  }

  if (between(sunrise, sunset)) return day
  if (between(sunset, sunsetEnd)) return Math.round(lerp(day, night, progress(sunset, sunsetEnd)))
  if (between(sunriseStart, sunrise)) return Math.round(lerp(night, day, progress(sunriseStart, sunrise)))
  return night
}

function targetTemperature(opts) {
  var nowMs = opts.nowMs !== undefined ? Number(opts.nowMs) : Date.now()
  var pauseUntil = parseFiniteNumber(opts.pauseUntil)
  if (pauseUntil !== null && nowMs < pauseUntil)
    return clampTemperature(opts.dayTemperature, DEFAULT_DAY_TEMPERATURE)
  if (opts.mode === "manual")
    return clampTemperature(opts.manualTemperature, TOGGLE_NIGHT_TEMPERATURE)
  return scheduledTemperature(opts)
}

function inTransition(opts) {
  if (opts.mode === "manual") return false
  var pauseUntil = parseFiniteNumber(opts.pauseUntil)
  if (pauseUntil !== null && (opts.nowMs !== undefined ? Number(opts.nowMs) : Date.now()) < pauseUntil)
    return false
  var now = Number(opts.nowMinutes)
  var sunrise = opts.sunriseMinutes
  var sunset = opts.sunsetMinutes
  var trans = Math.max(1, Math.round(Number(opts.transitionMinutes) || DEFAULT_TRANSITION_MINUTES))
  if (!isFinite(now) || sunrise === null || sunset === null) return false
  if (now >= sunset && now < sunset + trans) return true
  if (now >= sunrise - trans && now < sunrise) return true
  return false
}

function pauseActive(pauseUntil, nowMs) {
  var pause = parseFiniteNumber(pauseUntil)
  if (pause === null) return false
  return (nowMs !== undefined ? Number(nowMs) : Date.now()) < pause
}

function scheduleStatus(opts) {
  if (pauseActive(opts.pauseUntil, opts.nowMs)) {
    var until = new Date(Number(opts.pauseUntil))
    return "Paused until " + formatMinutes(until.getHours() * 60 + until.getMinutes())
  }
  if (opts.mode === "manual") return "Manual · " + warmthName(opts.manualTemperature)
  if (!hasCoordinates(opts.latitude, opts.longitude)) return "Locating sunrise and sunset…"
  if (opts.sunriseMinutes === null || opts.sunsetMinutes === null) return "Waiting for sun times"
  var now = Number(opts.nowMinutes)
  var sunrise = opts.sunriseMinutes
  var sunset = opts.sunsetMinutes
  var trans = Math.max(1, Math.round(Number(opts.transitionMinutes) || DEFAULT_TRANSITION_MINUTES))
  if (isFinite(now) && now >= sunset && now < sunset + trans)
    return "Warming until " + formatMinutes(sunset + trans)
  if (isFinite(now) && now >= sunrise - trans && now < sunrise)
    return "Cooling until " + formatMinutes(sunrise)
  if (isFinite(now) && now >= sunrise && now < sunset)
    return "Sunset " + formatMinutes(sunset) + " → " + clampTemperature(opts.nightTemperature, DEFAULT_NIGHT_TEMPERATURE) + "K"
  return "Sunrise " + formatMinutes(sunrise) + " → " + clampTemperature(opts.dayTemperature, DEFAULT_DAY_TEMPERATURE) + "K"
}

function nextPauseUntilSunrise(opts) {
  var sunrise = opts.sunriseMinutes
  if (sunrise === null || sunrise === undefined) return null
  var date = opts.date || new Date()
  var now = minutesOfDay(date)
  var target = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0)
  target.setMinutes(Math.round(sunrise))
  if (now >= sunrise) target.setDate(target.getDate() + 1)
  return target.getTime()
}

if (typeof module !== "undefined") {
  module.exports = {
    IDENTITY_TEMPERATURE: IDENTITY_TEMPERATURE,
    MIN_TEMPERATURE: MIN_TEMPERATURE,
    MAX_TEMPERATURE: MAX_TEMPERATURE,
    DEFAULT_DAY_TEMPERATURE: DEFAULT_DAY_TEMPERATURE,
    DEFAULT_NIGHT_TEMPERATURE: DEFAULT_NIGHT_TEMPERATURE,
    DEFAULT_TRANSITION_MINUTES: DEFAULT_TRANSITION_MINUTES,
    TOGGLE_NIGHT_TEMPERATURE: TOGGLE_NIGHT_TEMPERATURE,
    TOGGLE_DAY_TEMPERATURE: TOGGLE_DAY_TEMPERATURE,
    PRESETS: PRESETS,
    temperatureFromOutput: temperatureFromOutput,
    isNightlight: isNightlight,
    clampTemperature: clampTemperature,
    lerp: lerp,
    minutesOfDay: minutesOfDay,
    wrapMinutes: wrapMinutes,
    formatMinutes: formatMinutes,
    warmthName: warmthName,
    presetForTemperature: presetForTemperature,
    defaultState: defaultState,
    parseState: parseState,
    serializeState: serializeState,
    parseWeatherLocation: parseWeatherLocation,
    parseGeocode: parseGeocode,
    hasCoordinates: hasCoordinates,
    sunTimes: sunTimes,
    scheduledTemperature: scheduledTemperature,
    targetTemperature: targetTemperature,
    inTransition: inTransition,
    pauseActive: pauseActive,
    scheduleStatus: scheduleStatus,
    nextPauseUntilSunrise: nextPauseUntilSunrise
  }
}
