use crate::libraries::{FontEntry, LibrariesManager, PresetFolder};
use crate::theme::CraftTheme;
use egui::{vec2, Color32, CornerRadius, Frame, Margin, RichText, Stroke, Ui};
use std::process::Command;

pub struct LibrariesViewState {
    pub selected_subtab: usize, // 0: Swatches, 1: Typography, 2: Presets
    pub pangram_input: String,
    pub fonts: Vec<FontEntry>,
    pub presets: Vec<PresetFolder>,
}

impl Default for LibrariesViewState {
    fn default() -> Self {
        Self {
            selected_subtab: 0,
            pangram_input: "Sphinx of black quartz, judge my vow 0123456789".to_string(),
            fonts: LibrariesManager::scan_fonts(),
            presets: LibrariesManager::discover_presets(),
        }
    }
}

pub fn render(
    ui: &mut Ui,
    theme: &CraftTheme,
    state: &mut LibrariesViewState,
    status_msg: &mut Option<(String, bool)>,
) {
    // 1. Header
    Frame::new()
        .fill(theme.bg_card)
        .stroke(Stroke::new(1.0, theme.border_card))
        .corner_radius(CornerRadius::same(8))
        .inner_margin(Margin::same(16))
        .show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.vertical(|ui| {
                    ui.label(
                        RichText::new("Creative Cloud Libraries")
                            .size(22.0)
                            .color(theme.text_primary)
                            .strong(),
                    );
                    ui.label(
                        RichText::new("Shared design assets, live desktop color tokens, typography, and preset directories.")
                            .size(13.0)
                            .color(theme.text_secondary),
                    );
                });
            });
        });

    ui.add_space(14.0);

    // 2. Subtabs
    ui.horizontal(|ui| {
        let tabs = ["🎨 Color Swatches & Palettes", "🔤 Typography & Fonts", "📁 Presets & Asset Directories"];
        for (idx, tab) in tabs.iter().enumerate() {
            let is_sel = state.selected_subtab == idx;
            let (bg, fg) = if is_sel {
                (theme.accent, theme.text_on_accent)
            } else {
                (theme.bg_card, theme.text_secondary)
            };

            let btn = egui::Button::new(RichText::new(*tab).size(12.5).color(fg).strong())
                .fill(bg)
                .corner_radius(CornerRadius::same(6))
                .stroke(Stroke::new(1.0, if is_sel { theme.accent } else { theme.border_subtle }));

            if ui.add(btn).clicked() {
                state.selected_subtab = idx;
            }
        }
    });

    ui.add_space(12.0);

    // 3. Tab Contents
    egui::ScrollArea::vertical()
        .auto_shrink([false, false])
        .show(ui, |ui| {
            match state.selected_subtab {
                0 => render_swatches(ui, theme, status_msg),
                1 => render_fonts(ui, theme, state),
                2 => render_presets(ui, theme, state, status_msg),
                _ => {}
            }
        });
}

fn render_swatches(ui: &mut Ui, theme: &CraftTheme, status_msg: &mut Option<(String, bool)>) {
    ui.horizontal(|ui| {
        ui.label(
            RichText::new(format!("Active Theme Palette: {}", theme.theme_name))
                .size(14.0)
                .color(theme.text_primary)
                .strong(),
        );

        ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
            let copy_gpl = egui::Button::new(
                RichText::new("Export GIMP/Craft Palette (.gpl)")
                    .size(12.0)
                    .color(theme.text_secondary),
            )
            .fill(theme.bg_card)
            .stroke(Stroke::new(1.0, theme.border_subtle))
            .corner_radius(CornerRadius::same(6));

            if ui.add(copy_gpl).clicked() {
                let gpl = LibrariesManager::export_gpl_palette(&theme.theme_name, &theme.swatches);
                ui.ctx().copy_text(gpl);
                *status_msg = Some(("Copied .gpl palette to clipboard".to_string(), false));
            }
        });
    });

    ui.add_space(10.0);

    // Swatches grid
    let swatches = &theme.swatches;
    let cols = 3;
    let chunks = swatches.chunks(cols);

    for chunk in chunks {
        ui.horizontal(|ui| {
            for s in chunk {
                Frame::new()
                    .fill(theme.bg_card)
                    .stroke(Stroke::new(1.0, theme.border_card))
                    .corner_radius(CornerRadius::same(6))
                    .inner_margin(Margin::same(10))
                    .show(ui, |ui| {
                        ui.set_width(260.0);
                        ui.horizontal(|ui| {
                            // Color Chip
                            Frame::new()
                                .fill(s.color)
                                .stroke(Stroke::new(1.0, Color32::from_black_alpha(40)))
                                .corner_radius(CornerRadius::same(4))
                                .show(ui, |ui| {
                                    ui.allocate_space(vec2(32.0, 32.0));
                                });

                            ui.add_space(8.0);

                            ui.vertical(|ui| {
                                ui.label(RichText::new(&s.name).size(13.0).color(theme.text_primary).strong());
                                ui.label(RichText::new(&s.hex).size(11.5).color(theme.text_muted));
                            });

                            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                                let copy_btn = egui::Button::new(RichText::new("Copy").size(11.0).color(theme.accent))
                                    .fill(theme.bg_app)
                                    .corner_radius(CornerRadius::same(4));
                                if ui.add(copy_btn).clicked() {
                                    ui.ctx().copy_text(s.hex.clone());
                                    *status_msg = Some((format!("Copied {} to clipboard", s.hex), false));
                                }
                            });
                        });
                    });
            }
        });
        ui.add_space(6.0);
    }
}

fn render_fonts(ui: &mut Ui, theme: &CraftTheme, state: &mut LibrariesViewState) {
    ui.label(RichText::new("Pangram Preview String:").size(12.0).color(theme.text_muted));
    ui.text_edit_singleline(&mut state.pangram_input);
    ui.add_space(12.0);

    ui.label(RichText::new(format!("Installed Creative Fonts ({} found)", state.fonts.len())).size(14.0).color(theme.text_primary).strong());
    ui.add_space(8.0);

    for font in &state.fonts {
        Frame::new()
            .fill(theme.bg_card)
            .stroke(Stroke::new(1.0, theme.border_card))
            .corner_radius(CornerRadius::same(6))
            .inner_margin(Margin::symmetric(14, 10))
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.vertical(|ui| {
                        ui.label(RichText::new(&font.name).size(14.0).color(theme.text_primary).strong());
                        ui.label(RichText::new(&state.pangram_input).size(13.0).color(theme.text_secondary));
                        ui.label(RichText::new(font.path.to_string_lossy()).size(10.5).color(theme.text_muted));
                    });
                });
            });
        ui.add_space(6.0);
    }
}

fn render_presets(ui: &mut Ui, theme: &CraftTheme, state: &mut LibrariesViewState, status_msg: &mut Option<(String, bool)>) {
    ui.label(RichText::new("Craft Suite Application Asset Directories:").size(14.0).color(theme.text_primary).strong());
    ui.add_space(8.0);

    for preset in &state.presets {
        Frame::new()
            .fill(theme.bg_card)
            .stroke(Stroke::new(1.0, theme.border_card))
            .corner_radius(CornerRadius::same(6))
            .inner_margin(Margin::same(12))
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.vertical(|ui| {
                        ui.horizontal(|ui| {
                            ui.label(RichText::new(preset.app_name).size(15.0).color(theme.text_primary).strong());
                            crate::ui::badge(ui, preset.label, theme.bg_badge, theme.accent);
                            crate::ui::badge(ui, &format!("{} items", preset.file_count), theme.bg_badge, theme.text_muted);
                        });
                        ui.label(RichText::new(preset.path.to_string_lossy()).size(11.5).color(theme.text_muted));
                    });

                    ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                        let open_folder = egui::Button::new(
                            RichText::new("Open Folder")
                                .size(12.0)
                                .color(theme.text_secondary),
                        )
                        .fill(theme.bg_app)
                        .stroke(Stroke::new(1.0, theme.border_subtle))
                        .corner_radius(CornerRadius::same(6));

                        if ui.add(open_folder).clicked() {
                            let _ = Command::new("xdg-open").arg(&preset.path).spawn();
                            *status_msg = Some((format!("Opened {}", preset.path.display()), false));
                        }
                    });
                });
            });
        ui.add_space(6.0);
    }
}
