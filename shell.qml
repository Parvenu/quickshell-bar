//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

ShellRoot {
    id: root

    readonly property alias theme: themeModel
    readonly property alias systemClock: clock
    readonly property alias audio: audioService
    readonly property alias notifications: notificationService
    readonly property alias metrics: metricsService
    readonly property alias systemInfo: systemInfoService
    readonly property alias trayItems: trayService.items

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

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
                theme: root.theme
                clock: root.systemClock
                audio: root.audio
                notifications: root.notifications
                metrics: root.metrics
                systemInfo: root.systemInfo
                trayItems: root.trayItems
            }
        }
    }
}
