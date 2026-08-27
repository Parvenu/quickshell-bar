pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var panelWindow
    required property var anchorItem
    required property var theme
    required property var clock
    required property var audio
    required property var notifications
    required property var metrics
    required property var systemInfo
    required property var sessionControls
    required property var trayItems

    property bool powerMenuOpen: false
    property bool notificationPageOpen: false

    signal dashboardRequested()
    signal notificationsRequested()
    signal dismissed()

    onNotificationPageOpenChanged: {
        if (notificationPageOpen)
            powerMenuOpen = false
    }

    function trayItemId(item): string {
        return String(item?.id ?? "").toLowerCase()
    }

    function isBluetoothItem(item): bool {
        return trayItemId(item) === "blueman"
    }

    function isNetworkItem(item): bool {
        const id = trayItemId(item)
        return id === "nm-applet" || id === "nm_applet"
    }

    function isSystemItem(item): bool {
        return isBluetoothItem(item) || isNetworkItem(item)
    }

    function executePowerAction(command): void {
        root.powerMenuOpen = false
        root.visible = false
        Quickshell.execDetached(command)
    }

    implicitWidth: root.anchorItem.width + root.theme.drawerPadding * 2
    implicitHeight: contentColumn.implicitHeight + 10
    color: "transparent"
    grabFocus: true

    anchor {
        window: root.panelWindow
        item: root.anchorItem
        rect.x: root.theme.drawerPadding
        rect.y: 0
        rect.width: root.anchorItem.width
        rect.height: root.anchorItem.height
        edges: Edges.Top | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        adjustment: PopupAdjustment.None
    }

    Component.onCompleted: visible = true
    onVisibleChanged: {
        if (!visible) {
            powerMenuOpen = false
            dismissed()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.theme.drawerRadius
        color: root.theme.drawerBackground
        border.width: 1
        border.color: root.theme.divider

        Column {
            id: contentColumn

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            spacing: 6

            Item {
                id: drawerTopRow

                width: parent.width
                height: root.theme.barHeight

                StatusLine {
                    id: drawerStatusLine

                    anchors {
                        left: parent.left
                        leftMargin: root.theme.drawerPadding
                            + Math.floor(root.anchorItem.width)
                            - root.anchorItem.width
                        verticalCenter: parent.verticalCenter
                    }
                    theme: root.theme
                    clock: root.clock
                    audio: root.audio
                    metrics: root.metrics
                    showAudioControls: false
                    showDrawerButton: false
                }

                Item {
                    id: headerFeatureSlot

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: drawerStatusLine.right
                        leftMargin: 8
                        right: drawerCloseButton.left
                        rightMargin: 4
                    }
                    clip: true
                }

                DrawerActionButton {
                    id: drawerCloseButton

                    anchors {
                        right: parent.right
                        rightMargin: root.theme.drawerPadding
                        verticalCenter: parent.verticalCenter
                    }
                    theme: root.theme
                    glyph: ""
                    inactiveGlyphColor: root.theme.drawerLauncherActive
                    onClicked: root.visible = false
                }
            }

            Item {
                id: pageViewport

                width: parent.width
                height: root.theme.drawerBodyHeight
                clip: true

                Column {
                    id: dashboardPage

                    anchors.fill: parent
                    spacing: 6
                    visible: !root.notificationPageOpen

            Item {
                id: identityRow

                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 34

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 1

                    Text {
                        id: userSummaryLabel

                        width: parent.width
                        text: root.systemInfo.userSummary
                        elide: Text.ElideRight
                        color: root.theme.drawerTitle
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize + 1
                        font.weight: Font.DemiBold
                    }

                    Text {
                        id: platformSummaryLabel

                        width: parent.width
                        text: root.systemInfo.platformSummary
                        elide: Text.ElideRight
                        color: root.theme.textSecondary
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize - 1
                    }
                }
            }

            Rectangle {
                id: controlsSurface

                readonly property string hoveredLegend: {
                    if (drawerAudio.hoveredControlLabel.length > 0)
                        return drawerAudio.hoveredControlLabel
                    if (bluetoothHover.hovered)
                        return "Bluetooth"
                    if (networkHover.hovered)
                        return "Network"
                    if (hyprsunsetHover.hovered)
                        return "Night light"
                    if (idleInhibitHover.hovered)
                        return "Idle inhibitor"
                    if (dndHover.hovered)
                        return "Do not disturb"
                    if (hibernateHover.hovered)
                        return "Hibernate"
                    if (lockHover.hovered)
                        return "Lock"
                    if (suspendHover.hovered)
                        return "Suspend"
                    if (rebootHover.hovered)
                        return "Reboot"
                    if (powerMouse.containsMouse)
                        return root.powerMenuOpen ? "Shut down" : "Power options"
                    return ""
                }

                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 32
                radius: root.theme.smallRadius
                color: root.theme.controlBackground
                clip: true

                Row {
                    id: systemControls

                    anchors {
                        left: parent.left
                        leftMargin: 3
                        verticalCenter: parent.verticalCenter
                    }
                    height: root.theme.controlHeight
                    spacing: 2

                    Audio {
                        id: drawerAudio

                        audio: root.audio
                        theme: root.theme
                    }

                    Tray {
                        id: bluetoothTray

                        buttonWidth: 24
                        panelWindow: root
                        trayItems: root.trayItems
                        theme: root.theme
                        itemFilter: item => root.isBluetoothItem(item)
                        glyphForItem: item => ""
                        glyphHorizontalOffset: -0.5

                        HoverHandler {
                            id: bluetoothHover
                        }
                    }

                    Tray {
                        id: networkTray

                        buttonWidth: 24
                        panelWindow: root
                        trayItems: root.trayItems
                        theme: root.theme
                        itemFilter: item => root.isNetworkItem(item)
                        glyphForItem: item => "󰖩"

                        HoverHandler {
                            id: networkHover
                        }
                    }

                    DrawerActionButton {
                        id: hyprsunsetButton

                        theme: root.theme
                        glyph: "󰖔"
                        active: root.sessionControls.hyprsunsetEnabled
                        activeGlyphColor: root.theme.warningText
                        onClicked: root.sessionControls.toggleHyprsunset()

                        HoverHandler {
                            id: hyprsunsetHover
                        }
                    }

                    DrawerActionButton {
                        id: idleInhibitButton

                        theme: root.theme
                        glyph: root.sessionControls.idleInhibited ? "󰒳" : "󰒲"
                        active: root.sessionControls.idleInhibited
                        onClicked: root.sessionControls.toggleIdleInhibit(root.panelWindow)

                        HoverHandler {
                            id: idleInhibitHover
                        }
                    }

                    DrawerActionButton {
                        id: dndButton

                        theme: root.theme
                        glyph: root.notifications.dnd ? "󰂛" : "󰂚"
                        active: root.notifications.dnd
                        activeGlyphColor: root.theme.notificationAccent
                        onClicked: root.notifications.toggleDnd()

                        HoverHandler {
                            id: dndHover
                        }
                    }
                }

                Text {
                    id: controlLegend

                    anchors {
                        left: systemControls.right
                        leftMargin: 8
                        right: powerActions.left
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    text: controlsSurface.hoveredLegend
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: root.theme.textSecondary
                    opacity: text.length > 0 ? 1 : 0
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1

                    Behavior on opacity {
                        NumberAnimation { duration: root.theme.animationFast }
                    }
                }

                Row {
                    id: powerActions

                    anchors {
                        right: parent.right
                        rightMargin: 3
                        verticalCenter: parent.verticalCenter
                    }
                    height: root.theme.controlHeight
                    spacing: 2

                    DrawerActionButton {
                        id: hibernateButton

                        visible: root.powerMenuOpen
                        theme: root.theme
                        glyph: ""
                        onClicked: root.executePowerAction(["systemctl", "hibernate"])

                        HoverHandler {
                            id: hibernateHover
                        }
                    }

                    DrawerActionButton {
                        id: lockButton

                        visible: root.powerMenuOpen
                        theme: root.theme
                        glyph: ""
                        onClicked: root.executePowerAction(["hyprlock", "--quiet"])

                        HoverHandler {
                            id: lockHover
                        }
                    }

                    DrawerActionButton {
                        id: suspendButton

                        visible: root.powerMenuOpen
                        theme: root.theme
                        glyph: ""
                        onClicked: root.executePowerAction(["systemctl", "suspend"])

                        HoverHandler {
                            id: suspendHover
                        }
                    }

                    DrawerActionButton {
                        id: rebootButton

                        visible: root.powerMenuOpen
                        theme: root.theme
                        glyph: ""
                        onClicked: root.executePowerAction(["systemctl", "reboot"])

                        HoverHandler {
                            id: rebootHover
                        }
                    }

                    Rectangle {
                        id: powerButton

                        width: 24
                        height: root.theme.controlHeight
                        radius: root.theme.smallRadius
                        color: powerMouse.containsMouse
                            ? root.theme.criticalSurface
                            : root.powerMenuOpen
                                ? root.theme.controlHover
                                : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: root.theme.animationFast }
                        }

                        CenteredGlyph {
                            anchors.fill: parent
                            glyph: ""
                            color: powerMouse.containsMouse
                                ? root.theme.criticalSurfaceText
                                : root.theme.powerAccent
                            fontFamily: root.theme.fontFamily
                            fontPixelSize: root.theme.iconSize
                            opticalHorizontalOffset: 0.5
                        }

                        MouseArea {
                            id: powerMouse

                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (root.powerMenuOpen)
                                    root.executePowerAction(["systemctl", "poweroff"])
                                else
                                    root.powerMenuOpen = true
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: applicationSurface

                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 32
                radius: root.theme.smallRadius
                color: root.theme.controlBackground

                Tray {
                    id: applicationTray

                    anchors {
                        left: parent.left
                        leftMargin: 3
                        verticalCenter: parent.verticalCenter
                    }
                    panelWindow: root
                    trayItems: root.trayItems
                    theme: root.theme
                    itemFilter: item => !root.isSystemItem(item)
                }
            }

            Rectangle {
                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 1
                color: root.theme.divider
            }


            Calendar {
                id: calendarSurface

                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: implicitHeight
                theme: root.theme
                clock: root.clock

                onOpenProtonRequested: url => {
                    Quickshell.execDetached(["xdg-open", url])
                    root.visible = false
                }
            }
                }

                NotificationPage {
                    x: root.theme.drawerPadding
                    width: parent.width - root.theme.drawerPadding * 2
                    height: parent.height
                    visible: root.notificationPageOpen
                    theme: root.theme
                    notifications: root.notifications
                }
            }

            Rectangle {
                id: drawerNavigationRow

                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 32
                radius: root.theme.smallRadius
                color: root.theme.controlBackground
                clip: true

                Item {
                    anchors.fill: parent
                    visible: !root.notificationPageOpen

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        text: "  Notifications"
                        color: dashboardNavigationMouse.containsMouse
                            ? root.theme.notificationAccent
                            : root.theme.textPrimary
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                    }

                    Text {
                        anchors {
                            right: parent.right
                            rightMargin: 9
                            verticalCenter: parent.verticalCenter
                        }
                        text: root.notifications.count > 0 ? root.notifications.count : ""
                        color: root.theme.notificationAccent
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.fontSize
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: dashboardNavigationMouse

                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notificationsRequested()
                    }
                }

                Item {
                    anchors.fill: parent
                    visible: root.notificationPageOpen

                    DrawerActionButton {
                        id: notificationBackButton

                        anchors {
                            left: parent.left
                            leftMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        theme: root.theme
                        glyph: ""
                        inactiveGlyphColor: root.theme.notificationAccent
                        onClicked: root.dashboardRequested()
                    }

                    Rectangle {
                        id: notificationBackSurface

                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: notificationBackButton.right
                            leftMargin: 2
                            right: notificationDndButton.left
                            rightMargin: 2
                        }
                        radius: root.theme.smallRadius
                        color: notificationBackMouse.containsMouse
                            ? root.theme.controlHover
                            : "transparent"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 6
                                right: parent.right
                                rightMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            text: "Notifications"
                                + (root.notifications.count > 0
                                    ? "  " + root.notifications.count
                                    : "")
                            elide: Text.ElideRight
                            color: notificationBackMouse.containsMouse
                                ? root.theme.notificationAccent
                                : root.theme.textPrimary
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSize
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: notificationBackMouse

                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dashboardRequested()
                        }
                    }

                    DrawerActionButton {
                        id: notificationDndButton

                        anchors {
                            right: notificationClearButton.left
                            rightMargin: 2
                            verticalCenter: parent.verticalCenter
                        }
                        theme: root.theme
                        glyph: root.notifications.dnd ? "󰂛" : "󰂚"
                        active: root.notifications.dnd
                        activeGlyphColor: root.theme.notificationAccent
                        onClicked: root.notifications.toggleDnd()
                    }

                    DrawerActionButton {
                        id: notificationClearButton

                        anchors {
                            right: parent.right
                            rightMargin: 4
                            verticalCenter: parent.verticalCenter
                        }
                        theme: root.theme
                        glyph: "󰆴"
                        inactiveGlyphColor: root.notifications.count > 0
                            ? root.theme.criticalText
                            : root.theme.textMuted
                        onClicked: {
                            if (root.notifications.count > 0)
                                root.notifications.dismissAll()
                        }
                    }
                }
            }
        }

        Item {
            id: powerMenuDismissLayer

            readonly property point controlsOrigin: controlsSurface.mapToItem(
                powerMenuDismissLayer,
                0,
                0
            )
            readonly property point actionsOrigin: powerActions.mapToItem(
                powerMenuDismissLayer,
                0,
                0
            )
            readonly property real controlsTop: controlsOrigin.y
            readonly property real controlsBottom: controlsTop + controlsSurface.height
            readonly property real actionsLeft: actionsOrigin.x
            readonly property real actionsRight: actionsLeft + powerActions.width

            anchors.fill: parent
            z: 10
            visible: root.powerMenuOpen

            MouseArea {
                width: parent.width
                height: powerMenuDismissLayer.controlsTop
                onClicked: root.powerMenuOpen = false
            }

            MouseArea {
                y: powerMenuDismissLayer.controlsTop
                width: powerMenuDismissLayer.actionsLeft
                height: controlsSurface.height
                onClicked: root.powerMenuOpen = false
            }

            MouseArea {
                x: powerMenuDismissLayer.actionsRight
                y: powerMenuDismissLayer.controlsTop
                width: parent.width - x
                height: controlsSurface.height
                onClicked: root.powerMenuOpen = false
            }

            MouseArea {
                y: powerMenuDismissLayer.controlsBottom
                width: parent.width
                height: parent.height - y
                onClicked: root.powerMenuOpen = false
            }
        }
    }
}
