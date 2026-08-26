pragma ComponentBehavior: Bound

import QtQuick

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
    property real glyphHorizontalOffset: 0

    function customizedApplication(item): string {
        const id = String(item?.id ?? "").toLowerCase()
        if (id.startsWith("discord_status_icon_"))
            return "discord"
        if (id === "steam")
            return "steam"
        if (id === "wayscriber")
            return "wayscriber"
        if (id === "proton.vpn.app.gtk")
            return "proton"
        return ""
    }

    function protonState(item): string {
        const source = String(item?.icon ?? "").toLowerCase()
        if (source.includes("state-error"))
            return "error"
        if (source.includes("state-connected"))
            return "connected"
        return "disconnected"
    }

    function resolvedIconSource(item): string {
        const application = customizedApplication(item)
        if (application === "discord")
            return Qt.resolvedUrl("assets/tray/discord.svg").toString()
        if (application === "wayscriber")
            return Qt.resolvedUrl("assets/tray/wayscriber.svg").toString()
        if (application === "proton")
            return Qt.resolvedUrl(
                "assets/tray/proton-" + protonState(item) + ".svg"
            ).toString()
        if (application === "steam")
            return Qt.resolvedUrl("assets/tray/steam.svg").toString()
        return item.icon.toString()
    }


    function isErrorIcon(item): bool {
        return customizedApplication(item) === "proton"
            && protonState(item) === "error"
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
                readonly property bool highlighted: needsAttention || root.isErrorIcon(trayItem)
                readonly property string glyph: root.glyphForItem(trayItem)
                readonly property string iconSource: root.resolvedIconSource(trayItem)

                visible: root.itemFilter(trayItem)
                width: root.buttonWidth
                height: root.theme.controlHeight
                radius: root.theme.smallRadius
                color: trayMouse.containsMouse ? root.theme.controlHover : "transparent"
                border.width: highlighted ? 1 : 0
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
                }

                CenteredGlyph {
                    anchors.fill: parent
                    glyph: trayButton.glyph
                    color: trayButton.highlighted
                        ? root.theme.trayAttention
                        : root.theme.textPrimary
                    fontFamily: root.theme.fontFamily
                    fontPixelSize: root.theme.iconSize
                    fontWeight: Font.DemiBold
                    opticalHorizontalOffset: root.glyphHorizontalOffset
                    visible: trayButton.glyph.length > 0
                }

                Text {
                    anchors.centerIn: parent
                    text: trayButton.trayItem.title.length > 0
                        ? trayButton.trayItem.title.slice(0, 1).toUpperCase()
                        : "?"
                    color: trayButton.highlighted
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
