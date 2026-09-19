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
  - Rofi power menu with capability checks and all-monitor blur
  - Separate application tray and menus
  - Local month calendar and Proton Calendar web launcher
  - Native notification history in a fixed-height page that preserves the drawer frame
  - DND, unread state, individual dismiss, and clear-all controls
- Native Freedesktop notification daemon with focused-monitor toasts
- Default and alternate actions, notification images, progress hints, and inline replies
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
- `hyprlock`
- `pavucontrol`
- `kitty`
- `btop`
- `rofi`
- `xdg-open`
- JetBrainsMono Nerd Font

The drawer power button launches `~/.config/hypr/scripts/PowerMenu.sh`. The menu queries logind so unsupported actions are hidden and asks the bar to map click-through blur backdrops on the non-menu outputs. Selecting an action executes it immediately; locking invokes `hyprlock --quiet` directly.

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

This configuration is the notification daemon and owns `org.freedesktop.Notifications`. Do not run SwayNC, Mako, Dunst, or another notification server at the same time.

When migrating from SwayNC, remove its startup and reload commands, then prevent D-Bus activation from reclaiming the name:

```bash
systemctl --user mask swaync.service
pkill -x swaync
```

A typical Hyprland binding for the native notification page is:

```ini
bindd = $mainMod SHIFT, N, notification panel, exec, qs ipc -c bar call bar openNotifications
```

The bar exposes these IPC controls:

```bash
qs ipc -c bar call bar openDashboard
qs ipc -c bar call bar openNotifications
qs ipc -c bar call bar closeDrawer
qs ipc -c bar call bar setDoNotDisturb true
qs ipc -c bar call bar setDoNotDisturb false
qs ipc -c bar call bar clearNotifications
```

Normal notification history is retained for the active session and survives QML hot reloads. It is not serialized across logout or reboot. Transient notifications, including volume and brightness indicators, are shown as toasts but intentionally excluded from history. Critical notifications and existing `SWAYNC_BYPASS_DND` hints bypass DND.

Notification cards invoke Freedesktop default actions on click, expose alternative actions as buttons, and show an inline reply field when the sending application provides one. Whether a click opens a specific email, chat, or application is determined by the action supplied by that application.

> **Quickshell 0.3.1 limitation:** an application replacement can retain a stale changed action label or inline-reply placeholder, and a completely identical replacement emits no update signal to restart the toast timer. These are upstream notification-service limitations rather than local presentation behavior.

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
├── NotificationCard.qml
├── NotificationPage.qml
├── NotificationToastHost.qml
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
