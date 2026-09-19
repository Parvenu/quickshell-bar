//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    readonly property alias theme: themeModel
    readonly property alias systemClock: clock
    readonly property alias audio: audioService
    readonly property alias notifications: notificationService
    readonly property alias metrics: metricsService
    readonly property alias systemInfo: systemInfoService
    readonly property alias sessionControls: sessionControlsService
    readonly property alias trayItems: trayService.items

    property bool powerBackdropVisible: false
    property string powerBackdropMonitor: "DP-1"

    signal openDashboardRequested()
    signal openNotificationsRequested()
    signal closeDrawerRequested()

    Theme {
        id: themeModel
    }

    SystemInfoService {
        id: systemInfoService
    }

    TrayService {
        id: trayService
    }

    MetricsService {
        id: metricsService
    }

    NotificationService {
        id: notificationService
    }

    AudioService {
        id: audioService
    }

    SessionControlsService {
        id: sessionControlsService
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    IpcHandler {
        target: "bar"

        function openDashboard(): void {
            root.openDashboardRequested()
        }

        function openNotifications(): void {
            root.openNotificationsRequested()
        }

        function closeDrawer(): void {
            root.closeDrawerRequested()
        }

        function setPowerBackdrop(enabled: bool, monitor: string): void {
            root.powerBackdropMonitor = monitor
            root.powerBackdropVisible = enabled
            if (enabled)
                powerBackdropSafetyTimer.restart()
            else
                powerBackdropSafetyTimer.stop()
        }

        function setDoNotDisturb(enabled: bool): void {
            root.notifications.dnd = enabled
        }

        function clearNotifications(): void {
            root.notifications.dismissAll()
        }
    }

    Timer {
        id: powerBackdropSafetyTimer

        interval: 60000
        repeat: false
        onTriggered: root.powerBackdropVisible = false
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
                commandBus: root
                theme: root.theme
                clock: root.systemClock
                audio: root.audio
                notifications: root.notifications
                metrics: root.metrics
                systemInfo: root.systemInfo
                sessionControls: root.sessionControls
                trayItems: root.trayItems
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PowerBackdrop {
                required property var modelData

                screen: modelData
                active: root.powerBackdropVisible
                menuMonitor: root.powerBackdropMonitor
            }
        }
    }
}
