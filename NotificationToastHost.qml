pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Notifications

PopupWindow {
    id: root

    required property var panelWindow
    required property var anchorItem
    required property var monitor
    required property var theme
    required property var notifications

    property bool drawerOpen: false
    property real stableToastWidth: 0

    readonly property int toastCount: toastModel.count
    readonly property real naturalToastWidth: root.anchorItem.width
        + root.theme.drawerPadding * 2
    readonly property int maximumVisibleToasts: 3
    readonly property int defaultLowTimeoutMs: 3000
    readonly property int defaultNormalTimeoutMs: 6000

    function toastTimeoutMs(notification): int {
        if (!notification || notification.urgency === NotificationUrgency.Critical)
            return 0

        const requested = Number(notification.expireTimeout)
        if (requested === 0)
            return 0
        if (requested > 0)
            return Math.max(1000, Math.round(requested))

        return notification.urgency === NotificationUrgency.Low
            ? defaultLowTimeoutMs
            : defaultNormalTimeoutMs
    }

    function addToast(notification): void {
        if (!notification)
            return

        const key = root.notifications.notificationKey(notification)
        let existingIndex = -1
        for (let index = 0; index < toastModel.count; ++index) {
            const current = toastModel.get(index)
            if (current.notification === notification || current.key === key) {
                existingIndex = index
                break
            }
        }

        if (!root.monitor?.focused || root.drawerOpen) {
            if (existingIndex >= 0)
                toastModel.remove(existingIndex)
            if (toastModel.count === 0)
                root.stableToastWidth = 0
            return
        }

        if (toastModel.count === 0 || root.stableToastWidth <= 0)
            root.stableToastWidth = root.naturalToastWidth

        if (existingIndex >= 0) {
            const revision = Number(toastModel.get(existingIndex).revision ?? 0) + 1
            toastModel.setProperty(existingIndex, "key", key)
            toastModel.setProperty(existingIndex, "notification", notification)
            toastModel.setProperty(existingIndex, "revision", revision)
            if (existingIndex > 0)
                toastModel.move(existingIndex, 0, 1)
            return
        }

        toastModel.insert(0, {
            "key": key,
            "notification": notification,
            "revision": 0
        })
        while (toastModel.count > root.maximumVisibleToasts)
            toastModel.remove(toastModel.count - 1)
    }

    function removeToast(notification): void {
        let removed = false
        for (let index = toastModel.count - 1; index >= 0; --index) {
            if (toastModel.get(index).notification === notification) {
                toastModel.remove(index)
                removed = true
            }
        }

        if (removed && toastModel.count === 0)
            root.stableToastWidth = 0
    }

    function clearToasts(): void {
        toastModel.clear()
        root.stableToastWidth = 0
    }

    implicitWidth: root.stableToastWidth > 0
        ? root.stableToastWidth
        : root.naturalToastWidth
    implicitHeight: toastColumn.implicitHeight
    color: "transparent"
    grabFocus: false
    visible: root.toastCount > 0 && !root.drawerOpen

    anchor {
        window: root.panelWindow
        item: root.anchorItem
        rect.x: root.theme.drawerPadding
        rect.y: root.theme.hyprlandWindowTop - root.anchorItem.height + 1
        rect.width: root.anchorItem.width
        rect.height: root.anchorItem.height
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        adjustment: PopupAdjustment.None
    }

    onDrawerOpenChanged: {
        if (drawerOpen)
            clearToasts()
    }

    ListModel {
        id: toastModel
        dynamicRoles: true
    }

    Connections {
        target: root.notifications

        function onToastRequested(notification): void {
            root.addToast(notification)
        }
    }

    Column {
        id: toastColumn

        x: root.theme.drawerPadding
        y: 0
        width: parent.width - root.theme.drawerPadding * 2
        spacing: 6

        Repeater {
            model: toastModel

            delegate: Item {
                id: toastDelegate

                required property string key
                required property var notification
                required property int revision

                width: toastColumn.width
                height: toastCard.implicitHeight

                NotificationCard {
                    id: toastCard

                    width: parent.width
                    theme: root.theme
                    notifications: root.notifications
                    notification: toastDelegate.notification
                    compact: true
                }

                Timer {
                    id: toastTimer

                    interval: root.toastTimeoutMs(toastDelegate.notification)
                    running: interval > 0 && root.visible && !toastCard.hovered
                    repeat: false
                    onTriggered: root.removeToast(toastDelegate.notification)
                }

                Connections {
                    target: toastDelegate

                    function onRevisionChanged(): void {
                        if (toastTimer.running)
                            toastTimer.restart()
                    }
                }

                Connections {
                    target: toastDelegate.notification

                    function onClosed(): void {
                        root.removeToast(toastDelegate.notification)
                    }
                }
            }
        }
    }
}
