# Trackpad Speed for Omarchy

A native, theme-aware Omarchy Shell plugin for adjusting trackpad pointer
speed without opening a terminal.

It adds a compact speed control to the status bar and a **Trackpad Speed**
entry to the app launcher. Click the bar item for a slider and presets, or
scroll over it for quick adjustments.

## Features

- Pointer speed from `-1.00` to `+1.00` in `0.05` steps
- Precise, Natural, Fast, and Swift presets
- Scroll-to-adjust directly from the status bar
- Keyboard navigation with arrow keys
- Automatic touchpad detection through Omarchy
- Persistent speed across login and Hyprland config reloads
- Per-device configuration, so external mouse speed is unchanged
- Live Omarchy colors, typography, spacing, and control styling
- ARM64 and x86-64 compatible; no compiled components

## Requirements

- Omarchy 4.0 or newer with the Quickshell-based Omarchy Shell
- Hyprland
- A touchpad detected by `omarchy-hw-touchpad`

This includes Apple Silicon MacBooks running Omarchy/Asahi Linux.

## Install

```bash
omarchy plugin add https://github.com/Tigran01/omarchy-trackpad-speed.git --enable
```

The widget defaults to the right side of the bar. Move it at any time:

```bash
omarchy bar move io.github.tigran01.trackpad-speed --before omarchy.monitor
```

The app launcher entry is installed automatically when the plugin service
starts. Search for **Trackpad Speed** in Apps.

## Use

- Click the bar value to open the full control.
- Scroll over the bar value to adjust by `0.05`.
- Drag the slider or choose a preset.
- Use `Left`/`Right` for fine control and `Up`/`Down` for presets.

The selected value is stored in
`$XDG_STATE_HOME/omarchy-trackpad-speed/speed`, falling back to
`~/.local/state/omarchy-trackpad-speed/speed`.

## Update

```bash
omarchy plugin update io.github.tigran01.trackpad-speed
```

## Remove

```bash
omarchy plugin remove io.github.tigran01.trackpad-speed
rm -f ~/.local/share/applications/omarchy-trackpad-speed.desktop
rm -rf ~/.local/state/omarchy-trackpad-speed
```

The final two commands remove the app launcher entry and saved speed.

## How it works

The plugin uses Omarchy's own `omarchy-hw-touchpad` detector and applies the
setting with Hyprland's Lua evaluation API. It does not rewrite your
`~/.config/hypr/input.lua` file. A small background service reapplies the
saved value when Hyprland reloads its configuration.

The UI uses Omarchy Shell's shared components and live theme tokens. There
are no hard-coded theme colors.

## License

MIT
