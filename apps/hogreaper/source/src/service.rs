use std::env;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

pub struct ServiceManager;

impl ServiceManager {
    pub fn service_file_path() -> PathBuf {
        let home = env::var("HOME").unwrap_or_else(|_| ".".to_string());
        PathBuf::from(home)
            .join(".config")
            .join("systemd")
            .join("user")
            .join("hogreaper.service")
    }

    pub fn install(binary_path: &str) -> std::io::Result<()> {
        let path = Self::service_file_path();
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }

        let service_content = format!(
            r#"[Unit]
Description=HogReaper Zero-Overhead Hardware Governor
Documentation=https://github.com/omarchy/hogreaper
After=default.target

[Service]
Type=simple
ExecStart={} daemon
Restart=always
RestartSec=3
Nice=-5
MemoryHigh=50M
MemoryMax=80M
CPUWeight=100

[Install]
WantedBy=default.target
"#,
            binary_path
        );

        fs::write(&path, service_content)?;
        println!("Service unit written to {}", path.display());

        let _ = Command::new("systemctl")
            .args(["--user", "daemon-reload"])
            .status();

        let enable_status = Command::new("systemctl")
            .args(["--user", "enable", "--now", "hogreaper.service"])
            .status()?;

        if enable_status.success() {
            println!("HogReaper service successfully enabled and started in user systemd!");
        } else {
            eprintln!("Failed to enable/start user systemd service.");
        }

        Ok(())
    }

    pub fn uninstall() -> std::io::Result<()> {
        let _ = Command::new("systemctl")
            .args(["--user", "disable", "--now", "hogreaper.service"])
            .status();

        let path = Self::service_file_path();
        if path.exists() {
            fs::remove_file(&path)?;
            println!("Removed service file {}", path.display());
        }

        let _ = Command::new("systemctl")
            .args(["--user", "daemon-reload"])
            .status();

        println!("HogReaper service uninstalled.");
        Ok(())
    }

    pub fn status() -> std::io::Result<()> {
        let status = Command::new("systemctl")
            .args(["--user", "status", "hogreaper.service"])
            .status()?;
        if !status.success() {
            println!("Service is inactive or not found.");
        }
        Ok(())
    }

    pub fn restart() -> std::io::Result<()> {
        let status = Command::new("systemctl")
            .args(["--user", "restart", "hogreaper.service"])
            .status()?;
        if status.success() {
            println!("HogReaper service restarted.");
        }
        Ok(())
    }

    pub fn stop() -> std::io::Result<()> {
        let status = Command::new("systemctl")
            .args(["--user", "stop", "hogreaper.service"])
            .status()?;
        if status.success() {
            println!("HogReaper service stopped.");
        }
        Ok(())
    }
}
