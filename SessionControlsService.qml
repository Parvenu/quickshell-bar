pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

QtObject {
    id: root

    readonly property string hyprsunsetScript: Quickshell.env("HOME")
        + "/.config/hypr/scripts/Hyprsunset.sh"

    property bool hyprsunsetEnabled: false
    property bool idleInhibited: false
    property var idleInhibitWindow: null

    function refreshHyprsunset(): void {
        if (!hyprsunsetStatus.running)
            hyprsunsetStatus.running = true
    }

    function toggleHyprsunset(): void {
        Quickshell.execDetached([root.hyprsunsetScript, "toggle"])
        hyprsunsetRefresh.restart()
    }

    function toggleIdleInhibit(window): void {
        if (window !== null && window !== undefined)
            idleInhibitWindow = window
        idleInhibited = !idleInhibited
    }

    property IdleInhibitor idleInhibitor: IdleInhibitor {
        window: root.idleInhibitWindow
        enabled: root.idleInhibited && root.idleInhibitWindow !== null
    }

    property Process hyprsunsetStatus: Process {
        command: [root.hyprsunsetScript, "status"]

        stdout: StdioCollector {
            id: hyprsunsetOutput

            onStreamFinished: {
                try {
                    root.hyprsunsetEnabled = JSON.parse(hyprsunsetOutput.text).class === "on"
                } catch (error) {
                    console.warn("Failed to read Hyprsunset status:", error)
                }
            }
        }
    }

    property Timer hyprsunsetPoll: Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshHyprsunset()
    }

    property Timer hyprsunsetRefresh: Timer {
        interval: 750
        onTriggered: root.refreshHyprsunset()
    }
}
