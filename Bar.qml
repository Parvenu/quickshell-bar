pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: root

    required property var theme
    required property var clock
    required property var audio
    required property var notifications
    required property var metrics
    required property var systemInfo
    required property var trayItems

    property bool drawerOpen: false
    readonly property var monitor: Hyprland.monitorFor(root.screen)

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: root.theme.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: root.theme.barBackground

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: root.theme.barBorder
        }

        Workspaces {
            id: workspaces

            anchors {
                left: parent.left
                leftMargin: 6
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: root.theme.barContentVerticalOffset
            }
            monitor: root.monitor
            theme: root.theme
        }

        Text {
            id: clockLabel

            anchors {
                right: statusSeparator.left
                rightMargin: 8
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
            id: clockSeparator

            anchors {
                right: clockLabel.left
                rightMargin: 8
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: root.theme.barContentVerticalOffset
            }
            width: 1
            height: 16
            color: root.theme.divider
        }

        Rectangle {
            id: drawerButton

            anchors {
                right: parent.right
                rightMargin: 8
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

            Text {
                anchors.centerIn: parent
                text: ""
                color: root.drawerOpen ? root.theme.drawerLauncherActive : root.theme.textPrimary
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.iconSize + 1
            }

            Rectangle {
                anchors {
                    bottom: parent.bottom
                    bottomMargin: 1
                    horizontalCenter: parent.horizontalCenter
                }
                width: 14
                height: 2
                radius: 1
                visible: root.drawerOpen
                color: root.theme.drawerLauncherActive
            }

            MouseArea {
                id: drawerMouse

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.drawerOpen = !root.drawerOpen
            }
        }

        Audio {
            id: audioControls

            anchors {
                right: drawerButton.left
                rightMargin: 4
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: root.theme.barContentVerticalOffset
            }
            audio: root.audio
            theme: root.theme
        }

        Rectangle {
            id: statusSeparator

            anchors {
                right: audioControls.left
                rightMargin: 8
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: root.theme.barContentVerticalOffset
            }
            width: 1
            height: 16
            color: root.theme.divider
        }

        Metrics {
            anchors {
                right: clockSeparator.left
                rightMargin: 8
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: root.theme.barContentVerticalOffset
            }
            metrics: root.metrics
            theme: root.theme
        }

        LazyLoader {
            active: root.drawerOpen

            ControlDrawer {
                panelWindow: root
                anchorItem: drawerButton
                theme: root.theme
                audio: root.audio
                notifications: root.notifications
                systemInfo: root.systemInfo
                trayItems: root.trayItems
                onDismissed: root.drawerOpen = false
            }
        }
    }
}
