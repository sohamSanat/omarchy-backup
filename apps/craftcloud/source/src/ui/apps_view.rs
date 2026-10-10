use crate::app_registry::{AppCategory, CraftApp};
use crate::process_supervisor::{ProcessInfo, ProcessSupervisor};
use crate::theme::CraftTheme;
use egui::{vec2, Align, Color32, CornerRadius, Frame, Layout, Margin, RichText, Stroke, Ui};
use std::collections::HashMap;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AppViewMode {
    List,
    Grid,
}

pub struct AppsViewState {
    pub category_filter: AppCategory,
    pub view_mode: AppViewMode,
    pub xwayland_flags: HashMap<String, bool>,
}

impl Default for AppsViewState {
    fn default() -> Self {
        Self {
            category_filter: AppCategory::All,
            view_mode: AppViewMode::Grid,
            xwayland_flags: HashMap::new(),
        }
    }
}

pub fn render(
    ui: &mut Ui,
    apps: &[CraftApp],
    running_map: &mut HashMap<String, ProcessInfo>,
    theme: &CraftTheme,
    state: &mut AppsViewState,
    search_query: &str,
    status_msg: &mut Option<(String, bool)>,
    on_switch_to_recents: &mut Option<String>,
) {
    // 1. Top Section Header (Clean, Non-overlapping)
    Frame::new()
        .fill(theme.bg_card)
        .stroke(Stroke::new(1.0, theme.border_card))
        .corner_radius(CornerRadius::same(6))
        .inner_margin(Margin::symmetric(14, 10))
        .show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.vertical(|ui| {
                    ui.label(
                        RichText::new("Creative Suite Applications")
                            .size(17.0)
                            .color(theme.text_primary)
                            .strong(),
                    );
                    ui.label(
                        RichText::new("Unified command center for high-performance Rust creative tools.")
                            .size(11.5)
                            .color(theme.text_muted),
                    );
                });

                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                    // View Toggle (List vs Grid)
                    Frame::new()
                        .fill(theme.bg_app)
                        .stroke(Stroke::new(1.0, theme.border_subtle))
                        .corner_radius(CornerRadius::same(4))
                        .inner_margin(Margin::symmetric(2, 2))
                        .show(ui, |ui| {
                            ui.horizontal(|ui| {
                                let is_list = state.view_mode == AppViewMode::List;
                                let list_btn = egui::Button::new(
                                    RichText::new("☰ List")
                                        .size(11.0)
                                        .color(if is_list { theme.text_on_accent } else { theme.text_secondary })
                                        .strong(),
                                )
                                .fill(if is_list { theme.accent } else { Color32::TRANSPARENT })
                                .corner_radius(CornerRadius::same(3));

                                if ui.add(list_btn).clicked() {
                                    state.view_mode = AppViewMode::List;
                                }

                                let is_grid = state.view_mode == AppViewMode::Grid;
                                let grid_btn = egui::Button::new(
                                    RichText::new("⊞ Grid")
                                        .size(11.0)
                                        .color(if is_grid { theme.text_on_accent } else { theme.text_secondary })
                                        .strong(),
                                )
                                .fill(if is_grid { theme.accent } else { Color32::TRANSPARENT })
                                .corner_radius(CornerRadius::same(3));

                                if ui.add(grid_btn).clicked() {
                                    state.view_mode = AppViewMode::Grid;
                                }
                            });
                        });

                    ui.add_space(8.0);

                    let running_count = running_map.len();
                    if running_count > 0 {
                        crate::ui::badge(ui, &format!("● {} Running", running_count), theme.success, Color32::WHITE);
                    } else {
                        crate::ui::badge(ui, "○ 0 Running", theme.bg_badge, theme.text_muted);
                    }
                });
            });
        });

    ui.add_space(10.0);

    // 2. Category Filter Pills
    ui.horizontal_wrapped(|ui| {
        let categories = [
            AppCategory::All,
            AppCategory::Design,
            AppCategory::Photography,
            AppCategory::Video,
            AppCategory::Document,
        ];

        for cat in categories {
            let is_selected = state.category_filter == cat;
            let (bg, fg) = if is_selected {
                (theme.accent, theme.text_on_accent)
            } else {
                (theme.bg_card, theme.text_secondary)
            };

            let btn = egui::Button::new(RichText::new(cat.label()).size(11.0).color(fg).strong())
                .fill(bg)
                .corner_radius(CornerRadius::same(4))
                .stroke(Stroke::new(1.0, if is_selected { theme.accent } else { theme.border_subtle }));

            if ui.add(btn).clicked() {
                state.category_filter = cat;
            }
        }
    });

    ui.add_space(10.0);

    // Filter matching apps
    let filtered_apps: Vec<&CraftApp> = apps
        .iter()
        .filter(|app| {
            if state.category_filter != AppCategory::All && app.category != state.category_filter {
                return false;
            }
            if !search_query.is_empty() {
                let q = search_query.to_lowercase();
                let matches_name = app.name.to_lowercase().contains(&q);
                let matches_tag = app.tagline.to_lowercase().contains(&q);
                let matches_desc = app.description.to_lowercase().contains(&q);
                let matches_role = app.role.to_lowercase().contains(&q);
                if !matches_name && !matches_tag && !matches_desc && !matches_role {
                    return false;
                }
            }
            true
        })
        .collect();

    // 3. Render either Equal-Height List View or Equal-Height Grid View
    egui::ScrollArea::vertical()
        .auto_shrink([false, false])
        .show(ui, |ui| {
            ui.add_space(4.0);
            match state.view_mode {
                AppViewMode::List => render_list_view(
                    ui,
                    &filtered_apps,
                    running_map,
                    theme,
                    state,
                    status_msg,
                    on_switch_to_recents,
                ),
                AppViewMode::Grid => render_grid_view(
                    ui,
                    &filtered_apps,
                    running_map,
                    theme,
                    state,
                    status_msg,
                    on_switch_to_recents,
                ),
            }
        });
}

/// Adobe Creative Cloud Style: 100% Equal Height, Two-Tier Uniform Cards
fn render_list_view(
    ui: &mut Ui,
    apps: &[&CraftApp],
    running_map: &mut HashMap<String, ProcessInfo>,
    theme: &CraftTheme,
    state: &mut AppsViewState,
    status_msg: &mut Option<(String, bool)>,
    on_switch_to_recents: &mut Option<String>,
) {
    for app in apps {
        let proc_info = running_map.get(app.id).cloned();
        let is_running = proc_info.is_some();
        let force_xwayland = state.xwayland_flags.get(app.id).copied().unwrap_or(false);

        Frame::new()
            .fill(theme.bg_card)
            .stroke(Stroke::new(1.0, if is_running { theme.accent } else { theme.border_card }))
            .corner_radius(CornerRadius::same(8))
            .inner_margin(Margin::symmetric(16, 12))
            .show(ui, |ui| {
                ui.set_min_height(76.0);
                ui.set_max_height(76.0);

                ui.vertical(|ui| {
                    // Row 1: Icon + Title + Version + Tagline + Live Status Badge
                    ui.horizontal(|ui| {
                        let img = egui::Image::from_bytes(app.icon_uri, app.icon_bytes)
                            .fit_to_exact_size(vec2(34.0, 34.0))
                            .corner_radius(CornerRadius::same(6));
                        ui.add(img);

                        ui.add_space(8.0);

                        ui.vertical(|ui| {
                            ui.horizontal(|ui| {
                                ui.label(RichText::new(app.name).size(15.0).color(theme.text_primary).strong());
                                crate::ui::badge(ui, app.version, theme.bg_badge, theme.text_muted);
                                crate::ui::badge(ui, app.tagline, theme.bg_badge, theme.accent);
                            });
                            ui.label(RichText::new(app.role).size(11.0).color(theme.text_secondary));
                        });

                        ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                            if let Some(ref info) = proc_info {
                                crate::ui::badge(
                                    ui,
                                    &format!("● PID {} ({:.0}MB)", info.pid, info.rss_mb),
                                    theme.bg_badge,
                                    theme.success,
                                );
                            } else {
                                ui.label(RichText::new("○ Ready").size(11.0).color(theme.text_muted));
                            }
                        });
                    });

                    ui.add_space(6.0);

                    // Row 2: Secondary shortcuts on the left, Primary Action Buttons on the right
                    ui.horizontal(|ui| {
                        let recents_link = egui::Button::new(
                            RichText::new("Files →")
                                .size(11.0)
                                .color(theme.text_muted),
                        )
                        .frame(false);

                        if ui.add(recents_link).clicked() {
                            *on_switch_to_recents = Some(app.id.to_string());
                        }

                        ui.add_space(6.0);

                        let mut xwayland = force_xwayland;
                        if ui.checkbox(&mut xwayland, RichText::new("X11").size(10.5).color(theme.text_muted)).changed() {
                            state.xwayland_flags.insert(app.id.to_string(), xwayland);
                        }

                        // Right-docked Action Buttons
                        ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                            if is_running {
                                let focus_btn = egui::Button::new(
                                    RichText::new("Bring to Front")
                                        .size(11.5)
                                        .color(theme.text_on_accent)
                                        .strong(),
                                )
                                .fill(theme.accent)
                                .corner_radius(CornerRadius::same(4))
                                .min_size(vec2(90.0, 24.0));

                                if ui.add(focus_btn).clicked() {
                                    ProcessSupervisor::focus_window(app.wm_class);
                                    *status_msg = Some((format!("Focused {}", app.name), false));
                                }

                                let quit_btn = egui::Button::new(
                                    RichText::new("Quit")
                                        .size(11.0)
                                        .color(theme.danger),
                                )
                                .fill(theme.bg_app)
                                .stroke(Stroke::new(1.0, theme.danger))
                                .corner_radius(CornerRadius::same(4))
                                .min_size(vec2(50.0, 24.0));

                                if ui.add(quit_btn).clicked() {
                                    if let Some(ref info) = proc_info {
                                        ProcessSupervisor::terminate_app(app.id, info.pid, false);
                                        running_map.remove(app.id);
                                        *status_msg = Some((format!("Terminated {}", app.name), false));
                                    }
                                }
                            } else {
                                let open_btn = egui::Button::new(
                                    RichText::new("Open")
                                        .size(11.5)
                                        .color(theme.text_on_accent)
                                        .strong(),
                                )
                                .fill(theme.accent)
                                .corner_radius(CornerRadius::same(4))
                                .min_size(vec2(65.0, 24.0));

                                if ui.add(open_btn).clicked() {
                                    match ProcessSupervisor::launch(
                                        &app.binary_path,
                                        app.id,
                                        false,
                                        force_xwayland,
                                        None,
                                    ) {
                                        Ok((pid, target_ws)) => {
                                            running_map.insert(
                                                app.id.to_string(),
                                                ProcessInfo {
                                                    pid,
                                                    name: app.id.to_string(),
                                                    rss_mb: 25.0,
                                                    cmdline: app.binary_path.to_string_lossy().to_string(),
                                                },
                                            );
                                            let ws_text = target_ws.map(|w| format!(" on Workspace {}", w)).unwrap_or_default();
                                            *status_msg = Some((format!("Launched {}{} (PID {})", app.name, ws_text, pid), false));
                                        }
                                        Err(e) => {
                                            *status_msg = Some((e, true));
                                        }
                                    }
                                }

                                let demo_btn = egui::Button::new(
                                    RichText::new("Demo")
                                        .size(11.0)
                                        .color(theme.text_secondary),
                                )
                                .fill(theme.bg_app)
                                .stroke(Stroke::new(1.0, theme.border_subtle))
                                .corner_radius(CornerRadius::same(4))
                                .min_size(vec2(50.0, 24.0));

                                if ui.add(demo_btn).clicked() {
                                    match ProcessSupervisor::launch(
                                        &app.binary_path,
                                        app.id,
                                        true,
                                        force_xwayland,
                                        None,
                                    ) {
                                        Ok((pid, target_ws)) => {
                                            running_map.insert(
                                                app.id.to_string(),
                                                ProcessInfo {
                                                    pid,
                                                    name: app.id.to_string(),
                                                    rss_mb: 25.0,
                                                    cmdline: app.binary_path.to_string_lossy().to_string(),
                                                },
                                            );
                                            let ws_text = target_ws.map(|w| format!(" on Workspace {}", w)).unwrap_or_default();
                                            *status_msg = Some((format!("Launched {} Demo{} (PID {})", app.name, ws_text, pid), false));
                                        }
                                        Err(e) => {
                                            *status_msg = Some((e, true));
                                        }
                                    }
                                }
                            }
                        });
                    });
                });
            });

        ui.add_space(10.0);
    }
}

/// Equal-Height, Equal-Width Grid Cards with Generous Spacing and Margins
fn render_grid_view(
    ui: &mut Ui,
    apps: &[&CraftApp],
    running_map: &mut HashMap<String, ProcessInfo>,
    theme: &CraftTheme,
    state: &mut AppsViewState,
    status_msg: &mut Option<(String, bool)>,
    on_switch_to_recents: &mut Option<String>,
) {
    let min_outer_card_w = 260.0;
    let outer_card_h = 160.0;
    let card_padding = 14.0;
    let inner_card_h = outer_card_h - 2.0 * card_padding;
    let gap_x = 18.0;
    let gap_y = 18.0;

    // Symmetrical right margin: reserves clean right-side margin matching the left side
    // and clears the vertical scrollbar track
    let right_gutter = 12.0;
    let available_w = (ui.available_width() - right_gutter).max(min_outer_card_w);
    let cols = (((available_w + gap_x) / (min_outer_card_w + gap_x)).floor() as usize).max(1);

    // Compute exact outer and inner card widths so columns fill available_w perfectly
    let total_gap_w = (cols.saturating_sub(1)) as f32 * gap_x;
    let outer_card_w = (available_w - total_gap_w) / cols as f32;
    let inner_card_w = outer_card_w - 2.0 * card_padding;

    for chunk in apps.chunks(cols) {
        ui.horizontal(|ui| {
            ui.spacing_mut().item_spacing.x = gap_x;

            for app in chunk {
                let proc_info = running_map.get(app.id).cloned();
                let is_running = proc_info.is_some();
                let force_xwayland = state.xwayland_flags.get(app.id).copied().unwrap_or(false);

                Frame::new()
                    .fill(theme.bg_card)
                    .stroke(Stroke::new(1.0, if is_running { theme.accent } else { theme.border_card }))
                    .corner_radius(CornerRadius::same(8))
                    .inner_margin(Margin::same(card_padding as i8))
                    .show(ui, |ui| {
                        ui.spacing_mut().item_spacing.x = 6.0;
                        ui.set_width(inner_card_w);
                        ui.set_height(inner_card_h);

                        ui.vertical(|ui| {
                            // Header: Icon + Title + Version + Tagline
                            ui.horizontal(|ui| {
                                let img = egui::Image::from_bytes(app.icon_uri, app.icon_bytes)
                                    .fit_to_exact_size(vec2(36.0, 36.0))
                                    .corner_radius(CornerRadius::same(6));
                                ui.add(img);

                                ui.add_space(8.0);
                                ui.vertical(|ui| {
                                    ui.horizontal(|ui| {
                                        ui.label(RichText::new(app.name).size(14.5).color(theme.text_primary).strong());
                                        crate::ui::badge(ui, app.version, theme.bg_badge, theme.text_muted);
                                    });
                                    ui.label(RichText::new(app.tagline).size(11.0).color(theme.accent));
                                });
                            });

                            ui.add_space(6.0);
                            ui.label(
                                RichText::new(app.role)
                                    .size(11.0)
                                    .color(theme.text_secondary),
                            );

                            // Push bottom actions to strict aligned position
                            ui.with_layout(Layout::bottom_up(Align::Min), |ui| {
                                ui.horizontal(|ui| {
                                    if is_running {
                                        let focus_btn = egui::Button::new(
                                            RichText::new("Bring to Front")
                                                .size(11.0)
                                                .color(theme.text_on_accent)
                                                .strong(),
                                        )
                                        .fill(theme.accent)
                                        .corner_radius(CornerRadius::same(4))
                                        .min_size(vec2(90.0, 24.0));
                                        if ui.add(focus_btn).clicked() {
                                            ProcessSupervisor::focus_window(app.wm_class);
                                        }

                                        let quit_btn = egui::Button::new(
                                            RichText::new("Quit")
                                                .size(10.5)
                                                .color(theme.danger),
                                        )
                                        .fill(theme.bg_app)
                                        .stroke(Stroke::new(1.0, theme.danger))
                                        .corner_radius(CornerRadius::same(4))
                                        .min_size(vec2(50.0, 24.0));
                                        if ui.add(quit_btn).clicked() {
                                            if let Some(ref info) = proc_info {
                                                ProcessSupervisor::terminate_app(app.id, info.pid, false);
                                                running_map.remove(app.id);
                                                *status_msg = Some((format!("Terminated {}", app.name), false));
                                            }
                                        }
                                    } else {
                                        let open_btn = egui::Button::new(
                                            RichText::new("Open")
                                                .size(11.0)
                                                .color(theme.text_on_accent)
                                                .strong(),
                                        )
                                        .fill(theme.accent)
                                        .corner_radius(CornerRadius::same(4))
                                        .min_size(vec2(60.0, 24.0));

                                        if ui.add(open_btn).clicked() {
                                            match ProcessSupervisor::launch(
                                                &app.binary_path,
                                                app.id,
                                                false,
                                                force_xwayland,
                                                None,
                                            ) {
                                                Ok((pid, target_ws)) => {
                                                    running_map.insert(
                                                        app.id.to_string(),
                                                        ProcessInfo {
                                                            pid,
                                                            name: app.id.to_string(),
                                                            rss_mb: 25.0,
                                                            cmdline: app.binary_path.to_string_lossy().to_string(),
                                                        },
                                                    );
                                                    let ws_text = target_ws.map(|w| format!(" on Workspace {}", w)).unwrap_or_default();
                                                    *status_msg = Some((format!("Launched {}{} (PID {})", app.name, ws_text, pid), false));
                                                }
                                                Err(e) => {
                                                    *status_msg = Some((e, true));
                                                }
                                            }
                                        }

                                        let demo_btn = egui::Button::new(
                                            RichText::new("Demo")
                                                .size(10.5)
                                                .color(theme.text_secondary),
                                        )
                                        .fill(theme.bg_app)
                                        .stroke(Stroke::new(1.0, theme.border_subtle))
                                        .corner_radius(CornerRadius::same(4))
                                        .min_size(vec2(52.0, 24.0));

                                        if ui.add(demo_btn).clicked() {
                                            match ProcessSupervisor::launch(
                                                &app.binary_path,
                                                app.id,
                                                true,
                                                force_xwayland,
                                                None,
                                            ) {
                                                Ok((pid, target_ws)) => {
                                                    running_map.insert(
                                                        app.id.to_string(),
                                                        ProcessInfo {
                                                            pid,
                                                            name: app.id.to_string(),
                                                            rss_mb: 25.0,
                                                            cmdline: app.binary_path.to_string_lossy().to_string(),
                                                        },
                                                    );
                                                    let ws_text = target_ws.map(|w| format!(" on Workspace {}", w)).unwrap_or_default();
                                                    *status_msg = Some((format!("Launched {} Demo{} (PID {})", app.name, ws_text, pid), false));
                                                }
                                                Err(e) => {
                                                    *status_msg = Some((e, true));
                                                }
                                            }
                                        }
                                    }

                                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                                        let link = egui::Button::new(RichText::new("Files →").size(10.5).color(theme.text_muted)).frame(false);
                                        if ui.add(link).clicked() {
                                            *on_switch_to_recents = Some(app.id.to_string());
                                        }
                                    });
                                });

                                ui.add_space(4.0);

                                // Status row right above buttons
                                ui.horizontal(|ui| {
                                    if let Some(ref info) = proc_info {
                                        ui.label(RichText::new("● Active").size(10.5).color(theme.success).strong());
                                        ui.label(RichText::new(format!("PID {} ({:.0}MB)", info.pid, info.rss_mb)).size(10.0).color(theme.text_muted));
                                    } else {
                                        ui.label(RichText::new("○ Ready").size(10.5).color(theme.text_muted));
                                    }
                                });
                            });
                        });
                    });
            }
        });
        ui.add_space(gap_y);
    }
}
