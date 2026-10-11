use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub general: GeneralConfig,
    pub memory: MemoryPolicy,
    pub cpu: CpuPolicy,
    pub escalation: EscalationPolicy,
    pub whitelist: WhitelistConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GeneralConfig {
    pub poll_interval_secs: u64,
    pub dry_run: bool,
    pub enable_notifications: bool,
    pub log_actions: bool,
}

impl Default for GeneralConfig {
    fn default() -> Self {
        Self {
            poll_interval_secs: 2,
            dry_run: false,
            enable_notifications: true,
            log_actions: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryPolicy {
    /// Trigger mitigation when available RAM drops below this (MB)
    pub min_available_ram_mb: u64,
    /// Trigger mitigation when available RAM drops below this percentage
    pub min_available_ram_percent: f32,
    /// Memory Pressure Stall Information avg10 threshold
    pub psi_memory_avg10_threshold: f32,
    /// Single process RSS limit in MB (e.g. runaway tab)
    pub single_process_rss_limit_mb: u64,
}

impl Default for MemoryPolicy {
    fn default() -> Self {
        Self {
            min_available_ram_mb: 800,
            min_available_ram_percent: 12.0,
            psi_memory_avg10_threshold: 25.0,
            single_process_rss_limit_mb: 3500,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CpuPolicy {
    /// Background process CPU percentage threshold
    pub cpu_hog_threshold_percent: f32,
    /// Number of consecutive polling cycles a process must exceed threshold to be flagged
    pub sustained_ticks: u32,
}

impl Default for CpuPolicy {
    fn default() -> Self {
        Self {
            cpu_hog_threshold_percent: 75.0,
            sustained_ticks: 4, // e.g. 4 ticks * 2s = 8 seconds
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EscalationPolicy {
    /// Action for CPU hogs: "renice" (nice +15) or "freeze" (SIGSTOP)
    pub throttle_action: String,
    /// Nice priority value (1 to 19)
    pub nice_level: i32,
    /// Signal for memory hogs: "sigterm"
    pub kill_signal: String,
    /// Whether to escalate to SIGKILL if SIGTERM fails after grace period
    pub escalate_to_sigkill: bool,
    /// Grace period in seconds between SIGTERM and SIGKILL
    pub grace_period_secs: u64,
}

impl Default for EscalationPolicy {
    fn default() -> Self {
        Self {
            throttle_action: "renice".to_string(),
            nice_level: 15,
            kill_signal: "sigterm".to_string(),
            escalate_to_sigkill: true,
            grace_period_secs: 3,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WhitelistConfig {
    pub protect_active_window: bool,
    pub protect_child_processes_of_whitelisted: bool,
    /// Additional user-defined process comm names or regexes to protect
    pub processes: Vec<String>,
}

impl Default for WhitelistConfig {
    fn default() -> Self {
        Self {
            protect_active_window: true,
            protect_child_processes_of_whitelisted: true,
            processes: vec![
                "steam".to_string(),
                "gamescope".to_string(),
                "obs".to_string(),
                "ffmpeg".to_string(),
            ],
        }
    }
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            general: GeneralConfig::default(),
            memory: MemoryPolicy::default(),
            cpu: CpuPolicy::default(),
            escalation: EscalationPolicy::default(),
            whitelist: WhitelistConfig::default(),
        }
    }
}

impl AppConfig {
    pub fn config_path() -> PathBuf {
        dirs_config_path().join("hogreaper").join("config.toml")
    }

    pub fn load_or_create() -> (Self, PathBuf) {
        let path = Self::config_path();
        if path.exists() {
            if let Ok(content) = fs::read_to_string(&path) {
                if let Ok(cfg) = toml::from_str::<AppConfig>(&content) {
                    return (cfg, path);
                }
            }
        }

        // Create default config
        let cfg = AppConfig::default();
        if let Some(parent) = path.parent() {
            let _ = fs::create_dir_all(parent);
        }
        if let Ok(serialized) = toml::to_string_pretty(&cfg) {
            let _ = fs::write(&path, serialized);
        }
        (cfg, path)
    }

    pub fn save(&self, path: &Path) -> std::io::Result<()> {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        let serialized = toml::to_string_pretty(self)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))?;
        let mut file = File::create(path)?;
        file.write_all(serialized.as_bytes())?;
        Ok(())
    }
}

fn dirs_config_path() -> PathBuf {
    if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
        PathBuf::from(xdg)
    } else if let Ok(home) = std::env::var("HOME") {
        PathBuf::from(home).join(".config")
    } else {
        PathBuf::from(".config")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config_serialization() {
        let cfg = AppConfig::default();
        let serialized = toml::to_string_pretty(&cfg).expect("serialize config");
        assert!(serialized.contains("min_available_ram_mb = 800"));
        let deserialized: AppConfig = toml::from_str(&serialized).expect("deserialize config");
        assert_eq!(deserialized.general.poll_interval_secs, 2);
    }
}
