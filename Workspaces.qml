pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    required property var monitor
    required property var theme

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: workspaceRow.implicitHeight

    Row {
        id: workspaceRow
        spacing: 2

        Repeater {
            model: 10

            delegate: Rectangle {
                id: workspaceButton

                required property int index
                property int workspaceId: index + 1
                property var workspace: Hyprland.workspaces.values.find(candidate => candidate.id === workspaceId) ?? null
                property bool isActive: workspace?.active ?? false
                property bool isFocused: workspace?.focused ?? false
                property bool isUrgent: workspace?.urgent ?? false

                visible: workspace !== null
                width: 22
                height: root.theme.barHeight - 2
                radius: root.theme.smallRadius
                color: workspaceMouse.containsMouse ? root.theme.controlHover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: root.theme.animationFast }
                }

                Text {
                    id: workspaceLabel

                    anchors.centerIn: parent
                    text: workspaceButton.workspaceId
                    color: {
                        if (workspaceButton.isUrgent)
                            return root.theme.urgentWorkspace
                        if (workspaceButton.isFocused)
                            return root.theme.focusedWorkspace
                        if (workspaceButton.isActive)
                            return root.theme.activeWorkspace
                        return root.theme.inactiveWorkspace
                    }
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSize
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors {
                        top: workspaceLabel.bottom
                        topMargin: root.theme.workspaceIndicatorGap
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: root.theme.workspaceIndicatorWidth
                    height: root.theme.workspaceIndicatorHeight
                    radius: height / 2
                    visible: workspaceButton.isFocused || workspaceButton.isActive || workspaceButton.isUrgent
                    color: {
                        if (workspaceButton.isUrgent)
                            return root.theme.urgentWorkspace
                        if (workspaceButton.isFocused)
                            return root.theme.focusedWorkspace
                        return root.theme.activeWorkspace
                    }
                }

                MouseArea {
                    id: workspaceMouse

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: Hyprland.dispatch(
                        `hl.dsp.focus({ workspace = ${workspaceButton.workspaceId} })`
                    )
                }
            }
        }
    }
}
