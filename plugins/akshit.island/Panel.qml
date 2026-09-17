import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui
import "IslandModel.js" as IslandModel

Panel {
  id: root
  moduleName: "akshit.island"
  ipcTarget: "akshit.island"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // Player selection state (avoids auto-playing on selection)
  property string selectedPlayerKey: ""

  // Hover containment
  property bool panelHovered: false

  // Wayland toplevels for deep PWA detection
  readonly property var toplevels: ToplevelManager.toplevels ? ToplevelManager.toplevels.values : []

  // PipeWire's typed API is the only audio-control path. Do not spawn helpers
  // or shell commands from this plugin.
  readonly property var volumeSink: Pipewire.defaultAudioSink
  PwObjectTracker { objects: root.volumeSink ? [root.volumeSink] : [] }

  readonly property real audioVolume: volumeSink && volumeSink.audio ? volumeSink.audio.volume : 0.0
  readonly property real sliderVolume: IslandModel.uiVolumeFromPipewire(audioVolume)
  readonly property bool audioMuted: volumeSink && volumeSink.audio ? volumeSink.audio.muted : false

  function setAudioVolume(val) {
    var clamped = Math.max(0.0, Math.min(1.0, val))
    var pipewireVolume = IslandModel.pipewireVolumeFromUi(clamped)
    if (volumeSink && volumeSink.audio) {
      volumeSink.audio.volume = pipewireVolume
      if (volumeSink.audio.muted && clamped > 0) {
        volumeSink.audio.muted = false
      }
    }
  }

  function toggleAudioMute() {
    if (volumeSink && volumeSink.audio) {
      volumeSink.audio.muted = !volumeSink.audio.muted
    }
  }

  function volumeIcon(vol, muted) {
    if (muted || vol <= 0.001) return ""
    if (vol >= 0.67) return ""
    if (vol >= 0.33) return ""
    return ""
  }

  // MPRIS Services & Active Player Resolution
  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: IslandModel.resolveActivePlayer(players, selectedPlayerKey || (hostWidget ? hostWidget.configuredPreferredPlayer : ""))
  readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle || activePlayer.trackArtist) && (activePlayer.isPlaying || activePlayer.canTogglePlaying || activePlayer.canPlay || activePlayer.canPause)
  readonly property bool isPlaying: activePlayer ? (activePlayer.isPlaying === true && (activePlayer.canTogglePlaying || activePlayer.canPause || activePlayer.canPlay)) : false

  // Real Brand / Source Detection & Clean Metadata
  readonly property var sourceInfo: IslandModel.detectSource(activePlayer, toplevels)
  readonly property var cleanedTrack: IslandModel.cleanTrackInfo(activePlayer ? activePlayer.trackTitle : "", activePlayer ? activePlayer.trackArtist : "")
  readonly property string title: hasMedia ? cleanedTrack.title : "No Media Playing"
  readonly property string artist: hasMedia ? cleanedTrack.artist : ""
  readonly property string album: activePlayer && activePlayer.trackAlbum ? IslandModel.sanitizeString(activePlayer.trackAlbum, 80) : ""
  readonly property string playerIdentity: sourceInfo.name
  readonly property color contentForeground: bar && bar.barForeground ? bar.barForeground : Color.foreground
  readonly property string contentFontFamily: bar && bar.fontFamily ? bar.fontFamily : Style.font.family
  readonly property string artUrl: IslandModel.getSafeArtUrl(activePlayer)

  // Live audio peak monitoring from PipeWire for audio reactivity
  PwNodePeakMonitor {
    id: audioPeakMonitor
    node: root.volumeSink
    enabled: root.opened && root.hasMedia
  }

  property real dynamicPeak: 0.15

  // 40-band audio-reactive synth wave spectrum model (matches ytkew's spectrum bars)
  property var spectrumBars: [
    0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
    0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
    0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
    0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05,
    0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05
  ]

  function updateSpectrum() {
    var rawPeak = (audioPeakMonitor && isFinite(audioPeakMonitor.peak) && audioPeakMonitor.peak > 0.005)
      ? audioPeakMonitor.peak
      : (root.isPlaying ? 0.25 : 0.0);

    // Slowly-adapting AGC peak reference (matches ytkew visual.rs)
    if (rawPeak > root.dynamicPeak) {
      root.dynamicPeak = rawPeak;
    } else {
      root.dynamicPeak = Math.max(0.06, root.dynamicPeak * 0.992);
    }

    var normEnergy = root.isPlaying
      ? Math.min(1.0, Math.max(0.32, (rawPeak / root.dynamicPeak) * 0.7 + 0.3))
      : 0.0;

    var pLeft = rawPeak;
    var pRight = rawPeak;
    if (audioPeakMonitor && audioPeakMonitor.peaks && audioPeakMonitor.peaks.length >= 2) {
      if (isFinite(audioPeakMonitor.peaks[0])) pLeft = Math.max(0.0, audioPeakMonitor.peaks[0]);
      if (isFinite(audioPeakMonitor.peaks[1])) pRight = Math.max(0.0, audioPeakMonitor.peaks[1]);
    }

    var now = Date.now() / 1000.0;
    var newBars = root.spectrumBars.slice();
    var playing = root.isPlaying;

    for (var i = 0; i < 40; i++) {
      if (!playing) {
        newBars[i] = Math.max(0.02, newBars[i] * 0.86);
        continue;
      }

      var normI = i / 39.0; // 0.0 = low bass, 1.0 = high treble
      var chPeak = (1.0 - normI) * pLeft + normI * pRight;
      var effectivePeak = Math.max(normEnergy, chPeak);

      // Natural audio frequency spectral profile: strong bass, tapering toward highs
      var freqProfile = Math.max(0.35, 1.05 - Math.pow(normI, 0.6) * 0.52);

      // Multi-frequency harmonic synthesized phase for organic spectrum movement
      var s1 = Math.sin(now * (6.0 + (i % 5) * 1.5) + i * 0.45) * 0.32;
      var s2 = Math.sin(now * (11.2 + (i % 7) * 2.0) - i * 0.6) * 0.24;
      var s3 = Math.cos(now * 3.6 + i * 0.32) * 0.2;
      var harmonic = Math.max(0.2, (s1 + s2 + s3 + 0.9) * 0.6);

      // Target amplitude (scaled nicely to fill up to 85% of container height)
      var target = Math.min(1.0, Math.max(0.06, effectivePeak * freqProfile * harmonic * 1.25));

      // Instant rise on peaks, 0.86 exponential falloff (matches ytkew visual.rs)
      if (target > newBars[i]) {
        newBars[i] = target;
      } else {
        newBars[i] = Math.max(0.04, newBars[i] * 0.86 + target * 0.14);
      }
    }
    root.spectrumBars = newBars;
  }

  Timer {
    id: spectrumTimer
    interval: 30
    running: root.opened && root.hasMedia
    repeat: true
    onTriggered: root.updateSpectrum()
  }

  function refresh() {
    // Refresh triggered
  }

  function togglePlay() {
    var p = activePlayer
    if (!p) return
    if (p.canTogglePlaying) {
      p.togglePlaying()
    } else if (p.isPlaying && p.canPause) {
      p.pause()
    } else if (!p.isPlaying && p.canPlay) {
      p.play()
    }
  }

  function nextTrack() {
    var p = activePlayer
    if (p && p.canGoNext) p.next()
  }

  function prevTrack() {
    var p = activePlayer
    if (p && p.canGoPrevious) p.previous()
  }

  readonly property bool animationsEnabled: bar ? bar.foregroundAnimationEnabled : true

  PopupCard {
    id: panel
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root.barIdentity
    open: root.opened
    centerOnBar: true
    triggerMode: "hover"
    contentWidth: panel.fittedContentWidth(Style.space(root.hostWidget ? root.hostWidget.configuredPanelWidth : 380))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

    onOpenChanged: {
      if (open) {
        Qt.callLater(function() {
          if (keyCatcher) keyCatcher.forceActiveFocus()
        })
      } else {
        root.panelHovered = false
        if (root.hostWidget) root.hostWidget.remotePanelHovered = false
      }
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      HoverHandler {
        id: cardHoverHandler
        onHoveredChanged: {
          root.panelHovered = hovered
          if (root.hostWidget) {
            root.hostWidget.remotePanelHovered = hovered
          }
        }
      }

      onCloseRequested: root.close()
      onActivateRequested: root.togglePlay()
      onMoveRequested: function(dx, dy) {
        if (dx < 0) root.prevTrack()
        else if (dx > 0) root.nextTrack()
        if (dy > 0) root.setAudioVolume(root.sliderVolume + 0.05)
        else if (dy < 0) root.setAudioVolume(root.sliderVolume - 0.05)
      }
      onTextKey: function(t) {
        if (t === " ") root.togglePlay()
        else if (t === "n" || t === "l") root.nextTrack()
        else if (t === "p" || t === "h") root.prevTrack()
        else if (t === "+" || t === "=" || t === "k") root.setAudioVolume(root.sliderVolume + 0.05)
        else if (t === "-" || t === "_" || t === "j") root.setAudioVolume(root.sliderVolume - 0.05)
        else if (t === "m") root.toggleAudioMute()
      }

      Item {
        id: animWrapper
        anchors.fill: parent

        property real animProgress: 0.0
        property real animScale: 0.88
        property real animY: -16
        property real animOpacity: 0.0

        ParallelAnimation {
          id: openAnimation
          running: false
          NumberAnimation {
            target: animWrapper
            property: "animProgress"
            from: 0.0
            to: 1.0
            duration: root.animationsEnabled ? 320 : 0
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: animWrapper
            property: "animScale"
            from: root.animationsEnabled ? 0.88 : 1.0
            to: 1.0
            duration: root.animationsEnabled ? 340 : 0
            easing.type: Easing.OutBack
            easing.overshoot: root.animationsEnabled ? 1.14 : 1.0
          }
          NumberAnimation {
            target: animWrapper
            property: "animY"
            from: root.animationsEnabled ? -16 : 0
            to: 0
            duration: root.animationsEnabled ? 300 : 0
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: animWrapper
            property: "animOpacity"
            from: root.animationsEnabled ? 0.0 : 1.0
            to: 1.0
            duration: root.animationsEnabled ? 220 : 0
            easing.type: Easing.OutQuad
          }
        }

        Connections {
          target: root
          function onOpenedChanged() {
            if (root.opened) {
              openAnimation.restart()
            } else {
              openAnimation.stop()
              animWrapper.animScale = 0.88
              animWrapper.animY = -16
              animWrapper.animOpacity = 0.0
              animWrapper.animProgress = 0.0
            }
          }
        }

        ColumnLayout {
          id: mainColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          spacing: Style.space(12)
          transformOrigin: Item.Top

          y: animWrapper.animY
          scale: animWrapper.animScale
          opacity: animWrapper.animOpacity

        // 1. Header Bar: Island Identity & Source Badge
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Row {
            spacing: Style.space(6)
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
              width: Style.space(8)
              height: Style.space(8)
              radius: 4
              anchors.verticalCenter: parent.verticalCenter
              color: root.isPlaying ? Color.accent : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.4)

              Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
              text: "DYNAMIC ISLAND"
              textFormat: Text.PlainText
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.65)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.capitalization: Font.AllUppercase
              renderType: Text.NativeRendering
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Item { Layout.fillWidth: true }

          // Real Service/App Source Badge (e.g. YouTube, Spotify, Apple Music, Browser)
          BorderSurface {
            id: sourceBadge
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: Math.max(Style.space(22), badgeRow.implicitHeight + Style.space(6))
            implicitWidth: badgeRow.implicitWidth + Style.space(14)
            radius: Style.cornerRadius
            color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)
            borderSpec: Border.flat(Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.15), 1)

            // Smooth scale bounce on sound source change
            scale: 1.0

            SequentialAnimation on scale {
              id: badgePopAnim
              running: false
              NumberAnimation { from: 0.88; to: 1.06; duration: 130; easing.type: Easing.OutQuad }
              NumberAnimation { from: 1.06; to: 1.0; duration: 110; easing.type: Easing.OutBack }
            }

            Connections {
              target: root
              function onPlayerIdentityChanged() { badgePopAnim.restart() }
            }

            Row {
              id: badgeRow
              spacing: Style.space(5)
              anchors.centerIn: parent

              Text {
                text: root.sourceInfo.icon
                textFormat: Text.PlainText
                color: root.isPlaying ? Color.accent : root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                renderType: Text.NativeRendering
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                id: badgeText
                text: root.playerIdentity
                textFormat: Text.PlainText
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                elide: Text.ElideRight
                renderType: Text.NativeRendering
                anchors.verticalCenter: parent.verticalCenter
                Layout.maximumWidth: Style.space(160)
              }
            }
          }
        }

        // 2. Main Hero: Track Art + Info
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(12)

          // Album Art or Music Glyph with bounded decoding & safe sizing
          Rectangle {
            id: artBox
            Layout.preferredWidth: Style.space(68)
            Layout.preferredHeight: Style.space(68)
            radius: Math.min(Style.cornerRadius, Style.space(10))
            color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.15)
            layer.enabled: true
            layer.smooth: true

            scale: 1.0
            opacity: 1.0

            SequentialAnimation on scale {
              id: artPopAnim
              running: false
              NumberAnimation { from: 0.91; to: 1.04; duration: 140; easing.type: Easing.OutQuad }
              NumberAnimation { from: 1.04; to: 1.0; duration: 120; easing.type: Easing.OutBack }
            }

            SequentialAnimation on opacity {
              id: artFadeAnim
              running: false
              NumberAnimation { from: 0.4; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
            }

            Connections {
              target: root
              function onTitleChanged() {
                artPopAnim.restart()
                artFadeAnim.restart()
              }
              function onSelectedPlayerKeyChanged() {
                artPopAnim.restart()
                artFadeAnim.restart()
              }
              function onArtUrlChanged() {
                artPopAnim.restart()
                artFadeAnim.restart()
              }
            }

            // Fallback icon when no artwork is available or while loading
            Text {
              anchors.centerIn: parent
              visible: !artImg.visible || artImg.status !== Image.Ready
              text: root.sourceInfo.icon
              textFormat: Text.PlainText
              color: root.hasMedia ? Color.accent : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.3)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
              renderType: Text.NativeRendering
            }

            // High-fidelity album artwork layer with smooth corner mask
            Item {
              id: artImgContainer
              anchors.fill: parent
              anchors.margins: 1
              visible: artImg.status === Image.Ready && artImg.source !== ""
              layer.enabled: true
              layer.smooth: true
              layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
              }

              Image {
                id: artImg
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: root.artUrl
                cache: true
                smooth: true
              }
            }

            Rectangle {
              id: artMask
              anchors.fill: parent
              anchors.margins: 1
              radius: Math.max(0, artBox.radius - 1)
              visible: false
              layer.enabled: true
            }
          }

          // Track Details
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(3)

            Text {
              Layout.fillWidth: true
              text: root.title
              textFormat: Text.PlainText
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }

            Text {
              Layout.fillWidth: true
              text: root.artist
              textFormat: Text.PlainText
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.75)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              renderType: Text.NativeRendering
              visible: root.artist !== "" && root.artist !== root.title
            }

            Text {
              Layout.fillWidth: true
              text: root.album
              textFormat: Text.PlainText
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              renderType: Text.NativeRendering
              visible: root.album !== "" && root.album !== root.title && root.album !== root.artist
            }

            Text {
              text: root.isPlaying ? "Playing on " + root.sourceInfo.name : (root.hasMedia ? "Paused" : "Idle")
              textFormat: Text.PlainText
              color: root.isPlaying ? Color.accent : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              renderType: Text.NativeRendering
            }
          }
        }

        // 3. Playback Controls Bar with Dynamic Audio Waveform Background
        BorderSurface {
          Layout.fillWidth: true
          implicitHeight: Style.space(56)
          radius: Style.cornerRadius
          clip: true
          color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.05)
          borderSpec: Border.flat(Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12), 1)

          // Music Synth Waves Layer (Rising from bottom, stepped blocks & gradient, ytkew visualizer style)
          Item {
            id: synthWaveLayer
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            anchors.bottomMargin: Style.space(3)
            opacity: root.isPlaying ? 0.62 : 0.15

            Behavior on opacity {
              NumberAnimation { duration: 280; easing.type: Easing.OutQuad }
            }

            // Synth wave spectrum bars
            Row {
              anchors.bottom: parent.bottom
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(2)

              Repeater {
                model: 40

                Item {
                  id: waveColumn
                  required property int index
                  width: Style.space(5.8)
                  height: Style.space(48)
                  anchors.bottom: parent.bottom

                  readonly property real curVal: (root.spectrumBars && root.spectrumBars.length > index)
                    ? root.spectrumBars[index]
                    : 0.04
                  readonly property real barHeight: Math.max(Style.space(3), Math.round(curVal * Style.space(46)))

                  // Flat-topped stepped spectrum bar
                  Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: waveColumn.barHeight
                    radius: Style.space(1)
                    clip: true

                    // Vertical gradient matching ytkew: peak is light highlight, fading to accent/dark
                    gradient: Gradient {
                      GradientStop { position: 0.0; color: root.contentForeground }
                      GradientStop { position: 0.22; color: Qt.lighter(Color.accent, 1.3) }
                      GradientStop { position: 0.65; color: Color.accent }
                      GradientStop { position: 1.0; color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.4) }
                    }

                    // Stepped horizontal strata dividers (ratatui block equalizer aesthetic)
                    Column {
                      anchors.fill: parent
                      anchors.bottom: parent.bottom
                      spacing: Style.space(5)
                      Repeater {
                        model: 9
                        Rectangle {
                          width: parent.width
                          height: 1.5
                          color: Qt.rgba(0, 0, 0, 0.32)
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // Floating Controls Row (Foreground)
          RowLayout {
            anchors.centerIn: parent
            spacing: Style.space(26)
            z: 2

            // Previous Button
            BorderSurface {
              id: prevBtn
              Layout.preferredWidth: Style.space(36)
              Layout.preferredHeight: Style.space(36)
              radius: Math.round(width / 2)
              color: prevMouse.containsMouse
                ? Style.hoverFillFor(root.contentForeground, root.contentForeground)
                : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)

              Text {
                anchors.centerIn: parent
                text: "󰒮"
                textFormat: Text.PlainText
                color: root.activePlayer && root.activePlayer.canGoPrevious ? root.contentForeground : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.3)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.title
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.activePlayer && root.activePlayer.canGoPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.prevTrack()
              }
            }

            // Play / Pause Button with optical glyph centering & accent halo
            BorderSurface {
              id: playBtn
              Layout.preferredWidth: Style.space(44)
              Layout.preferredHeight: Style.space(44)
              radius: Math.round(width / 2)
              color: playMouse.containsMouse
                ? Style.hoverFillFor(Color.accent, Color.accent)
                : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.16)
              borderSpec: Border.flat(Color.accent, 1)

              Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.isPlaying ? 0 : Style.space(1.5)
                text: root.isPlaying ? "󰏤" : "󰐊"
                textFormat: Text.PlainText
                color: Color.accent
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.heading
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePlay()
              }
            }

            // Next Button
            BorderSurface {
              id: nextBtn
              Layout.preferredWidth: Style.space(36)
              Layout.preferredHeight: Style.space(36)
              radius: Math.round(width / 2)
              color: nextMouse.containsMouse
                ? Style.hoverFillFor(root.contentForeground, root.contentForeground)
                : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)

              Text {
                anchors.centerIn: parent
                text: "󰒭"
                textFormat: Text.PlainText
                color: root.activePlayer && root.activePlayer.canGoNext ? root.contentForeground : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.3)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.title
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.activePlayer && root.activePlayer.canGoNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.nextTrack()
              }
            }
          }
        }

        // 4. Volume Control Bar
        BorderSurface {
          Layout.fillWidth: true
          implicitHeight: Style.space(38)
          radius: Style.cornerRadius
          color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.05)
          borderSpec: Border.flat(Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12), 1)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(10)
            anchors.rightMargin: Style.space(10)
            spacing: Style.space(10)

            // Mute / Speaker Icon Button
            BorderSurface {
              Layout.preferredWidth: Style.space(26)
              Layout.preferredHeight: Style.space(26)
              radius: Math.round(width / 2)
              color: muteMouse.containsMouse
                ? Style.hoverFillFor(root.contentForeground, root.contentForeground)
                : "transparent"

              Text {
                anchors.centerIn: parent
                text: root.volumeIcon(root.sliderVolume, root.audioMuted)
                textFormat: Text.PlainText
                color: root.audioMuted ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.4) : Color.accent
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.body
                renderType: Text.NativeRendering
              }

              MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleAudioMute()
              }
            }

            // Smooth Interactive Volume Slider
            PanelSlider {
              id: volSlider
              bar: root.bar
              Layout.fillWidth: true
              minimum: 0
              maximum: 1
              step: 0.05
              value: root.sliderVolume
              opacity: root.audioMuted ? 0.5 : 1.0
              fillColor: root.audioMuted ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.3) : Color.accent
              knobColor: root.audioMuted ? Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5) : Color.accent
              onMoved: function(v) { root.setAudioVolume(v) }
              onRightClicked: root.toggleAudioMute()
            }

            // Volume Percentage Label
            Text {
              text: (root.audioMuted ? "0" : Math.round(root.sliderVolume * 100)) + "%"
              textFormat: Text.PlainText
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.75)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              renderType: Text.NativeRendering
              Layout.preferredWidth: Style.space(34)
              horizontalAlignment: Text.AlignRight
              Layout.alignment: Qt.AlignVCenter
            }
          }
        }

        // 5. Multiple Players Switcher (Flow layout with auto-wrap, click to switch without auto-play)
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)
          visible: root.players.length > 1

          Text {
            text: "SELECT MEDIA SOURCE"
            textFormat: Text.PlainText
            color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.caption
            font.capitalization: Font.AllUppercase
            renderType: Text.NativeRendering
          }

          Flow {
            Layout.fillWidth: true
            spacing: Style.space(6)

            Repeater {
              model: IslandModel.boundPlayerList(root.players, 6)

              delegate: BorderSurface {
                required property var modelData
                readonly property var itemSource: IslandModel.detectSource(modelData, root.toplevels)
                readonly property bool isCurrent: root.activePlayer === modelData
                implicitHeight: Style.space(26)
                implicitWidth: chipRow.implicitWidth + Style.space(12)
                radius: Style.cornerRadius
                color: isCurrent
                  ? Style.hoverFillFor(Color.accent, Color.accent)
                  : (chipMouse.containsMouse ? Style.hoverFillFor(root.contentForeground, root.contentForeground) : "transparent")
                borderSpec: Border.flat(isCurrent ? Color.accent : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.15), 1)

                scale: isCurrent ? 1.04 : (chipMouse.containsMouse ? 1.02 : 1.0)

                Behavior on scale {
                  NumberAnimation { duration: 160; easing.type: Easing.OutBack }
                }

                Behavior on color {
                  ColorAnimation { duration: 140 }
                }

                Row {
                  id: chipRow
                  anchors.centerIn: parent
                  spacing: Style.space(4)

                  Text {
                    text: modelData.isPlaying ? "󰎆" : itemSource.icon
                    textFormat: Text.PlainText
                    color: isCurrent ? Color.accent : root.contentForeground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: itemSource.name
                    textFormat: Text.PlainText
                    color: isCurrent ? Color.accent : root.contentForeground
                    font.family: root.contentFontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: isCurrent
                    renderType: Text.NativeRendering
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                MouseArea {
                  id: chipMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    var key = IslandModel.playerKey(modelData)
                    root.selectedPlayerKey = key
                    if (root.hostWidget) {
                      root.hostWidget.selectedPlayerKey = key
                    }
                  }
                }
              }
            }
          }
        }

        // 5. Extensible Event Sources Area (Aggregator design for reminders, OSDs, notifications)
        BorderSurface {
          Layout.fillWidth: true
          implicitHeight: Style.space(32)
          radius: Style.cornerRadius
          color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.03)
          borderSpec: Border.flat(Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08), 1)

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.space(8)
            anchors.rightMargin: Style.space(8)
            spacing: Style.space(8)

            Text {
              text: "󰋽"
              textFormat: Text.PlainText
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              renderType: Text.NativeRendering
            }

            Text {
              Layout.fillWidth: true
              text: "Dynamic Island Engine active • System controls ready"
              textFormat: Text.PlainText
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }
          }
        }
      }
    }
  }
}
}
