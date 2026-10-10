use crate::app_registry::CraftApp;
use crate::process_supervisor::{ProcessInfo, ProcessSupervisor};
use crate::theme::CraftTheme;
use egui::{CornerRadius, Frame, Margin, RichText, Stroke, Ui};
use std::collections::HashMap;

pub fn render(
    ui: &mut Ui,
    apps: &[CraftApp],
    running_map: &mut HashMap<String, ProcessInfo>,
    theme: &CraftTheme,
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
                        RichText::new("Activity & Process Telemetry")
                            .size(22.0)
                            .color(theme.text_primary)
                            .strong(),
                    );
                    ui.label(
                        RichText::new("Real-time Linux process supervisor. Zero background daemons, zero telemetry.")
                            .size(13.0)
                            .color(theme.text_secondary),
                    );
                });

                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    let total_rss: f32 = running_map.values().map(|p| p.rss_mb).sum();
                    crate::ui::badge(
                        ui,
                        &format!("Total RAM: {:.1} MB", total_rss),
                        theme.accent,
                        theme.text_on_accent,
                    );
                    crate::ui::badge(
                        ui,
                        &format!("{} Processes Active", running_map.len()),
                        theme.bg_badge,
                        theme.text_primary,
                    );
                });
            });
        });

    ui.add_space(14.0);

    // 2. Active Processes Table
    ui.label(RichText::new("Active Craft Processes:").size(15.0).color(theme.text_primary).strong());
    ui.add_space(6.0);

    if running_map.is_empty() {
        Frame::new()
            .fill(theme.bg_card)
            .corner_radius(CornerRadius::same(8))
            .inner_margin(Margin::same(32))
            .show(ui, |ui| {
                ui.vertical_centered(|ui| {
                    ui.label(RichText::new("No Craft applications currently running").size(16.0).color(theme.text_secondary).strong());
                    ui.label(RichText::new("Launch PhotoCraft, VectorCraft, FilmCraft, LightCraft, or PdfCraft from the Apps tab to monitor their process state.").size(13.0).color(theme.text_muted));
                });
            });
    } else {
        let mut action: Option<(String, u32, bool)> = None;

        for (app_id, proc) in running_map.iter() {
            let app_name = apps
                .iter()
                .find(|a| a.id == app_id)
                .map(|a| a.name)
                .unwrap_or(proc.name.as_str());

            Frame::new()
                .fill(theme.bg_card)
                .stroke(Stroke::new(1.0, theme.border_card))
                .corner_radius(CornerRadius::same(8))
                .inner_margin(Margin::same(14))
                .show(ui, |ui| {
                    ui.horizontal(|ui| {
                        ui.vertical(|ui| {
                            ui.horizontal(|ui| {
                                ui.label(RichText::new(app_name).size(16.0).color(theme.text_primary).strong());
                                crate::ui::badge(ui, &format!("PID {}", proc.pid), theme.bg_badge, theme.accent);
                                crate::ui::badge(ui, &format!("{:.1} MB RSS", proc.rss_mb), theme.bg_badge, theme.text_secondary);
                            });

                            ui.label(RichText::new(&proc.cmdline).monospace().size(11.0).color(theme.text_muted));
                        });

                        ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                            let kill_btn = egui::Button::new(RichText::new("Force Kill").size(12.0).color(theme.danger))
                                .fill(theme.bg_app)
                                .stroke(Stroke::new(1.0, theme.danger))
                                .corner_radius(CornerRadius::same(6));

                            if ui.add(kill_btn).clicked() {
                                action = Some((app_id.clone(), proc.pid, true));
                            }

                            let quit_btn = egui::Button::new(RichText::new("Quit Gracefully").size(12.0).color(theme.text_secondary))
                                .fill(theme.bg_app)
                                .stroke(Stroke::new(1.0, theme.border_subtle))
                                .corner_radius(CornerRadius::same(6));

                            if ui.add(quit_btn).clicked() {
                                action = Some((app_id.clone(), proc.pid, false));
                            }

                            if let Some(app) = apps.iter().find(|a| a.id == app_id) {
                                let focus_btn = egui::Button::new(RichText::new("Focus Window").size(12.0).color(theme.text_on_accent).strong())
                                    .fill(theme.accent)
                                    .corner_radius(CornerRadius::same(6));

                                if ui.add(focus_btn).clicked() {
                                    ProcessSupervisor::focus_window(app.wm_class);
                                }
                            }
                        });
                    });
                });

            ui.add_space(6.0);
        }

        if let Some((app_id, pid, is_force)) = action {
            ProcessSupervisor::terminate_app(&app_id, pid, is_force);
            running_map.remove(&app_id);
            if is_force {
                *status_msg = Some((format!("Force killed {}", app_id), true));
            } else {
                *status_msg = Some((format!("Terminated {}", app_id), false));
            }
        }
    }

    ui.add_space(16.0);

    // 3. Suite Health & Architecture summary
    ui.label(RichText::new("Suite Health & Architecture:").size(15.0).color(theme.text_primary).strong());
    ui.add_space(6.0);

    Frame::new()
        .fill(theme.bg_card)
        .stroke(Stroke::new(1.0, theme.border_card))
        .corner_radius(CornerRadius::same(8))
        .inner_margin(Margin::same(16))
        .show(ui, |ui| {
            ui.vertical(|ui| {
                for app in apps {
                    let is_active = running_map.contains_key(app.id);
                    ui.horizontal(|ui| {
                        let dot = if is_active { "●" } else { "○" };
                        let dot_color = if is_active { theme.success } else { theme.text_muted };
                        ui.label(RichText::new(dot).color(dot_color).strong());
                        ui.label(RichText::new(app.name).size(13.5).color(theme.text_primary).strong());
                        ui.label(RichText::new(format!("({})", app.tagline)).size(12.0).color(theme.text_muted));
                        ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                            let status_label = if is_active { "ACTIVE" } else { "STANDBY" };
                            let color = if is_active { theme.success } else { theme.text_muted };
                            ui.label(RichText::new(status_label).size(11.5).color(color).strong());
                        });
                    });
                    ui.separator();
                }
            });
        });
}
