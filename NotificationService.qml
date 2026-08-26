pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property int count: 0
    property bool dnd: false
    property bool controlCenterVisible: false
    property bool inhibited: false

    function updateState(line): void {
        try {
            const state = JSON.parse(line)
            count = state.count ?? 0
            dnd = state.dnd ?? false
            controlCenterVisible = state.visible ?? false
            inhibited = state.inhibited ?? false
        } catch (error) {
            console.warn("Failed to parse SwayNC state:", error)
        }
    }

    function openControlCenter(): void {
        Quickshell.execDetached(["swaync-client", "--open-panel", "--skip-wait"])
    }

    function toggleDnd(): void {
        Quickshell.execDetached(["swaync-client", "--toggle-dnd"])
    }

    property Process subscriber: Process {
        command: ["swaync-client", "--subscribe"]
        running: true

        stdout: SplitParser {
            onRead: line => root.updateState(line)
        }

        onRunningChanged: {
            if (!running)
                root.restartTimer.restart()
        }
    }

    property Timer restartTimer: Timer {
        interval: 1000
        onTriggered: root.subscriber.running = true
    }
}
