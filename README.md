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
  - Unified audio, Bluetooth, network, Hyprsunset, idle-inhibition, and DND controls with hover labels
  - Inline lock, suspend, hibernate, reboot, and shutdown actions
  - Separate application tray and menus
  - Local month calendar and Proton Calendar web launcher
  - SwayNC notification count and control-center launcher
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
- `hyprlock`
- `pavucontrol`
- `kitty`
- `btop`
- `xdg-open`
- JetBrainsMono Nerd Font

The drawer invokes `hyprlock --quiet` directly for locking and uses `systemctl` for suspend, hibernate, reboot, and shutdown. Suspend and hibernate availability depends on host support; the current `hypridle` configuration locks the session before sleep.

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

## Calendar integration

The drawer calendar is a local month view. Clicking its month header opens [Proton Calendar](https://calendar.proton.me/) through `xdg-open`; clicking a date opens Proton's week view directly on that date.

The 11 nationwide French public holidays are calculated locally and marked with a distinct date-number color. Region-specific holidays for Alsace-Moselle and overseas territories are not included.

Version 1 does not read or synchronize Proton events. Proton Calendar does not provide CalDAV, so native calendar applications cannot offer direct two-way synchronization. Any future read-only subscription should keep its private calendar URL outside this repository.

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
├── StatusLine.qml
├── CenteredGlyph.qml
├── Calendar.qml
├── DrawerActionButton.qml
├── Workspaces.qml
├── Audio.qml
├── AudioService.qml
├── Metrics.qml
├── MetricsService.qml
├── NotificationService.qml
├── SessionControlsService.qml
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
