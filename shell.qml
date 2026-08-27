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

        function setDoNotDisturb(enabled: bool): void {
            root.notifications.dnd = enabled
        }

        function clearNotifications(): void {
            root.notifications.dismissAll()
        }
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
}
