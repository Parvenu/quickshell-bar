pragma ComponentBehavior: Bound

import QtQuick

QtObject {
    readonly property string name: "Rosé Pine"
    readonly property int barExclusiveZone: 30

    readonly property color barBackground: "#191724"
    readonly property color barBorder: "#6e6a86"
    readonly property color drawerBackground: "#f2191724"
    readonly property color controlBackground: "#1f1d2e"
    readonly property color controlHover: "#26233a"
    readonly property color divider: "#6e6a86"

    readonly property color textPrimary: "#e0def4"
    readonly property color textSecondary: "#908caa"
    readonly property color textMuted: "#6e6a86"
    readonly property color clockText: "#9ccfd8"
    readonly property color drawerTitle: "#ebbcba"
    readonly property color drawerLauncherActive: "#9ccfd8"

    readonly property color focusedWorkspace: "#9ccfd8"
    readonly property color activeWorkspace: "#c4a7e7"
    readonly property color inactiveWorkspace: "#6e6a86"
    readonly property color urgentWorkspace: "#eb6f92"

    readonly property color warningText: "#f6c177"
    readonly property color criticalText: "#eb6f92"
    readonly property color criticalSurface: "#eb6f92"
    readonly property color criticalSurfaceText: "#191724"

    readonly property color cpuAccent: "#ebbcba"
    readonly property color temperatureAccent: "#eb6f92"
    readonly property color memoryAccent: "#c4a7e7"
    readonly property color audioOutputAccent: "#e0def4"
    readonly property color audioInputAccent: "#e0def4"
    readonly property color powerAccent: "#eb6f92"
    readonly property color notificationAccent: "#9ccfd8"
    readonly property color trayAttention: "#eb6f92"
}
