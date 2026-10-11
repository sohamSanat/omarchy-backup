import QtQuick
import qs.Commons
import Quickshell
import Quickshell.Io

/**
 * Animated status head for the code-mode card header.
 *
 * Plays one baked PNG frame per tick and swaps the image source. Each frame is
 * its own file, so Qt's pixmap cache holds them and a tick is only a source
 * change -- no clip-rect math, no WebGL, no canvas, no second process.
 *
 * Frame metrics come from `assets/heads/manifest.json`, which the offline baker
 * writes, so a re-bake with a different frame count never drifts from this
 * player.
 */
Item {
  id: head

  /** idle | thinking | searching | working | happy | error */
  property string state: "idle"
  /** Animate only while the overlay is open. Hidden-pause is handled by `visible`. */
  property bool animate: false

  // No system-wide reduced-motion signal is exposed to the shell, so the still
  // pose is an explicit opt-in rather than a guess.
  readonly property bool still: Quickshell.env("OMAGENT_STILL_HEAD") === "1"

  readonly property bool isLightMode: {
    const bg = Color.background;
    return (bg.r * 0.299 + bg.g * 0.587 + bg.b * 0.114) > 0.5;
  }
  readonly property string themeDir: head.isLightMode ? "light" : "dark"
  readonly property url themeDirUrl: Qt.resolvedUrl("assets/heads/" + head.themeDir + "/")

  // Manifest-driven geometry, with the baked defaults until it loads.
  property int frameCount: 48
  property int fps: 24

  property int frame: 0
  onStateChanged: head.frame = 0

  /** Frame source. A missing frame falls back to the idle still. */
  readonly property url frameSource: head.themeDirUrl + head.state + "/frame_"
    + (head.frame < 10 ? "0" : "") + head.frame + ".png"

  // Set `running` once per change rather than binding it: re-evaluating a
  // binding on `running` restarts the timer interval, which reads as judder.
  onAnimateChanged: frameTimer.running = animate && visible && !still
  onVisibleChanged: frameTimer.running = animate && visible && !still
  onStillChanged: frameTimer.running = animate && visible && !still

  width: Style.space(56)
  height: Style.space(70)

  FileView {
    id: metaFile
    path: String(Qt.resolvedUrl("assets/heads/manifest.json")).replace("file://", "")
    printErrors: false
    onLoaded: {
      try {
        const meta = JSON.parse(text());
        const s = meta.states && meta.states.idle;
        if (s) head.frameCount = s.frames || head.frameCount;
      } catch (error) {
        // A malformed manifest keeps the baked default; the head still plays.
      }
    }
  }

  Timer {
    id: frameTimer
    interval: Math.max(1, Math.round(1000 / head.fps))
    repeat: true
    onTriggered: {
      head.frame = (head.frame + 1) % head.frameCount;
      if (head.state !== "idle" && frameImage.status === Image.Error) {
        // Unknown or missing state: settle to the idle still rather than a hole.
        head.state = "idle";
        head.frame = 0;
      }
    }
  }

  Image {
    id: frameImage
    anchors.fill: parent
    asynchronous: false
    smooth: true
    fillMode: Image.PreserveAspectFit
    source: head.frameSource
  }
}
