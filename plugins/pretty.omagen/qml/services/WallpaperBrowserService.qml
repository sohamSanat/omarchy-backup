import QtQuick
import Quickshell.Io

Item {
    id: root

    property string executable: ""
    property alias running: browser.running
    property bool ignoreNextExit: false

    signal selected(string path)
    signal cancelled()
    signal failed(string message)

    function choose() {
        root.ignoreNextExit = false;
        browser.exec([root.executable !== "" ? root.executable : "omagen-wallpaper-browser"]);
    }

    function cancel() {
        root.ignoreNextExit = true;
        if (!browser.running)
            return false;
        browser.running = false;
        return true;
    }

    Process {
        id: browser

        stdout: BoundedOutputParser {
            id: browserStdout
        }

        stderr: BoundedOutputParser {
            id: browserStderr
        }

        onStarted: {
            browserStdout.reset();
            browserStderr.reset();
        }

        onExited: function(exitCode, exitStatus) {
            if (root.ignoreNextExit) {
                root.ignoreNextExit = false;
                return;
            }

            if (exitCode === 0) {
                root.selected(browserStdout.text.trim());
                return;
            }

            if (exitCode === 1) {
                root.cancelled();
                return;
            }

            const message = browserStderr.text.trim();
            root.failed(message !== "" ? message : "Wallpaper browser failed");
        }
    }
}
