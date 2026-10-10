use crate::app_registry::CraftApp;
use crate::process_supervisor::ProcessSupervisor;
use crate::recents::{RecentItem, RecentsScanner};
use crate::theme::CraftTheme;
use egui::{Color32, CornerRadius, Frame, Margin, RichText, Stroke, Ui};
use std::process::Command;

pub struct RecentsViewState {
    pub app_filter: Option<String>,
    pub items: Vec<RecentItem>,
}

impl Default for RecentsViewState {
    fn default() -> Self {
        Self {
            app_filter: None,
            items: RecentsScanner::scan_all(),
        }
    }
}

pub fn render(
    ui: &mut Ui,
    apps: &[CraftApp],
    theme: &CraftTheme,
    state: &mut RecentsViewState,
    search_query: &str,
    status_msg: &mut Option<(String, bool)>,
) {
    // 1. Header & Controls
    Frame::new()
        .fill(theme.bg_card)
        .stroke(Stroke::new(1.0, theme.border_card))
        .corner_radius(CornerRadius::same(8))
        .inner_margin(Margin::same(16))
        .show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.vertical(|ui| {
                    ui.label(
                        RichText::new("Recent Projects & Files")
                            .size(22.0)
                            .color(theme.text_primary)
                            .strong(),
                    );
                    ui.label(
                        RichText::new("Aggregated creative documents across PhotoCraft, VectorCraft, FilmCraft, LightCraft, and PdfCraft.")
                            .size(13.0)
                            .color(theme.text_secondary),
                    );
                });

                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    let rescan_btn = egui::Button::new(
                        RichText::new("↻ Rescan Files")
                            .size(12.5)
                            .color(theme.text_secondary),
                    )
                    .fill(theme.bg_app)
                    .stroke(Stroke::new(1.0, theme.border_subtle))
                    .corner_radius(CornerRadius::same(6));

                    if ui.add(rescan_btn).clicked() {
                        state.items = RecentsScanner::scan_all();
                        *status_msg = Some(("Rescanned recent creative documents".to_string(), false));
                    }

                    crate::ui::badge(
                        ui,
                        &format!("{} Files Found", state.items.len()),
                        theme.bg_badge,
                        theme.text_primary,
                    );
                });
            });
        });

    ui.add_space(14.0);

    // 2. Filter Pills
    ui.horizontal(|ui| {
        ui.label(RichText::new("Filter by App:").size(12.0).color(theme.text_muted));

        let is_all = state.app_filter.is_none();
        let all_btn = egui::Button::new(RichText::new("All Documents").size(12.0).color(if is_all { theme.text_on_accent } else { theme.text_secondary }).strong())
            .fill(if is_all { theme.accent } else { theme.bg_card })
            .corner_radius(CornerRadius::same(14))
            .stroke(Stroke::new(1.0, if is_all { theme.accent } else { theme.border_subtle }));

        if ui.add(all_btn).clicked() {
            state.app_filter = None;
        }

        for app in apps {
            let is_sel = state.app_filter.as_deref() == Some(app.id);
            let btn = egui::Button::new(RichText::new(app.name).size(12.0).color(if is_sel { theme.text_on_accent } else { theme.text_secondary }).strong())
                .fill(if is_sel { theme.accent } else { theme.bg_card })
                .corner_radius(CornerRadius::same(14))
                .stroke(Stroke::new(1.0, if is_sel { theme.accent } else { theme.border_subtle }));

            if ui.add(btn).clicked() {
                state.app_filter = Some(app.id.to_string());
            }
        }
    });

    ui.add_space(12.0);

    // 3. Files List
    egui::ScrollArea::vertical()
        .auto_shrink([false, false])
        .show(ui, |ui| {
            let filtered: Vec<&RecentItem> = state
                .items
                .iter()
                .filter(|item| {
                    if let Some(ref filter_id) = state.app_filter {
                        if item.app_id != *filter_id {
                            return false;
                        }
                    }
                    if !search_query.is_empty() {
                        let q = search_query.to_lowercase();
                        let matches_name = item.filename.to_lowercase().contains(&q);
                        let matches_path = item.path.to_string_lossy().to_lowercase().contains(&q);
                        let matches_app = item.app_name.to_lowercase().contains(&q);
                        if !matches_name && !matches_path && !matches_app {
                            return false;
                        }
                    }
                    true
                })
                .collect();

            if filtered.is_empty() {
                Frame::new()
                    .fill(theme.bg_card)
                    .corner_radius(CornerRadius::same(8))
                    .inner_margin(Margin::same(32))
                    .show(ui, |ui| {
                        ui.vertical_centered(|ui| {
                            ui.label(RichText::new("No recent documents found").size(16.0).color(theme.text_secondary).strong());
                            ui.label(RichText::new("Open or save projects in any Craft application to populate your creative timeline.").size(13.0).color(theme.text_muted));
                        });
                    });
                return;
            }

            for item in filtered {
                Frame::new()
                    .fill(theme.bg_card)
                    .stroke(Stroke::new(1.0, theme.border_card))
                    .corner_radius(CornerRadius::same(6))
                    .inner_margin(Margin::symmetric(14, 10))
                    .show(ui, |ui| {
                        ui.set_min_height(52.0);
                        ui.horizontal(|ui| {
                            // File extension badge
                            let ext_color = match item.extension.as_str() {
                                "PSD" | "PCRAFT" => Color32::from_rgb(56, 142, 244),
                                "VECTORCRAFT" | "AI" | "SVG" => Color32::from_rgb(255, 140, 0),
                                "FILMCRAFT" | "MP4" => Color32::from_rgb(170, 70, 240),
                                "DNG" | "ARW" | "CR2" | "CR3" | "NEF" => Color32::from_rgb(46, 204, 113),
                                "PDF" => Color32::from_rgb(231, 76, 60),
                                _ => theme.accent,
                            };

                            Frame::new()
                                .fill(theme.bg_badge)
                                .stroke(Stroke::new(1.5, ext_color))
                                .corner_radius(CornerRadius::same(6))
                                .inner_margin(Margin::symmetric(10, 8))
                                .show(ui, |ui| {
                                    ui.label(RichText::new(&item.extension).size(12.0).color(ext_color).strong());
                                });

                            ui.add_space(10.0);

                            // File Metadata
                            ui.vertical(|ui| {
                                ui.horizontal(|ui| {
                                    ui.label(RichText::new(&item.filename).size(15.0).color(theme.text_primary).strong());
                                    crate::ui::badge(ui, &item.app_name, theme.bg_badge, theme.text_secondary);
                                });

                                ui.label(
                                    RichText::new(item.path.to_string_lossy())
                                        .size(11.5)
                                        .color(theme.text_muted),
                                );

                                ui.horizontal(|ui| {
                                    ui.label(RichText::new(&item.size_formatted).size(11.5).color(theme.text_secondary));
                                    ui.label(RichText::new("·").size(11.5).color(theme.text_muted));
                                    ui.label(RichText::new(&item.modified_formatted).size(11.5).color(theme.text_secondary));
                                });
                            });

                            // Action buttons right aligned
                            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                                let open_btn = egui::Button::new(
                                    RichText::new(format!("Open in {}", item.app_name))
                                        .size(12.5)
                                        .color(theme.text_on_accent)
                                        .strong(),
                                )
                                .fill(theme.accent)
                                .corner_radius(CornerRadius::same(6));

                                if ui.add(open_btn).clicked() {
                                    if let Some(app) = apps.iter().find(|a| a.id == item.app_id) {
                                        let file_str = item.path.to_string_lossy().to_string();
                                        match ProcessSupervisor::launch(&app.binary_path, app.id, false, false, Some(&file_str)) {
                                            Ok((pid, target_ws)) => {
                                                let ws_text = target_ws.map(|w| format!(" on Workspace {}", w)).unwrap_or_default();
                                                *status_msg = Some((format!("Opened {} in {}{} (PID {})", item.filename, item.app_name, ws_text, pid), false));
                                            }
                                            Err(e) => {
                                                *status_msg = Some((e, true));
                                            }
                                        }
                                    }
                                }

                                let reveal_btn = egui::Button::new(
                                    RichText::new("Reveal in Files")
                                        .size(12.0)
                                        .color(theme.text_secondary),
                                )
                                .fill(theme.bg_card)
                                .stroke(Stroke::new(1.0, theme.border_subtle))
                                .corner_radius(CornerRadius::same(6));

                                if ui.add(reveal_btn).clicked() {
                                    if let Some(parent) = item.path.parent() {
                                        let _ = Command::new("xdg-open").arg(parent).spawn();
                                        *status_msg = Some((format!("Opened folder for {}", item.filename), false));
                                    }
                                }
                            });
                        });
                    });

                ui.add_space(6.0);
            }
        });
}
