mod config;
mod display;
mod governor;
mod hyprland;
mod notification;
mod procfs;
mod safety;
mod service;

use clap::{Parser, Subcommand};
use std::env;
use std::thread::sleep;
use std::time::Duration;

use crate::config::AppConfig;
use crate::governor::Governor;
use crate::hyprland::HyprlandIpc;
use crate::service::ServiceManager;

#[derive(Parser)]
#[command(
    name = "hogreaper",
    about = "Zero-overhead RAM and CPU hardware governor for Omarchy Linux",
    version = "0.1.0"
)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Run the continuous hardware governor daemon
    Daemon {
        /// Run in dry-run mode (log decisions without signaling processes)
        #[arg(long)]
        dry_run: bool,

        /// Custom polling interval in seconds
        #[arg(long, short)]
        interval: Option<u64>,
    },

    /// Scan system once and report memory, CPU pressure, and rogue hogs
    Scan,

    /// Live real-time terminal dashboard
    Top,

    /// One-shot mitigation: scan and immediately reap/throttle detected hogs
    KillHogs {
        /// Dry run simulation
        #[arg(long)]
        dry_run: bool,
    },

    /// Show quick system hardware pressure and daemon status
    Status {
        /// Output status as compact JSON for status bar plugins
        #[arg(long)]
        json: bool,
    },

    /// Print or manage configuration
    Config {
        /// Reset configuration file to factory defaults
        #[arg(long)]
        reset: bool,
    },

    /// Manage systemd user background service
    Service {
        #[command(subcommand)]
        action: ServiceAction,
    },
}

#[derive(Subcommand)]
enum ServiceAction {
    /// Install and enable hogreaper systemd user service
    Install,
    /// Uninstall and disable hogreaper systemd user service
    Uninstall,
    /// Check systemd user service status
    Status,
    /// Restart systemd user service
    Restart,
    /// Stop systemd user service
    Stop,
}

fn main() {
    let cli = Cli::parse();
    let (mut config, config_path) = AppConfig::load_or_create();

    match cli.command {
        Some(Commands::Daemon { dry_run, interval }) => {
            if dry_run {
                config.general.dry_run = true;
            }
            if let Some(secs) = interval {
                config.general.poll_interval_secs = secs;
            }

            println!(
                "Starting HogReaper Governor Daemon (Interval: {}s, DryRun: {})...",
                config.general.poll_interval_secs, config.general.dry_run
            );

            let mut gov = Governor::new(config);
            let poll_duration = Duration::from_secs(gov.config.general.poll_interval_secs);

            loop {
                let (_, _, _, decisions) = gov.evaluate_cycle();
                if !decisions.is_empty() {
                    gov.execute_decisions(&decisions);
                }
                sleep(poll_duration);
            }
        }

        Some(Commands::Scan) => {
            let mut gov = Governor::new(config);
            // Run two fast cycles separated by 100ms to seed CPU usage delta
            let _ = gov.evaluate_cycle();
            sleep(Duration::from_millis(150));
            let (mem, psi_mem, psi_cpu, decisions) = gov.evaluate_cycle();
            let procs = gov.evaluate_top_processes(10);
            let active_win = HyprlandIpc::new().get_active_window();

            display::render_scan(&mem, &psi_mem, &psi_cpu, &procs, &decisions, active_win.as_ref());
        }

        Some(Commands::Top) => {
            let mut gov = Governor::new(config);
            display::run_top(&mut gov);
        }

        Some(Commands::KillHogs { dry_run }) => {
            if dry_run {
                config.general.dry_run = true;
            }
            let mut gov = Governor::new(config);
            println!("Scanning for runaway hardware hogs...");
            let _ = gov.evaluate_cycle();
            sleep(Duration::from_millis(200));
            let (mem, _, _, decisions) = gov.evaluate_cycle();

            if decisions.is_empty() {
                println!(
                    "No rogue hogs found. Memory available: {} MB ({:.1}%). System is smooth.",
                    mem.available_mb(),
                    mem.available_percent()
                );
            } else {
                println!("Mitigating {} flagged process(es)...", decisions.len());
                gov.execute_decisions(&decisions);
            }
        }

        Some(Commands::Status { json }) => {
            let mut gov = Governor::new(config);
            let (mem, psi_mem, psi_cpu, _) = gov.evaluate_cycle();
            let active_win = HyprlandIpc::new().get_active_window();
            let is_daemon_active = std::process::Command::new("systemctl")
                .args(["--user", "is-active", "--quiet", "hogreaper.service"])
                .status()
                .map(|s| s.success())
                .unwrap_or(false);

            if json {
                #[derive(serde::Serialize)]
                struct StatusJson {
                    ram_used_mb: u64,
                    ram_total_mb: u64,
                    ram_available_mb: u64,
                    ram_used_percent: f32,
                    swap_used_mb: u64,
                    swap_total_mb: u64,
                    swap_used_percent: f32,
                    psi_memory_avg10: f32,
                    psi_cpu_avg10: f32,
                    active_app: Option<String>,
                    active_pid: Option<u32>,
                    daemon_active: bool,
                }

                let payload = StatusJson {
                    ram_used_mb: mem.used_mb(),
                    ram_total_mb: mem.total_mb(),
                    ram_available_mb: mem.available_mb(),
                    ram_used_percent: mem.used_percent(),
                    swap_used_mb: mem.swap_used_mb(),
                    swap_total_mb: mem.swap_total_mb(),
                    swap_used_percent: mem.swap_used_percent(),
                    psi_memory_avg10: psi_mem.some_avg10,
                    psi_cpu_avg10: psi_cpu.some_avg10,
                    active_app: active_win.as_ref().and_then(|w| w.class.clone()),
                    active_pid: active_win.as_ref().and_then(|w| w.pid),
                    daemon_active: is_daemon_active,
                };

                println!("{}", serde_json::to_string(&payload).unwrap_or_default());
            } else {
                let p = display::ThemePalette::detect();

                println!("{}", p.accent_blue("󰍛 HogReaper Status Summary"));
                println!(
                    "  RAM:       {:.1}% used ({} MB avail / {} MB total)",
                    mem.used_percent(),
                    mem.available_mb(),
                    mem.total_mb()
                );
                println!(
                    "  PSI Mem:   some avg10={:.2} avg60={:.2}",
                    psi_mem.some_avg10, psi_mem.some_avg60
                );
                println!(
                    "  PSI CPU:   some avg10={:.2} avg60={:.2}",
                    psi_cpu.some_avg10, psi_cpu.some_avg60
                );
                println!("  Config:    {}", config_path.display());
                let _ = ServiceManager::status();
            }
        }

        Some(Commands::Config { reset }) => {
            if reset {
                let default_cfg = AppConfig::default();
                if let Err(e) = default_cfg.save(&config_path) {
                    eprintln!("Failed to reset config: {}", e);
                } else {
                    println!("Configuration reset to factory defaults at {}", config_path.display());
                }
            } else {
                println!("# Configuration: {}", config_path.display());
                if let Ok(content) = std::fs::read_to_string(&config_path) {
                    println!("{}", content);
                }
            }
        }

        Some(Commands::Service { action }) => match action {
            ServiceAction::Install => {
                let current_exe = env::current_exe()
                    .unwrap_or_else(|_| std::path::PathBuf::from("hogreaper"));
                let bin_str = current_exe.to_string_lossy();
                let target_bin = if bin_str.contains("/target/") {
                    // If in build target, recommend ~/.local/bin/hogreaper
                    let home = env::var("HOME").unwrap_or_else(|_| ".".to_string());
                    format!("{}/.local/bin/hogreaper", home)
                } else {
                    bin_str.to_string()
                };

                if let Err(e) = ServiceManager::install(&target_bin) {
                    eprintln!("Error installing service: {}", e);
                }
            }
            ServiceAction::Uninstall => {
                if let Err(e) = ServiceManager::uninstall() {
                    eprintln!("Error uninstalling service: {}", e);
                }
            }
            ServiceAction::Status => {
                let _ = ServiceManager::status();
            }
            ServiceAction::Restart => {
                let _ = ServiceManager::restart();
            }
            ServiceAction::Stop => {
                let _ = ServiceManager::stop();
            }
        },

        None => {
            // Default when invoked with no arguments: show scan
            let mut gov = Governor::new(config);
            let _ = gov.evaluate_cycle();
            sleep(Duration::from_millis(150));
            let (mem, psi_mem, psi_cpu, decisions) = gov.evaluate_cycle();
            let procs = gov.evaluate_top_processes(10);
            let active_win = HyprlandIpc::new().get_active_window();

            display::render_scan(&mem, &psi_mem, &psi_cpu, &procs, &decisions, active_win.as_ref());
        }
    }
}
