pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property bool active
    required property string menuMonitor

    visible: root.active && root.screen?.name !== root.menuMonitor
    color: "#d9191724"
    exclusiveZone: 0
    mask: Region {}

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:power-backdrop"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
}
