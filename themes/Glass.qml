pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    readonly property string name: "Glass"
    readonly property int barContentVerticalOffset: 1

    readonly property color barBackground: "#00000000"
    readonly property color barBorder: "#00000000"
    readonly property color drawerBackground: "#b0121212"
    readonly property color controlBackground: "#18ffffff"
    readonly property color controlHover: "#2bffffff"
    readonly property color divider: "#55cecece"

    readonly property color textPrimary: "#cecece"
    readonly property color textSecondary: "#b8b8b8"
    readonly property color textMuted: "#787878"
    readonly property color clockText: "#cecece"
    readonly property color drawerTitle: "#d8dee9"
    readonly property color drawerLauncherActive: "#d8dee9"

    readonly property color focusedWorkspace: "#d8dee9"
    readonly property color activeWorkspace: "#cecece"
    readonly property color inactiveWorkspace: "#787878"
    readonly property color urgentWorkspace: "#ffffff"

    readonly property color warningText: "#e4e4e4"
    readonly property color criticalText: "#ffffff"
    readonly property color criticalSurface: "#d9ffffff"
    readonly property color criticalSurfaceText: "#111111"

    readonly property color cpuAccent: "#cecece"
    readonly property color temperatureAccent: "#cecece"
    readonly property color memoryAccent: "#cecece"
    readonly property color audioOutputAccent: "#cecece"
    readonly property color audioInputAccent: "#cecece"
    readonly property color powerAccent: "#cecece"
    readonly property color notificationAccent: "#cecece"
    readonly property color trayAttention: "#ffffff"
}
