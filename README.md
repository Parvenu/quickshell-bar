# Quickshell Bar

A compact, multi-monitor Hyprland status bar built with [Quickshell](https://quickshell.org/).

> **Alpha:** this is currently a personal Fedora 43 configuration. Some integration points are intentionally specific to the host setup described below.

## Features

- Active and occupied Hyprland workspaces
- CPU usage, AMD CPU temperature, and memory usage
- Right-click on the metrics group to open `btop` in `kitty`
- PipeWire speaker and microphone mute controls
- Right-click audio controls to open the matching `pavucontrol` tab
- Per-monitor control drawer with:
  - User, host, Hyprland version, and uptime information
  - System tray and application menus
  - SwayNC notification count and control-center launcher
  - Power-menu launcher
- Shared service objects rather than one service instance per monitor
- Lazy-loaded control drawers
- Semantic, swappable color schemes:
  - Glass
  - Tokyo Night
  - Rosé Pine

## Requirements

The current configuration is tested with:

- Quickshell 0.3.1
- Hyprland 0.56.2
- PipeWire
- SwayNC
- `pavucontrol`
- `kitty`
- `btop`
- JetBrainsMono Nerd Font

The power button expects an executable script at:

```text
~/.config/hypr/scripts/Wlogout.sh
```

The temperature service currently discovers the AMD `k10temp/Tccd1` sensor. Systems without that sensor will show `--°C` until `MetricsService.qml` is adapted to their hardware.

## Installation

Clone the repository as a named Quickshell configuration:

```bash
git clone git@github.com:Parvenu/quickshell-bar.git ~/.config/quickshell/bar
```

Launch it with:

```bash
qs --no-duplicate --daemonize -c bar
```

Stop it with:

```bash
qs kill -c bar
```

`//@ pragma UseQApplication` in `shell.qml` is required for tray application menus.

## Hyprland integration

Workspace clicks currently use the Hyprland Lua configuration provider:

```qml
Hyprland.dispatch(
    `hl.dsp.focus({ workspace = ${workspaceButton.workspaceId} })`
)
```

This expression is intentional. If Hyprland is using the legacy configuration provider, adapt the dispatcher call to the syntax expected by that provider.

Only one StatusNotifier host should run at a time. Stop Waybar or disable its tray module before starting this bar if it would otherwise compete for `org.kde.StatusNotifierWatcher`.

SwayNC remains the notification daemon and owns `org.freedesktop.Notifications`; this bar only subscribes to SwayNC state and opens its control center.

## Themes

The stable semantic facade is `Theme.qml`. Visual components consume role names such as `focusedWorkspace`, `warningText`, and `audioOutputAccent` rather than raw hue names.

To change the active scheme, update the typed `scheme` assignment in `Theme.qml`. For example:

```qml
readonly property Themes.RosePine scheme: Themes.RosePine {}
```

Color values belong in the files under `themes/`. New schemes should expose the same semantic role set as the existing schemes.

## Layout

```text
bar/
├── shell.qml
├── Bar.qml
├── Workspaces.qml
├── Audio.qml
├── AudioService.qml
├── Metrics.qml
├── MetricsService.qml
├── NotificationService.qml
├── SystemInfoService.qml
├── Tray.qml
├── TrayService.qml
├── ControlDrawer.qml
├── Theme.qml
└── themes/
    ├── Glass.qml
    ├── TokyoNight.qml
    └── RosePine.qml
```
