pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property var panelWindow
    required property var trayItems
    required property var theme

    property var itemFilter: item => true
    property var glyphForItem: item => ""
    property int buttonWidth: 26

    function iconName(source): string {
        const value = source.toString()
        const pathStart = value.lastIndexOf("/") + 1
        const queryStart = value.indexOf("?", pathStart)
        return value.slice(pathStart, queryStart >= 0 ? queryStart : value.length)
    }

    function preferredIconName(item): string {
        const id = String(item?.id ?? "").toLowerCase()
        if (id.startsWith("discord"))
            return "discord"
        if (id === "steam")
            return "steam"
        return ""
    }

    function resolvedIconSource(item): string {
        const id = String(item?.id ?? "").toLowerCase()
        if (id === "wayscriber")
            return "file:///usr/share/icons/hicolor/symbolic/apps/wayscriber-symbolic.svg"

        const preferredName = preferredIconName(item)
        if (preferredName.length > 0) {
            const preferredIcon = Quickshell.iconPath(preferredName, true)
            if (preferredIcon.length > 0)
                return preferredIcon
        }

        const value = item.icon.toString()
        const name = iconName(value)
        if (!name.endsWith("-symbolic"))
            return value

        const regularName = name.slice(0, -"-symbolic".length)
        const regularIcon = Quickshell.iconPath(regularName, true)
        return regularIcon.length > 0 ? regularIcon : value
    }

    function isSymbolicIcon(item, source): bool {
        const id = String(item?.id ?? "").toLowerCase()
        return id === "wayscriber" || iconName(source).endsWith("-symbolic")
    }

    implicitWidth: trayRow.implicitWidth
    implicitHeight: trayRow.implicitHeight

    Row {
        id: trayRow
        spacing: 3

        Repeater {
            model: root.trayItems

            delegate: Rectangle {
                id: trayButton

                required property var modelData
                readonly property var trayItem: modelData
                readonly property bool needsAttention: trayItem.status === Status.NeedsAttention
                readonly property string glyph: root.glyphForItem(trayItem)
                readonly property string iconSource: root.resolvedIconSource(trayItem)
                readonly property bool symbolicIcon: root.isSymbolicIcon(trayItem, iconSource)

                visible: root.itemFilter(trayItem)
                width: root.buttonWidth
                height: root.theme.controlHeight
                radius: root.theme.smallRadius
                color: trayMouse.containsMouse ? root.theme.controlHover : "transparent"
                border.width: needsAttention ? 1 : 0
                border.color: root.theme.trayAttention

                Behavior on color {
                    ColorAnimation { duration: root.theme.animationFast }
                }

                IconImage {
                    anchors {
                        fill: parent
                        margins: 3
                    }
                    source: trayButton.iconSource
                    asynchronous: true
                    visible: trayButton.glyph.length === 0 && source.toString().length > 0
                    layer.enabled: trayButton.symbolicIcon
                    layer.effect: MultiEffect {
                        brightness: 1
                        colorization: 1
                        colorizationColor: trayButton.needsAttention
                            ? root.theme.trayAttention
                            : root.theme.textPrimary
                    }
                }

                CenteredGlyph {
                    anchors.fill: parent
                    glyph: trayButton.glyph
                    color: trayButton.needsAttention
                        ? root.theme.trayAttention
                        : root.theme.textPrimary
                    fontFamily: root.theme.fontFamily
                    fontPixelSize: root.theme.iconSize
                    fontWeight: Font.DemiBold
                    visible: trayButton.glyph.length > 0
                }

                Text {
                    anchors.centerIn: parent
                    text: trayButton.trayItem.title.length > 0
                        ? trayButton.trayItem.title.slice(0, 1).toUpperCase()
                        : "?"
                    color: trayButton.needsAttention
                        ? root.theme.trayAttention
                        : root.theme.textSecondary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                    font.weight: Font.DemiBold
                    visible: trayButton.glyph.length === 0 && trayButton.trayItem.icon.length === 0
                }

                MouseArea {
                    id: trayMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function openMenu(mouse) {
                        const position = mapToItem(
                            root.panelWindow.contentItem,
                            mouse.x,
                            mouse.y
                        )
                        trayButton.trayItem.display(
                            root.panelWindow,
                            Math.round(position.x),
                            Math.round(position.y)
                        )
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            if (trayButton.trayItem.hasMenu)
                                openMenu(mouse)
                            else
                                trayButton.trayItem.secondaryActivate()
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayButton.trayItem.secondaryActivate()
                        } else if (trayButton.trayItem.onlyMenu && trayButton.trayItem.hasMenu) {
                            openMenu(mouse)
                        } else {
                            trayButton.trayItem.activate()
                        }
                        mouse.accepted = true
                    }

                    onWheel: wheel => {
                        trayButton.trayItem.scroll(wheel.angleDelta.y, false)
                        wheel.accepted = true
                    }
                }
            }
        }
    }
}
