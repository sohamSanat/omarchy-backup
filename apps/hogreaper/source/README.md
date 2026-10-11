# 󰍛 HogReaper

**Zero-Overhead RAM and CPU Hardware Governor for Omarchy Linux**

HogReaper is a lightweight, high-performance background daemon and CLI monitor written in Rust. It eliminates system lag by actively monitoring memory pressure and background CPU runaway, safeguarding your desktop from thrashing and freezes without introducing any lag itself.

---

## ⚡ Zero-Lag Architecture

- **Sub-1MB Footprint:** Uses ~670 KB of resident memory (RSS).
- **0.0% Idle CPU:** Reads `/proc/pressure/memory`, `/proc/pressure/cpu`, and `/proc/[pid]/` directly via low-overhead kernel APIs—no heavy shell wrappers, no subprocess spawning during monitoring.
- **Microsecond Hyprland IPC:** Connects directly to Hyprland's UNIX domain socket (`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock`) in <0.2ms to protect the currently active foreground window from being throttled or terminated.
- **Safety First:** Immutable safety allowlist protects systemd, Hyprland, Wayland portals, PipeWire audio, terminal emulators (Ghostty/Kitty/Foot), user shells, and AI coding agents.

---

## 🚀 Quick Start

### CLI Commands

```bash
# One-shot scan of system RAM, CPU pressure, and top consumers
hogreaper scan

# Live real-time terminal dashboard
hogreaper top

# Check memory pressure and daemon status
hogreaper status

# Run daemon in the foreground (with optional dry-run or custom interval)
hogreaper daemon --dry-run
hogreaper daemon --interval 2

# One-shot mitigation: immediately scan and neutralize rogue hogs
hogreaper kill-hogs

# Manage systemd background service
hogreaper service install     # Enable and start user systemd service
hogreaper service status      # View service status and resource footprint
hogreaper service restart     # Restart service
hogreaper service stop        # Stop service
hogreaper service uninstall   # Disable and remove unit file
```

---

## ⚙️ Configuration

Configuration is automatically generated at `~/.config/hogreaper/config.toml`:

```toml
[general]
poll_interval_secs = 2
dry_run = false
enable_notifications = true
log_actions = true

[memory]
min_available_ram_mb = 800          # Trigger mitigation when available RAM < 800 MB
min_available_ram_percent = 12.0     # Or when available RAM drops below 12%
psi_memory_avg10_threshold = 25.0    # Linux PSI memory pressure threshold
single_process_rss_limit_mb = 3500   # Mitigate single rogue processes exceeding 3.5GB

[cpu]
cpu_hog_threshold_percent = 75.0     # Trigger throttling when process uses > 75% CPU
sustained_ticks = 4                  # Must sustain high CPU for 4 ticks (8 seconds)

[escalation]
throttle_action = "renice"           # "renice" (nice +15) or "freeze" (SIGSTOP)
nice_level = 15
kill_signal = "sigterm"              # Sends SIGTERM first
escalate_to_sigkill = true           # Escalate to SIGKILL if SIGTERM ignored after grace period
grace_period_secs = 3

[whitelist]
protect_active_window = true         # Protect whatever app you are actively using
protect_child_processes_of_whitelisted = true
processes = [
    "steam",
    "gamescope",
    "obs",
    "ffmpeg",
]
```

To view or reset configuration:
```bash
hogreaper config
hogreaper config --reset
```

---

## 🛡️ Built-in Protected Services

HogReaper will **never** terminate or freeze:
- **Core System:** `systemd`, `systemd-journald`, `systemd-logind`, `systemd-oomd`, `dbus-daemon`, `polkitd`, `seatd`
- **Compositor & Shell:** `Hyprland`, `Xwayland`, `quickshell`, `waybar`, `mako`, `dunst`, `xdg-desktop-portal*`
- **Audio:** `pipewire`, `pipewire-pulse`, `wireplumber`, `easyeffects`
- **Terminals:** `ghostty`, `kitty`, `alacritty`, `foot`, `tmux`, `zellij`
- **Shells:** `bash`, `zsh`, `fish`, `sh`
- **Editors & Agents:** `hogreaper`, `agy-real`, `antigravity`, `opencode`, `code`, `cursor`, `nvim`, `vim`, `cargo`, `rustc`
- **Active App:** The active window reported in real-time by Hyprland.
