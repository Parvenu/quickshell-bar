pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Row {
    id: root

    required property var metrics
    required property var theme
    property bool showBatteryHoverInfo: true

    height: root.theme.controlHeight
    spacing: 12

    Row {
        id: batteryDisplay

        height: root.height
        spacing: 4
        visible: root.metrics.batteryAvailable

        readonly property int capacity: root.metrics.batteryCapacity
        readonly property bool charging: root.metrics.batteryStatus === "Charging"

        HoverHandler {
            id: batteryHover
            enabled: root.showBatteryHoverInfo
                && root.metrics.batteryDetailsAvailable
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showBatteryHoverInfo
                && batteryHover.hovered
                && root.metrics.batteryDetailsAvailable
            text: root.metrics.batteryDetailText
            color: root.theme.textSecondary
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showBatteryHoverInfo
                && batteryHover.hovered
                && root.metrics.batteryDetailsAvailable
            width: 1
            height: 16
            color: root.theme.divider
        }

        Text {
            id: batteryIcon

            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (parent.charging)
                    return "󰂄"
                if (parent.capacity >= 95)
                    return "󰁹"
                if (parent.capacity >= 85)
                    return "󰂂"
                if (parent.capacity >= 75)
                    return "󰂁"
                if (parent.capacity >= 65)
                    return "󰂀"
                if (parent.capacity >= 55)
                    return "󰁿"
                if (parent.capacity >= 45)
                    return "󰁾"
                if (parent.capacity >= 35)
                    return "󰁽"
                if (parent.capacity >= 25)
                    return "󰁼"
                if (parent.capacity >= 15)
                    return "󰁻"
                if (parent.capacity >= 5)
                    return "󰁺"
                return "󰂎"
            }
            color: {
                if (parent.charging)
                    return root.theme.powerAccent
                if (parent.capacity <= 15)
                    return root.theme.criticalText
                if (parent.capacity <= 30)
                    return root.theme.warningText
                return root.theme.powerAccent
            }
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.iconSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: `${parent.capacity}%`
            color: {
                if (parent.capacity <= 15 && !parent.charging)
                    return root.theme.criticalText
                if (parent.capacity <= 30 && !parent.charging)
                    return root.theme.warningText
                return root.theme.textPrimary
            }
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
            font.weight: Font.DemiBold
        }
    }

    Row {
        height: root.height
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍛"
            color: root.theme.cpuAccent
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.iconSize
        }

        Text {
            readonly property int temperature: Math.round(root.metrics.cpuTemperature)

            anchors.verticalCenter: parent.verticalCenter
            text: `${temperature > 0 ? temperature : "--"}°C`
            color: {
                if (temperature >= 82)
                    return root.theme.criticalText
                if (temperature >= 70)
                    return root.theme.warningText
                return root.theme.textPrimary
            }
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
            font.weight: Font.DemiBold
        }
    }

    Row {
        height: root.height
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: root.theme.memoryAccent
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.iconSize
        }

        Text {
            readonly property int usage: Math.round(root.metrics.memoryUsage)
            readonly property real usedGiB: root.metrics.memoryUsedGiB

            anchors.verticalCenter: parent.verticalCenter
            text: `${usedGiB.toFixed(1)}G`
            color: usage >= 90 ? root.theme.criticalText : root.theme.textPrimary
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
            font.weight: Font.DemiBold
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onTapped: Quickshell.execDetached(["kitty", "btop"])
    }
}
