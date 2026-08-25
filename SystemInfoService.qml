pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string userName: Quickshell.env("USER") || "user"
    property string hostName: ""
    property string hyprlandVersion: ""
    property string kernelVersion: ""
    property int uptimeSeconds: 0

    readonly property string identity: hostName.length > 0
        ? `${userName}@${hostName}`
        : userName
    readonly property string uptimeText: formatUptime(uptimeSeconds)
    readonly property string shortKernelVersion: kernelVersion.split("-")[0]
    readonly property string userSummary: `${userName} · up ${uptimeText}`
    readonly property string compositorSummary: hyprlandVersion.length > 0
        ? `Hyprland ${hyprlandVersion}`
        : "Hyprland"
    readonly property string platformSummary: shortKernelVersion.length > 0
        ? `${compositorSummary} · Linux ${shortKernelVersion}`
        : compositorSummary

    function formatUptime(seconds): string {
        const days = Math.floor(seconds / 86400)
        const hours = Math.floor((seconds % 86400) / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)

        if (days > 0)
            return `${days}d ${hours}h`
        if (hours > 0)
            return `${hours}h ${minutes}m`
        return `${minutes}m`
    }

    function updateUptime(text): void {
        const seconds = Math.floor(Number(text.trim().split(/\s+/)[0]))
        if (Number.isFinite(seconds))
            uptimeSeconds = seconds
    }

    property FileView hostnameFile: FileView {
        path: "/etc/hostname"
        preload: true
        watchChanges: false
        onLoaded: root.hostName = root.hostnameFile.text().trim()
    }

    property FileView kernelFile: FileView {
        path: "/proc/sys/kernel/osrelease"
        preload: true
        watchChanges: false
        onLoaded: root.kernelVersion = root.kernelFile.text().trim()
    }

    property FileView uptimeFile: FileView {
        path: "/proc/uptime"
        preload: true
        watchChanges: false
        onLoaded: root.updateUptime(root.uptimeFile.text())
    }

    property Process hyprlandVersionProcess: Process {
        command: ["hyprctl", "version", "-j"]
        running: true

        stdout: StdioCollector {
            id: versionOutput

            onStreamFinished: {
                try {
                    root.hyprlandVersion = JSON.parse(versionOutput.text).version ?? ""
                } catch (error) {
                    console.warn("Failed to parse Hyprland version:", error)
                }
            }
        }
    }

    property Timer uptimeTimer: Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.uptimeFile.reload()
    }
}
