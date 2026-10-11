use std::collections::HashSet;
use crate::config::AppConfig;
use crate::procfs::ProcessSnapshot;

pub struct SafetyEngine {
    core_whitelist: HashSet<&'static str>,
    custom_whitelist: Vec<String>,
    self_pid: u32,
    my_uid: u32,
}

impl SafetyEngine {
    pub fn new(config: &AppConfig) -> Self {
        let self_pid = std::process::id();
        let my_uid = unsafe { libc::getuid() };

        let mut core = HashSet::new();

        // 1. Core init and system services
        core.insert("systemd");
        core.insert("init");
        core.insert("systemd-journald");
        core.insert("systemd-logind");
        core.insert("systemd-udevd");
        core.insert("systemd-oomd");
        core.insert("systemd-resolved");
        core.insert("dbus-daemon");
        core.insert("dbus-broker");
        core.insert("dbus-broker-launch");
        core.insert("polkitd");
        core.insert("seatd");
        core.insert("elogind");

        // 2. Wayland compositor & desktop components
        core.insert("Hyprland");
        core.insert("hyprland");
        core.insert("Xwayland");
        core.insert("quickshell");
        core.insert("waybar");
        core.insert("hyprpaper");
        core.insert("hyprsunset");
        core.insert("hyprlock");
        core.insert("hypridle");
        core.insert("xdg-desktop-portal");
        core.insert("xdg-desktop-portal-hyprland");
        core.insert("xdg-desktop-portal-gtk");
        core.insert("mako");
        core.insert("dunst");

        // 3. Audio infrastructure
        core.insert("pipewire");
        core.insert("pipewire-pulse");
        core.insert("wireplumber");
        core.insert("easyeffects");

        // 4. Terminals & multiplexers
        core.insert("ghostty");
        core.insert("kitty");
        core.insert("alacritty");
        core.insert("foot");
        core.insert("tmux");
        core.insert("zellij");
        core.insert("herdr");

        // 5. User shells
        core.insert("bash");
        core.insert("zsh");
        core.insert("fish");
        core.insert("sh");

        // 6. Active editors & Agentic runtime
        core.insert("hogreaper");
        core.insert("agy-real");
        core.insert("antigravity");
        core.insert("antigravity-app");
        core.insert("agy");
        core.insert("opencode");
        core.insert("code");
        core.insert("code-oss");
        core.insert("cursor");
        core.insert("nvim");
        core.insert("vim");
        core.insert("helix");
        core.insert("ssh");
        core.insert("sshd");
        core.insert("git");
        core.insert("cargo");
        core.insert("rustc");

        // 7. Core hardware & networking
        core.insert("udiskie");
        core.insert("kdeconnectd");
        core.insert("NetworkManager");
        core.insert("wpa_supplicant");
        core.insert("bluetoothd");

        Self {
            core_whitelist: core,
            custom_whitelist: config.whitelist.processes.clone(),
            self_pid,
            my_uid,
        }
    }

    /// Check if a process is protected from being reaped or throttled
    pub fn is_protected(
        &self,
        process: &ProcessSnapshot,
        active_window_pid: Option<u32>,
        all_processes: &[ProcessSnapshot],
    ) -> bool {
        // Rule 0: Never touch PID 0 or PID 1
        if process.pid <= 1 {
            return true;
        }

        // Rule 1: Self protection (hogreaper or self tree)
        if process.pid == self.self_pid {
            return true;
        }

        // Rule 2: Cannot/should not kill root processes if running as non-root user
        if self.my_uid != 0 && process.uid == 0 {
            return true;
        }

        // Rule 3: Kernel threads (cmdline starts with [ and ends with ])
        if process.cmdline.starts_with('[') && process.cmdline.ends_with(']') && process.rss_bytes == 0 {
            return true;
        }

        // Rule 4: Active window PID (or its process tree)
        if let Some(active_pid) = active_window_pid {
            if process.pid == active_pid || self.is_descendant_of(process.pid, active_pid, all_processes) {
                return true;
            }
        }

        // Rule 5: Core immutable whitelist
        if self.core_whitelist.contains(process.comm.as_str()) {
            return true;
        }

        // Rule 6: Custom user whitelist
        let comm_lower = process.comm.to_lowercase();
        let cmdline_lower = process.cmdline.to_lowercase();
        for item in &self.custom_whitelist {
            let item_lower = item.to_lowercase();
            if comm_lower.contains(&item_lower) || cmdline_lower.contains(&item_lower) {
                return true;
            }
        }

        // Rule 7: Direct children of interactive shells (avoid killing active running CLI tools)
        if self.is_child_of_shell(process, all_processes) {
            return true;
        }

        false
    }

    /// Check if process is a child or grandchild of an interactive shell
    fn is_child_of_shell(&self, process: &ProcessSnapshot, all_procs: &[ProcessSnapshot]) -> bool {
        let shells = ["bash", "zsh", "fish"];
        let mut curr_ppid = process.ppid;
        for _ in 0..2 {
            if curr_ppid <= 1 {
                break;
            }
            if let Some(parent) = all_procs.iter().find(|p| p.pid == curr_ppid) {
                if shells.contains(&parent.comm.as_str()) {
                    return true;
                }
                curr_ppid = parent.ppid;
            } else {
                break;
            }
        }
        false
    }

    /// Check if pid is a descendant of ancestor_pid
    fn is_descendant_of(&self, pid: u32, ancestor_pid: u32, all_procs: &[ProcessSnapshot]) -> bool {
        if pid == ancestor_pid {
            return true;
        }
        let mut curr_pid = pid;
        // Bound loop to avoid cycles
        for _ in 0..10 {
            if let Some(proc) = all_procs.iter().find(|p| p.pid == curr_pid) {
                if proc.ppid == ancestor_pid {
                    return true;
                }
                if proc.ppid <= 1 {
                    break;
                }
                curr_pid = proc.ppid;
            } else {
                break;
            }
        }
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn dummy_proc(pid: u32, ppid: u32, comm: &str) -> ProcessSnapshot {
        ProcessSnapshot {
            pid,
            ppid,
            uid: 1000,
            comm: comm.to_string(),
            cmdline: comm.to_string(),
            state: 'S',
            rss_bytes: 1024 * 1024 * 100,
            nice: 0,
            num_threads: 1,
            utime: 100,
            stime: 100,
            cpu_percent: 0.0,
        }
    }

    #[test]
    fn test_core_protection() {
        let cfg = AppConfig::default();
        let engine = SafetyEngine::new(&cfg);
        let procs = vec![
            dummy_proc(1, 0, "systemd"),
            dummy_proc(100, 1, "Hyprland"),
            dummy_proc(101, 100, "ghostty"),
            dummy_proc(500, 1, "node_rogue_server"),
        ];

        assert!(engine.is_protected(&procs[0], None, &procs));
        assert!(engine.is_protected(&procs[1], None, &procs));
        assert!(engine.is_protected(&procs[2], None, &procs));
        assert!(!engine.is_protected(&procs[3], None, &procs));
    }

    #[test]
    fn test_active_window_protection() {
        let cfg = AppConfig::default();
        let engine = SafetyEngine::new(&cfg);
        let procs = vec![
            dummy_proc(200, 1, "zen"),
            dummy_proc(201, 200, "Isolated Web Co"),
            dummy_proc(300, 1, "bad_miner"),
        ];

        assert!(engine.is_protected(&procs[0], Some(200), &procs));
        assert!(engine.is_protected(&procs[1], Some(200), &procs));
        assert!(!engine.is_protected(&procs[2], Some(200), &procs));
    }
}
