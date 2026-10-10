use std::fs;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

#[derive(Clone, Debug)]
pub struct RecentItem {
    pub path: PathBuf,
    pub filename: String,
    pub app_id: String,
    pub app_name: String,
    pub extension: String,
    pub size_formatted: String,
    pub modified_formatted: String,
    pub timestamp: u64,
}

pub struct RecentsScanner;

impl RecentsScanner {
    pub fn scan_all() -> Vec<RecentItem> {
        let mut items = Vec::new();
        let home = std::env::var("HOME").unwrap_or_else(|_| "/home/soham".to_string());

        // 1. Parse ~/.local/share/recently-used.xbel
        let xbel_path = PathBuf::from(&home).join(".local/share/recently-used.xbel");
        if let Ok(content) = fs::read_to_string(&xbel_path) {
            Self::parse_xbel(&content, &mut items);
        }

        // 2. Scan ~/Pictures and ~/Documents for Craft projects
        let scan_dirs = [
            PathBuf::from(&home).join("Pictures"),
            PathBuf::from(&home).join("Documents"),
            PathBuf::from(&home).join("Videos"),
            PathBuf::from(&home).join("Downloads"),
        ];

        for dir in &scan_dirs {
            if dir.is_dir() {
                Self::scan_directory(dir, &mut items, 2);
            }
        }

        // Deduplicate by canonical path
        items.sort_by_key(|a| std::cmp::Reverse(a.timestamp));
        let mut seen = std::collections::HashSet::new();
        items.retain(|item| {
            let key = item.path.to_string_lossy().to_string();
            if seen.contains(&key) {
                false
            } else {
                seen.insert(key);
                true
            }
        });

        // Keep top 40 recents
        items.truncate(40);
        items
    }

    fn scan_directory(dir: &Path, items: &mut Vec<RecentItem>, max_depth: usize) {
        if max_depth == 0 {
            return;
        }
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_file() {
                    if let Some(item) = Self::inspect_file(&path) {
                        items.push(item);
                    }
                } else if path.is_dir() {
                    let name = path.file_name().unwrap_or_default().to_string_lossy();
                    if !name.starts_with('.') && name != "node_modules" && name != "target" {
                        Self::scan_directory(&path, items, max_depth - 1);
                    }
                }
            }
        }
    }

    fn parse_xbel(content: &str, items: &mut Vec<RecentItem>) {
        for line in content.lines() {
            if let Some(start) = line.find("<bookmark href=\"file://") {
                let rest = &line[start + 23..];
                if let Some(end) = rest.find('"') {
                    let encoded_path = &rest[..end];
                    let decoded_path = percent_decode(encoded_path);
                    let path = PathBuf::from(decoded_path);
                    if path.is_file() {
                        if let Some(item) = Self::inspect_file(&path) {
                            items.push(item);
                        }
                    }
                }
            }
        }
    }

    fn inspect_file(path: &Path) -> Option<RecentItem> {
        let ext = path.extension()?.to_string_lossy().to_lowercase();
        let ext_with_dot = format!(".{}", ext);

        let (app_id, app_name) = match ext_with_dot.as_str() {
            ".pcraft" | ".psd" | ".psb" => ("photocraft", "PhotoCraft"),
            ".vectorcraft" | ".ai" => ("vectorcraft", "VectorCraft"),
            ".filmcraft" => ("filmcraft", "FilmCraft"),
            ".dng" | ".arw" | ".cr2" | ".cr3" | ".nef" | ".raf" => ("lightcraft", "LightCraft"),
            ".pdf" => ("pdfcraft", "PdfCraft"),
            _ => return None,
        };

        let metadata = fs::metadata(path).ok()?;
        let size_bytes = metadata.len();
        let modified = metadata.modified().unwrap_or(SystemTime::UNIX_EPOCH);
        let timestamp = modified
            .duration_since(SystemTime::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);

        let filename = path.file_name()?.to_string_lossy().to_string();
        let size_formatted = format_bytes(size_bytes);
        let modified_formatted = format_relative_time(modified);

        Some(RecentItem {
            path: path.to_path_buf(),
            filename,
            app_id: app_id.to_string(),
            app_name: app_name.to_string(),
            extension: ext.to_uppercase(),
            size_formatted,
            modified_formatted,
            timestamp,
        })
    }
}

fn percent_decode(input: &str) -> String {
    let mut result = String::new();
    let mut chars = input.bytes().peekable();
    while let Some(b) = chars.next() {
        if b == b'%' {
            let h1 = chars.next().unwrap_or(b'0');
            let h2 = chars.next().unwrap_or(b'0');
            let hex = [h1, h2];
            if let Ok(s) = std::str::from_utf8(&hex) {
                if let Ok(byte) = u8::from_str_radix(s, 16) {
                    result.push(byte as char);
                    continue;
                }
            }
        }
        result.push(b as char);
    }
    result
}

fn format_bytes(bytes: u64) -> String {
    if bytes < 1024 {
        format!("{} B", bytes)
    } else if bytes < 1024 * 1024 {
        format!("{:.1} KB", bytes as f64 / 1024.0)
    } else if bytes < 1024 * 1024 * 1024 {
        format!("{:.1} MB", bytes as f64 / (1024.0 * 1024.0))
    } else {
        format!("{:.2} GB", bytes as f64 / (1024.0 * 1024.0 * 1024.0))
    }
}

fn format_relative_time(time: SystemTime) -> String {
    let now = SystemTime::now();
    let elapsed = match now.duration_since(time) {
        Ok(d) => d.as_secs(),
        Err(_) => return "Just now".to_string(),
    };

    if elapsed < 60 {
        "Just now".to_string()
    } else if elapsed < 3600 {
        format!("{}m ago", elapsed / 60)
    } else if elapsed < 86400 {
        format!("{}h ago", elapsed / 3600)
    } else if elapsed < 86400 * 7 {
        format!("{}d ago", elapsed / 86400)
    } else {
        format!("{}w ago", elapsed / (86400 * 7))
    }
}
