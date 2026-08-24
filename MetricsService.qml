pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property real cpuUsage: 0
    property real memoryUsage: 0
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property real cpuTemperature: 0
    property string temperaturePath: ""

    property double previousCpuTotal: 0
    property double previousCpuIdle: 0

    function parseCpu(text): void {
        const line = text.split("\n")[0].trim()
        const fields = line.split(/\s+/)
        if (fields[0] !== "cpu" || fields.length < 9)
            return

        const values = fields.slice(1, 9).map(value => Number(value))
        const idle = values[3] + values[4]
        const total = values.reduce((sum, value) => sum + value, 0)

        if (previousCpuTotal > 0) {
            const totalDelta = total - previousCpuTotal
            const idleDelta = idle - previousCpuIdle
            if (totalDelta > 0)
                cpuUsage = Math.max(0, Math.min(100, 100 * (totalDelta - idleDelta) / totalDelta))
        }

        previousCpuTotal = total
        previousCpuIdle = idle
    }

    function parseMemory(text): void {
        let totalKiB = 0
        let availableKiB = 0

        for (const line of text.split("\n")) {
            const match = line.match(/^(MemTotal|MemAvailable):\s+(\d+)/)
            if (!match)
                continue
            if (match[1] === "MemTotal")
                totalKiB = Number(match[2])
            else
                availableKiB = Number(match[2])
        }

        if (totalKiB <= 0)
            return

        const usedKiB = totalKiB - availableKiB
        memoryTotalGiB = totalKiB / 1048576
        memoryUsedGiB = usedKiB / 1048576
        memoryUsage = 100 * usedKiB / totalKiB
    }

    function parseTemperature(text): void {
        const millidegrees = Number(text.trim())
        if (Number.isFinite(millidegrees))
            cpuTemperature = millidegrees / 1000
    }

    property FileView cpuFile: FileView {
        path: "/proc/stat"
        preload: true
        watchChanges: false
        onLoaded: root.parseCpu(root.cpuFile.text())
    }

    property FileView memoryFile: FileView {
        path: "/proc/meminfo"
        preload: true
        watchChanges: false
        onLoaded: root.parseMemory(root.memoryFile.text())
    }

    property FileView temperatureFile: FileView {
        path: root.temperaturePath
        preload: root.temperaturePath.length > 0
        watchChanges: false
        printErrors: false
        onLoaded: root.parseTemperature(root.temperatureFile.text())
    }

    property Process temperatureDetector: Process {
        command: [
            "sh",
            "-c",
            "grep -l '^Tccd1$' /sys/class/hwmon/hwmon*/temp*_label | sed 's/_label$/_input/'"
        ]
        running: true

        stdout: StdioCollector {
            id: temperaturePathOutput

            onStreamFinished: {
                const detectedPath = temperaturePathOutput.text.trim().split("\n")[0]
                if (detectedPath.length > 0)
                    root.temperaturePath = detectedPath
            }
        }
    }

    property Timer refreshTimer: Timer {
        interval: 2000
        repeat: true
        running: true

        onTriggered: {
            root.cpuFile.reload()
            root.memoryFile.reload()
            if (root.temperaturePath.length > 0)
                root.temperatureFile.reload()
        }
    }
}
