# Trackpad Speed for Omarchy

A native, theme-aware Omarchy Shell plugin for adjusting trackpad pointer
speed without opening a terminal.

It adds a **Trackpad Speed** entry to the app launcher and can optionally add
a compact speed control to the status bar. Click the bar item for a slider
and presets, or scroll over it for quick adjustments.

## Features

- Pointer speed from `-1.00` to `+1.00` in `0.05` steps
- Precise, Natural, Fast, and Swift presets
- Scroll-to-adjust directly from the status bar
- Keyboard navigation with arrow keys
- Automatic touchpad detection through Omarchy
- Persistent speed across login and Hyprland config reloads
- Per-device configuration, so external mouse speed is unchanged
- Optional status-bar presence, controlled from the settings panel
- Live Omarchy colors, typography, spacing, and control styling
- ARM64 and x86-64 compatible; no compiled components

## Requirements

- Omarchy 4.0 or newer with the Quickshell-based Omarchy Shell
- Hyprland
- A touchpad detected by `omarchy-hw-touchpad`

This includes Apple Silicon MacBooks running Omarchy/Asahi Linux.

## Dependencies and permissions

The plugin uses components already included with Omarchy: Quickshell,
Hyprland, `omarchy-hw-touchpad`, `hyprctl`, `jq`, and standard shell tools.
It has no network service, remote build, package installation, or compiled
dependency. It runs entirely with the current user's permissions and never
uses `sudo`, `pkexec`, or another privilege boundary.

When enabled, the plugin creates these user-owned files:

- `~/.local/share/applications/omarchy-trackpad-speed.desktop`
- `~/.local/state/omarchy-trackpad-speed/speed`

It will not replace an unrelated desktop entry at that path. The plugin only
changes status-bar layout after the user explicitly clicks **Show in status
bar**. It never edits Hyprland configuration files.

## Install

```bash
omarchy plugin add https://github.com/Tigran01/omarchy-trackpad-speed.git --enable
```

Open **Trackpad Speed** from Apps and turn on **Show in status bar** for quick
access. The widget is added to the right side of the bar and can be turned
off again from either interface.

Move the visible widget at any time:

```bash
omarchy bar move io.github.tigran01.trackpad-speed --before omarchy.monitor
```

The app launcher entry is installed automatically when the plugin service
starts. Search for **Trackpad Speed** in Apps. It opens a standalone themed
settings panel whether or not the status-bar widget is visible.

## Use

- Open **Trackpad Speed** from Apps for the full settings panel.
- Click the optional bar value for a compact control.
- Scroll over the bar value to adjust by `0.05`.
- Drag the slider or choose a preset.
- Use `Left`/`Right` for fine control and `Up`/`Down` for presets.

The selected value is stored in
`$XDG_STATE_HOME/omarchy-trackpad-speed/speed`, falling back to
`~/.local/state/omarchy-trackpad-speed/speed`. Clicking the status-bar toggle
explicitly moves the plugin between Omarchy's normal bar layout and enabled
plugin list in `shell.json`; it does not rewrite unrelated settings.

## Update

```bash
omarchy plugin update io.github.tigran01.trackpad-speed
```

## Remove

```bash
~/.config/omarchy/plugins/io.github.tigran01.trackpad-speed/scripts/bar-visibility remove
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

## Security

Plugins run unsandboxed inside the long-running Omarchy Shell process. This
plugin executes only its bundled scripts plus the dependencies listed above.
Detected device names containing control characters are rejected and quoted
before being passed to Hyprland's Lua evaluator. Security reports can be sent
privately through GitHub's vulnerability-reporting flow.

## License

MIT
