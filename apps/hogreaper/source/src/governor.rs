use std::collections::HashMap;
use std::time::{Duration, Instant};

use crate::config::AppConfig;
use crate::hyprland::HyprlandIpc;
use crate::notification::Notifier;
use crate::procfs::{MemInfo, ProcessSnapshot, ProcessTracker, PsiMetrics};
use crate::safety::SafetyEngine;

#[derive(Debug, Clone)]
pub enum ActionType {
    ThrottleRenice { target_nice: i32 },
    ThrottleFreeze,
    GracefulTerminate { rss_mb: u64 },
    ForceKill { rss_mb: u64 },
}

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct Decision {
    pub pid: u32,
    pub comm: String,
    pub rss_mb: u64,
    pub cpu_percent: f32,
    pub reason: String,
    pub action: ActionType,
}

pub struct Governor {
    pub config: AppConfig,
    proc_tracker: ProcessTracker,
    hyprland: HyprlandIpc,
    safety: SafetyEngine,
    notifier: Notifier,
    /// Tracks consecutive high-CPU ticks per PID: pid -> tick_count
    cpu_hog_ticks: HashMap<u32, u32>,
    /// Tracks pending SIGTERM kills to escalate to SIGKILL if necessary: pid -> (sent_time, rss_mb, comm)
    pending_kills: HashMap<u32, (Instant, u64, String)>,
}

impl Governor {
    pub fn new(config: AppConfig) -> Self {
        let safety = SafetyEngine::new(&config);
        let notifier = Notifier::new(config.general.enable_notifications);
        Self {
            config,
            proc_tracker: ProcessTracker::new(),
            hyprland: HyprlandIpc::new(),
            safety,
            notifier,
            cpu_hog_ticks: HashMap::new(),
            pending_kills: HashMap::new(),
        }
    }

    pub fn scan_processes(&mut self) -> Vec<ProcessSnapshot> {
        self.proc_tracker.scan_processes().unwrap_or_default()
    }

    /// Evaluate system state and generate decisions
    pub fn evaluate_cycle(&mut self) -> (MemInfo, PsiMetrics, PsiMetrics, Vec<Decision>) {
        let mem = MemInfo::read().unwrap_or_default();
        let psi_mem = PsiMetrics::read_memory().unwrap_or_default();
        let psi_cpu = PsiMetrics::read_cpu().unwrap_or_default();

        let processes = self.proc_tracker.scan_processes().unwrap_or_default();
        let active_pid = if self.config.whitelist.protect_active_window {
            self.hyprland.get_active_pid()
        } else {
            None
        };

        let mut decisions = Vec::new();
        let now = Instant::now();

        // 1. Check pending kills escalation (SIGKILL escalation)
        if self.config.escalation.escalate_to_sigkill {
            let grace_duration = Duration::from_secs(self.config.escalation.grace_period_secs);
            let mut resolved_kills = Vec::new();

            for (&pid, &(sent_at, rss_mb, ref comm)) in &self.pending_kills {
                if let Some(proc) = processes.iter().find(|p| p.pid == pid) {
                    if now.duration_since(sent_at) >= grace_duration {
                        decisions.push(Decision {
                            pid,
                            comm: comm.clone(),
                            rss_mb,
                            cpu_percent: proc.cpu_percent,
                            reason: format!(
                                "Did not exit within {}s after SIGTERM, escalating to SIGKILL",
                                self.config.escalation.grace_period_secs
                            ),
                            action: ActionType::ForceKill { rss_mb },
                        });
                        resolved_kills.push(pid);
                    }
                } else {
                    // Process exited cleanly
                    resolved_kills.push(pid);
                }
            }

            for pid in resolved_kills {
                self.pending_kills.remove(&pid);
            }
        }

        // 2. Check Memory Pressure Condition
        let mem_pressure = mem.available_mb() < self.config.memory.min_available_ram_mb
            || mem.available_percent() < self.config.memory.min_available_ram_percent
            || psi_mem.some_avg10 > self.config.memory.psi_memory_avg10_threshold;

        if mem_pressure {
            // Find top candidate memory hogs that are not protected
            let mut candidates: Vec<&ProcessSnapshot> = processes
                .iter()
                .filter(|p| !self.safety.is_protected(p, active_pid, &processes))
                .filter(|p| !self.pending_kills.contains_key(&p.pid))
                .collect();

            // Sort by RSS descending
            candidates.sort_by_key(|p| std::cmp::Reverse(p.rss_bytes));

            // Select largest un-whitelisted hog to mitigate memory pressure
            if let Some(top_hog) = candidates.first() {
                // If it consumes > 150 MB RSS
                if top_hog.rss_mb() >= 150 {
                    decisions.push(Decision {
                        pid: top_hog.pid,
                        comm: top_hog.comm.clone(),
                        rss_mb: top_hog.rss_mb(),
                        cpu_percent: top_hog.cpu_percent,
                        reason: format!(
                            "Memory pressure critical (Available: {} MB / {:.1}%, PSI avg10: {:.1})",
                            mem.available_mb(),
                            mem.available_percent(),
                            psi_mem.some_avg10
                        ),
                        action: ActionType::GracefulTerminate {
                            rss_mb: top_hog.rss_mb(),
                        },
                    });
                }
            }
        } else {
            // Also check individual rogue processes that exceed single_process_rss_limit_mb
            for proc in &processes {
                if proc.rss_mb() > self.config.memory.single_process_rss_limit_mb
                    && !self.safety.is_protected(proc, active_pid, &processes)
                    && !self.pending_kills.contains_key(&proc.pid)
                {
                    decisions.push(Decision {
                        pid: proc.pid,
                        comm: proc.comm.clone(),
                        rss_mb: proc.rss_mb(),
                        cpu_percent: proc.cpu_percent,
                        reason: format!(
                            "Single process RSS ({} MB) exceeded limit ({} MB)",
                            proc.rss_mb(),
                            self.config.memory.single_process_rss_limit_mb
                        ),
                        action: ActionType::GracefulTerminate {
                            rss_mb: proc.rss_mb(),
                        },
                    });
                }
            }
        }

        // 3. Check CPU Runaway Condition
        let mut active_pids_this_tick = HashMap::new();
        for proc in &processes {
            if proc.cpu_percent >= self.config.cpu.cpu_hog_threshold_percent
                && !self.safety.is_protected(proc, active_pid, &processes)
            {
                let count = self.cpu_hog_ticks.get(&proc.pid).copied().unwrap_or(0) + 1;
                active_pids_this_tick.insert(proc.pid, count);

                if count >= self.config.cpu.sustained_ticks {
                    // Check if already reniced
                    if proc.nice < self.config.escalation.nice_level {
                        let action = match self.config.escalation.throttle_action.as_str() {
                            "freeze" => ActionType::ThrottleFreeze,
                            _ => ActionType::ThrottleRenice {
                                target_nice: self.config.escalation.nice_level,
                            },
                        };

                        decisions.push(Decision {
                            pid: proc.pid,
                            comm: proc.comm.clone(),
                            rss_mb: proc.rss_mb(),
                            cpu_percent: proc.cpu_percent,
                            reason: format!(
                                "Background CPU runaway ({:.1}% CPU sustained for {} ticks)",
                                proc.cpu_percent, count
                            ),
                            action,
                        });
                    }
                }
            }
        }
        self.cpu_hog_ticks = active_pids_this_tick;

        (mem, psi_mem, psi_cpu, decisions)
    }

    /// Execute decisions (or simulate if dry_run is true)
    pub fn execute_decisions(&mut self, decisions: &[Decision]) {
        for decision in decisions {
            if self.config.general.dry_run {
                println!(
                    "[DRY-RUN] Would execute {:?} on {} (PID {}): {}",
                    decision.action, decision.comm, decision.pid, decision.reason
                );
                continue;
            }

            match decision.action {
                ActionType::ThrottleRenice { target_nice } => {
                    unsafe {
                        libc::setpriority(libc::PRIO_PROCESS, decision.pid, target_nice);
                    }
                    if self.config.general.log_actions {
                        println!(
                            "[THROTTLE] Reniced PID {} ({}) to nice +{}: {}",
                            decision.pid, decision.comm, target_nice, decision.reason
                        );
                    }
                    self.notifier.notify_throttle(
                        &decision.comm,
                        decision.pid,
                        decision.cpu_percent,
                        &format!("Reniced to +{}", target_nice),
                    );
                }
                ActionType::ThrottleFreeze => {
                    unsafe {
                        libc::kill(decision.pid as i32, libc::SIGSTOP);
                    }
                    if self.config.general.log_actions {
                        println!(
                            "[FREEZE] Sent SIGSTOP to PID {} ({}): {}",
                            decision.pid, decision.comm, decision.reason
                        );
                    }
                    self.notifier.notify_throttle(
                        &decision.comm,
                        decision.pid,
                        decision.cpu_percent,
                        "Paused (SIGSTOP)",
                    );
                }
                ActionType::GracefulTerminate { rss_mb } => {
                    unsafe {
                        libc::kill(decision.pid as i32, libc::SIGTERM);
                    }
                    self.pending_kills.insert(
                        decision.pid,
                        (Instant::now(), rss_mb, decision.comm.clone()),
                    );
                    if self.config.general.log_actions {
                        println!(
                            "[REAP] Sent SIGTERM to PID {} ({}, {} MB): {}",
                            decision.pid, decision.comm, rss_mb, decision.reason
                        );
                    }
                    self.notifier.notify_kill(
                        &decision.comm,
                        decision.pid,
                        rss_mb,
                        &decision.reason,
                    );
                }
                ActionType::ForceKill { rss_mb } => {
                    unsafe {
                        libc::kill(decision.pid as i32, libc::SIGKILL);
                    }
                    if self.config.general.log_actions {
                        println!(
                            "[FORCE-KILL] Sent SIGKILL to PID {} ({}, {} MB): {}",
                            decision.pid, decision.comm, rss_mb, decision.reason
                        );
                    }
                    self.notifier.notify_kill(
                        &decision.comm,
                        decision.pid,
                        rss_mb,
                        "Force-killed with SIGKILL",
                    );
                }
            }
        }
    }
}
