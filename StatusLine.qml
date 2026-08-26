pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property var theme
    required property var clock
    required property var audio
    required property var metrics

    property bool drawerOpen: false
    property bool showAudioControls: true
    property bool showDrawerButton: true

    signal drawerClicked()

    implicitWidth: {
        if (root.showDrawerButton)
            return drawerButton.x + drawerButton.width
        if (root.showAudioControls)
            return audioControls.x + audioControls.width
        return clockLabel.x + clockLabel.width
    }
    implicitHeight: root.theme.barHeight

    Metrics {
        id: metricsDisplay

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        metrics: root.metrics
        theme: root.theme
    }

    Rectangle {
        id: clockSeparator

        anchors {
            left: metricsDisplay.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        width: 1
        height: 16
        color: root.theme.divider
    }

    Text {
        id: clockLabel

        anchors {
            left: clockSeparator.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text: Qt.formatDateTime(root.clock.date, "ddd, MMM dd · HH:mm:ss")
        color: root.theme.clockText
        font.family: root.theme.fontFamily
        font.pixelSize: root.theme.fontSize
        font.weight: Font.DemiBold
    }

    Rectangle {
        id: statusSeparator

        anchors {
            left: clockLabel.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        width: 1
        height: 16
        color: root.theme.divider
        visible: root.showAudioControls
    }

    Audio {
        id: audioControls

        anchors {
            left: statusSeparator.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
        audio: root.audio
        theme: root.theme
        visible: root.showAudioControls
    }

    Rectangle {
        id: drawerButton

        anchors {
            left: root.showAudioControls ? audioControls.right : clockLabel.right
            leftMargin: root.showAudioControls ? 2 : 8
            verticalCenter: parent.verticalCenter
        }
        width: 24
        height: root.theme.controlHeight
        radius: root.theme.smallRadius
        color: drawerMouse.containsMouse ? root.theme.controlHover : "transparent"
        visible: root.showDrawerButton

        Behavior on color {
            ColorAnimation { duration: root.theme.animationFast }
        }

        CenteredGlyph {
            anchors.fill: parent
            glyph: ""
            color: root.drawerOpen ? root.theme.drawerLauncherActive : root.theme.textPrimary
            fontFamily: root.theme.fontFamily
            fontPixelSize: root.theme.iconSize + 1
        }


        MouseArea {
            id: drawerMouse

            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.drawerClicked()
        }
    }
}
