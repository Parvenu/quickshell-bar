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
    exclusiveZone: root.theme.barExclusiveZone
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
            }
            monitor: root.monitor
            theme: root.theme
        }

        StatusLine {
            id: statusLine

            anchors {
                right: parent.right
                rightMargin: root.theme.drawerPadding
                verticalCenter: parent.verticalCenter
            }
            theme: root.theme
            clock: root.clock
            audio: root.audio
            metrics: root.metrics
            drawerOpen: root.drawerOpen
            onDrawerClicked: root.drawerOpen = !root.drawerOpen
        }

        LazyLoader {
            active: root.drawerOpen

            ControlDrawer {
                panelWindow: root
                anchorItem: statusLine
                theme: root.theme
                clock: root.clock
                audio: root.audio
                notifications: root.notifications
                metrics: root.metrics
                systemInfo: root.systemInfo
                trayItems: root.trayItems
                onDismissed: root.drawerOpen = false
            }
        }
    }
}
