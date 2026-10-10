use egui::{Color32, CornerRadius};
use std::fs;
use std::path::PathBuf;

#[derive(Clone, Debug)]
pub struct Swatch {
    pub name: String,
    pub hex: String,
    pub color: Color32,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct CraftTheme {
    pub is_light: bool,
    pub theme_name: String,
    // Backgrounds
    pub bg_app: Color32,
    pub bg_sidebar: Color32,
    pub bg_card: Color32,
    pub bg_card_hover: Color32,
    pub bg_input: Color32,
    pub bg_badge: Color32,
    // Borders
    pub border_subtle: Color32,
    pub border_card: Color32,
    pub border_focus: Color32,
    // Texts (Strict contrast rules for both dark and light modes)
    pub text_primary: Color32,
    pub text_secondary: Color32,
    pub text_muted: Color32,
    pub text_on_accent: Color32,
    // Accents & Semantics
    pub accent: Color32,
    pub accent_hover: Color32,
    pub success: Color32,
    pub warning: Color32,
    pub danger: Color32,
    // Palette swatches loaded from Omarchy
    pub swatches: Vec<Swatch>,
}

impl Default for CraftTheme {
    fn default() -> Self {
        Self::detect()
    }
}

impl CraftTheme {
    pub fn detect() -> Self {
        let is_light = std::env::var("OMARCHY_THEME_MODE")
            .map(|v| v.to_lowercase() == "light")
            .unwrap_or_else(|_| {
                std::env::var("COLORFGBG")
                    .map(|v| v.starts_with("0;"))
                    .unwrap_or(false)
            });

        let theme_name = std::env::var("OMARCHY_THEME_NAME").unwrap_or_else(|_| {
            if is_light {
                "Omarchy Light".to_string()
            } else {
                "Omarchy Dark".to_string()
            }
        });

        // Attempt reading colors.toml
        let mut swatches = Vec::new();
        let home = std::env::var("HOME").unwrap_or_else(|_| "/home/soham".to_string());
        let colors_path = PathBuf::from(&home).join(".local/state/omarchy/current/theme/colors.toml");

        let mut extracted_accent = None;
        let mut extracted_bg = None;
        let mut extracted_fg = None;

        if let Ok(content) = fs::read_to_string(&colors_path) {
            if let Ok(parsed) = content.parse::<toml::Table>() {
                for (key, val) in parsed {
                    if let Some(hex_str) = val.as_str() {
                        if let Some(c) = parse_hex(hex_str) {
                            if key == "accent" {
                                extracted_accent = Some(c);
                            } else if key == "background" {
                                extracted_bg = Some(c);
                            } else if key == "foreground" {
                                extracted_fg = Some(c);
                            }
                            swatches.push(Swatch {
                                name: key,
                                hex: hex_str.to_string(),
                                color: c,
                            });
                        }
                    }
                }
            }
        }

        if is_light {
            // Light Theme Palette: strictly following RULE[/home/soham/.agents/rules/theming.md]
            // NEVER use white, light gray or DIM for text on light backgrounds
            let bg_app = extracted_bg.unwrap_or(Color32::from_rgb(246, 248, 250));
            let bg_sidebar = Color32::from_rgb(238, 241, 245);
            let bg_card = Color32::from_rgb(255, 255, 255);
            let bg_card_hover = Color32::from_rgb(243, 246, 250);
            let bg_input = Color32::from_rgb(255, 255, 255);
            let bg_badge = Color32::from_rgb(230, 235, 242);

            let border_subtle = Color32::from_rgb(222, 226, 233);
            let border_card = Color32::from_rgb(215, 220, 229);
            let border_focus = Color32::from_rgb(37, 99, 235);

            let text_primary = Color32::from_rgb(26, 32, 44);     // Deep charcoal
            let text_secondary = Color32::from_rgb(74, 85, 104);   // Dark slate
            let text_muted = Color32::from_rgb(100, 116, 139);     // Readable slate
            let text_on_accent = Color32::from_rgb(255, 255, 255);

            let accent = extracted_accent.unwrap_or(Color32::from_rgb(25, 82, 165)); // Deep cobalt
            let accent_hover = Color32::from_rgb(20, 68, 140);
            let success = Color32::from_rgb(28, 116, 48);          // Forest green
            let warning = Color32::from_rgb(184, 93, 25);          // Deep rust
            let danger = Color32::from_rgb(200, 35, 51);           // Crimson

            Self {
                is_light: true,
                theme_name,
                bg_app,
                bg_sidebar,
                bg_card,
                bg_card_hover,
                bg_input,
                bg_badge,
                border_subtle,
                border_card,
                border_focus,
                text_primary,
                text_secondary,
                text_muted,
                text_on_accent,
                accent,
                accent_hover,
                success,
                warning,
                danger,
                swatches,
            }
        } else {
            // Dark Theme Palette: Sleek Creative Cloud Dark Mode
            let bg_app = extracted_bg.unwrap_or(Color32::from_rgb(24, 28, 34));
            let bg_sidebar = Color32::from_rgb(18, 21, 26);
            let bg_card = Color32::from_rgb(30, 35, 43);
            let bg_card_hover = Color32::from_rgb(38, 44, 54);
            let bg_input = Color32::from_rgb(22, 26, 32);
            let bg_badge = Color32::from_rgb(42, 49, 60);

            let border_subtle = Color32::from_rgb(45, 52, 64);
            let border_card = Color32::from_rgb(52, 60, 74);
            let border_focus = Color32::from_rgb(78, 205, 196);

            let text_primary = extracted_fg.unwrap_or(Color32::from_rgb(230, 235, 242));
            let text_secondary = Color32::from_rgb(175, 185, 198);
            let text_muted = Color32::from_rgb(130, 142, 158);
            let text_on_accent = Color32::from_rgb(18, 21, 26);

            let accent = extracted_accent.unwrap_or(Color32::from_rgb(78, 205, 196)); // Cyan/Teal accent
            let accent_hover = Color32::from_rgb(110, 225, 216);
            let success = Color32::from_rgb(60, 207, 142);
            let warning = Color32::from_rgb(245, 158, 11);
            let danger = Color32::from_rgb(248, 113, 113);

            Self {
                is_light: false,
                theme_name,
                bg_app,
                bg_sidebar,
                bg_card,
                bg_card_hover,
                bg_input,
                bg_badge,
                border_subtle,
                border_card,
                border_focus,
                text_primary,
                text_secondary,
                text_muted,
                text_on_accent,
                accent,
                accent_hover,
                success,
                warning,
                danger,
                swatches,
            }
        }
    }

    pub fn apply_to_egui(&self, ctx: &egui::Context) {
        let mut visuals = if self.is_light {
            egui::Visuals::light()
        } else {
            egui::Visuals::dark()
        };

        visuals.panel_fill = self.bg_app;
        visuals.window_fill = self.bg_card;
        visuals.extreme_bg_color = self.bg_input;

        // Widgets
        visuals.widgets.noninteractive.bg_fill = self.bg_card;
        visuals.widgets.noninteractive.fg_stroke = egui::Stroke::new(1.0, self.text_primary);
        visuals.widgets.noninteractive.bg_stroke = egui::Stroke::new(1.0, self.border_subtle);

        visuals.widgets.inactive.bg_fill = self.bg_card;
        visuals.widgets.inactive.fg_stroke = egui::Stroke::new(1.0, self.text_secondary);
        visuals.widgets.inactive.bg_stroke = egui::Stroke::new(1.0, self.border_card);

        visuals.widgets.hovered.bg_fill = self.bg_card_hover;
        visuals.widgets.hovered.fg_stroke = egui::Stroke::new(1.0, self.text_primary);
        visuals.widgets.hovered.bg_stroke = egui::Stroke::new(1.0, self.accent);

        visuals.widgets.active.bg_fill = self.accent;
        visuals.widgets.active.fg_stroke = egui::Stroke::new(1.0, self.text_on_accent);

        visuals.selection.bg_fill = self.accent;
        visuals.selection.stroke = egui::Stroke::new(1.0, self.text_on_accent);

        // Window & card roundings
        visuals.window_corner_radius = CornerRadius::same(10);
        visuals.widgets.noninteractive.corner_radius = CornerRadius::same(6);
        visuals.widgets.inactive.corner_radius = CornerRadius::same(6);
        visuals.widgets.hovered.corner_radius = CornerRadius::same(6);
        visuals.widgets.active.corner_radius = CornerRadius::same(6);

        ctx.set_visuals(visuals);
    }
}

pub fn parse_hex(hex_str: &str) -> Option<Color32> {
    let clean = hex_str.trim().trim_start_matches('#');
    if clean.len() == 6 {
        let r = u8::from_str_radix(&clean[0..2], 16).ok()?;
        let g = u8::from_str_radix(&clean[2..4], 16).ok()?;
        let b = u8::from_str_radix(&clean[4..6], 16).ok()?;
        Some(Color32::from_rgb(r, g, b))
    } else if clean.len() == 8 {
        let r = u8::from_str_radix(&clean[0..2], 16).ok()?;
        let g = u8::from_str_radix(&clean[2..4], 16).ok()?;
        let b = u8::from_str_radix(&clean[4..6], 16).ok()?;
        let a = u8::from_str_radix(&clean[6..8], 16).ok()?;
        Some(Color32::from_rgba_premultiplied(r, g, b, a))
    } else {
        None
    }
}
