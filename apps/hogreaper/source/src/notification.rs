use std::process::Command;

pub struct Notifier {
    enabled: bool,
}

impl Notifier {
    pub fn new(enabled: bool) -> Self {
        Self { enabled }
    }

    pub fn notify(&self, title: &str, body: &str, urgency: &str) {
        if !self.enabled {
            return;
        }

        let _ = Command::new("notify-send")
            .arg("--app-name=hogreaper")
            .arg(format!("--urgency={}", urgency))
            .arg("--icon=preferences-system-performance")
            .arg(title)
            .arg(body)
            .spawn();
    }

    pub fn notify_kill(&self, comm: &str, pid: u32, freed_mb: u64, reason: &str) {
        let title = "HogReaper: Process Terminated";
        let body = format!(
            "Terminated {} (PID {})\nFreed ~{} MB RAM\nReason: {}",
            comm, pid, freed_mb, reason
        );
        self.notify(title, &body, "normal");
    }

    pub fn notify_throttle(&self, comm: &str, pid: u32, cpu_pct: f32, action: &str) {
        let title = "HogReaper: Background CPU Throttled";
        let body = format!(
            "{} on {} (PID {})\nCPU was at {:.1}%",
            action, comm, pid, cpu_pct
        );
        self.notify(title, &body, "low");
    }
}
