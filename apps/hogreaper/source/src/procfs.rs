use std::collections::HashMap;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Read};
use std::path::Path;
use std::time::Instant;

/// Memory metrics from /proc/meminfo
#[derive(Debug, Clone, Default)]
pub struct MemInfo {
    pub total_kb: u64,
    pub free_kb: u64,
    pub available_kb: u64,
    pub buffers_kb: u64,
    pub cached_kb: u64,
    pub swap_total_kb: u64,
    pub swap_free_kb: u64,
}

impl MemInfo {
    pub fn read() -> std::io::Result<Self> {
        let file = File::open("/proc/meminfo")?;
        let reader = BufReader::new(file);
        let mut info = MemInfo::default();

        for line in reader.lines() {
            let line = line?;
            if let Some((key, val_str)) = line.split_once(':') {
                let val = val_str
                    .trim_start()
                    .split_whitespace()
                    .next()
                    .and_then(|s| s.parse::<u64>().ok())
                    .unwrap_or(0);

                match key {
                    "MemTotal" => info.total_kb = val,
                    "MemFree" => info.free_kb = val,
                    "MemAvailable" => info.available_kb = val,
                    "Buffers" => info.buffers_kb = val,
                    "Cached" => info.cached_kb = val,
                    "SwapTotal" => info.swap_total_kb = val,
                    "SwapFree" => info.swap_free_kb = val,
                    _ => {}
                }
            }
        }
        Ok(info)
    }

    pub fn used_kb(&self) -> u64 {
        self.total_kb.saturating_sub(self.available_kb)
    }

    pub fn used_mb(&self) -> u64 {
        self.used_kb() / 1024
    }

    pub fn total_mb(&self) -> u64 {
        self.total_kb / 1024
    }

    pub fn available_mb(&self) -> u64 {
        self.available_kb / 1024
    }

    pub fn used_percent(&self) -> f32 {
        if self.total_kb == 0 {
            return 0.0;
        }
        (self.used_kb() as f32 / self.total_kb as f32) * 100.0
    }

    pub fn available_percent(&self) -> f32 {
        if self.total_kb == 0 {
            return 0.0;
        }
        (self.available_kb as f32 / self.total_kb as f32) * 100.0
    }

    pub fn swap_used_kb(&self) -> u64 {
        self.swap_total_kb.saturating_sub(self.swap_free_kb)
    }

    pub fn swap_used_mb(&self) -> u64 {
        self.swap_used_kb() / 1024
    }

    pub fn swap_total_mb(&self) -> u64 {
        self.swap_total_kb / 1024
    }

    pub fn swap_used_percent(&self) -> f32 {
        if self.swap_total_kb == 0 {
            return 0.0;
        }
        (self.swap_used_kb() as f32 / self.swap_total_kb as f32) * 100.0
    }
}

/// Linux Pressure Stall Information (PSI)
#[derive(Debug, Clone, Default)]
pub struct PsiMetrics {
    pub some_avg10: f32,
    pub some_avg60: f32,
    pub some_avg300: f32,
    pub full_avg10: f32,
    pub full_avg60: f32,
    pub full_avg300: f32,
}

impl PsiMetrics {
    pub fn read_file(path: &str) -> std::io::Result<Self> {
        let file = File::open(path)?;
        let reader = BufReader::new(file);
        let mut metrics = PsiMetrics::default();

        for line in reader.lines() {
            let line = line?;
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.is_empty() {
                continue;
            }
            let is_some = parts[0] == "some";
            let is_full = parts[0] == "full";

            for part in &parts[1..] {
                if let Some((k, v)) = part.split_once('=') {
                    if let Ok(val) = v.parse::<f32>() {
                        match (is_some, is_full, k) {
                            (true, _, "avg10") => metrics.some_avg10 = val,
                            (true, _, "avg60") => metrics.some_avg60 = val,
                            (true, _, "avg300") => metrics.some_avg300 = val,
                            (_, true, "avg10") => metrics.full_avg10 = val,
                            (_, true, "avg60") => metrics.full_avg60 = val,
                            (_, true, "avg300") => metrics.full_avg300 = val,
                            _ => {}
                        }
                    }
                }
            }
        }
        Ok(metrics)
    }

    pub fn read_memory() -> std::io::Result<Self> {
        Self::read_file("/proc/pressure/memory")
    }

    pub fn read_cpu() -> std::io::Result<Self> {
        Self::read_file("/proc/pressure/cpu")
    }
}

/// Process snapshot
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct ProcessSnapshot {
    pub pid: u32,
    pub ppid: u32,
    pub uid: u32,
    pub comm: String,
    pub cmdline: String,
    pub state: char,
    pub rss_bytes: u64,
    pub nice: i32,
    pub num_threads: u32,
    pub utime: u64,
    pub stime: u64,
    pub cpu_percent: f32,
}

impl ProcessSnapshot {
    pub fn rss_mb(&self) -> u64 {
        self.rss_bytes / (1024 * 1024)
    }
}

/// Helper to track CPU usage across ticks
pub struct ProcessTracker {
    last_samples: HashMap<u32, (u64, Instant)>,
    page_size: u64,
    ticks_per_second: u64,
    #[allow(dead_code)]
    num_cpus: usize,
}

impl ProcessTracker {
    pub fn new() -> Self {
        let page_size = unsafe { libc::sysconf(libc::_SC_PAGESIZE) };
        let page_size = if page_size > 0 { page_size as u64 } else { 4096 };

        let clk_tck = unsafe { libc::sysconf(libc::_SC_CLK_TCK) };
        let ticks_per_second = if clk_tck > 0 { clk_tck as u64 } else { 100 };

        let num_cpus = std::thread::available_parallelism()
            .map(|n| n.get())
            .unwrap_or(1);

        Self {
            last_samples: HashMap::new(),
            page_size,
            ticks_per_second,
            num_cpus,
        }
    }

    /// Read all running processes from /proc
    pub fn scan_processes(&mut self) -> std::io::Result<Vec<ProcessSnapshot>> {
        let now = Instant::now();
        let proc_dir = Path::new("/proc");
        let mut processes = Vec::new();
        let mut current_pids = HashMap::new();

        let entries = match fs::read_dir(proc_dir) {
            Ok(e) => e,
            Err(err) => return Err(err),
        };

        for entry in entries.flatten() {
            let file_name = entry.file_name();
            let name_str = file_name.to_string_lossy();
            let pid = match name_str.parse::<u32>() {
                Ok(p) => p,
                Err(_) => continue, // Skip non-PID entries
            };

            let pid_path = entry.path();

            // 1. Read /proc/[pid]/stat
            let stat_path = pid_path.join("stat");
            let mut stat_content = String::new();
            if let Ok(mut f) = File::open(&stat_path) {
                if f.read_to_string(&mut stat_content).is_err() {
                    continue;
                }
            } else {
                continue;
            }

            // Parse comm between first '(' and last ')'
            let first_paren = match stat_content.find('(') {
                Some(p) => p,
                None => continue,
            };
            let last_paren = match stat_content.rfind(')') {
                Some(p) => p,
                None => continue,
            };

            let comm = stat_content[first_paren + 1..last_paren].to_string();
            let rest = &stat_content[last_paren + 1..];
            let fields: Vec<&str> = rest.split_whitespace().collect();
            if fields.len() < 17 {
                continue;
            }

            let state = fields[0].chars().next().unwrap_or('?');
            let ppid = fields[1].parse::<u32>().unwrap_or(0);
            let utime = fields[11].parse::<u64>().unwrap_or(0);
            let stime = fields[12].parse::<u64>().unwrap_or(0);
            let nice = fields[16].parse::<i32>().unwrap_or(0);
            let num_threads = fields[17].parse::<u32>().unwrap_or(1);
            let total_ticks = utime + stime;

            // 2. Read /proc/[pid]/statm for RSS
            let mut rss_bytes = 0;
            let statm_path = pid_path.join("statm");
            if let Ok(statm_content) = fs::read_to_string(&statm_path) {
                let statm_parts: Vec<&str> = statm_content.split_whitespace().collect();
                if statm_parts.len() >= 2 {
                    if let Ok(pages) = statm_parts[1].parse::<u64>() {
                        rss_bytes = pages * self.page_size;
                    }
                }
            }

            // 3. Read /proc/[pid]/cmdline
            let cmdline_path = pid_path.join("cmdline");
            let mut cmdline = String::new();
            if let Ok(cmd_bytes) = fs::read(&cmdline_path) {
                let args: Vec<String> = cmd_bytes
                    .split(|&b| b == 0)
                    .filter(|s| !s.is_empty())
                    .map(|s| String::from_utf8_lossy(s).to_string())
                    .collect();
                cmdline = args.join(" ");
            }
            if cmdline.is_empty() {
                cmdline = format!("[{}]", comm);
            }

            // 4. Read UID from /proc/[pid]/status
            let mut uid = 0;
            let status_path = pid_path.join("status");
            if let Ok(status_file) = File::open(&status_path) {
                let status_reader = BufReader::new(status_file);
                for sline in status_reader.lines().flatten() {
                    if sline.starts_with("Uid:") {
                        let uparts: Vec<&str> = sline.split_whitespace().collect();
                        if uparts.len() >= 2 {
                            uid = uparts[1].parse::<u32>().unwrap_or(0);
                        }
                        break;
                    }
                }
            }

            // 5. Calculate CPU percentage
            let mut cpu_percent = 0.0;
            if let Some(&(prev_ticks, prev_time)) = self.last_samples.get(&pid) {
                let delta_time = now.duration_since(prev_time).as_secs_f32();
                if delta_time > 0.05 && total_ticks >= prev_ticks {
                    let delta_ticks = total_ticks - prev_ticks;
                    let cpu_secs = delta_ticks as f32 / self.ticks_per_second as f32;
                    cpu_percent = (cpu_secs / delta_time) * 100.0;
                }
            }

            current_pids.insert(pid, (total_ticks, now));

            processes.push(ProcessSnapshot {
                pid,
                ppid,
                uid,
                comm,
                cmdline,
                state,
                rss_bytes,
                nice,
                num_threads,
                utime,
                stime,
                cpu_percent,
            });
        }

        self.last_samples = current_pids;
        Ok(processes)
    }

    #[allow(dead_code)]
    pub fn num_cpus(&self) -> usize {
        self.num_cpus
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_meminfo_read() {
        let mem = MemInfo::read().expect("should read /proc/meminfo on linux");
        assert!(mem.total_kb > 0);
        assert!(mem.available_kb > 0);
        assert!(mem.used_percent() >= 0.0 && mem.used_percent() <= 100.0);
    }

    #[test]
    fn test_psi_read() {
        // PSI might or might not be enabled, but reading shouldn't panic
        let _ = PsiMetrics::read_memory();
        let _ = PsiMetrics::read_cpu();
    }

    #[test]
    fn test_scan_processes() {
        let mut tracker = ProcessTracker::new();
        let procs = tracker.scan_processes().expect("should scan /proc");
        assert!(!procs.is_empty());
        let self_pid = std::process::id();
        assert!(procs.iter().any(|p| p.pid == self_pid));
    }
}
