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

    property bool notificationPageOpen: false

    signal dashboardRequested()
    signal notificationsRequested()
    signal dismissed()


    function trayItemId(item): string {
        return String(item?.id ?? "").toLowerCase()
    }

    function isBluetoothItem(item): bool {
        return trayItemId(item) === "blueman"
    }

    function isNetworkItem(item): bool {
        const id = trayItemId(item)
        const title = String(item?.title ?? "").toLowerCase()
        return id === "nm-applet" || id === "nm_applet"
            || id.includes("networkmanager")
            || title.includes("networkmanager")
    }

    function isSystemItem(item): bool {
        return isBluetoothItem(item) || isNetworkItem(item)
    }

    function openPowerMenu(): void {
        Quickshell.execDetached(["/home/uta/.config/hypr/scripts/PowerMenu.sh"])
        root.visible = false
    }

    implicitWidth: root.anchorItem.width + root.theme.drawerPadding * 2
    implicitHeight: contentColumn.implicitHeight + 10
    color: "transparent"
    grabFocus: true

    anchor {
        window: root.panelWindow
        item: root.anchorItem
        rect.x: root.theme.drawerPadding - root.theme.drawerScreenMargin
        rect.y: 0
        rect.width: root.anchorItem.width
        rect.height: root.anchorItem.height
        edges: Edges.Top | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        adjustment: PopupAdjustment.None
    }

    Component.onCompleted: visible = true
    onVisibleChanged: {
        if (!visible)
            dismissed()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.visible
        onActivated: root.visible = false
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
                            + root.theme.drawerScreenMargin
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
                        rightMargin: Math.max(
                            0,
                            root.theme.drawerPadding - root.theme.drawerScreenMargin
                        )
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
                    if (powerHover.hovered)
                        return "Power menu"
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
                        id: powerButton

                        theme: root.theme
                        glyph: ""
                        inactiveGlyphColor: root.theme.powerAccent
                        opticalHorizontalOffset: 0.5
                        onClicked: root.openPowerMenu()

                        HoverHandler {
                            id: powerHover
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


    }
}
