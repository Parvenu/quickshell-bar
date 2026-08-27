pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: root

    required property var commandBus
    required property var theme
    required property var clock
    required property var audio
    required property var notifications
    required property var metrics
    required property var systemInfo
    required property var sessionControls
    required property var trayItems

    property bool drawerOpen: false
    property bool drawerContentActive: false
    property bool notificationPageOpen: false
    readonly property var monitor: Hyprland.monitorFor(root.screen)

    function openDashboard(): void {
        notificationPageOpen = false
        drawerOpen = true
    }

    function openNotifications(): void {
        notificationPageOpen = true
        drawerOpen = true
    }

    function closeDrawer(): void {
        drawerOpen = false
    }

    function toggleDashboard(): void {
        if (drawerOpen && !notificationPageOpen)
            closeDrawer()
        else
            openDashboard()
    }

    onDrawerOpenChanged: {
        if (!drawerOpen) {
            notificationPageOpen = false
            drawerContentActive = false
            drawerActivationDelay.stop()
            return
        }

        drawerContentActive = false
        drawerActivationDelay.restart()
    }

    Timer {
        id: drawerActivationDelay

        interval: 20
        repeat: false
        onTriggered: {
            if (root.drawerOpen)
                root.drawerContentActive = true
        }
    }

    Connections {
        target: root.commandBus

        function onOpenDashboardRequested(): void {
            if (root.monitor?.focused)
                root.openDashboard()
            else
                root.closeDrawer()
        }

        function onOpenNotificationsRequested(): void {
            if (root.monitor?.focused)
                root.openNotifications()
            else
                root.closeDrawer()
        }

        function onCloseDrawerRequested(): void {
            root.closeDrawer()
        }
    }

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
            onDrawerClicked: root.toggleDashboard()
        }

        NotificationToastHost {
            panelWindow: root
            anchorItem: statusLine
            monitor: root.monitor
            theme: root.theme
            notifications: root.notifications
            drawerOpen: root.drawerOpen
        }

        LazyLoader {
            active: root.drawerContentActive

            ControlDrawer {
                panelWindow: root
                anchorItem: statusLine
                theme: root.theme
                clock: root.clock
                audio: root.audio
                notifications: root.notifications
                metrics: root.metrics
                systemInfo: root.systemInfo
                sessionControls: root.sessionControls
                trayItems: root.trayItems
                notificationPageOpen: root.notificationPageOpen
                onDashboardRequested: root.openDashboard()
                onNotificationsRequested: root.openNotifications()
                onDismissed: root.closeDrawer()
            }
        }
    }
}
