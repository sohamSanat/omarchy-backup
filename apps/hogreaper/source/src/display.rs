use std::env;
use std::io::{stdout, Write};
use std::thread::sleep;
use std::time::Duration;

use crate::governor::{Decision, Governor};
use crate::hyprland::ActiveWindow;
use crate::procfs::{MemInfo, ProcessSnapshot, PsiMetrics};

pub struct ThemePalette {
    pub is_light: bool,
}

impl ThemePalette {
    pub fn detect() -> Self {
        let is_light = if let Ok(mode) = env::var("OMARCHY_THEME_MODE") {
            mode.to_lowercase() == "light"
        } else if let Ok(colorfgbg) = env::var("COLORFGBG") {
            colorfgbg.starts_with("0;")
        } else {
            false
        };

        Self { is_light }
    }

    pub fn text(&self, s: &str) -> String {
        if self.is_light {
            format!("\x1b[38;5;235m{}\x1b[0m", s)
        } else {
            format!("\x1b[37m{}\x1b[0m", s)
        }
    }

    pub fn muted(&self, s: &str) -> String {
        if self.is_light {
            format!("\x1b[38;5;240m{}\x1b[0m", s)
        } else {
            format!("\x1b[90m{}\x1b[0m", s)
        }
    }

    pub fn bold(&self, s: &str) -> String {
        if self.is_light {
            format!("\x1b[1;38;5;235m{}\x1b[0m", s)
        } else {
            format!("\x1b[1;37m{}\x1b[0m", s)
        }
    }

    pub fn accent_blue(&self, s: &str) -> String {
        if self.is_light {
            format!("\x1b[1;38;5;25m{}\x1b[0m", s)
        } else {
            format!("\x1b[1;36m{}\x1b[0m", s)
        }
    }

    pub fn accent_green(&self, s: &str) -> String {
        if self.is_light {
            format!("\x1b[1;38;5;28m{}\x1b[0m", s)
        } else {
            format!("\x1b[1;32m{}\x1b[0m", s)
        }
    }

    pub fn accent_yellow(&self, s: &str) -> String {
        if self.is_light {
            format!("\x1b[1;38;5;166m{}\x1b[0m", s)
        } else {
            format!("\x1b[1;33m{}\x1b[0m", s)
        }
    }

    pub fn accent_red(&self, s: &str) -> String {
        if self.is_light {
            format!("\x1b[1;38;5;160m{}\x1b[0m", s)
        } else {
            format!("\x1b[1;31m{}\x1b[0m", s)
        }
    }

    pub fn bar(&self, percent: f32, width: usize) -> String {
        let filled = ((percent / 100.0) * width as f32).round() as usize;
        let filled = filled.min(width);
        let empty = width.saturating_sub(filled);

        let color = if percent > 85.0 {
            self.accent_red("█")
        } else if percent > 65.0 {
            self.accent_yellow("█")
        } else {
            self.accent_green("█")
        };

        let empty_char = if self.is_light { "░" } else { "░" };
        let mut bar_str = String::new();
        for _ in 0..filled {
            bar_str.push_str(&color);
        }
        bar_str.push_str(&self.muted(&empty_char.repeat(empty)));
        bar_str
    }
}

pub fn render_scan(
    mem: &MemInfo,
    psi_mem: &PsiMetrics,
    psi_cpu: &PsiMetrics,
    top_procs: &[ProcessSnapshot],
    decisions: &[Decision],
    active_win: Option<&ActiveWindow>,
) {
    let p = ThemePalette::detect();

    println!("{}", p.accent_blue("━".repeat(60).as_str()));
    println!(
        "{} {}",
        p.accent_blue("󰍛 HogReaper Hardware Governor"),
        p.muted("[Zero-Overhead RAM & CPU Shield]")
    );
    println!("{}", p.accent_blue("━".repeat(60).as_str()));

    // Memory Overview
    let mem_used_pct = mem.used_percent();
    let mem_bar = p.bar(mem_used_pct, 20);
    println!(
        "{}  [{}] {:.1}% ({} MB / {} MB, Avail: {})",
        p.bold("RAM Usage:     "),
        mem_bar,
        mem_used_pct,
        mem.used_mb(),
        mem.total_mb(),
        p.accent_green(&format!("{} MB", mem.available_mb()))
    );

    // Swap Overview
    if mem.swap_total_mb() > 0 {
        let swap_pct = mem.swap_used_percent();
        let swap_bar = p.bar(swap_pct, 20);
        println!(
            "{} [{}] {:.1}% ({} MB / {} MB)",
            p.bold("Swap Usage:    "),
            swap_bar,
            swap_pct,
            mem.swap_used_mb(),
            mem.swap_total_mb()
        );
    }

    // Kernel PSI
    println!(
        "{} PSI Memory: some avg10={:.2} avg60={:.2} | CPU: some avg10={:.2}",
        p.bold("Pressure Stall:"),
        psi_mem.some_avg10,
        psi_mem.some_avg60,
        psi_cpu.some_avg10
    );

    // Active Window
    if let Some(win) = active_win {
        let app = win.class.as_deref().unwrap_or("unknown");
        let title = win.title.as_deref().unwrap_or("");
        let pid_str = win.pid.map(|n| n.to_string()).unwrap_or_else(|| "?".to_string());
        println!(
            "{} {} (PID {}) - {}",
            p.bold("Active Window: "),
            p.accent_green(app),
            pid_str,
            p.muted(&title.chars().take(35).collect::<String>())
        );
    }

    println!();
    println!("{}", p.bold("Top Memory Consumers:"));
    println!(
        "{}",
        p.muted(&format!(
            "  {:<8} {:<18} {:<10} {:<8} {:<8}",
            "PID", "COMM", "RSS", "CPU%", "NICE"
        ))
    );
    println!("  {}", p.muted("─".repeat(54).as_str()));

    for proc in top_procs.iter().take(8) {
        println!(
            "  {:<8} {:<18} {:<10} {:<8.1} {:<8}",
            proc.pid,
            proc.comm.chars().take(17).collect::<String>(),
            format!("{} MB", proc.rss_mb()),
            proc.cpu_percent,
            proc.nice
        );
    }

    println!();
    if decisions.is_empty() {
        println!(
            "{} {}",
            p.accent_green("✔ Health Status:"),
            p.text("System healthy. No rogue hogs detected.")
        );
    } else {
        println!(
            "{} Found {} action(s) to mitigate hardware contention:",
            p.accent_yellow("⚠ Governor Flagged:"),
            decisions.len()
        );
        for d in decisions {
            let act_desc = match &d.action {
                crate::governor::ActionType::ThrottleRenice { target_nice } => {
                    p.accent_yellow(&format!("Renice to +{}", target_nice))
                }
                crate::governor::ActionType::ThrottleFreeze => p.accent_yellow("SIGSTOP (Freeze)"),
                crate::governor::ActionType::GracefulTerminate { rss_mb } => {
                    p.accent_red(&format!("SIGTERM (Free ~{} MB)", rss_mb))
                }
                crate::governor::ActionType::ForceKill { rss_mb } => {
                    p.accent_red(&format!("SIGKILL (Free ~{} MB)", rss_mb))
                }
            };

            println!(
                "  • [PID {}] {} -> {}\n    {}",
                d.pid,
                p.bold(&d.comm),
                act_desc,
                p.muted(&d.reason)
            );
        }
    }
    println!("{}", p.accent_blue("━".repeat(60).as_str()));
}

pub fn run_top(governor: &mut Governor) {
    let p = ThemePalette::detect();
    println!("\x1b[2J\x1b[H"); // Clear screen

    loop {
        let (mem, psi_mem, psi_cpu, decisions) = governor.evaluate_cycle();
        let procs = governor.evaluate_top_processes(10);
        let active_win = crate::hyprland::HyprlandIpc::new().get_active_window();

        print!("\x1b[H"); // Move cursor to top left
        render_scan(&mem, &psi_mem, &psi_cpu, &procs, &decisions, active_win.as_ref());
        println!("  {}", p.muted("Press Ctrl+C to exit dashboard"));
        stdout().flush().unwrap();

        sleep(Duration::from_secs(governor.config.general.poll_interval_secs));
    }
}

impl Governor {
    pub fn evaluate_top_processes(&mut self, limit: usize) -> Vec<ProcessSnapshot> {
        let mut procs = self.scan_processes();
        procs.sort_by_key(|p| std::cmp::Reverse(p.rss_bytes));
        procs.into_iter().take(limit).collect()
    }
}
