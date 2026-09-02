import QtQuick
import Quickshell
import Quickshell.Io

// Keeps the Gemini usage record fresh, and is what makes the plugin work from
// `omarchy plugin add` alone.
//
// The agents panel draws whatever JSON records sit in
// ~/.local/state/omarchy/agents/usage/, "regardless of who wrote it".
// omarchy-agent-usage-update, by contrast, only ever globs
// $OMARCHY_PATH/bin/omarchy-agent-usage-* -- a directory no plugin can write
// to without root. Routing the refresh through it would make adding this
// plugin a half-install that shows nothing until a sudo step is run by hand,
// which is exactly the trap this avoids: the collector ships in the plugin, so
// run it from here and let it write its own record.
//
// install.sh is still worth running, but only for what genuinely needs root:
// the system-wide collector and the Gemini mark in the panel's asset dir.
Item {
  id: root
  visible: false

  // Injected by the shell when it instantiates a service plugin; carries the
  // plugin's absolute source directory in __sourceDir.
  property var manifest: null

  readonly property string collectorRelPath: "bin/omarchy-agent-usage-gemini"

  // Resolved against this file rather than assembled from the injected
  // manifest, because the first refresh is triggered on start -- before the
  // shell has had a chance to inject anything. __sourceDir is the fallback for
  // a host that resolves the component from somewhere other than its own file.
  readonly property string collector: {
    var url = String(Qt.resolvedUrl(collectorRelPath))
    if (url.indexOf("file://") === 0) return url.substring(7)
    if (manifest && manifest.__sourceDir)
      return String(manifest.__sourceDir).replace(/\/$/, "") + "/" + collectorRelPath
    return ""
  }

  // Refreshes usage in the background so the agents panel always has up-to-date data.
  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (root.collector !== "" && !collectorProcess.running) collectorProcess.running = true
    }
  }

  Process {
    id: collectorProcess
    running: false
    // python3 by name rather than the shebang: a clone that lost the exec bit
    // should still collect.
    command: ["python3", root.collector, "--write"]

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") console.warn("agent-gemini", text.trim())
    }
  }
}
