# Security policy

Please report security-sensitive issues privately through GitHub's
**Security → Report a vulnerability** flow rather than opening a public issue.

The plugin runs inside Omarchy Shell and invokes only bundled scripts,
`omarchy-hw-touchpad`, `hyprctl`, and standard POSIX utilities. Device names
are rejected if they contain control characters and escaped before being
passed to Hyprland's Lua evaluator.
