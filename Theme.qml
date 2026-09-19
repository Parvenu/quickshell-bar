pragma ComponentBehavior: Bound

import QtQuick
import "themes" as Themes

QtObject {
    // Change this one assignment to activate another compatible color scheme.
    readonly property Themes.Glass scheme: Themes.Glass {}

    readonly property string name: scheme.name
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int iconSize: 14

    readonly property int barHeight: 30
    readonly property int barExclusiveZone: scheme.barExclusiveZone
    readonly property int hyprlandOuterGap: 8
    readonly property int hyprlandBorderSize: 2
    readonly property int hyprlandWindowTop: barExclusiveZone + hyprlandOuterGap
    readonly property int hyprlandClientTop: hyprlandWindowTop + hyprlandBorderSize
    readonly property int controlHeight: 24
    readonly property int smallRadius: 4
    readonly property int drawerRadius: 8
    readonly property int drawerPadding: 10
    readonly property int drawerScreenMargin: hyprlandOuterGap
    readonly property int drawerBodyHeight: 343
    readonly property int workspaceIndicatorWidth: 10
    readonly property int workspaceIndicatorHeight: 1
    readonly property int workspaceIndicatorGap: 0
    readonly property int animationFast: 120

    readonly property color barBackground: scheme.barBackground
    readonly property color barBorder: scheme.barBorder
    readonly property color drawerBackground: scheme.drawerBackground
    readonly property color controlBackground: scheme.controlBackground
    readonly property color controlHover: scheme.controlHover
    readonly property color divider: scheme.divider

    readonly property color textPrimary: scheme.textPrimary
    readonly property color textSecondary: scheme.textSecondary
    readonly property color textMuted: scheme.textMuted
    readonly property color clockText: scheme.clockText
    readonly property color drawerTitle: scheme.drawerTitle
    readonly property color drawerLauncherActive: scheme.drawerLauncherActive
    readonly property color calendarHoliday: scheme.calendarHoliday

    readonly property color focusedWorkspace: scheme.focusedWorkspace
    readonly property color activeWorkspace: scheme.activeWorkspace
    readonly property color inactiveWorkspace: scheme.inactiveWorkspace
    readonly property color urgentWorkspace: scheme.urgentWorkspace

    readonly property color warningText: scheme.warningText
    readonly property color criticalText: scheme.criticalText
    readonly property color criticalSurface: scheme.criticalSurface
    readonly property color criticalSurfaceText: scheme.criticalSurfaceText

    readonly property color cpuAccent: scheme.cpuAccent
    readonly property color temperatureAccent: scheme.temperatureAccent
    readonly property color memoryAccent: scheme.memoryAccent
    readonly property color audioOutputAccent: scheme.audioOutputAccent
    readonly property color audioInputAccent: scheme.audioInputAccent
    readonly property color powerAccent: scheme.powerAccent
    readonly property color notificationAccent: scheme.notificationAccent
    readonly property color trayAttention: scheme.trayAttention
}
