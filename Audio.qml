pragma ComponentBehavior: Bound

import QtQuick

Row {
    id: root

    required property var audio
    required property var theme

    spacing: 2

    Rectangle {
        id: speakerButton

        readonly property int level: root.audio.sinkVolume
        readonly property string icon: {
            if (!root.audio.sinkAvailable || root.audio.sinkMuted)
                return "󰖁"
            if (level < 34)
                return ""
            if (level < 67)
                return ""
            return ""
        }

        width: 24
        height: root.theme.controlHeight
        radius: root.theme.smallRadius
        color: speakerMouse.containsMouse ? root.theme.controlHover : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.theme.animationFast }
        }

        CenteredGlyph {
            anchors.fill: parent
            glyph: speakerButton.icon
            color: root.audio.sinkMuted ? root.theme.textMuted : root.theme.audioOutputAccent
            fontFamily: root.theme.fontFamily
            fontPixelSize: root.theme.iconSize
            fontWeight: Font.DemiBold
        }

        MouseArea {
            id: speakerMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.audio.openMixer(3)
                else
                    root.audio.toggleSinkMute()
                mouse.accepted = true
            }
        }
    }

    Rectangle {
        id: microphoneButton

        width: 24
        height: root.theme.controlHeight
        radius: root.theme.smallRadius
        color: microphoneMouse.containsMouse ? root.theme.controlHover : "transparent"

        Behavior on color {
            ColorAnimation { duration: root.theme.animationFast }
        }

        CenteredGlyph {
            anchors.fill: parent
            glyph: root.audio.sourceAvailable && !root.audio.sourceMuted ? "" : ""
            color: root.audio.sourceMuted ? root.theme.textMuted : root.theme.audioInputAccent
            fontFamily: root.theme.fontFamily
            fontPixelSize: root.theme.iconSize
            fontWeight: Font.DemiBold
        }

        MouseArea {
            id: microphoneMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.audio.openMixer(4)
                else
                    root.audio.toggleSourceMute()
                mouse.accepted = true
            }
        }
    }
}
