pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    required property var panelWindow
    required property var trayItems
    required property var theme

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

                width: 26
                height: root.theme.controlHeight
                radius: root.theme.smallRadius
                color: trayMouse.containsMouse ? root.theme.controlHover : "transparent"
                border.width: needsAttention ? 1 : 0
                border.color: root.theme.trayAttention

                Behavior on color {
                    ColorAnimation { duration: root.theme.animationFast }
                }

                Image {
                    anchors {
                        fill: parent
                        margins: 3
                    }
                    source: trayButton.trayItem.icon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    visible: source.toString().length > 0
                }

                Text {
                    anchors.centerIn: parent
                    text: trayButton.trayItem.title.length > 0
                        ? trayButton.trayItem.title.slice(0, 1).toUpperCase()
                        : "?"
                    color: root.theme.textSecondary
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                    font.weight: Font.DemiBold
                    visible: trayButton.trayItem.icon.length === 0
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
