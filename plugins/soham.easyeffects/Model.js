.pragma library

// Parse output of `easyeffects -s`
// Example output:
// input: 
// output: CrinEar Daybreak
function parseActivePreset(text) {
  if (!text) return null;
  var lines = String(text).split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    var match = line.match(/^output:\s*(.*)$/i);
    if (match) {
      return match[1].trim();
    }
  }
  return null;
}

// Parse output of `easyeffects -b 3`
// 1 = bypass is enabled (EQ bypassed / off)
// 2 = bypass is disabled (EQ active / processing)
function parseBypass(text) {
  if (!text) return false;
  var val = String(text).trim();
  return val === "1";
}

// Parse output from `easyeffects --presets` or a find/ls file list.
// Accept both the CLI's numbered format and plain filenames, then place the
// stock preset first and sort the remaining presets alphabetically.
function parsePresetList(output) {
  if (!output) return [];
  var lines = String(output).split("\n");
  var list = [];
  for (var i = 0; i < lines.length; i++) {
    var name = lines[i].trim();
    if (!name) continue;
    if (/^(?:Output|Input) presets:$/i.test(name) || /^No (?:input|output) presets\.$/i.test(name)) {
      continue;
    }
    var numbered = name.match(/^\d+\s+(.*)$/);
    if (numbered) name = numbered[1].trim();
    if (name.slice(-5) === ".json") {
      name = name.slice(0, -5);
    }
    if (name.length > 0 && list.indexOf(name) === -1) {
      list.push(name);
    }
  }

  // Sort with Stock first, then alphabetically
  list.sort(function(a, b) {
    var isStockA = isStockPreset(a);
    var isStockB = isStockPreset(b);
    if (isStockA && !isStockB) return -1;
    if (!isStockA && isStockB) return 1;
    return a.localeCompare(b);
  });

  return list;
}

// Check if a preset name is the protected stock baseline preset
function isStockPreset(name) {
  if (!name) return false;
  return String(name).toLowerCase().indexOf("stock") !== -1;
}

// Find stock preset from the list
function findStockPreset(presets) {
  if (!presets || !presets.length) return "";
  for (var i = 0; i < presets.length; i++) {
    if (isStockPreset(presets[i])) return presets[i];
  }
  return "";
}

