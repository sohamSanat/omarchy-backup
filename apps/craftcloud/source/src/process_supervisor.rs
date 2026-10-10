use std::fs;
use std::os::unix::process::CommandExt;
use std::path::Path;
use std::process::Command;

#[derive(Clone, Debug)]
pub struct ProcessInfo {
    pub pid: u32,
    pub name: String,
    pub rss_mb: f32,
    pub cmdline: String,
}

pub struct ProcessSupervisor;

impl ProcessSupervisor {
    /// Non-blocking waitpid to reap any terminated child processes
    pub fn reap_zombies() {
        unsafe {
            let mut status = 0;
            while libc::waitpid(-1, &mut status, libc::WNOHANG) > 0 {}
        }
    }

    /// Checks if a process is genuinely alive (not a zombie 'Z' or dead 'X') and extracts its RSS
    fn is_process_alive_and_rss(pid_path: &Path) -> (bool, f32) {
        let status_path = pid_path.join("status");
        let content = match fs::read_to_string(status_path) {
            Ok(c) => c,
            Err(_) => return (false, 0.0),
        };

        let mut is_alive = false;
        let mut rss_mb = 0.0;

        for line in content.lines() {
            if line.starts_with("State:") {
                if let Some(state_char) = line.split_whitespace().nth(1).and_then(|s| s.chars().next()) {
                    // 'Z' = Zombie, 'X' = Dead. Only R, S, D, T are alive
                    is_alive = state_char != 'Z' && state_char != 'X';
                }
            } else if line.starts_with("VmRSS:") {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 2 {
                    if let Ok(kb) = parts[1].parse::<f32>() {
                        rss_mb = kb / 1024.0;
                    }
                }
            }
        }

        (is_alive, rss_mb)
    }

    /// Scans /proc to find all truly running Craft app processes
    pub fn scan_running() -> Vec<(String, ProcessInfo)> {
        Self::reap_zombies();

        let mut results = Vec::new();
        let proc_dir = Path::new("/proc");

        if let Ok(entries) = fs::read_dir(proc_dir) {
            for entry in entries.flatten() {
                let file_name = entry.file_name();
                let pid_str = file_name.to_string_lossy();
                if let Ok(pid) = pid_str.parse::<u32>() {
                    let pid_path = entry.path();

                    // Check process alive status: skip defunct/zombie processes completely!
                    let (is_alive, rss_mb) = Self::is_process_alive_and_rss(&pid_path);
                    if !is_alive {
                        continue;
                    }

                    let comm_path = pid_path.join("comm");
                    if let Ok(comm) = fs::read_to_string(comm_path) {
                        let comm_clean = comm.trim().to_string();
                        let app_id = match comm_clean.as_str() {
                            "photocraft" | "photocraft.real" => Some("photocraft"),
                            "vectorcraft" | "vectorcraft.real" => Some("vectorcraft"),
                            "filmcraft" | "filmcraft.real" => Some("filmcraft"),
                            "effectcraft" | "effectcraft.real" => Some("effectcraft"),
                            "lightcraft" | "lightcraft.real" => Some("lightcraft"),
                            "pdfcraft" | "pdfcraft.real" => Some("pdfcraft"),
                            "wordcraft" | "wordcraft.real" => Some("wordcraft"),
                            "gridcraft" | "gridcraft.real" => Some("gridcraft"),
                            "deckcraft" | "deckcraft.real" => Some("deckcraft"),
                            _ => None,
                        };

                        if let Some(id) = app_id {
                            let cmdline = fs::read_to_string(pid_path.join("cmdline"))
                                .unwrap_or_default()
                                .replace('\0', " ");

                            results.push((
                                id.to_string(),
                                ProcessInfo {
                                    pid,
                                    name: comm_clean,
                                    rss_mb,
                                    cmdline,
                                },
                            ));
                        }
                    }
                }
            }
        }
        results
    }

    /// Focus existing application window via Hyprland / Wayland IPC
    pub fn focus_window(wm_class: &str) -> bool {
        let clean_class = wm_class.trim_start_matches("ai.storyteller.").trim();
        let lua_eval = format!(
            "return hl.dispatch(hl.dsp.focus({{ window = \"class:.*{}.*\" }}))",
            clean_class
        );
        if let Ok(output) = Command::new("hyprctl").args(["eval", &lua_eval]).output() {
            if output.status.success() {
                return true;
            }
        }

        let legacy_eval = format!("hl.dsp.focus({{ window = \"class:.*{}.*\" }})", clean_class);
        if let Ok(output) = Command::new("hyprctl").args(["dispatch", &legacy_eval]).output() {
            if output.status.success() {
                return true;
            }
        }

        let _ = Command::new("wmctrl")
            .args(["-x", "-a", wm_class])
            .status();

        false
    }

    /// Finds the next available free workspace that currently has 0 windows open in it,
    /// strictly excluding the workspace where CraftCloud itself is running.
    pub fn find_next_free_workspace() -> Option<i32> {
        let current_pid = std::process::id() as i64;
        let mut craftcloud_ws = None;
        let mut occupied = std::collections::HashSet::new();

        // 1. Scan all active windows from Hyprland clients
        if let Ok(output) = Command::new("hyprctl").args(["clients", "-j"]).output() {
            if output.status.success() {
                if let Ok(val) = serde_json::from_slice::<serde_json::Value>(&output.stdout) {
                    if let Some(arr) = val.as_array() {
                        for client in arr {
                            let client_class = client.get("class").and_then(|v| v.as_str()).unwrap_or("");
                            let initial_class = client.get("initialClass").and_then(|v| v.as_str()).unwrap_or("");
                            let client_pid = client.get("pid").and_then(|v| v.as_i64());

                            if let Some(ws) = client.get("workspace") {
                                if let Some(id) = ws.get("id").and_then(|v| v.as_i64()) {
                                    let ws_id = id as i32;
                                    occupied.insert(ws_id);
                                    if client_class.contains("craftcloud")
                                        || initial_class.contains("craftcloud")
                                        || client_pid == Some(current_pid)
                                    {
                                        craftcloud_ws = Some(ws_id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Scan workspaces list for any workspace that has windows > 0
        if let Ok(output) = Command::new("hyprctl").args(["workspaces", "-j"]).output() {
            if output.status.success() {
                if let Ok(val) = serde_json::from_slice::<serde_json::Value>(&output.stdout) {
                    if let Some(arr) = val.as_array() {
                        for ws in arr {
                            let windows_count = ws.get("windows").and_then(|v| v.as_i64()).unwrap_or(0);
                            if windows_count > 0 {
                                if let Some(id) = ws.get("id").and_then(|v| v.as_i64()) {
                                    occupied.insert(id as i32);
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. Fallback for base workspace: prioritize detected CraftCloud workspace, else active workspace
        let active_id = Self::get_current_workspace_id().unwrap_or(1);
        let base_id = craftcloud_ws.unwrap_or(active_id);
        occupied.insert(base_id);
        occupied.insert(active_id);

        Some(Self::find_next_free_workspace_from(base_id, &occupied))
    }

    /// Pure helper to compute next free workspace given current ID and occupied IDs
    pub fn find_next_free_workspace_from(
        current_id: i32,
        occupied_workspaces: &std::collections::HashSet<i32>,
    ) -> i32 {
        // Search forward starting from current_id + 1 up to 10
        for cand in (current_id + 1)..=10 {
            if !occupied_workspaces.contains(&cand) {
                return cand;
            }
        }
        // Wrap around from workspace 1 up to current_id - 1
        for cand in 1..current_id {
            if !occupied_workspaces.contains(&cand) {
                return cand;
            }
        }
        // If all 1..10 are occupied, find lowest integer > 10
        let mut cand = 11;
        while occupied_workspaces.contains(&cand) {
            cand += 1;
        }
        cand
    }

    /// Helper to get current active workspace ID
    pub fn get_current_workspace_id() -> Option<i32> {
        let output = Command::new("hyprctl").args(["activeworkspace", "-j"]).output().ok()?;
        if output.status.success() {
            if let Ok(val) = serde_json::from_slice::<serde_json::Value>(&output.stdout) {
                if let Some(id) = val.get("id").and_then(|v| v.as_i64()) {
                    return Some(id as i32);
                }
            }
        }

        // Fallback to text parsing
        let output_text = Command::new("hyprctl").args(["activeworkspace"]).output().ok()?;
        let text = String::from_utf8_lossy(&output_text.stdout);
        for line in text.lines() {
            if line.contains("workspace ID") {
                for part in line.split_whitespace() {
                    if let Ok(id) = part.parse::<i32>() {
                        return Some(id);
                    }
                }
            }
        }

        None
    }

    /// Injects dynamic window rules into Hyprland so newly launched application windows
    /// map directly into `target_ws` upon creation, eliminating same-workspace split-screen.
    pub fn set_window_workspace_rule(app_id: &str, target_ws: i32) {
        let lua_code = format!(
            "local id = \"{app_id}\"; local ws = \"{target_ws}\"; \
             hl.window_rule({{ match = {{ class = \".*\" .. id .. \".*\" }}, workspace = ws }}); \
             hl.window_rule({{ match = {{ class = \"ai.storyteller.\" .. id }}, workspace = ws }}); \
             hl.window_rule({{ match = {{ class = id }}, workspace = ws }})"
        );
        let _ = Command::new("hyprctl").args(["eval", &lua_code]).status();
    }

    /// Switch active workspace via Hyprland Lua dispatcher with legacy fallback
    pub fn switch_to_workspace(ws_id: i32) -> bool {
        let lua_eval = format!(
            "return hl.dispatch(hl.dsp.focus({{ workspace = \"{}\" }}))",
            ws_id
        );
        if let Ok(output) = Command::new("hyprctl").args(["eval", &lua_eval]).output() {
            if output.status.success() {
                return true;
            }
        }

        let legacy_eval = format!("hl.dsp.focus({{ workspace = \"{}\" }})", ws_id);
        if let Ok(output) = Command::new("hyprctl").args(["dispatch", &legacy_eval]).output() {
            if output.status.success() {
                return true;
            }
        }

        let legacy_status = Command::new("hyprctl")
            .args(["dispatch", "workspace", &ws_id.to_string()])
            .status();

        if let Ok(s) = legacy_status {
            if s.success() {
                return true;
            }
        }

        false
    }

    /// Background watcher that verifies window location on target workspace and moves it if needed
    pub fn ensure_window_on_workspace(pid: u32, app_id: String, target_ws: i32) {
        std::thread::spawn(move || {
            let pid_i64 = pid as i64;
            for _ in 0..40 {
                std::thread::sleep(std::time::Duration::from_millis(60));

                let output = match Command::new("hyprctl").args(["clients", "-j"]).output() {
                    Ok(o) if o.status.success() => o,
                    _ => continue,
                };

                let val: serde_json::Value = match serde_json::from_slice(&output.stdout) {
                    Ok(v) => v,
                    _ => continue,
                };

                if let Some(arr) = val.as_array() {
                    for client in arr {
                        let client_pid = client.get("pid").and_then(|v| v.as_i64());
                        let client_class = client.get("class").and_then(|v| v.as_str()).unwrap_or("");
                        let client_initial_class = client.get("initialClass").and_then(|v| v.as_str()).unwrap_or("");
                        let client_address = client.get("address").and_then(|v| v.as_str()).unwrap_or("");

                        let is_match = client_pid == Some(pid_i64)
                            || client_class.contains(&app_id)
                            || client_initial_class.contains(&app_id);

                        if is_match {
                            let current_client_ws = client
                                .get("workspace")
                                .and_then(|w| w.get("id"))
                                .and_then(|id| id.as_i64())
                                .map(|id| id as i32);

                            if current_client_ws != Some(target_ws) {
                                // Move window via robust Lua script targeting the window's exact address
                                let lua_move = format!(
                                    "local wins = hl.get_windows(); \
                                     for _, w in ipairs(wins) do \
                                       if (w.address == \"{client_address}\") or (w.class and w.class:find(\"{app_id}\")) or w.pid == {pid} then \
                                         hl.dispatch(hl.dsp.focus({{ window = \"address:\" .. tostring(w.address) }})); \
                                         hl.dispatch(hl.dsp.window.move({{ workspace = \"{target_ws}\" }})); \
                                         hl.dispatch(hl.dsp.focus({{ workspace = \"{target_ws}\" }})); \
                                         break \
                                       end \
                                     end"
                                );
                                let _ = Command::new("hyprctl").args(["eval", &lua_move]).status();
                            }

                            Self::switch_to_workspace(target_ws);
                            return;
                        }
                    }
                }
            }
        });
    }

    /// Launch a Craft application in the next available free workspace that has 0 windows
    pub fn launch(
        binary_path: &Path,
        app_id: &str,
        demo_mode: bool,
        force_xwayland: bool,
        file_arg: Option<&str>,
    ) -> Result<(u32, Option<i32>), String> {
        // 1. Identify next available free workspace with 0 open windows
        let target_ws = Self::find_next_free_workspace();

        // 2. Pre-configure Hyprland window rule so the window opens into target_ws directly
        if let Some(ws) = target_ws {
            Self::set_window_workspace_rule(app_id, ws);
            Self::switch_to_workspace(ws);
        }

        let mut cmd = Command::new(binary_path);
        // Isolate into its own process group so all children can be killed cleanly
        cmd.process_group(0);

        if force_xwayland {
            match app_id {
                "photocraft" => { cmd.env("PHOTOCRAFT_FORCE_XWAYLAND", "1"); }
                "filmcraft" => { cmd.env("FILMCRAFT_FORCE_XWAYLAND", "1"); }
                "pdfcraft" => { cmd.env("PDFCRAFT_FORCE_XWAYLAND", "1"); }
                _ => {}
            }
        }

        if demo_mode && app_id == "lightcraft" {
            cmd.arg("--memory");
        }

        if let Some(file) = file_arg {
            cmd.arg(file);
        }

        match cmd.spawn() {
            Ok(child) => {
                let pid = child.id();
                // 3. Confirm window location on target workspace via background verification
                if let Some(ws) = target_ws {
                    Self::ensure_window_on_workspace(pid, app_id.to_string(), ws);
                }
                Ok((pid, target_ws))
            }
            Err(e) => Err(format!("Failed to launch {}: {}", binary_path.display(), e)),
        }
    }

    /// Terminate process and its entire process tree reliably
    pub fn terminate(pid: u32, force: bool) -> bool {
        if pid <= 1 {
            return false;
        }

        Self::reap_zombies();

        let pid_i32 = pid as libc::pid_t;
        let sig = if force { libc::SIGKILL } else { libc::SIGTERM };

        unsafe {
            // Signal target PID directly
            libc::kill(pid_i32, sig);
            // Signal target's process group as well in case wrapper script spawned children
            let _ = libc::kill(-pid_i32, sig);
        }

        // Give the process 60ms to exit cleanly, then reap zombies
        std::thread::sleep(std::time::Duration::from_millis(60));
        Self::reap_zombies();

        // If process did not exit with SIGTERM, escalate to SIGKILL
        let still_alive = unsafe { libc::kill(pid_i32, 0) == 0 };
        if still_alive {
            unsafe {
                libc::kill(pid_i32, libc::SIGKILL);
                let _ = libc::kill(-pid_i32, libc::SIGKILL);
            }
            std::thread::sleep(std::time::Duration::from_millis(30));
            Self::reap_zombies();
        }

        true
    }

    /// Terminate all running processes associated with an app ID
    pub fn terminate_app(app_id: &str, pid: u32, force: bool) {
        Self::terminate(pid, force);
        for (id, info) in Self::scan_running() {
            if id == app_id && info.pid != pid {
                Self::terminate(info.pid, force);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::process::Command;

    #[test]
    fn test_terminate_process_and_no_zombies() {
        // Spawn a dummy sleep process
        let child = Command::new("sleep")
            .arg("10")
            .spawn()
            .expect("failed to spawn sleep");

        let pid = child.id();
        assert!(pid > 0);

        let proc_path = std::path::PathBuf::from(format!("/proc/{}", pid));
        let (alive_before, _) = ProcessSupervisor::is_process_alive_and_rss(&proc_path);
        assert!(alive_before, "Process should be alive before termination");

        // Terminate via ProcessSupervisor
        let res = ProcessSupervisor::terminate(pid, false);
        assert!(res, "terminate should return true");

        // Process should no longer be alive in /proc
        let (alive_after, _) = ProcessSupervisor::is_process_alive_and_rss(&proc_path);
        assert!(!alive_after, "Process should NOT be alive or zombie after termination");
    }

    #[test]
    fn test_find_next_free_workspace_forward() {
        let mut occupied = std::collections::HashSet::new();
        occupied.insert(1); // current workspace where CraftCloud is
        occupied.insert(2); // workspace with existing window
        // Workspaces 3..10 are free with 0 windows
        let next_ws = ProcessSupervisor::find_next_free_workspace_from(1, &occupied);
        assert_eq!(next_ws, 3);
    }

    #[test]
    fn test_find_next_free_workspace_skips_occupied() {
        let mut occupied = std::collections::HashSet::new();
        occupied.insert(2); // current workspace
        occupied.insert(3); // occupied
        occupied.insert(4); // occupied
        // Workspace 5 is free
        let next_ws = ProcessSupervisor::find_next_free_workspace_from(2, &occupied);
        assert_eq!(next_ws, 5);
    }

    #[test]
    fn test_find_next_free_workspace_wrap_around() {
        let mut occupied = std::collections::HashSet::new();
        occupied.insert(5); // current workspace
        for i in 6..=10 {
            occupied.insert(i); // all 6..10 occupied
        }
        occupied.insert(2); // 2 occupied
        // Workspace 1 is free
        let next_ws = ProcessSupervisor::find_next_free_workspace_from(5, &occupied);
        assert_eq!(next_ws, 1);
    }

    #[test]
    fn test_find_next_free_workspace_overflow_past_10() {
        let mut occupied = std::collections::HashSet::new();
        for i in 1..=10 {
            occupied.insert(i);
        }
        let next_ws = ProcessSupervisor::find_next_free_workspace_from(1, &occupied);
        assert_eq!(next_ws, 11);
    }

    #[test]
    fn test_find_next_free_workspace_live() {
        let curr_ws = ProcessSupervisor::get_current_workspace_id();
        if let Some(curr) = curr_ws {
            let free_ws = ProcessSupervisor::find_next_free_workspace();
            assert!(free_ws.is_some());
            let target = free_ws.unwrap();
            // Crucial requirement: MUST NOT open in the same workspace!
            assert_ne!(target, curr, "Target workspace MUST NOT be the current workspace");
        }
    }

    #[test]
    fn test_launch_live() {
        let bin_path = std::path::Path::new("/home/soham/.local/bin/pdfcraft");
        if bin_path.exists() {
            let curr = ProcessSupervisor::get_current_workspace_id().unwrap_or(1);
            let launch_res = ProcessSupervisor::launch(bin_path, "pdfcraft", false, false, None);
            assert!(launch_res.is_ok());
            let (pid, target_ws) = launch_res.unwrap();
            assert!(pid > 0);
            assert!(target_ws.is_some());
            let ws = target_ws.unwrap();
            println!("\n[LIVE TEST] Current WS: {}, Target WS: {}, Launched PID: {}", curr, ws, pid);
            assert_ne!(ws, curr, "App must NOT open in the same workspace!");

            // Sleep a moment to let window map and verify
            std::thread::sleep(std::time::Duration::from_millis(800));

            // Verify window's actual workspace via hyprctl clients
            if let Ok(out) = std::process::Command::new("hyprctl").args(["clients", "-j"]).output() {
                if let Ok(val) = serde_json::from_slice::<serde_json::Value>(&out.stdout) {
                    if let Some(arr) = val.as_array() {
                        let client = arr.iter().find(|c| {
                            c.get("pid").and_then(|p| p.as_i64()) == Some(pid as i64)
                                || c.get("class").and_then(|cls| cls.as_str()).map(|s| s.contains("pdfcraft")).unwrap_or(false)
                        });
                        if let Some(c) = client {
                            let actual_ws = c.get("workspace").and_then(|w| w.get("id")).and_then(|i| i.as_i64()).map(|i| i as i32);
                            println!("[LIVE TEST] Window mapped! Actual WS: {:?}", actual_ws);
                            assert_eq!(actual_ws, Some(ws), "Window must be on target free workspace");
                        }
                    }
                }
            }

            // Clean up
            ProcessSupervisor::terminate_app("pdfcraft", pid, true);
        }
    }
}
