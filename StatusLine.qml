pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property var theme
    required property var clock
    required property var audio
    required property var metrics

    property bool drawerOpen: false

    signal drawerClicked()

    implicitWidth: drawerButton.x + drawerButton.width
    implicitHeight: root.theme.barHeight

    Metrics {
        id: metricsDisplay

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: root.theme.barContentVerticalOffset
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
            verticalCenterOffset: root.theme.barContentVerticalOffset
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
            verticalCenterOffset: root.theme.barContentVerticalOffset
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
            verticalCenterOffset: root.theme.barContentVerticalOffset
        }
        width: 1
        height: 16
        color: root.theme.divider
    }

    Audio {
        id: audioControls

        anchors {
            left: statusSeparator.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: root.theme.barContentVerticalOffset
        }
        audio: root.audio
        theme: root.theme
    }

    Rectangle {
        id: drawerButton

        anchors {
            left: audioControls.right
            leftMargin: 2
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: root.theme.barContentVerticalOffset
        }
        width: 24
        height: root.theme.controlHeight
        radius: root.theme.smallRadius
        color: drawerMouse.containsMouse ? root.theme.controlHover : "transparent"

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
