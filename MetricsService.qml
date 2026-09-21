pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool batteryAvailable: false
    property int batteryCapacity: 0
    property string batteryStatus: "Unknown"
    property string batteryPath: ""
    property bool batteryDetailsAvailable: false
    property string batteryDetailText: ""

    property real cpuUsage: 0
    property real memoryUsage: 0
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property real cpuTemperature: 0
    property string temperaturePath: ""

    property double previousCpuTotal: 0
    property double previousCpuIdle: 0

    function parseBatteryCapacity(text): void {
        const capacity = Number(text.trim())
        if (Number.isFinite(capacity))
            batteryCapacity = Math.max(0, Math.min(100, Math.round(capacity)))
    }

    function parseBatteryStatus(text): void {
        const status = text.trim()
        batteryStatus = status.length > 0 ? status : "Unknown"
    }

    function parseUpowerNumber(value): real {
        const number = Number(value.replace(",", "."))
        return Number.isFinite(number) ? number : NaN
    }

    function formatBatteryTime(value): string {
        const match = value.match(/^([\d.,]+)\s+(second|minute|hour|day)s?$/)
        if (!match)
            return ""

        const amount = root.parseUpowerNumber(match[1])
        if (!Number.isFinite(amount))
            return ""

        let seconds = amount
        if (match[2] === "minute")
            seconds *= 60
        else if (match[2] === "hour")
            seconds *= 3600
        else if (match[2] === "day")
            seconds *= 86400

        const roundedMinutes = Math.max(1, Math.round(seconds / 60))
        const days = Math.floor(roundedMinutes / 1440)
        const hours = Math.floor((roundedMinutes % 1440) / 60)
        const minutes = roundedMinutes % 60

        if (days > 0)
            return `${days}d ${hours}h`
        if (hours > 0)
            return `${hours}h ${minutes}m`
        return `${minutes}m`
    }

    function parseUpowerBattery(text): void {
        const fields = {}

        for (const line of text.split("\n")) {
            const match = line.match(/^\s*([^:]+):\s*(.*?)\s*$/)
            if (match)
                fields[match[1].trim()] = match[2].trim()
        }
        const state = fields.state ?? ""
        const rateValue = fields["energy-rate"] ?? ""
        const rateMatch = rateValue.match(/^([\d.,]+)\s+W$/)
        const rate = rateMatch ? root.parseUpowerNumber(rateMatch[1]) : NaN
        const rateText = Number.isFinite(rate) ? `${rate.toFixed(1)} W` : ""

        let direction = ""
        let remaining = ""
        if (state === "charging" || state === "pending-charge") {
            direction = "Charge"
            remaining = root.formatBatteryTime(fields["time to full"] ?? "")
        } else if (state === "discharging" || state === "pending-discharge") {
            direction = "Discharge"
            remaining = root.formatBatteryTime(fields["time to empty"] ?? "")
        } else if (state === "fully-charged") {
            root.batteryDetailText = "Full"
            root.batteryDetailsAvailable = true
            return
        }

        const parts = [direction, rateText].filter(part => part.length > 0)
        if (parts.length === 0) {
            root.batteryDetailText = ""
            root.batteryDetailsAvailable = false
            return
        }

        root.batteryDetailText = parts.join(" ")
            + (remaining.length > 0 ? ` (${remaining})` : "")
        root.batteryDetailsAvailable = true
    }

    function refreshBatteryDetails(): void {
        if (root.batteryAvailable && !upowerBattery.running)
            upowerBattery.running = true
    }

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

    property FileView batteryCapacityFile: FileView {
        path: root.batteryPath.length > 0 ? `${root.batteryPath}/capacity` : ""
        preload: root.batteryPath.length > 0
        watchChanges: false
        printErrors: false
        onLoaded: root.parseBatteryCapacity(root.batteryCapacityFile.text())
    }

    property FileView batteryStatusFile: FileView {
        path: root.batteryPath.length > 0 ? `${root.batteryPath}/status` : ""
        preload: root.batteryPath.length > 0
        watchChanges: false
        printErrors: false
        onLoaded: root.parseBatteryStatus(root.batteryStatusFile.text())
    }

    property Process batteryDetector: Process {
        command: [
            "sh",
            "-c",
            "for supply in /sys/class/power_supply/*; do [ -f \"$supply/type\" ] || continue; [ \"$(cat \"$supply/type\")\" = Battery ] && { printf '%s\\n' \"$supply\"; break; }; done"
        ]
        running: true

        stdout: StdioCollector {
            id: batteryPathOutput

            onStreamFinished: {
                const detectedPath = batteryPathOutput.text.trim().split("\n")[0]
                if (detectedPath.length > 0) {
                    root.batteryPath = detectedPath
                    root.batteryAvailable = true
                    root.refreshBatteryDetails()
                }
            }
        }
    }

    property Process upowerBattery: Process {
        command: [
            "sh",
            "-c",
            "export LC_ALL=C; for device in $(upower --enumerate | sed -n '/battery/p'); do info=$(upower --show-info \"$device\"); printf '%s\\n' \"$info\" | grep -q 'power supply: *yes' && { printf '%s\\n' \"$info\"; break; }; done"
        ]

        stdout: StdioCollector {
            id: upowerOutput
            onStreamFinished: root.parseUpowerBattery(upowerOutput.text)
        }
    }

    property Timer batteryDetailsTimer: Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshBatteryDetails()
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
            "grep -l '^k10temp$' /sys/class/hwmon/hwmon*/name | sed 's|/name$|/temp1_input|'"
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
            if (root.batteryAvailable) {
                root.batteryCapacityFile.reload()
                root.batteryStatusFile.reload()
            }
            root.cpuFile.reload()
            root.memoryFile.reload()
            if (root.temperaturePath.length > 0)
                root.temperatureFile.reload()
        }
    }
}
