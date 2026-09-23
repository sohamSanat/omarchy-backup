.pragma library

// Parse output of `easyeffects -s`
// Example output:
// input: 
// output: CrinEar Daybreak
function parseActivePreset(text) {
  if (!text) return "";
  var lines = String(text).split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim();
    var match = line.match(/^output:\s*(.*)$/i);
    if (match) {
      return match[1].trim();
    }
  }
  return "";
}

// Parse output of `easyeffects -b 3`
// 1 = bypass is enabled (EQ bypassed / off)
// 2 = bypass is disabled (EQ active / processing)
function parseBypass(text) {
  if (!text) return false;
  var val = String(text).trim();
  return val === "1";
}

// Parse preset filenames from find/ls
// Strips .json and places Stock preset first
function parsePresetList(output) {
  if (!output) return [];
  var lines = String(output).split("\n");
  var list = [];
  for (var i = 0; i < lines.length; i++) {
    var name = lines[i].trim();
    if (!name) continue;
    if (name.slice(-5) === ".json") {
      name = name.slice(0, -5);
    }
    if (name.length > 0 && list.indexOf(name) === -1) {
      list.push(name);
    }
  }

  // Sort with Stock first, then alphabetically
  list.sort(function(a, b) {
    var isStockA = a.toLowerCase().indexOf("stock") !== -1;
    var isStockB = b.toLowerCase().indexOf("stock") !== -1;
    if (isStockA && !isStockB) return -1;
    if (!isStockA && isStockB) return 1;
    return a.localeCompare(b);
  });

  return list;
}
