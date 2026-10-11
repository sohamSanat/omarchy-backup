use serde::Deserialize;
use std::env;
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::process::Command;

#[derive(Debug, Deserialize, Clone)]
pub struct ActiveWindow {
    pub pid: Option<u32>,
    pub class: Option<String>,
    pub title: Option<String>,
}

pub struct HyprlandIpc {
    socket_path: Option<PathBuf>,
}

impl HyprlandIpc {
    pub fn new() -> Self {
        let socket_path = match (env::var("XDG_RUNTIME_DIR"), env::var("HYPRLAND_INSTANCE_SIGNATURE")) {
            (Ok(runtime_dir), Ok(sig)) => {
                let p = PathBuf::from(runtime_dir).join("hypr").join(sig).join(".socket.sock");
                if p.exists() {
                    Some(p)
                } else {
                    None
                }
            }
            _ => None,
        };

        Self { socket_path }
    }

    /// Query active window from Hyprland via direct UNIX domain socket (or hyprctl fallback)
    pub fn get_active_window(&self) -> Option<ActiveWindow> {
        // Fast path: direct UNIX socket
        if let Some(ref path) = self.socket_path {
            if let Ok(mut stream) = UnixStream::connect(path) {
                // Hyprland IPC format: "j/activewindow"
                if stream.write_all(b"j/activewindow").is_ok() {
                    let mut buffer = Vec::new();
                    if stream.read_to_end(&mut buffer).is_ok() {
                        if let Ok(window) = serde_json::from_slice::<ActiveWindow>(&buffer) {
                            return Some(window);
                        }
                    }
                }
            }
        }

        // Fallback: hyprctl command
        if let Ok(output) = Command::new("hyprctl")
            .args(["activewindow", "-j"])
            .output()
        {
            if output.status.success() {
                if let Ok(window) = serde_json::from_slice::<ActiveWindow>(&output.stdout) {
                    return Some(window);
                }
            }
        }

        None
    }

    /// Returns active window PID if available and > 0
    pub fn get_active_pid(&self) -> Option<u32> {
        self.get_active_window().and_then(|w| w.pid).filter(|&p| p > 0)
    }
}
