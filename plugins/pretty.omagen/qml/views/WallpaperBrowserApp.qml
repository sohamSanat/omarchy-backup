import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine
import Qt.labs.settings 1.1

import "../services/WallpaperBridge.js" as WallpaperBridge

// Standalone wallpaper browser built around Wallpaper Flare. It runs outside
// the bundled Omagen shell (QtWebEngine cannot start inside Quickshell's
// hosted QCoreApplication) and follows the same stdio contract as
// omagen-file-select:
//   stdout: selected image path          -> exit 0
//   (cancelled / closed)                 -> exit 1
//   stderr: error message                -> exit 2
ApplicationWindow {
    id: root

    width: 1240
    height: 820
    minimumWidth: 720
    minimumHeight: 520
    visible: true
    title: "Omagen — Wallpaper Browser"
    color: pageBackground

    readonly property color pageBackground: "#1b1b26"
    readonly property color panel: "#24242f"
    readonly property color panelBorder: "#34344a"
    readonly property color foreground: "#f2f2f8"
    readonly property color muted: "#9aa0b8"
    readonly property color accent: "#89b4fa"
    readonly property string homeUrl: "https://www.wallpaperflare.com"

    property string currentUrl: homeUrl
    property string pageTitle: ""
    property bool loading: false
    property int progress: 0
    property string candidateUrl: ""
    property string statusText: ""
    property bool markerSent: false

    function emitSelected(path) {
        if (root.markerSent)
            return;
        root.markerSent = true;
        console.log("[[OMAGEN]] selected " + path);
        wallpaperSettings.resultPath = path;
        wallpaperSettings.sync();
        Qt.exit(0);
    }

    function emitCancelled() {
        if (root.markerSent)
            return;
        root.markerSent = true;
        console.log("[[OMAGEN]] cancelled");
        Qt.exit(1);
    }

    function emitFailed(message) {
        if (root.markerSent)
            return;
        root.markerSent = true;
        console.log("[[OMAGEN]] failed " + message);
        Qt.exit(2);
    }

    function isSupportedWallpaper(filename) {
        var lower = filename.toLowerCase();
        return lower.endsWith(".jpg") ||
               lower.endsWith(".jpeg") ||
               lower.endsWith(".png");
    }

    Component.onCompleted: {
        Qt.application.name = "omagen-wallpaper-browser";
        Qt.application.organization = "omagen";
    }

    onClosing: function (close) {
        if (!root.markerSent) {
            root.markerSent = true;
            console.log("[[OMAGEN]] cancelled");
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.emitCancelled()
    }

    Settings {
        // Result channel. The wrapper deletes this file before launch and
        // validates the value alongside the process exit code.
        id: wallpaperSettings
        fileName: "/tmp/omagen-wallpaper-browser.ini"
        property string resultPath: ""
    }

    WebEngineProfile {
        id: webProfile

        onDownloadRequested: function (download) {
            download.accept();
        }

        onDownloadFinished: function (download) {
            if (download.state !== WebEngineDownloadRequest.DownloadCompleted) {
                if (download.state === WebEngineDownloadRequest.DownloadInterrupted)
                    root.statusText = "Download interrupted: " + download.interruptReasonString;
                return;
            }
            var name = download.downloadFileName;
            if (!root.isSupportedWallpaper(name)) {
                root.statusText = "Only PNG or JPEG wallpapers can be used as a theme source (got " + name + ").";
                return;
            }
            var path = download.downloadDirectory + "/" + name;
            root.statusText = "Saved " + name;
            root.emitSelected(path);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Toolbar: address bar + navigation controls.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            color: panel

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Button {
                    text: "\u25C0"
                    enabled: web.canGoBack
                    onClicked: web.goBack()
                    ToolTip.visible: hovered
                    ToolTip.text: "Back"
                }
                Button {
                    text: "\u25B6"
                    enabled: web.canGoForward
                    onClicked: web.goForward()
                    ToolTip.visible: hovered
                    ToolTip.text: "Forward"
                }
                Button {
                    text: "\u21BB"
                    onClicked: web.reload()
                    ToolTip.visible: hovered
                    ToolTip.text: "Reload"
                }
                Button {
                    text: "\u2302"
                    onClicked: web.url = root.homeUrl
                    ToolTip.visible: hovered
                    ToolTip.text: "Wallpaper Flare home"
                }

                TextField {
                    id: addressBar
                    Layout.fillWidth: true
                    text: root.currentUrl
                    placeholderText: "Enter a URL or search"
                    selectByMouse: true
                    onAccepted: {
                        var url = text.trim();
                        if (url.indexOf("://") < 0)
                            url = "https://" + url;
                        web.url = url;
                    }
                }

                Button {
                    text: "\u2715 Close"
                    onClicked: root.emitCancelled()
                }
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            visible: root.loading
            value: root.progress / 100
        }

        WebEngineView {
            id: web
            Layout.fillWidth: true
            Layout.fillHeight: true
            profile: webProfile
            url: root.homeUrl

            onUrlChanged: { root.currentUrl = url.toString(); console.log("URL:", root.currentUrl); }
            onTitleChanged: { root.pageTitle = title; console.log("TITLE:", title); }
            onLoadProgressChanged: root.progress = web.loadProgress
            onLoadingChanged: function (info) {
                root.loading = info.status !== WebEngineLoadingInfo.LoadSucceededStatus &&
                               info.status !== WebEngineLoadingInfo.LoadFailedStatus;
                if (info.status === WebEngineLoadingInfo.LoadSucceededStatus)
                    web.runJavaScript(WallpaperBridge.injectSource());
                else if (info.status === WebEngineLoadingInfo.LoadFailedStatus)
                    root.statusText = "Could not load page: " + info.errorString;
            }
            onNavigationRequested: function (request) {
                // Abort downloads that WebEngine tries to navigate to so they
                // go through the downloadRequested flow instead.
                var url = request.url.toString().toLowerCase();
                if (request.navigationType === WebEngineNavigationRequest.NavigationTypeLinkClicked &&
                        (url.endsWith(".jpg") || url.endsWith(".jpeg") || url.endsWith(".png"))) {
                    request.action = WebEngineNavigationRequest.AcceptRequest;
                }
            }
            onJavaScriptConsoleMessage: function (level, message, lineNumber, sourceID) {
                if (message.indexOf("[[OMAGEN]] image:") === 0) {
                    root.candidateUrl = message.substring("[[OMAGEN]] image:".length);
                }
            }
        }

        // Candidate image picked via the in-page badge.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 64
            visible: root.candidateUrl !== ""
            color: panel
            border.width: 1
            border.color: panelBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Image {
                    width: 48
                    height: 48
                    fillMode: Image.PreserveAspectCrop
                    source: root.candidateUrl
                    asynchronous: true
                    sourceSize.width: 96
                    sourceSize.height: 96
                }

                Text {
                    Layout.fillWidth: true
                    text: "Use this wallpaper as the Omagen theme source?"
                    color: foreground
                    elide: Text.ElideMiddle
                }

                Button {
                    text: "Download"
                    onClicked: {
                        var name = WallpaperBridge.filenameFor(root.candidateUrl);
                        web.runJavaScript(WallpaperBridge.downloadViaHref(root.candidateUrl, name));
                        root.statusText = "Downloading " + name + "\u2026";
                        root.candidateUrl = "";
                    }
                }
                Button {
                    text: "Cancel"
                    onClicked: root.candidateUrl = ""
                }
            }
        }

        // Status line.
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 26
            visible: root.statusText !== ""
            color: panel

            Text {
                anchors.fill: parent
                anchors.leftMargin: 12
                text: root.statusText
                color: muted
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideMiddle
            }
        }
    }
}
