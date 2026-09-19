pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property var theme
    required property var notifications

    readonly property var newestFirstItems: root.buildNewestFirstItems()
    readonly property bool empty: root.newestFirstItems.length === 0

    function buildNewestFirstItems() {
        const serviceItems = root.notifications?.items
        if (!serviceItems)
            return []

        const exposedValues = serviceItems.values
        const source = exposedValues !== undefined
                && typeof exposedValues !== "function"
            ? exposedValues
            : serviceItems
        const result = []

        if (source.length !== undefined) {
            for (let index = 0; index < source.length; ++index) {
                if (source[index])
                    result.push(source[index])
            }
            return result
        }

        if (source.count !== undefined && typeof source.get === "function") {
            for (let index = 0; index < source.count; ++index) {
                const notification = source.get(index)
                if (notification)
                    result.push(notification)
            }
        }
        return result
    }

    function markRead(notification): void {
        if (!notification)
            return
        if (root.notifications && typeof root.notifications.markRead === "function")
            root.notifications.markRead(notification)
        else if (typeof notification.markRead === "function")
            notification.markRead()
    }

    clip: true

    ListView {
        id: notificationList

        anchors.fill: parent
        z: 1
        model: root.newestFirstItems
        spacing: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        pixelAligned: true
        cacheBuffer: 0

        delegate: NotificationCard {
            id: notificationCard

            required property var modelData
            readonly property bool exposed: root.visible
                && notificationList.visible
                && notificationList.width > 0
                && notificationList.height > 0
                && y + height > notificationList.contentY
                && y < notificationList.contentY + notificationList.height

            width: Math.max(
                0,
                notificationList.width - (scrollIndicator.visible ? 8 : 0)
            )
            theme: root.theme
            notifications: root.notifications
            notification: modelData
            compact: false

            onExposedChanged: {
                if (exposed)
                    readDelay.restart()
                else
                    readDelay.stop()
            }

            Component.onCompleted: {
                if (exposed)
                    readDelay.restart()
            }

            Timer {
                id: readDelay

                interval: 300
                repeat: false
                onTriggered: {
                    if (notificationCard.exposed)
                        root.markRead(notificationCard.notification)
                }
            }
        }
    }

    Column {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: root.theme.drawerPadding
            rightMargin: root.theme.drawerPadding
        }
        z: 0
        spacing: 4
        visible: root.empty

        Text {
            width: parent.width
            text: "󰂛"
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            color: root.theme.notificationAccent
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.iconSize + 6
        }

        Text {
            width: parent.width
            text: "No notifications"
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            color: root.theme.textPrimary
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            text: "You’re all caught up."
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            color: root.theme.textMuted
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSize - 1
        }
    }

    Rectangle {
        id: scrollIndicator

        readonly property real heightRatio: Math.min(
            1,
            notificationList.visibleArea.heightRatio
        )

        anchors.right: parent.right
        z: 2
        y: Math.max(
            0,
            Math.min(
                root.height - height,
                root.height * notificationList.visibleArea.yPosition
            )
        )
        width: 2
        height: Math.max(18, root.height * heightRatio)
        radius: 1
        color: root.theme.textMuted
        opacity: 0.8
        visible: !root.empty
            && notificationList.contentHeight > notificationList.height
    }
}
