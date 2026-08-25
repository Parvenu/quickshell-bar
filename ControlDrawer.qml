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

    signal dismissed()

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

    implicitWidth: Math.ceil(Math.max(
        root.anchorItem.width,
        drawerHeader.implicitWidth,
        applicationSurface.implicitWidth,
        notificationButton.implicitWidth
    )) + root.theme.drawerPadding * 2
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
        if (!visible)
            dismissed()
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
                id: drawerHeader

                width: parent.width
                height: root.theme.barHeight + 66
                implicitWidth: Math.max(
                    drawerStatusLine.implicitWidth,
                    Math.max(
                        userSummaryLabel.implicitWidth,
                        platformSummaryLabel.implicitWidth
                    ) + Math.max(headerActions.implicitWidth, sessionActions.implicitWidth) + 8
                )

                StatusLine {
                    id: drawerStatusLine

                    anchors {
                        right: parent.right
                        rightMargin: root.theme.drawerPadding
                    }
                    theme: root.theme
                    clock: root.clock
                    audio: root.audio
                    metrics: root.metrics
                    drawerOpen: true
                    onDrawerClicked: root.visible = false
                }

                Text {
                    id: userSummaryLabel

                    anchors {
                        left: parent.left
                        leftMargin: root.theme.drawerPadding
                        right: headerActions.left
                        rightMargin: 8
                        verticalCenter: headerActions.verticalCenter
                    }
                    text: root.systemInfo.userSummary
                    elide: Text.ElideRight
                    color: root.theme.drawerTitle
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize + 1
                    font.weight: Font.DemiBold
                }

                Text {
                    id: platformSummaryLabel

                    anchors {
                        top: userSummaryLabel.bottom
                        topMargin: 1
                        left: userSummaryLabel.left
                        right: userSummaryLabel.right
                    }
                    text: root.systemInfo.platformSummary
                    elide: Text.ElideRight
                    color: root.theme.textSecondary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1
                }

                Row {
                    id: headerActions

                    anchors {
                        top: parent.top
                        topMargin: (root.theme.barHeight - root.theme.controlHeight) / 2
                            + root.theme.controlHeight
                            + 2
                        right: parent.right
                        rightMargin: root.theme.drawerPadding
                    }
                    height: root.theme.controlHeight
                    spacing: 2

                    Tray {
                        buttonWidth: 24
                        panelWindow: root
                        trayItems: root.trayItems
                        theme: root.theme
                        itemFilter: item => root.isBluetoothItem(item)
                        glyphForItem: item => ""
                        glyphHorizontalOffset: -0.5
                    }

                    Tray {
                        buttonWidth: 24
                        panelWindow: root
                        trayItems: root.trayItems
                        theme: root.theme
                        itemFilter: item => root.isNetworkItem(item)
                        glyphForItem: item => "󰖩"
                    }

                    Rectangle {
                        id: powerButton

                        width: 24
                        height: root.theme.controlHeight
                        radius: root.theme.smallRadius
                        color: powerMouse.containsMouse ? root.theme.criticalSurface : "transparent"

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
                                Quickshell.execDetached([
                                    Quickshell.env("HOME") + "/.config/hypr/scripts/Wlogout.sh"
                                ])
                                root.visible = false
                            }
                        }
                    }
                }

                Row {
                    id: sessionActions

                    anchors {
                        top: headerActions.bottom
                        topMargin: 2
                        right: parent.right
                        rightMargin: root.theme.drawerPadding
                    }
                    height: root.theme.controlHeight
                    spacing: 2

                    DrawerActionButton {
                        theme: root.theme
                        glyph: "󰖔"
                        active: root.sessionControls.hyprsunsetEnabled
                        activeGlyphColor: root.theme.warningText
                        onClicked: root.sessionControls.toggleHyprsunset()
                    }

                    DrawerActionButton {
                        theme: root.theme
                        glyph: root.sessionControls.idleInhibited ? "󰒳" : "󰒲"
                        active: root.sessionControls.idleInhibited
                        onClicked: root.sessionControls.toggleIdleInhibit(root.panelWindow)
                    }

                    DrawerActionButton {
                        theme: root.theme
                        glyph: root.notifications.dnd ? "󰂛" : "󰂚"
                        active: root.notifications.dnd
                        activeGlyphColor: root.theme.notificationAccent
                        onClicked: root.notifications.toggleDnd()
                    }
                }
            }

            Rectangle {
                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 1
                color: root.theme.divider
            }


            Rectangle {
                id: applicationSurface

                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 32
                implicitWidth: applicationTray.implicitWidth + 6
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
                id: notificationButton

                x: root.theme.drawerPadding
                width: parent.width - root.theme.drawerPadding * 2
                height: 32
                implicitWidth: notificationLabel.implicitWidth
                    + notificationCount.implicitWidth
                    + 28
                radius: root.theme.smallRadius
                color: notificationMouse.containsMouse ? root.theme.controlHover : root.theme.controlBackground

                Behavior on color {
                    ColorAnimation { duration: root.theme.animationFast }
                }

                Text {
                    id: notificationLabel

                    anchors {
                        left: parent.left
                        leftMargin: 9
                        verticalCenter: parent.verticalCenter
                    }
                    text: "  Notifications"
                    color: root.theme.textPrimary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                }

                Text {
                    id: notificationCount

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
                    id: notificationMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.notifications.openControlCenter()
                        root.visible = false
                    }
                }
            }
        }
    }
}
