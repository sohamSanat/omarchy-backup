// RaycastSearch.js — Raycast-like intelligence engine for Switchboard
//
// Capabilities:
//   1. Mathematical calculations (arithmetic, percentages, scientific functions, base conversion)
//   2. Currency conversion (50+ currencies, crypto, live cache support)
//   3. Quick Links (customizable URL shortcuts e.g. "yt cat videos")
//   4. Time Zone Converter (city/country/abbreviation lookup, time diffs, scheduling)

var DEFAULT_QUICKLINKS = [
  { prefix: "yt", name: "YouTube", url: "https://www.youtube.com/results?search_query={query}", home: "https://www.youtube.com", icon: "󰗃", description: "Search YouTube videos" },
  { prefix: "g", name: "Google", url: "https://www.google.com/search?q={query}", home: "https://www.google.com", icon: "󰊭", description: "Search Google" },
  { prefix: "gh", name: "GitHub", url: "https://github.com/search?q={query}", home: "https://github.com", icon: "", description: "Search GitHub repositories & code" },
  { prefix: "wiki", name: "Wikipedia", url: "https://en.wikipedia.org/wiki/Special:Search?search={query}", home: "https://en.wikipedia.org", icon: "󰖬", description: "Search Wikipedia articles" },
  { prefix: "maps", name: "Google Maps", url: "https://www.google.com/maps/search/{query}", home: "https://www.google.com/maps", icon: "󰆊", description: "Search Google Maps locations" },
  { prefix: "r", name: "Reddit", url: "https://www.reddit.com/search/?q={query}", home: "https://www.reddit.com", icon: "", description: "Search Reddit communities & posts" },
  { prefix: "ddg", name: "DuckDuckGo", url: "https://duckduckgo.com/?q={query}", home: "https://duckduckgo.com", icon: "󰇧", description: "Search DuckDuckGo" },
  { prefix: "x", name: "Twitter / X", url: "https://x.com/search?q={query}", home: "https://x.com", icon: "", description: "Search Twitter / X" },
  { prefix: "npm", name: "NPM", url: "https://www.npmjs.com/search?q={query}", home: "https://www.npmjs.com", icon: "󰏗", description: "Search NPM packages" },
  { prefix: "arch", name: "ArchWiki", url: "https://wiki.archlinux.org/index.php?search={query}", home: "https://wiki.archlinux.org", icon: "󰣇", description: "Search Arch Linux Wiki" },
  { prefix: "aur", name: "AUR", url: "https://aur.archlinux.org/packages?K={query}", home: "https://aur.archlinux.org", icon: "󰣇", description: "Search Arch User Repository" },
  { prefix: "so", name: "StackOverflow", url: "https://stackoverflow.com/search?q={query}", home: "https://stackoverflow.com", icon: "󰘷", description: "Search StackOverflow questions" },
  { prefix: "ai", name: "ChatGPT", url: "https://chatgpt.com/?q={query}", home: "https://chatgpt.com", icon: "󰭹", description: "Ask ChatGPT" }
]

// ----------------------------------------------------------- Math Calculator

function formatNumber(num) {
  if (!isFinite(num)) return String(num)
  var rounded = Math.round(num * 1e12) / 1e12
  var parts = String(rounded).split(".")
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  return parts.join(".")
}

function isMathQuery(rawQuery) {
  if (!rawQuery) return false
  var q = String(rawQuery).trim()
  if (!q) return false
  if (q.charAt(0) === "=") return true
  var lower = q.toLowerCase()
  if (lower === "calc" || lower === "math" || lower.indexOf("calc ") === 0 || lower.indexOf("math ") === 0) return true
  if (evaluateMath(q) !== null) return true
  if (/^\d{4}-\d{2}-\d{2}$/.test(q)) return false
  if (/\b(sqrt|cbrt|abs|round|floor|ceil|sin|cos|tan|log|ln|exp|pow|pi|e)\b/i.test(q)) return true
  if (/\b(?:to|in)\s+(?:hex|bin|binary|oct)\b/i.test(q)) return true
  if (/\d\s*%\s*(?:of)?/i.test(q)) return true
  if (/^[\d\s+\-*/%^().,×÷=]+$/.test(q) && /[\d]/.test(q) && /[+\-*/%^×÷=()]/.test(q)) return true
  return false
}

function evaluateMath(rawQuery) {
  if (!rawQuery) return null
  var q = String(rawQuery).trim()
  if (!q) return null

  var explicit = false
  if (q.charAt(0) === "=") {
    explicit = true
    q = q.slice(1).trim()
  }

  // Base conversions: "255 to hex", "10 to bin", "255 in hex", "64 to oct"
  var baseMatch = q.match(/^(.+?)\s+(?:to|in)\s+(hex|bin|binary|oct)$/i)
  if (baseMatch) {
    var subRes = evaluateMath("=" + baseMatch[1])
    if (subRes && isFinite(subRes.value)) {
      var intVal = Math.floor(subRes.value)
      var target = baseMatch[2].toLowerCase()
      var formatted = ""
      if (target === "hex") formatted = "0x" + intVal.toString(16).toUpperCase()
      else if (target === "bin" || target === "binary") formatted = "0b" + intVal.toString(2)
      else if (target === "oct") formatted = "0o" + intVal.toString(8)
      return {
        itemId: "!calc.base",
        kind: "copy",
        type: "calc",
        value: intVal,
        label: "= " + formatted,
        detail: "Base conversion: " + rawQuery + " • Press ⏎ to copy",
        action: formatted,
        shortcut: "calc",
        icon: "󰃬"
      }
    }
  }

  // Percentage: "X% of Y"
  var pctOfMatch = q.match(/^([+-]?\d+(?:\.\d+)?)\s*%\s*(?:of)\s*([+-]?\d+(?:\.\d+)?)$/i)
  if (pctOfMatch) {
    var pct = parseFloat(pctOfMatch[1])
    var total = parseFloat(pctOfMatch[2])
    var val = (pct / 100) * total
    return {
      itemId: "!calc.pct",
      kind: "copy",
      type: "calc",
      value: val,
      label: "= " + formatNumber(val),
      detail: "Calculation: " + q + " • Press ⏎ to copy",
      action: String(Math.round(val * 1e12) / 1e12),
      shortcut: "calc",
      icon: "󰃬"
    }
  }

  // Percentage addition/subtraction: "X + Y%" or "X - Y%"
  var addPctMatch = q.match(/^([+-]?\d+(?:\.\d+)?)\s*([+-])\s*(\d+(?:\.\d+)?)\s*%$/)
  if (addPctMatch) {
    var base = parseFloat(addPctMatch[1])
    var op = addPctMatch[2]
    var pctVal = parseFloat(addPctMatch[3])
    var delta = (base * pctVal) / 100
    var calcVal = op === "+" ? base + delta : base - delta
    return {
      itemId: "!calc.addpct",
      kind: "copy",
      type: "calc",
      value: calcVal,
      label: "= " + formatNumber(calcVal),
      detail: "Calculation: " + q + " • Press ⏎ to copy",
      action: String(Math.round(calcVal * 1e12) / 1e12),
      shortcut: "calc",
      icon: "󰃬"
    }
  }

  var expr = q.replace(/×/g, "*")
              .replace(/÷/g, "/")
              .replace(/\*\*/g, "^")
              .replace(/π/g, "pi")

  var hasOperator = /[+\-*/%^]/.test(expr)
  var hasFunc = /\b(sqrt|cbrt|abs|round|floor|ceil|sin|cos|tan|log|ln|exp|pow|pi|e)\b/i.test(expr)
  if (!explicit && !hasOperator && !hasFunc) {
    return null
  }

  var tokens = []
  var i = 0
  var len = expr.length

  while (i < len) {
    var ch = expr.charAt(i)
    if (/\s/.test(ch)) {
      i++
      continue
    }

    if (ch === "0" && i + 1 < len && (expr.charAt(i+1) === "x" || expr.charAt(i+1) === "X")) {
      var jHex = i + 2
      while (jHex < len && /[0-9a-fA-F]/.test(expr.charAt(jHex))) jHex++
      tokens.push({ type: "NUM", value: parseInt(expr.slice(i, jHex), 16) })
      i = jHex
      continue
    }
    if (ch === "0" && i + 1 < len && (expr.charAt(i+1) === "b" || expr.charAt(i+1) === "B")) {
      var jBin = i + 2
      while (jBin < len && /[01]/.test(expr.charAt(jBin))) jBin++
      tokens.push({ type: "NUM", value: parseInt(expr.slice(i+2, jBin), 2) })
      i = jBin
      continue
    }
    if (/[0-9]/.test(ch) || (ch === "." && i + 1 < len && /[0-9]/.test(expr.charAt(i+1)))) {
      var jNum = i
      var hasDot = false
      while (jNum < len && (/[0-9]/.test(expr.charAt(jNum)) || (expr.charAt(jNum) === "." && !hasDot))) {
        if (expr.charAt(jNum) === ".") hasDot = true
        jNum++
      }
      tokens.push({ type: "NUM", value: parseFloat(expr.slice(i, jNum)) })
      i = jNum
      continue
    }

    if (/[a-zA-Z_]/.test(ch)) {
      var jId = i
      while (jId < len && /[a-zA-Z0-9_]/.test(expr.charAt(jId))) jId++
      tokens.push({ type: "IDENT", value: expr.slice(i, jId).toLowerCase() })
      i = jId
      continue
    }

    if ("+-*/%^(),".indexOf(ch) >= 0) {
      tokens.push({ type: ch })
      i++
      continue
    }

    return null
  }

  if (tokens.length === 0) return null

  var pos = 0
  function peek() { return tokens[pos] }
  function consume(expected) {
    var tok = tokens[pos]
    if (expected && (!tok || tok.type !== expected)) return null
    pos++
    return tok
  }

  function parseExpression() { return parseAdditive() }

  function parseAdditive() {
    var left = parseMultiplicative()
    if (left === null) return null
    while (pos < tokens.length && (tokens[pos].type === "+" || tokens[pos].type === "-")) {
      var opTok = consume().type
      var right = parseMultiplicative()
      if (right === null) return null
      left = opTok === "+" ? left + right : left - right
    }
    return left
  }

  function parseMultiplicative() {
    var left = parseExponential()
    if (left === null) return null
    while (pos < tokens.length && (tokens[pos].type === "*" || tokens[pos].type === "/" || tokens[pos].type === "%")) {
      var opTok = consume().type
      var right = parseExponential()
      if (right === null) return null
      if (opTok === "*") left = left * right
      else if (opTok === "/") {
        if (right === 0) return null
        left = left / right
      }
      else if (opTok === "%") left = left % right
    }
    return left
  }

  function parseExponential() {
    var left = parseUnary()
    if (left === null) return null
    if (pos < tokens.length && tokens[pos].type === "^") {
      consume("^")
      var right = parseExponential()
      if (right === null) return null
      left = Math.pow(left, right)
    }
    return left
  }

  function parseUnary() {
    if (pos < tokens.length && tokens[pos].type === "+") {
      consume("+")
      return parseUnary()
    }
    if (pos < tokens.length && tokens[pos].type === "-") {
      consume("-")
      var val = parseUnary()
      return val === null ? null : -val
    }
    return parsePrimary()
  }

  function parsePrimary() {
    var tok = peek()
    if (!tok) return null

    if (tok.type === "NUM") {
      consume()
      return tok.value
    }

    if (tok.type === "IDENT") {
      var name = tok.value
      consume()

      if (name === "pi") return Math.PI
      if (name === "e") return Math.E

      if (pos < tokens.length && tokens[pos].type === "(") {
        consume("(")
        var args = []
        if (tokens[pos] && tokens[pos].type !== ")") {
          while (true) {
            var arg = parseExpression()
            if (arg === null) return null
            args.push(arg)
            if (tokens[pos] && tokens[pos].type === ",") {
              consume(",")
            } else {
              break
            }
          }
        }
        if (!consume(")")) return null

        switch (name) {
          case "sqrt": return args.length === 1 && args[0] >= 0 ? Math.sqrt(args[0]) : null
          case "cbrt": return args.length === 1 ? Math.cbrt(args[0]) : null
          case "abs": return args.length === 1 ? Math.abs(args[0]) : null
          case "round": return args.length === 1 ? Math.round(args[0]) : null
          case "floor": return args.length === 1 ? Math.floor(args[0]) : null
          case "ceil": return args.length === 1 ? Math.ceil(args[0]) : null
          case "sin": return args.length === 1 ? Math.sin(args[0]) : null
          case "cos": return args.length === 1 ? Math.cos(args[0]) : null
          case "tan": return args.length === 1 ? Math.tan(args[0]) : null
          case "asin": return args.length === 1 ? Math.asin(args[0]) : null
          case "acos": return args.length === 1 ? Math.acos(args[0]) : null
          case "atan": return args.length === 1 ? Math.atan(args[0]) : null
          case "log": return args.length === 1 && args[0] > 0 ? Math.log10(args[0]) : null
          case "ln": return args.length === 1 && args[0] > 0 ? Math.log(args[0]) : null
          case "exp": return args.length === 1 ? Math.exp(args[0]) : null
          case "pow": return args.length === 2 ? Math.pow(args[0], args[1]) : null
          case "min": return args.length >= 1 ? Math.min.apply(null, args) : null
          case "max": return args.length >= 1 ? Math.max.apply(null, args) : null
          default: return null
        }
      }

      return null
    }

    if (tok.type === "(") {
      consume("(")
      var v = parseExpression()
      if (!consume(")")) return null
      return v
    }

    return null
  }

  var result = parseExpression()
  if (result === null || pos !== tokens.length || !isFinite(result)) {
    return null
  }

  var cleanNum = Math.round(result * 1e12) / 1e12
  return {
    itemId: "!calc",
    kind: "copy",
    type: "calc",
    value: cleanNum,
    label: "= " + formatNumber(cleanNum),
    detail: "Calculation: " + q + " • Press ⏎ to copy",
    action: String(cleanNum),
    shortcut: "calc",
    icon: "󰃬"
  }
}

// ------------------------------------------------------ Currency Conversion

var BASE_RATES_TO_USD = {
  USD: 1.0,
  EUR: 0.92,
  GBP: 0.79,
  INR: 83.5,
  JPY: 155.0,
  CAD: 1.36,
  AUD: 1.52,
  CHF: 0.90,
  CNY: 7.23,
  HKD: 7.82,
  NZD: 1.64,
  SGD: 1.35,
  SEK: 10.5,
  KRW: 1370.0,
  NOK: 10.6,
  MXN: 17.5,
  BRL: 5.25,
  ZAR: 18.5,
  TRY: 32.5,
  AED: 3.67,
  SAR: 3.75,
  THB: 36.5,
  IDR: 16000.0,
  MYR: 4.70,
  PHP: 58.0,
  PLN: 3.98,
  CZK: 23.2,
  DKK: 6.87,
  HUF: 365.0,
  ILS: 3.72,
  RUB: 91.0,
  TWD: 32.4,
  VND: 25400.0,
  PKR: 278.0,
  BDT: 117.0,
  BTC: 0.000015,
  ETH: 0.00029,
  SOL: 0.0068
}

var CURRENCY_SYMBOLS = {
  USD: "$",
  EUR: "€",
  GBP: "£",
  INR: "₹",
  JPY: "¥",
  CAD: "C$",
  AUD: "A$",
  CHF: "Fr",
  CNY: "¥",
  KRW: "₩",
  RUB: "₽",
  TRY: "₺",
  THB: "฿",
  BRL: "R$",
  ILS: "₪",
  BTC: "₿",
  ETH: "Ξ",
  SOL: "SOL"
}

var SYMBOL_TO_CODE = {
  "$": "USD",
  "€": "EUR",
  "£": "GBP",
  "₹": "INR",
  "¥": "JPY",
  "₩": "KRW",
  "₽": "RUB",
  "₺": "TRY",
  "₿": "BTC",
  "฿": "THB",
  "₪": "ILS",
  "C$": "CAD",
  "A$": "AUD",
  "R$": "BRL"
}

var CURRENCY_ALIASES = {
  dollar: "USD",
  dollars: "USD",
  bucks: "USD",
  buck: "USD",
  usd: "USD",
  euro: "EUR",
  euros: "EUR",
  eur: "EUR",
  pound: "GBP",
  pounds: "GBP",
  quid: "GBP",
  gbp: "GBP",
  rupee: "INR",
  rupees: "INR",
  inr: "INR",
  yen: "JPY",
  jpy: "JPY",
  cad: "CAD",
  aud: "AUD",
  chf: "CHF",
  franc: "CHF",
  francs: "CHF",
  cny: "CNY",
  rmb: "CNY",
  yuan: "CNY",
  krw: "KRW",
  won: "KRW",
  rub: "RUB",
  ruble: "RUB",
  rubles: "RUB",
  try: "TRY",
  lira: "TRY",
  thb: "THB",
  baht: "THB",
  idr: "IDR",
  rupiah: "IDR",
  myr: "MYR",
  ringgit: "MYR",
  php: "PHP",
  peso: "PHP",
  pesos: "PHP",
  pln: "PLN",
  zloty: "PLN",
  sek: "SEK",
  nok: "NOK",
  dkk: "DKK",
  nzd: "NZD",
  sgd: "SGD",
  hkd: "HKD",
  aed: "AED",
  dirham: "AED",
  dirhams: "AED",
  sar: "SAR",
  riyal: "SAR",
  riyals: "SAR",
  btc: "BTC",
  bitcoin: "BTC",
  eth: "ETH",
  ethereum: "ETH",
  ether: "ETH",
  sol: "SOL",
  solana: "SOL"
}

function normalizeCurrency(raw) {
  if (!raw) return null
  var s = String(raw).trim()
  if (SYMBOL_TO_CODE[s]) return SYMBOL_TO_CODE[s]
  var lower = s.toLowerCase()
  if (CURRENCY_ALIASES[lower]) return CURRENCY_ALIASES[lower]
  var upper = s.toUpperCase()
  if (BASE_RATES_TO_USD[upper]) return upper
  return null
}

function formatCurrencyAmount(num, code) {
  if (num === 0) return "0.00"
  if (!isFinite(num)) return String(num)

  if (code === "JPY" || code === "KRW" || code === "IDR" || code === "VND" || code === "HUF") {
    var intStr = String(Math.round(num))
    return intStr.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  }

  if (num < 0.01 && num > 0) {
    return num.toFixed(6)
  }

  var rounded = (Math.round(num * 100) / 100).toFixed(2)
  var parts = rounded.split(".")
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",")
  return parts.join(".")
}

function convertCurrency(query, customRates) {
  if (!query) return null
  var q = String(query).trim()
  if (q.toLowerCase().indexOf("convert ") === 0) {
    q = q.slice(8).trim()
  }

  var re = /^([$€£¥₹₩₽₺₿A-Z$]{1,3})?\s*([0-9,]+(?:\.[0-9]+)?)\s*([$€£¥₹₩₽₺₿a-zA-Z]+)?\s*(?:to|in|into|=|as)\s*([$€£¥₹₩₽₺₿a-zA-Z]+)$/i
  var match = q.match(re)
  if (!match) return null

  var leadSymbol = match[1]
  var numStr = match[2].replace(/,/g, "")
  var amount = parseFloat(numStr)
  if (isNaN(amount) || amount < 0) return null

  var trailCurr = match[3]
  var targetCurr = match[4]

  var fromCode = null
  if (leadSymbol) fromCode = normalizeCurrency(leadSymbol)
  if (!fromCode && trailCurr) fromCode = normalizeCurrency(trailCurr)
  if (!fromCode) fromCode = "USD"

  var toCode = normalizeCurrency(targetCurr)
  if (!fromCode || !toCode || fromCode === toCode) return null

  var rates = customRates || BASE_RATES_TO_USD
  var fromRate = rates[fromCode] || BASE_RATES_TO_USD[fromCode]
  var toRate = rates[toCode] || BASE_RATES_TO_USD[toCode]
  if (!fromRate || !toRate) return null

  var converted = (amount / fromRate) * toRate
  var rate1 = (1 / fromRate) * toRate

  var toSymbol = CURRENCY_SYMBOLS[toCode] || ""
  var fromSymbol = CURRENCY_SYMBOLS[fromCode] || ""
  var formattedConverted = formatCurrencyAmount(converted, toCode)
  var formattedRate = formatCurrencyAmount(rate1, toCode)
  var formattedAmount = formatCurrencyAmount(amount, fromCode)

  return {
    itemId: "!currency",
    kind: "copy",
    type: "currency",
    label: toSymbol + formattedConverted + " " + toCode,
    detail: fromSymbol + formattedAmount + " " + fromCode + " = " + toSymbol + formattedConverted + " " + toCode + " (1 " + fromCode + " ≈ " + toSymbol + formattedRate + " " + toCode + ") • Press ⏎ to copy",
    action: formattedConverted.replace(/,/g, ""),
    shortcut: "fx",
    icon: "󰮄"
  }
}

// ---------------------------------------------------- Time Zone Converter

function isUsDst(year, month1, day) {
  if (month1 < 3 || month1 > 11) return false
  if (month1 > 3 && month1 < 11) return true
  if (month1 === 3) {
    var d3 = new Date(Date.UTC(year, 2, 1))
    var firstSun3 = (7 - d3.getUTCDay()) % 7 + 1
    return day >= firstSun3 + 7
  }
  if (month1 === 11) {
    var d11 = new Date(Date.UTC(year, 10, 1))
    var firstSun11 = (7 - d11.getUTCDay()) % 7 + 1
    return day < firstSun11
  }
  return false
}

function isEuDst(year, month1, day) {
  if (month1 < 3 || month1 > 10) return false
  if (month1 > 3 && month1 < 10) return true
  if (month1 === 3) {
    var d3 = new Date(Date.UTC(year, 2, 31))
    return day >= (31 - d3.getUTCDay())
  }
  if (month1 === 10) {
    var d10 = new Date(Date.UTC(year, 9, 31))
    return day < (31 - d10.getUTCDay())
  }
  return false
}

function isAuDst(year, month1, day) {
  if (month1 > 4 && month1 < 10) return false
  if (month1 < 4 || month1 > 10) return true
  if (month1 === 10) {
    var d10 = new Date(Date.UTC(year, 9, 1))
    var firstSun10 = (7 - d10.getUTCDay()) % 7 + 1
    return day >= firstSun10
  }
  if (month1 === 4) {
    var d4 = new Date(Date.UTC(year, 3, 1))
    var firstSun4 = (7 - d4.getUTCDay()) % 7 + 1
    return day < firstSun4
  }
  return false
}

var TIMEZONES = [
  { id: "utc", city: "UTC", country: "Universal", name: "UTC", baseOffset: 0, dst: "none", aliases: ["utc", "gmt", "zulu"] },
  { id: "tokyo", city: "Tokyo", country: "Japan", name: "JST", baseOffset: 540, dst: "none", aliases: ["tokyo", "japan", "jst", "osaka", "kyoto"] },
  { id: "london", city: "London", country: "UK", name: "GMT/BST", baseOffset: 0, dst: "eu", aliases: ["london", "uk", "england", "britain", "gmt", "bst"] },
  { id: "nyc", city: "New York", country: "USA", name: "EST/EDT", baseOffset: -300, dst: "us", aliases: ["new york", "nyc", "ny", "est", "edt", "eastern", "boston", "miami"] },
  { id: "sf", city: "San Francisco", country: "USA", name: "PST/PDT", baseOffset: -480, dst: "us", aliases: ["san francisco", "sf", "los angeles", "la", "pst", "pdt", "pacific", "seattle", "california"] },
  { id: "chicago", city: "Chicago", country: "USA", name: "CST/CDT", baseOffset: -360, dst: "us", aliases: ["chicago", "cst", "cdt", "central", "dallas", "houston", "austin"] },
  { id: "denver", city: "Denver", country: "USA", name: "MST/MDT", baseOffset: -420, dst: "us", aliases: ["denver", "mst", "mdt", "mountain", "phoenix", "salt lake"] },
  { id: "paris", city: "Paris", country: "France", name: "CET/CEST", baseOffset: 60, dst: "eu", aliases: ["paris", "france", "berlin", "germany", "rome", "madrid", "amsterdam", "cet", "cest", "brussels", "vienna", "warsaw"] },
  { id: "dubai", city: "Dubai", country: "UAE", name: "GST", baseOffset: 240, dst: "none", aliases: ["dubai", "uae", "abu dhabi", "gst"] },
  { id: "india", city: "New Delhi", country: "India", name: "IST", baseOffset: 330, dst: "none", aliases: ["india", "delhi", "mumbai", "bangalore", "bengaluru", "kolkata", "chennai", "hyderabad", "ist"] },
  { id: "singapore", city: "Singapore", country: "Singapore", name: "SGT", baseOffset: 480, dst: "none", aliases: ["singapore", "sgt"] },
  { id: "hongkong", city: "Hong Kong", country: "China", name: "HKT", baseOffset: 480, dst: "none", aliases: ["hong kong", "hk", "hkt", "beijing", "shanghai", "china"] },
  { id: "sydney", city: "Sydney", country: "Australia", name: "AEST/AEDT", baseOffset: 600, dst: "au", aliases: ["sydney", "melbourne", "canberra", "australia", "aest", "aedt"] },
  { id: "auckland", city: "Auckland", country: "New Zealand", name: "NZST/NZDT", baseOffset: 720, dst: "au", aliases: ["auckland", "wellington", "new zealand", "nz", "nzst", "nzdt"] },
  { id: "seoul", city: "Seoul", country: "South Korea", name: "KST", baseOffset: 540, dst: "none", aliases: ["seoul", "korea", "kst"] },
  { id: "saopaulo", city: "São Paulo", country: "Brazil", name: "BRT", baseOffset: -180, dst: "none", aliases: ["sao paulo", "brazil", "rio", "brt"] },
  { id: "cairo", city: "Cairo", country: "Egypt", name: "EEST", baseOffset: 120, dst: "none", aliases: ["cairo", "egypt"] },
  { id: "honolulu", city: "Honolulu", country: "USA (Hawaii)", name: "HST", baseOffset: -600, dst: "none", aliases: ["honolulu", "hawaii", "hst"] }
]

function getEffectiveOffset(tz, date) {
  var offset = tz.baseOffset
  var y = date.getUTCFullYear()
  var m = date.getUTCMonth() + 1
  var d = date.getUTCDate()

  if (tz.dst === "us" && isUsDst(y, m, d)) offset += 60
  else if (tz.dst === "eu" && isEuDst(y, m, d)) offset += 60
  else if (tz.dst === "au" && isAuDst(y, m, d)) offset += 60
  return offset
}

function findTimezone(raw) {
  if (!raw) return null
  var q = String(raw).trim().toLowerCase().replace(/^(in|at|the)\s+/i, "")
  for (var i = 0; i < TIMEZONES.length; i++) {
    var tz = TIMEZONES[i]
    for (var a = 0; a < tz.aliases.length; a++) {
      if (tz.aliases[a] === q) return tz
    }
  }
  for (var j = 0; j < TIMEZONES.length; j++) {
    var tz2 = TIMEZONES[j]
    for (var b = 0; b < tz2.aliases.length; b++) {
      if (tz2.aliases[b].indexOf(q) >= 0 || q.indexOf(tz2.aliases[b]) >= 0) return tz2
    }
  }
  return null
}

function formatTimeParts(totalMinutes) {
  var m = Math.floor(totalMinutes) % (24 * 60)
  if (m < 0) m += 24 * 60

  var hours24 = Math.floor(m / 60)
  var mins = m % 60
  var ampm = hours24 >= 12 ? "PM" : "AM"
  var hours12 = hours24 % 12
  if (hours12 === 0) hours12 = 12

  var pad = function(n) { return n < 10 ? "0" + n : "" + n }
  var time12 = hours12 + ":" + pad(mins) + " " + ampm
  var time24 = pad(hours24) + ":" + pad(mins)

  var schedule = ""
  if (hours24 >= 9 && hours24 < 17) schedule = "Work Hours (09:00 - 17:00)"
  else if (hours24 >= 17 && hours24 < 22) schedule = "Evening"
  else if (hours24 >= 6 && hours24 < 9) schedule = "Morning"
  else schedule = "Night / Sleep"

  return { hours24: hours24, hours12: hours12, mins: mins, ampm: ampm, time12: time12, time24: time24, schedule: schedule }
}

function formatDiff(diffMinutes) {
  if (diffMinutes === 0) return "Same time as local"
  var absMin = Math.abs(diffMinutes)
  var h = Math.floor(absMin / 60)
  var m = absMin % 60
  var diffStr = m > 0 ? (h + "h " + m + "m") : (h + "h")
  if (diffMinutes > 0) return diffStr + " ahead of local"
  return diffStr + " behind local"
}

function convertTimeZone(query, nowMs, localOffsetMin) {
  if (!query) return null
  var q = String(query).trim()
  var lower = q.toLowerCase()

  var now = new Date(nowMs || Date.now())
  var localOffset = (typeof localOffsetMin === "number") ? localOffsetMin : -now.getTimezoneOffset()

  // 1. "time in <place>", "now in <place>", "<place> time"
  var placeMatch = lower.match(/^(?:time|now|clock)\s+(?:in|at|for)\s+(.+)$/i) ||
                   lower.match(/^(.+?)\s+(?:time|now)$/i)

  if (placeMatch) {
    var tz = findTimezone(placeMatch[1])
    if (!tz) return null

    var tzOffset = getEffectiveOffset(tz, now)
    var utcMinutes = now.getUTCHours() * 60 + now.getUTCMinutes()
    var targetMinutes = utcMinutes + tzOffset
    var tParts = formatTimeParts(targetMinutes)

    var diffMin = tzOffset - localOffset
    var diffStr = formatDiff(diffMin)

    var utcDateMs = now.getTime()
    var targetDate = new Date(utcDateMs + tzOffset * 60000)
    var localDate = new Date(utcDateMs + localOffset * 60000)
    var dayRel = "Today"
    if (targetDate.getUTCDate() > localDate.getUTCDate()) dayRel = "Tomorrow"
    else if (targetDate.getUTCDate() < localDate.getUTCDate()) dayRel = "Yesterday"

    return {
      itemId: "!tz." + tz.id,
      kind: "copy",
      type: "timezone",
      label: tParts.time12 + " (" + tz.city + ") • " + dayRel,
      detail: tz.city + ", " + tz.country + " (" + tz.name + ") • " + diffStr + " • " + tParts.schedule + " • Press ⏎ to copy",
      action: tParts.time12 + " " + tz.name + " (" + tz.city + ")",
      shortcut: "tz",
      icon: "󰥔"
    }
  }

  // 2. Specific time conversion: "3pm est to ist", "10am london in tokyo", "15:30 cet to utc"
  var convMatch = lower.match(/^(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s+([a-zA-Z\s]+?)\s+(?:to|in|into)\s+([a-zA-Z\s]+)$/i)
  if (convMatch) {
    var timeStr = convMatch[1].trim()
    var fromStr = convMatch[2].trim()
    var toStr = convMatch[3].trim()

    var fromTz = findTimezone(fromStr)
    var toTz = findTimezone(toStr)
    if (!fromTz || !toTz) return null

    var srcHours = 0
    var srcMins = 0
    var isPm = timeStr.indexOf("pm") >= 0
    var isAm = timeStr.indexOf("am") >= 0
    var cleanTime = timeStr.replace(/(am|pm)/g, "").trim()
    var timeParts = cleanTime.split(":")
    srcHours = parseInt(timeParts[0], 10)
    if (timeParts.length > 1) srcMins = parseInt(timeParts[1], 10)

    if (isPm && srcHours < 12) srcHours += 12
    if (isAm && srcHours === 12) srcHours = 0

    var fromOffset = getEffectiveOffset(fromTz, now)
    var toOffset = getEffectiveOffset(toTz, now)

    var srcTotalMin = srcHours * 60 + srcMins
    var utcTotalMin = srcTotalMin - fromOffset
    var toTotalMin = utcTotalMin + toOffset

    var tPartsConv = formatTimeParts(toTotalMin)
    var diffHours = (toOffset - fromOffset) / 60
    var diffSign = diffHours >= 0 ? "+" : ""

    var dayDiff = "Same day"
    var dayShift = Math.floor((srcTotalMin - fromOffset + toOffset) / (24 * 60)) - Math.floor(srcTotalMin / (24 * 60))
    if (dayShift > 0) dayDiff = "Tomorrow"
    else if (dayShift < 0) dayDiff = "Yesterday"

    var fromParts = formatTimeParts(srcTotalMin)

    return {
      itemId: "!tz.conv",
      kind: "copy",
      type: "timezone",
      label: tPartsConv.time12 + " (" + toTz.city + ") • " + dayDiff,
      detail: fromParts.time12 + " " + fromTz.name + " = " + tPartsConv.time12 + " " + toTz.name + " (" + diffSign + diffHours + "h difference) • " + tPartsConv.schedule + " • Press ⏎ to copy",
      action: tPartsConv.time12 + " " + toTz.name + (dayDiff !== "Same day" ? " (" + dayDiff + ")" : ""),
      shortcut: "tz",
      icon: "󰥔"
    }
  }

  // 3. "<place> to <place>" (e.g. "est to ist", "nyc to tokyo")
  var diffMatch = lower.match(/^([a-zA-Z\s]+?)\s+(?:to|in)\s+([a-zA-Z\s]+)$/i)
  if (diffMatch) {
    var fromTzDiff = findTimezone(diffMatch[1].trim())
    var toTzDiff = findTimezone(diffMatch[2].trim())
    if (fromTzDiff && toTzDiff && fromTzDiff.id !== toTzDiff.id) {
      var fromOff = getEffectiveOffset(fromTzDiff, now)
      var toOff = getEffectiveOffset(toTzDiff, now)
      var diffH = (toOff - fromOff) / 60
      var diffS = diffH >= 0 ? "+" : ""

      var utcM = now.getUTCHours() * 60 + now.getUTCMinutes()
      var fromP = formatTimeParts(utcM + fromOff)
      var toP = formatTimeParts(utcM + toOff)

      return {
        itemId: "!tz.diff",
        kind: "copy",
        type: "timezone",
        label: toTzDiff.city + " is " + diffS + diffH + "h relative to " + fromTzDiff.city,
        detail: fromTzDiff.city + ": " + fromP.time12 + " ➔ " + toTzDiff.city + ": " + toP.time12 + " (" + toTzDiff.name + ") • Press ⏎ to copy",
        action: toTzDiff.city + ": " + toP.time12 + " (" + toTzDiff.name + ")",
        shortcut: "tz",
        icon: "󰥔"
      }
    }
  }

  return null
}

function getWorldClockRows(nowMs, localOffsetMin) {
  var now = new Date(nowMs || Date.now())
  var localOffset = (typeof localOffsetMin === "number") ? localOffsetMin : -now.getTimezoneOffset()
  var utcMinutes = now.getUTCHours() * 60 + now.getUTCMinutes()

  var cities = ["london", "nyc", "sf", "tokyo", "paris", "dubai", "sydney", "utc"]
  var rows = []

  for (var i = 0; i < cities.length; i++) {
    var tz = findTimezone(cities[i])
    if (!tz) continue
    var tzOffset = getEffectiveOffset(tz, now)
    var targetMin = utcMinutes + tzOffset
    var tParts = formatTimeParts(targetMin)
    var diffMin = tzOffset - localOffset
    var diffStr = formatDiff(diffMin)

    rows.push({
      itemId: "!tz." + tz.id,
      kind: "copy",
      type: "timezone",
      label: tParts.time12 + " — " + tz.city,
      detail: tz.city + ", " + tz.country + " (" + tz.name + ") • " + diffStr + " • " + tParts.schedule + " • Press ⏎ to copy",
      action: tParts.time12 + " " + tz.name + " (" + tz.city + ")",
      shortcut: "tz",
      icon: "󰥔"
    })
  }

  return rows
}

// ---------------------------------------------------------- Quick Links

function matchQuickLinks(query, quickLinksList) {
  if (!query) return []
  var q = String(query).trim()
  if (!q) return []

  var list = (quickLinksList && quickLinksList.length > 0) ? quickLinksList : DEFAULT_QUICKLINKS
  var lower = q.toLowerCase()

  // Check 1: User typed "ql", "quicklinks", "links", "quicklink"
  if (lower === "ql" || lower === "quicklinks" || lower === "quicklink" || lower === "links") {
    var allRows = []
    for (var k = 0; k < list.length; k++) {
      var item = list[k]
      allRows.push({
        itemId: "!ql." + item.prefix,
        kind: "fill",
        type: "quicklink",
        icon: item.icon || "󰌹",
        label: item.name + " (" + item.prefix + ")",
        detail: item.description || ("Search " + item.name + " — type '" + item.prefix + " <query>'"),
        action: item.prefix + " ",
        shortcut: item.prefix
      })
    }
    allRows.push({
      itemId: "!ql.config",
      kind: "open",
      type: "quicklink",
      icon: "",
      label: "Customize Quick Links",
      detail: "Edit shortcuts in ~/.config/omarchy/quicklinks.json",
      action: "~/.config/omarchy/quicklinks.json",
      shortcut: "edit"
    })
    return allRows
  }

  // Check 2: Prefix followed by search terms: e.g. "yt cat videos"
  var spaceIdx = q.indexOf(" ")
  if (spaceIdx > 0) {
    var prefix = q.slice(0, spaceIdx).toLowerCase()
    var searchArg = q.slice(spaceIdx + 1).trim()
    for (var i = 0; i < list.length; i++) {
      var ql = list[i]
      if (ql.prefix.toLowerCase() === prefix) {
        var encoded = encodeURIComponent(searchArg).replace(/%20/g, "+")
        var targetUrl = ql.url
        if (targetUrl.indexOf("{query}") >= 0) targetUrl = targetUrl.replace(/{query}/g, encoded)
        else if (targetUrl.indexOf("{}") >= 0) targetUrl = targetUrl.replace(/{}/g, encoded)
        else if (targetUrl.indexOf("%s") >= 0) targetUrl = targetUrl.replace(/%s/g, encoded)
        else targetUrl = targetUrl + encoded

        return [{
          itemId: "!ql." + ql.prefix,
          kind: "url",
          type: "quicklink",
          icon: ql.icon || "󰌹",
          label: ql.name + ": Search for \"" + searchArg + "\"",
          detail: targetUrl + " • Press ⏎ to open in browser",
          action: targetUrl,
          shortcut: ql.prefix
        }]
      }
    }
  }

  // Check 3: Exact prefix match: e.g. "yt"
  for (var j = 0; j < list.length; j++) {
    var qlExact = list[j]
    if (qlExact.prefix.toLowerCase() === lower) {
      var homeUrl = qlExact.home || qlExact.url.replace(/{query}|{}|%s/g, "")
      return [{
        itemId: "!ql." + qlExact.prefix,
        kind: "url",
        type: "quicklink",
        icon: qlExact.icon || "󰌹",
        label: "Open " + qlExact.name,
        detail: "Type '" + qlExact.prefix + " <query>' to search • Press ⏎ to open " + homeUrl,
        action: homeUrl,
        shortcut: qlExact.prefix
      }]
    }
  }

  // Check 4: Quicklink name matches search query (e.g. user typed "youtube")
  var nameMatches = []
  for (var n = 0; n < list.length; n++) {
    var qlName = list[n]
    if (qlName.name.toLowerCase().indexOf(lower) >= 0) {
      var hUrl = qlName.home || qlName.url.replace(/{query}|{}|%s/g, "")
      nameMatches.push({
        itemId: "!ql." + qlName.prefix,
        kind: "url",
        type: "quicklink",
        icon: qlName.icon || "󰌹",
        label: qlName.name + " (" + qlName.prefix + ")",
        detail: (qlName.description || ("Type '" + qlName.prefix + " <query>' to search")) + " • Press ⏎ to open",
        action: hUrl,
        shortcut: qlName.prefix
      })
    }
  }

  return nameMatches
}

// ---------------------------------------------------------- Master Dispatcher

function getSmartRows(query, options) {
  if (!query) return []
  var q = String(query).trim()
  if (!q) return []

  var opts = options || {}
  var quickLinks = opts.quickLinks || DEFAULT_QUICKLINKS
  var rates = opts.exchangeRates || null
  var nowMs = opts.nowMs || Date.now()
  var localOffset = opts.localOffsetMin

  var lower = q.toLowerCase()

  // 1. Calculator
  var calcResult = evaluateMath(q)
  if (calcResult) {
    return [calcResult]
  }
  if (isMathQuery(q)) {
    return [
      {
        itemId: "!calc.incomplete",
        kind: "noop",
        type: "calc",
        icon: "󰃬",
        label: "= …",
        detail: "Calculation: " + q + " • Type to complete expression",
        action: "",
        shortcut: "calc"
      }
    ]
  }

  // 2. Currency conversion
  var currResult = convertCurrency(q, rates)
  if (currResult) {
    return [currResult]
  }

  // 3. Time Zone conversion
  var tzResult = convertTimeZone(q, nowMs, localOffset)
  if (tzResult) {
    return [tzResult]
  }

  // 4. World clock dashboard
  if (lower === "tz" || lower === "timezone" || lower === "timezones" || lower === "world clock" || lower === "time") {
    return getWorldClockRows(nowMs, localOffset)
  }

  // 5. FMHY FreeMediaHeckYeah Directory
  if (lower === "fmhy" || (lower === "f" && q.indexOf(" ") === 1)) {
    return getFmhyPortalRows()
  }

  if (lower.indexOf("fmhy ") === 0 || lower.indexOf("f ") === 0) {
    var fmhySub = q.replace(/^(?:fmhy|f)\s+/i, "").trim()
    if (!fmhySub) {
      return getFmhyPortalRows()
    }
    return formatFmhyResults(fmhySub, opts.fmhyResults, opts.fmhySearching)
  }

  // 6. Quick Links
  var qlResults = matchQuickLinks(q, quickLinks)
  if (qlResults && qlResults.length > 0) {
    // If it's an exact prefix or prefix+query match, return it
    if (q.indexOf(" ") > 0 || qlResults[0].itemId.indexOf("!ql.") === 0) {
      return qlResults
    }
  }

  // 7. Help / trigger shortcuts
  if (lower === "calc" || lower === "math") {
    return [
      {
        itemId: "!calc.help",
        kind: "fill",
        type: "calc",
        icon: "󰃬",
        label: "Calculator: Type any math expression",
        detail: "Examples: 25 * 4, sqrt(144), 15% of 200, 2^10, 255 to hex",
        action: "25 * 4",
        shortcut: "calc"
      }
    ]
  }

  if (lower === "currency" || lower === "fx") {
    return [
      {
        itemId: "!currency.help",
        kind: "fill",
        type: "currency",
        icon: "󰮄",
        label: "Currency Converter: Convert 50+ currencies & crypto",
        detail: "Examples: 100 usd to inr, 50 eur in usd, $100 to inr, 1 btc to usd",
        action: "100 usd to inr",
        shortcut: "fx"
      }
    ]
  }

  // 8. General search: if query is at least 2 chars, provide an FMHY search recommendation
  if (q.length >= 2 && !q.match(/^(!|\/|~|=)/)) {
    var suggestRow = {
      itemId: "!fmhy.suggest." + q,
      kind: "fill",
      type: "fmhy-suggest",
      icon: "󰘧",
      label: "Search FMHY for \"" + q + "\"",
      detail: "Explore 14,500+ free resources & tools • Press ⏎ to search",
      action: "fmhy " + q,
      shortcut: "fmhy"
    }
    if (qlResults && qlResults.length > 0) {
      return qlResults.concat([suggestRow])
    }
    return [suggestRow]
  }

  return qlResults || []
}

function getFmhyPortalRows() {
  return [
    {
      itemId: "!fmhy.portal",
      kind: "fill",
      type: "fmhy",
      icon: "󰘧",
      label: "Search FMHY Directory (14,500+ curated resources)",
      detail: "Type 'fmhy <query>' to search free media, tools, streaming & guides",
      action: "fmhy ",
      shortcut: "fmhy"
    },
    {
      itemId: "!fmhy.deck",
      kind: "fmhy-deck",
      type: "fmhy",
      icon: "󰄛",
      label: "Open FMHY Deck Bar Panel",
      detail: "Launch dedicated FMHY Deck panel with category tree & saved bookmarks",
      action: "fmhy-panel",
      shortcut: "deck"
    },
    {
      itemId: "!fmhy.cat.adblock",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ Adblocking & Privacy Tools",
      detail: "uBlock Origin, AdGuard, DNS Adblockers, Anti-Tracking • Press ⏎",
      action: "fmhy adblock",
      shortcut: "adblock"
    },
    {
      itemId: "!fmhy.cat.stream",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ Streaming Sites & Media",
      detail: "Movies, TV Shows, Anime, Live TV, Sports Streaming • Press ⏎",
      action: "fmhy streaming",
      shortcut: "stream"
    },
    {
      itemId: "!fmhy.cat.video",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ Video Editing & Converters",
      detail: "Shotcut, Kdenlive, LosslessCut, Handbrake, Downloaders • Press ⏎",
      action: "fmhy video editor",
      shortcut: "video"
    },
    {
      itemId: "!fmhy.cat.linux",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ Linux Apps & Open Source",
      detail: "Curated Linux software, terminal tools, utilities • Press ⏎",
      action: "fmhy linux",
      shortcut: "linux"
    },
    {
      itemId: "!fmhy.cat.gaming",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ Gaming & Emulation",
      detail: "Emulators, ROMs, Repacks, Compatibility layers • Press ⏎",
      action: "fmhy game",
      shortcut: "gaming"
    },
    {
      itemId: "!fmhy.cat.music",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ Audio & Music Tools",
      detail: "Streaming players, FLAC/MP3 downloaders, taggers, DAWs • Press ⏎",
      action: "fmhy music",
      shortcut: "audio"
    },
    {
      itemId: "!fmhy.cat.ai",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ AI Tools & Productivity",
      detail: "Local LLMs, Web AI, Image Generators, Assistants • Press ⏎",
      action: "fmhy ai",
      shortcut: "ai"
    },
    {
      itemId: "!fmhy.cat.books",
      kind: "fill",
      type: "fmhy",
      icon: "",
      label: "★ Books & Learning Materials",
      detail: "Anna's Archive, Libgen, Textbooks, Research papers • Press ⏎",
      action: "fmhy books",
      shortcut: "books"
    }
  ]
}

function formatFmhyResults(subQuery, results, isSearching) {
  if (results && results.length > 0) {
    var out = []
    for (var i = 0; i < results.length; i++) {
      var item = results[i]
      var starPrefix = item.starred ? "★ " : ""
      var catPrefix = item.category ? "[" + item.category + "] " : ""
      var desc = item.description ? item.description : ""
      var host = item.hostname ? " • " + item.hostname : ""
      out.push({
        itemId: "!fmhy." + (item.url || i),
        kind: "url",
        type: "fmhy",
        label: starPrefix + item.title,
        detail: catPrefix + desc + host + " • Press ⏎ to open",
        action: item.url,
        shortcut: "fmhy",
        icon: item.starred ? "" : "󰖟"
      })
    }
    return out
  }

  if (isSearching) {
    return [
      {
        itemId: "!fmhy.loading",
        kind: "noop",
        type: "fmhy",
        icon: "󰘧",
        label: "Searching FMHY for \"" + subQuery + "\"…",
        detail: "Searching local catalog of 14,500+ curated free resources",
        action: "",
        shortcut: "fmhy"
      }
    ]
  }

  return [
    {
      itemId: "!fmhy.empty",
      kind: "url",
      type: "fmhy",
      icon: "󰘧",
      label: "No local FMHY results for \"" + subQuery + "\"",
      detail: "Search on fmhy.net in browser • Press ⏎",
      action: "https://fmhy.net/search?q=" + encodeURIComponent(subQuery),
      shortcut: "fmhy"
    }
  ]
}

function detectSearchGlyph(query, quickLinksList) {
  if (!query) return "󰍉"
  var q = String(query).trim()
  if (!q) return "󰍉"

  if (q.charAt(0) === "!") return ""
  if (q.indexOf("~/") === 0 || q.charAt(0) === "/") return ""

  var lower = q.toLowerCase()

  // FMHY check
  if (lower === "fmhy" || lower.indexOf("fmhy ") === 0 || (lower.indexOf("f ") === 0)) {
    return "󰘧"
  }

  var list = (quickLinksList && quickLinksList.length > 0) ? quickLinksList : DEFAULT_QUICKLINKS

  // Quicklink prefix check
  for (var i = 0; i < list.length; i++) {
    var ql = list[i]
    var pfx = ql.prefix.toLowerCase()
    if (lower === pfx || lower.indexOf(pfx + " ") === 0) {
      return ql.icon || "󰌹"
    }
  }

  // Currency check
  if (convertCurrency(q)) return "󰮄"

  // Time zone check
  if (lower === "tz" || lower === "timezone" || lower === "timezones" || lower.indexOf("time in") >= 0 || lower.indexOf("now in") >= 0 || convertTimeZone(q)) {
    return "󰥔"
  }

  // Math check
  if (isMathQuery(q)) return "󰃬"

  return "󰍉"
}

if (typeof module !== "undefined") {
  module.exports = {
    DEFAULT_QUICKLINKS: DEFAULT_QUICKLINKS,
    formatNumber: formatNumber,
    evaluateMath: evaluateMath,
    isMathQuery: isMathQuery,
    convertCurrency: convertCurrency,
    convertTimeZone: convertTimeZone,
    getWorldClockRows: getWorldClockRows,
    matchQuickLinks: matchQuickLinks,
    getSmartRows: getSmartRows,
    detectSearchGlyph: detectSearchGlyph,
    getFmhyPortalRows: getFmhyPortalRows,
    formatFmhyResults: formatFmhyResults
  }
}
