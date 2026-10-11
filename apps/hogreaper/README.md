# 󰍛 HogReaper

**Zero-Overhead RAM and CPU Hardware Governor for Omarchy Linux**

HogReaper is Soham's custom-engineered Linux hardware pressure governor and desktop anti-freeze daemon written in Rust. It eliminates thrashing, system freezes, and background runaway CPU/RAM hogs without introducing any system lag or polling overhead.

---

## ⚡ Zero-Lag Architecture

- **Sub-1MB Footprint:** Uses ~670 KB to 1.8 MB resident memory (RSS).
- **0.0% Idle CPU:** Directly reads Linux Pressure Stall Information (`/proc/pressure/memory`, `/proc/pressure/cpu`) and `/proc/[pid]/` via kernel file descriptors—zero subprocess spawning during continuous monitoring.
- **Microsecond Hyprland IPC:** Connects directly to Hyprland's UNIX domain socket (`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock`) in `<0.2ms` to protect the currently active foreground window from being throttled or terminated.
- **Immutable Safety Allowlist:** Protects systemd, Hyprland, Wayland portals, PipeWire audio, terminal emulators (Ghostty/Kitty/Foot), user shells, and AI coding agents.
- **Quickshell Navbar Plugin (`soham.hogreaper`):** Live floating bar indicator (`BarWidget.qml`) and interactive panel dashboard (`Panel.qml`) displaying real-time RAM/SWAP usage gauges, PSI memory/CPU meters, active window tracking, one-click hog termination (`kill-hogs`), top dashboard launcher, and daemon controls.

---

## 📦 Directory Structure

- [`source/`](file:///home/soham/omarchy-backup/apps/hogreaper/source): Complete Rust source repository (`Cargo.toml`, `Cargo.lock`, `src/`).
- [`build.sh`](file:///home/soham/omarchy-backup/apps/hogreaper/build.sh): Compiles an optimized release build via `cargo build --release` and installs the binary to `~/.local/bin/hogreaper`.
- [`install.sh`](file:///home/soham/omarchy-backup/apps/hogreaper/install.sh): Restores the binary, config, Quickshell plugin, and enables the systemd user service (`systemctl --user enable --now hogreaper.service`).

---

## 🚀 CLI Commands

```bash
# One-shot scan of system RAM, CPU pressure, and top consumers
hogreaper scan

# Live real-time terminal dashboard
hogreaper top

# Check memory pressure and daemon status (text or JSON for widgets)
hogreaper status
hogreaper status --json

# Run daemon in the foreground
hogreaper daemon --dry-run
hogreaper daemon --interval 2

# One-shot mitigation: immediately scan and neutralize rogue hogs
hogreaper kill-hogs

# Manage systemd background service
hogreaper service install
hogreaper service status
hogreaper service restart
hogreaper service stop
hogreaper service uninstall
```

---

## ⚙️ Configuration (`~/.config/hogreaper/config.toml`)

- **RAM Thresholds:** `min_available_ram_mb = 800`, `min_available_ram_percent = 12.0`, `psi_memory_avg10_threshold = 25.0`, `single_process_rss_limit_mb = 3500`.
- **CPU Thresholds:** `cpu_hog_threshold_percent = 75.0`, `sustained_ticks = 4`.
- **Escalation Policy:** `throttle_action = "renice"`, `nice_level = 15`, `kill_signal = "sigterm"`, `escalate_to_sigkill = true`, `grace_period_secs = 3`.
- **Whitelist:** `protect_active_window = true`, `protect_child_processes_of_whitelisted = true`, custom processes list.
