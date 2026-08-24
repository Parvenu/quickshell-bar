pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    readonly property string name: "Tokyo Night"
    readonly property int barContentVerticalOffset: 0

    readonly property color barBackground: "#1a1b26"
    readonly property color barBorder: "#3b4261"
    readonly property color drawerBackground: "#f21a1b26"
    readonly property color controlBackground: "#24283b"
    readonly property color controlHover: "#292e42"
    readonly property color divider: "#3b4261"

    readonly property color textPrimary: "#c0caf5"
    readonly property color textSecondary: "#a9b1d6"
    readonly property color textMuted: "#565f89"
    readonly property color clockText: "#7dcfff"
    readonly property color drawerTitle: "#7dcfff"
    readonly property color drawerLauncherActive: "#7dcfff"

    readonly property color focusedWorkspace: "#7dcfff"
    readonly property color activeWorkspace: "#73daca"
    readonly property color inactiveWorkspace: "#565f89"
    readonly property color urgentWorkspace: "#f7768e"

    readonly property color warningText: "#ff9e64"
    readonly property color criticalText: "#f7768e"
    readonly property color criticalSurface: "#f7768e"
    readonly property color criticalSurfaceText: "#16161e"

    readonly property color cpuAccent: "#7aa2f7"
    readonly property color temperatureAccent: "#f7768e"
    readonly property color memoryAccent: "#bb9af7"
    readonly property color audioOutputAccent: "#c0caf5"
    readonly property color audioInputAccent: "#c0caf5"
    readonly property color powerAccent: "#f7768e"
    readonly property color notificationAccent: "#7dcfff"
    readonly property color trayAttention: "#f7768e"
}
