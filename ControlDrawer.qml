pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var panelWindow
    required property var anchorItem
    required property var theme
    required property var audio
    required property var notifications
    required property var systemInfo
    required property var trayItems

    signal dismissed()

    implicitWidth: 260
    implicitHeight: 186
    color: "transparent"
    grabFocus: true

    anchor {
        window: root.panelWindow
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
        adjustment: PopupAdjustment.Slide
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
            anchors {
                fill: parent
                margins: 12
            }
            spacing: 8

            Column {
                width: parent.width
                spacing: 1

                Text {
                    text: `  ${root.systemInfo.identity}`
                    color: root.theme.drawerTitle
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize + 1
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.systemInfo.sessionSummary
                    color: root.theme.textSecondary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize - 1
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.theme.divider
            }

            Item {
                width: parent.width
                height: root.theme.controlHeight

                Audio {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    audio: root.audio
                    theme: root.theme
                }

                Rectangle {
                    id: powerButton

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: 26
                    height: root.theme.controlHeight
                    radius: root.theme.smallRadius
                    color: powerMouse.containsMouse ? root.theme.criticalSurface : root.theme.controlBackground

                    Behavior on color {
                        ColorAnimation { duration: root.theme.animationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: powerMouse.containsMouse ? root.theme.criticalSurfaceText : root.theme.powerAccent
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.iconSize
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

            Tray {
                panelWindow: root
                trayItems: root.trayItems
                theme: root.theme
            }

            Rectangle {
                id: notificationButton

                width: parent.width
                height: 32
                radius: root.theme.smallRadius
                color: notificationMouse.containsMouse ? root.theme.controlHover : root.theme.controlBackground

                Behavior on color {
                    ColorAnimation { duration: root.theme.animationFast }
                }

                Text {
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
