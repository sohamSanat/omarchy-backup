use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug)]
pub struct FontEntry {
    pub name: String,
    pub path: PathBuf,
}

#[derive(Clone, Debug)]
pub struct PresetFolder {
    pub app_name: &'static str,
    pub label: &'static str,
    pub path: PathBuf,
    pub file_count: usize,
}

pub struct LibrariesManager;

impl LibrariesManager {
    /// Scans font files in system font directories
    pub fn scan_fonts() -> Vec<FontEntry> {
        let mut fonts = Vec::new();
        let home = std::env::var("HOME").unwrap_or_else(|_| "/home/soham".to_string());
        let font_dirs = [
            PathBuf::from(&home).join(".local/share/fonts"),
            PathBuf::from("/usr/share/fonts"),
        ];

        for dir in &font_dirs {
            if dir.is_dir() {
                Self::collect_fonts(dir, &mut fonts, 3);
            }
        }

        fonts.sort_by(|a, b| a.name.cmp(&b.name));
        fonts.dedup_by(|a, b| a.name == b.name);
        fonts.truncate(30);
        fonts
    }

    fn collect_fonts(dir: &Path, fonts: &mut Vec<FontEntry>, depth: usize) {
        if depth == 0 {
            return;
        }
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_file() {
                    if let Some(ext) = path.extension() {
                        let ext_str = ext.to_string_lossy().to_lowercase();
                        if ext_str == "ttf" || ext_str == "otf" || ext_str == "woff2" {
                            let stem = path
                                .file_stem()
                                .unwrap_or_default()
                                .to_string_lossy()
                                .to_string();
                            fonts.push(FontEntry {
                                name: stem,
                                path: path.clone(),
                            });
                        }
                    }
                } else if path.is_dir() {
                    Self::collect_fonts(&path, fonts, depth - 1);
                }
            }
        }
    }

    /// Discovers preset directories for the Craft apps
    pub fn discover_presets() -> Vec<PresetFolder> {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/home/soham".to_string());
        let home_p = PathBuf::from(home);

        let candidates = [
            ("PhotoCraft", "Configurations & Presets", home_p.join(".config/photocraft")),
            ("VectorCraft", "Vector Presets & State", home_p.join(".config/vectorcraft")),
            ("FilmCraft", "Video Presets & Themes", home_p.join(".config/filmcraft")),
            ("FilmCraft", "Project Recovery & Cache", home_p.join(".local/share/filmcraft")),
            ("LightCraft", "Photo Develop Presets", home_p.join(".config/lightcraft")),
            ("PdfCraft", "Document Settings & State", home_p.join(".config/pdfcraft")),
        ];

        let mut folders = Vec::new();
        for (app_name, label, path) in candidates {
            let count = if path.is_dir() {
                fs::read_dir(&path)
                    .map(|entries| entries.flatten().count())
                    .unwrap_or(0)
            } else {
                0
            };
            folders.push(PresetFolder {
                app_name,
                label,
                path,
                file_count: count,
            });
        }
        folders
    }

    /// Generates a GIMP/Inkscape/Craft compatible .gpl palette text
    pub fn export_gpl_palette(theme_name: &str, swatches: &[crate::theme::Swatch]) -> String {
        let mut out = String::new();
        out.push_str("GIMP Palette\n");
        out.push_str(&format!("Name: CraftCloud - {}\n", theme_name));
        out.push_str("Columns: 4\n#\n");

        for s in swatches {
            out.push_str(&format!(
                "{:3} {:3} {:3}\t{}\n",
                s.color.r(),
                s.color.g(),
                s.color.b(),
                s.name
            ));
        }
        out
    }
}
