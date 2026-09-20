pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.impl as ControlsImpl
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var theme
    required property var notifications
    required property var notification

    property bool compact: false

    readonly property bool hovered: cardHover.hovered
    readonly property int contentPadding: root.compact ? 8 : 10
    readonly property int iconExtent: root.compact ? 32 : 40
    readonly property string appNameText: {
        const name = String(root.notification?.appName ?? "").trim()
        return name.length > 0 ? name : "Notification"
    }
    readonly property string summaryText: String(root.notification?.summary ?? "").trim()
    readonly property string bodyText: String(root.notification?.body ?? "").trim()
    readonly property int urgency: Number(
        root.notification?.urgency ?? NotificationUrgency.Normal
    )
    readonly property bool critical: root.urgency === NotificationUrgency.Critical
    readonly property bool unread: root.notificationIsUnread()
    readonly property color accentColor: root.critical
        ? root.theme.criticalText
        : root.urgency === NotificationUrgency.Low
            ? root.theme.textMuted
            : root.theme.notificationAccent
    readonly property real progressValue: root.notificationProgress()
    readonly property bool hasProgress: root.progressValue >= 0
    readonly property bool systemOsd: root.hasProgress
    readonly property color systemIconColor: "#cecece"
    readonly property var defaultAction: root.findDefaultAction()
    readonly property var alternateActions: root.findAlternateActions()
    readonly property bool hasInlineReply: !root.compact
        && Boolean(root.notification?.hasInlineReply ?? false)
    readonly property string notificationImageSource: root.normalizedImageSource(
        root.notification?.image
    )
    readonly property string appIconSource: root.normalizedImageSource(
        root.notification?.appIcon
    )
    readonly property string resolvedIconSource: {
        if (!root.notificationImageFailed && root.notificationImageSource.length > 0)
            return root.notificationImageSource
        return root.appIconSource
    }

    property bool notificationImageFailed: false
    property bool resolvedIconFailed: false

    function normalizedImageSource(value): string {
        const source = String(value ?? "").trim()
        if (source.length === 0)
            return ""

        const lowerSource = source.toLowerCase()
        if (lowerSource.startsWith("http://") || lowerSource.startsWith("https://"))
            return ""
        if (lowerSource.startsWith("javascript:"))
            return ""
        if (lowerSource.startsWith("data:") && !lowerSource.startsWith("data:image/"))
            return ""

        // Notification image-path hints are exposed as image://icon URLs. The
        // provider returns a missing-texture pixmap with Ready status when an
        // icon is absent, so resolve simple icon requests with an existence
        // check here to allow the glyph fallback below to take over.
        const iconProviderPrefix = "image://icon/"
        if (lowerSource.startsWith(iconProviderPrefix)
                && source.indexOf("?", iconProviderPrefix.length) < 0) {
            const iconName = source.slice(iconProviderPrefix.length).trim()
            return iconName.length > 0 ? Quickshell.iconPath(iconName, true) : ""
        }

        const hasScheme = source.indexOf(":") >= 0
        const looksLikePath = source.startsWith("/")
            || source.startsWith("./")
            || source.startsWith("../")
            || source.indexOf("/") >= 0
        if (hasScheme || looksLikePath)
            return source

        return Quickshell.iconPath(source, true)
    }

    function notificationProgress(): real {
        const hints = root.notification?.hints
        if (!hints)
            return -1

        const rawValue = hints["value"]
        if (rawValue === undefined || rawValue === null || rawValue === "")
            return -1

        const numericValue = Number(rawValue)
        if (!isFinite(numericValue))
            return -1
        return Math.max(0, Math.min(100, numericValue))
    }

    function notificationIsUnread(): bool {
        if (!root.notification)
            return false

        if (root.notifications && typeof root.notifications.isUnread === "function")
            return root.notifications.isUnread(root.notification)
        if (root.notifications && typeof root.notifications.isRead === "function")
            return !root.notifications.isRead(root.notification)
        if (root.notification.unread !== undefined)
            return Boolean(root.notification.unread)
        if (root.notification.read !== undefined)
            return !Boolean(root.notification.read)
        return false
    }

    function markRead(): void {
        if (!root.notification)
            return
        if (root.notifications && typeof root.notifications.markRead === "function")
            root.notifications.markRead(root.notification)
        else if (typeof root.notification.markRead === "function")
            root.notification.markRead()
    }

    function actionIdentifier(action): string {
        return String(action?.identifier ?? "").trim()
    }

    function findDefaultAction() {
        if (root.notifications && typeof root.notifications.defaultAction === "function")
            return root.notifications.defaultAction(root.notification)

        const actions = root.notification?.actions ?? []
        for (let index = 0; index < actions.length; ++index) {
            if (root.actionIdentifier(actions[index]) === "default")
                return actions[index]
        }
        return null
    }

    function findAlternateActions() {
        const actions = root.notification?.actions ?? []
        const result = []
        for (let index = 0; index < actions.length; ++index) {
            const action = actions[index]
            const identifier = root.actionIdentifier(action)
            if (identifier === "default")
                continue
            if (Boolean(root.notification?.hasInlineReply ?? false)
                    && (identifier === "inline-reply" || identifier === "inline_reply"))
                continue
            result.push(action)
        }
        return result
    }

    function invokeDefaultAction(): void {
        if (!root.notification || !root.defaultAction)
            return

        root.markRead()
        if (root.notifications && typeof root.notifications.invokeDefault === "function")
            root.notifications.invokeDefault(root.notification)
        else
            root.invokeAction(root.defaultAction)
    }

    function invokeAction(action): void {
        if (!root.notification || !action)
            return

        root.markRead()
        if (root.notifications && typeof root.notifications.invokeAction === "function")
            root.notifications.invokeAction(root.notification, action)
        else if (typeof action.invoke === "function")
            action.invoke()
    }

    function dismissNotification(): void {
        if (!root.notification)
            return

        root.markRead()
        if (root.notifications && typeof root.notifications.dismiss === "function")
            root.notifications.dismiss(root.notification)
        else if (root.notifications
                && typeof root.notifications.dismissNotification === "function")
            root.notifications.dismissNotification(root.notification)
        else if (typeof root.notification.dismiss === "function")
            root.notification.dismiss()
    }

    function sendReply(): void {
        const reply = replyInput.text
        if (!root.hasInlineReply || reply.trim().length === 0)
            return

        root.markRead()
        let sent = false
        if (root.notifications && typeof root.notifications.sendInlineReply === "function")
            sent = root.notifications.sendInlineReply(root.notification, reply) !== false
        else if (typeof root.notification.sendInlineReply === "function") {
            root.notification.sendInlineReply(reply)
            sent = true
        }

        if (sent)
            replyInput.clear()
    }

    implicitWidth: 320
    implicitHeight: cardContent.implicitHeight + root.contentPadding * 2
    radius: root.theme.smallRadius
    color: cardMouse.enabled && cardMouse.containsMouse
        ? root.theme.controlHover
        : root.theme.controlBackground
    border.width: 1
    border.color: root.critical || root.unread
        ? root.accentColor
        : root.theme.divider
    clip: true

    onNotificationChanged: {
        notificationImageFailed = false
        resolvedIconFailed = false
    }
    onNotificationImageSourceChanged: {
        notificationImageFailed = false
        resolvedIconFailed = false
    }
    onAppIconSourceChanged: resolvedIconFailed = false
    onResolvedIconSourceChanged: resolvedIconFailed = false

    Behavior on color {
        ColorAnimation { duration: root.theme.animationFast }
    }

    HoverHandler {
        id: cardHover
    }

    MouseArea {
        id: cardMouse

        anchors.fill: parent
        z: 0
        enabled: root.defaultAction !== null
        acceptedButtons: Qt.LeftButton
        hoverEnabled: enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        propagateComposedEvents: false
        onClicked: root.invokeDefaultAction()
    }

    Column {
        id: cardContent

        x: root.contentPadding
        y: root.contentPadding
        z: 1
        width: parent.width - root.contentPadding * 2
        spacing: root.compact ? 6 : 8

        Item {
            id: primaryRow

            width: parent.width
            height: Math.max(
                root.iconExtent,
                notificationText.implicitHeight,
                closeButton.height
            )

            Rectangle {
                id: iconFrame

                anchors {
                    top: parent.top
                    left: parent.left
                }
                width: root.iconExtent
                height: root.iconExtent
                radius: root.theme.smallRadius
                color: root.theme.drawerBackground
                border.width: 1
                border.color: root.theme.divider
                clip: true

                ControlsImpl.IconImage {
                    id: notificationIcon

                    anchors {
                        fill: parent
                        margins: 4
                    }
                    source: root.resolvedIconSource
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    color: root.systemOsd ? root.systemIconColor : "transparent"
                    asynchronous: true
                    mipmap: true
                    visible: root.resolvedIconSource.length > 0
                        && !root.resolvedIconFailed

                    onStatusChanged: {
                        if (status !== Image.Error)
                            return

                        if (!root.notificationImageFailed
                                && root.notificationImageSource.length > 0
                                && root.appIconSource.length > 0
                                && root.notificationImageSource !== root.appIconSource) {
                            root.notificationImageFailed = true
                        } else {
                            root.resolvedIconFailed = true
                        }
                    }
                }

                CenteredGlyph {
                    anchors.fill: parent
                    glyph: ""
                    color: root.systemOsd
                        ? root.systemIconColor
                        : root.accentColor
                    fontFamily: root.theme.fontFamily
                    fontPixelSize: root.theme.iconSize + 1
                    visible: root.resolvedIconSource.length === 0
                        || root.resolvedIconFailed
                }
            }

            Column {
                id: notificationText

                anchors {
                    top: parent.top
                    left: iconFrame.right
                    leftMargin: 8
                    right: closeButton.left
                    rightMargin: 8
                }
                spacing: 2

                Text {
                    width: parent.width
                    text: root.appNameText
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.unread
                        ? root.theme.notificationAccent
                        : root.theme.textSecondary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1
                    font.weight: root.unread ? Font.DemiBold : Font.Normal
                }

                Text {
                    width: parent.width
                    text: root.summaryText
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: root.compact ? 1 : 2
                    color: root.theme.textPrimary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                    font.weight: Font.DemiBold
                    visible: text.length > 0
                }

                Text {
                    width: parent.width
                    text: root.bodyText
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: root.compact ? 2 : 5
                    color: root.theme.textSecondary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1
                    visible: text.length > 0
                }
            }

            Rectangle {
                id: closeButton

                anchors {
                    top: parent.top
                    right: parent.right
                }
                z: 3
                width: 24
                height: root.theme.controlHeight
                radius: root.theme.smallRadius
                color: closeMouse.containsMouse
                    ? root.theme.controlHover
                    : root.theme.controlBackground

                CenteredGlyph {
                    anchors.fill: parent
                    glyph: ""
                    color: closeMouse.containsMouse
                        ? root.theme.criticalText
                        : root.theme.textMuted
                    fontFamily: root.theme.fontFamily
                    fontPixelSize: root.theme.iconSize
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    propagateComposedEvents: false
                    onPressed: mouse => mouse.accepted = true
                    onClicked: mouse => {
                        mouse.accepted = true
                        root.dismissNotification()
                    }
                }
            }
        }

        Item {
            id: progressRow

            width: parent.width
            height: root.compact ? 4 : 14
            visible: root.hasProgress

            Rectangle {
                id: progressTrack

                anchors {
                    left: parent.left
                    right: progressLabel.visible ? progressLabel.left : parent.right
                    rightMargin: progressLabel.visible ? 8 : 0
                    verticalCenter: parent.verticalCenter
                }
                height: 4
                radius: 2
                color: root.theme.divider
                clip: true

                Rectangle {
                    width: Math.round(parent.width * root.progressValue / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.accentColor
                }
            }

            Text {
                id: progressLabel

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: `${Math.round(root.progressValue)}%`
                textFormat: Text.PlainText
                color: root.theme.textMuted
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSize - 2
                visible: !root.compact
            }
        }

        Flow {
            id: actionFlow

            width: parent.width
            spacing: 4
            visible: root.alternateActions.length > 0

            Repeater {
                model: root.alternateActions

                delegate: Rectangle {
                    id: actionButton

                    required property var modelData
                    readonly property var action: modelData
                    readonly property string actionText: {
                        const label = String(action?.text ?? "").trim()
                        return label.length > 0 ? label : "Open"
                    }

                    width: Math.min(actionLabel.implicitWidth + 16, actionFlow.width)
                    height: root.theme.controlHeight
                    radius: root.theme.smallRadius
                    color: actionMouse.containsMouse
                        ? root.theme.controlHover
                        : root.theme.drawerBackground
                    border.width: 1
                    border.color: root.theme.divider

                    Behavior on color {
                        ColorAnimation { duration: root.theme.animationFast }
                    }

                    Text {
                        id: actionLabel

                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        text: actionButton.actionText
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: actionMouse.containsMouse
                            ? root.theme.notificationAccent
                            : root.theme.textPrimary
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize - 1
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        propagateComposedEvents: false
                        onPressed: mouse => mouse.accepted = true
                        onClicked: mouse => {
                            mouse.accepted = true
                            root.invokeAction(actionButton.action)
                        }
                    }
                }
            }
        }

        Item {
            id: replyRow

            width: parent.width
            height: root.theme.controlHeight
            visible: root.hasInlineReply

            Rectangle {
                anchors.fill: parent
                radius: root.theme.smallRadius
                color: root.theme.drawerBackground
                border.width: 1
                border.color: replyInput.activeFocus
                    ? root.theme.notificationAccent
                    : root.theme.divider
                clip: true

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 8
                        right: sendReplyButton.left
                        rightMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    text: String(
                        root.notification?.inlineReplyPlaceholder ?? "Reply…"
                    )
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.theme.textMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1
                    visible: replyInput.text.length === 0
                }

                TextInput {
                    id: replyInput

                    anchors {
                        left: parent.left
                        leftMargin: 8
                        right: sendReplyButton.left
                        rightMargin: 6
                        verticalCenter: parent.verticalCenter
                    }
                    color: root.theme.textPrimary
                    selectionColor: root.theme.notificationAccent
                    selectedTextColor: root.theme.drawerBackground
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1
                    selectByMouse: true
                    clip: true
                    onAccepted: root.sendReply()
                }

                Rectangle {
                    id: sendReplyButton

                    anchors {
                        top: parent.top
                        right: parent.right
                        bottom: parent.bottom
                    }
                    z: 3
                    width: 28
                    radius: root.theme.smallRadius
                    color: sendReplyMouse.containsMouse
                        ? root.theme.controlHover
                        : root.theme.controlBackground

                    CenteredGlyph {
                        anchors.fill: parent
                        glyph: "󰒊"
                        color: replyInput.text.trim().length > 0
                            ? root.theme.notificationAccent
                            : root.theme.textMuted
                        fontFamily: root.theme.fontFamily
                        fontPixelSize: root.theme.iconSize
                    }

                    MouseArea {
                        id: sendReplyMouse

                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: replyInput.text.trim().length > 0
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor
                        propagateComposedEvents: false
                        onPressed: mouse => mouse.accepted = true
                        onClicked: mouse => {
                            mouse.accepted = true
                            if (replyInput.text.trim().length > 0)
                                root.sendReply()
                        }
                    }
                }
            }
        }
    }
}
