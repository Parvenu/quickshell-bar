pragma ComponentBehavior: Bound

import QtQuick

Rectangle {
    id: root

    required property var theme
    required property string glyph

    property bool active: false
    property color activeGlyphColor: theme.drawerLauncherActive
    property color inactiveGlyphColor: theme.textSecondary
    property real opticalHorizontalOffset: 0

    signal clicked()

    width: 24
    height: root.theme.controlHeight
    radius: root.theme.smallRadius
    color: actionMouse.containsMouse
        ? root.theme.controlHover
        : root.active
            ? root.theme.controlBackground
            : "transparent"

    Behavior on color {
        ColorAnimation { duration: root.theme.animationFast }
    }

    CenteredGlyph {
        anchors.fill: parent
        glyph: root.glyph
        color: root.active ? root.activeGlyphColor : root.inactiveGlyphColor
        fontFamily: root.theme.fontFamily
        fontPixelSize: root.theme.iconSize
        fontWeight: Font.DemiBold
        opticalHorizontalOffset: root.opticalHorizontalOffset
    }

    MouseArea {
        id: actionMouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
