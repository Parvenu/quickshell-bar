pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Row {
    id: root

    required property var metrics
    required property var theme

    height: root.theme.controlHeight
    spacing: 12

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
            readonly property int usage: Math.round(root.metrics.cpuUsage)

            anchors.verticalCenter: parent.verticalCenter
            text: `${usage}%`
            color: usage >= 90 ? root.theme.criticalText : root.theme.textPrimary
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
            text: "󰈸"
            color: root.theme.temperatureAccent
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
            text: "󰾆"
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
