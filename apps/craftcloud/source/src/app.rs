use crate::app_registry::CraftApp;
use crate::process_supervisor::{ProcessInfo, ProcessSupervisor};
use crate::quick_tools::QuickToolsRunner;
use crate::theme::CraftTheme;
use crate::ui::apps_view::{self, AppsViewState};
use crate::ui::libraries_view::{self, LibrariesViewState};
use crate::ui::recents_view::{self, RecentsViewState};
use crate::ui::tools_view;
use crate::ui::activity_view;
use egui::{vec2, Align, Align2, Color32, CornerRadius, Frame, Layout, Margin, Panel, Pos2, Rect, RichText, Sense, Stroke};
use std::collections::HashMap;
use std::time::Instant;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NavTab {
    Apps,
    Recents,
    Libraries,
    Tools,
    Activity,
}

impl NavTab {
    pub fn icon(&self) -> &'static str {
        match self {
            NavTab::Apps => "▦",
            NavTab::Recents => "◷",
            NavTab::Libraries => "◈",
            NavTab::Tools => "⚡",
            NavTab::Activity => "∿",
        }
    }

    pub fn label(&self) -> &'static str {
        match self {
            NavTab::Apps => "All Applications",
            NavTab::Recents => "Recent Documents",
            NavTab::Libraries => "Design Libraries",
            NavTab::Tools => "Express Quick Tools",
            NavTab::Activity => "Process Monitor",
        }
    }
}

pub struct CraftCloudApp {
    pub theme: CraftTheme,
    pub apps: Vec<CraftApp>,
    pub running_processes: HashMap<String, ProcessInfo>,
    pub active_tab: NavTab,
    pub search_query: String,
    pub apps_state: AppsViewState,
    pub recents_state: RecentsViewState,
    pub libraries_state: LibrariesViewState,
    pub tools_runner: QuickToolsRunner,
    pub status_message: Option<(String, bool, Instant)>,
    pub last_proc_scan: Instant,
}

impl CraftCloudApp {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        egui_extras::install_image_loaders(&cc.egui_ctx);
        let theme = CraftTheme::detect();
        theme.apply_to_egui(&cc.egui_ctx);

        let apps = CraftApp::all();
        let running = ProcessSupervisor::scan_running().into_iter().collect();

        Self {
            theme,
            apps,
            running_processes: running,
            active_tab: NavTab::Apps,
            search_query: String::new(),
            apps_state: AppsViewState::default(),
            recents_state: RecentsViewState::default(),
            libraries_state: LibrariesViewState::default(),
            tools_runner: QuickToolsRunner::default(),
            status_message: None,
            last_proc_scan: Instant::now(),
        }
    }

    fn refresh_running_processes(&mut self) {
        let current = ProcessSupervisor::scan_running();
        self.running_processes = current.into_iter().collect();
        self.last_proc_scan = Instant::now();
    }
}

impl eframe::App for CraftCloudApp {
    fn ui(&mut self, root_ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        let ctx = root_ui.ctx().clone();

        // Poll process table every 1.5 seconds
        if self.last_proc_scan.elapsed().as_millis() > 1500 {
            self.refresh_running_processes();
        }

        // Poll QuickTools background worker
        self.tools_runner.update();

        // Clear toast message after 4.5 seconds
        if let Some((_, _, time)) = self.status_message {
            if time.elapsed().as_secs() > 4 {
                self.status_message = None;
            }
        }

        ctx.request_repaint_after(std::time::Duration::from_millis(500));

        let mut status_msg_pass = None;
        let mut switch_to_recents = None;

        // 1. Top Bar Panel (Minimalist, Pro Header)
        Panel::top("top_panel")
            .frame(
                Frame::new()
                    .fill(self.theme.bg_sidebar)
                    .stroke(Stroke::new(1.0, self.theme.border_subtle))
                    .inner_margin(Margin::symmetric(16, 10)),
            )
            .show(root_ui, |ui| {
                ui.horizontal(|ui| {
                    // Brand Mark (Clean, Typographic, Restrained)
                    ui.horizontal(|ui| {
                        let logo = egui::Image::from_bytes(
                            "bytes://icons/craftcloud.png",
                            include_bytes!("../assets/icons/craftcloud.png"),
                        )
                        .fit_to_exact_size(vec2(22.0, 22.0))
                        .corner_radius(CornerRadius::same(5));
                        ui.add(logo);
                        ui.add_space(4.0);
                        ui.label(RichText::new("CraftCloud").size(16.0).color(self.theme.text_primary).strong());
                        ui.label(RichText::new("Creative Suite").size(11.5).color(self.theme.text_muted));
                    });

                    ui.add_space(20.0);

                    // Omnisearch Box
                    let search_box = egui::TextEdit::singleline(&mut self.search_query)
                        .hint_text("Search apps, projects, or quick tools...")
                        .desired_width(280.0);
                    ui.add(search_box);

                    if !self.search_query.is_empty() {
                        if ui.button("✕").clicked() {
                            self.search_query.clear();
                        }
                    }

                    // Right Controls
                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        // Refresh button
                        let refresh_btn = egui::Button::new(RichText::new("↻").size(13.0).color(self.theme.text_secondary))
                            .fill(self.theme.bg_card)
                            .stroke(Stroke::new(1.0, self.theme.border_subtle))
                            .corner_radius(CornerRadius::same(4));
                        if ui.add(refresh_btn).clicked() {
                            self.refresh_running_processes();
                            self.recents_state = RecentsViewState::default();
                            self.status_message = Some(("Refreshed Craft processes & files".to_string(), false, Instant::now()));
                        }

                        // Theme indicator badge
                        let theme_mode_label = if self.theme.is_light { "Light" } else { "Dark" };
                        crate::ui::badge(
                            ui,
                            &format!("{} • {}", theme_mode_label, self.theme.theme_name),
                            self.theme.bg_badge,
                            self.theme.text_secondary,
                        );

                        // Running Count Pill
                        let run_count = self.running_processes.len();
                        let (pill_text, pill_color) = if run_count > 0 {
                            (format!("● {} Running", run_count), self.theme.success)
                        } else {
                            ("○ 0 Active".to_string(), self.theme.text_muted)
                        };
                        crate::ui::badge(ui, &pill_text, self.theme.bg_badge, pill_color);
                    });
                });
            });

        // 2. Left Sidebar Navigation Panel (Ultra-clean, Professional Design)
        Panel::left("left_sidebar")
            .default_size(200.0)
            .resizable(false)
            .frame(
                Frame::new()
                    .fill(self.theme.bg_sidebar)
                    .stroke(Stroke::new(1.0, self.theme.border_subtle))
                    .inner_margin(Margin::symmetric(10, 14)),
            )
            .show(root_ui, |ui| {
                ui.label(
                    RichText::new("NAVIGATION")
                        .size(10.0)
                        .color(self.theme.text_muted)
                        .strong(),
                );
                ui.add_space(6.0);

                let tabs = [
                    NavTab::Apps,
                    NavTab::Recents,
                    NavTab::Libraries,
                    NavTab::Tools,
                    NavTab::Activity,
                ];

                for tab in tabs {
                    let is_active = self.active_tab == tab;
                    let (rect, response) = ui.allocate_exact_size(vec2(ui.available_width(), 32.0), Sense::click());

                    let is_hovered = response.hovered();
                    let bg_color = if is_active {
                        self.theme.bg_card
                    } else if is_hovered {
                        self.theme.bg_card_hover
                    } else {
                        Color32::TRANSPARENT
                    };

                    // Draw background
                    ui.painter().rect_filled(rect, CornerRadius::same(5), bg_color);

                    // Draw subtle active left indicator stripe
                    if is_active {
                        let indicator_rect = Rect::from_min_size(rect.min, vec2(3.0, rect.height()));
                        ui.painter().rect_filled(indicator_rect, CornerRadius::same(2), self.theme.accent);
                    }

                    // Draw icon and text
                    let icon_color = if is_active { self.theme.accent } else { self.theme.text_secondary };
                    let text_color = if is_active { self.theme.text_primary } else { self.theme.text_secondary };

                    let icon_pos = Pos2::new(rect.min.x + 10.0, rect.center().y);
                    ui.painter().text(
                        icon_pos,
                        Align2::LEFT_CENTER,
                        tab.icon(),
                        egui::FontId::proportional(13.0),
                        icon_color,
                    );

                    let text_pos = Pos2::new(rect.min.x + 30.0, rect.center().y);
                    ui.painter().text(
                        text_pos,
                        Align2::LEFT_CENTER,
                        tab.label(),
                        egui::FontId::proportional(12.5),
                        text_color,
                    );

                    if response.clicked() {
                        self.active_tab = tab;
                    }
                    ui.add_space(2.0);
                }

                ui.add_space(18.0);
                ui.label(
                    RichText::new("INSTALLED SUITE")
                        .size(10.0)
                        .color(self.theme.text_muted)
                        .strong(),
                );
                ui.add_space(6.0);

                // Compact Installed App Items in sidebar
                for app in &self.apps {
                    let is_running = self.running_processes.contains_key(app.id);
                    let (rect, response) = ui.allocate_exact_size(vec2(ui.available_width(), 28.0), Sense::click());

                    if response.hovered() {
                        ui.painter().rect_filled(rect, CornerRadius::same(4), self.theme.bg_card_hover);
                    }

                    // Mini Icon (18x18)
                    let icon_rect = Rect::from_min_size(
                        Pos2::new(rect.min.x + 8.0, rect.center().y - 9.0),
                        vec2(18.0, 18.0),
                    );
                    let img = egui::Image::from_bytes(app.icon_uri, app.icon_bytes)
                        .fit_to_exact_size(vec2(18.0, 18.0))
                        .corner_radius(CornerRadius::same(3));
                    img.paint_at(ui, icon_rect);

                    // App Name
                    let text_pos = Pos2::new(rect.min.x + 34.0, rect.center().y);
                    ui.painter().text(
                        text_pos,
                        Align2::LEFT_CENTER,
                        app.name,
                        egui::FontId::proportional(12.0),
                        self.theme.text_primary,
                    );

                    // Running Dot
                    let dot = if is_running { "●" } else { "○" };
                    let dot_color = if is_running { self.theme.success } else { self.theme.text_muted };
                    let dot_pos = Pos2::new(rect.max.x - 12.0, rect.center().y);
                    ui.painter().text(
                        dot_pos,
                        Align2::RIGHT_CENTER,
                        dot,
                        egui::FontId::proportional(9.0),
                        dot_color,
                    );

                    if response.clicked() {
                        self.active_tab = NavTab::Apps;
                    }
                    ui.add_space(2.0);
                }

                // Docked Footer (Matching the reference screenshot)
                ui.with_layout(Layout::bottom_up(Align::Min), |ui| {
                    ui.label(RichText::new("Craft Suite v0.1.0 • Pure Rust").size(10.0).color(self.theme.text_muted));
                    ui.add_space(4.0);

                    let (rect, response) = ui.allocate_exact_size(vec2(ui.available_width(), 26.0), Sense::click());
                    if response.hovered() {
                        ui.painter().rect_filled(rect, CornerRadius::same(4), self.theme.bg_card_hover);
                    }
                    let settings_pos = Pos2::new(rect.min.x + 8.0, rect.center().y);
                    ui.painter().text(
                        settings_pos,
                        Align2::LEFT_CENTER,
                        "⚙  Theme Settings",
                        egui::FontId::proportional(11.5),
                        self.theme.text_secondary,
                    );
                    if response.clicked() {
                        self.active_tab = NavTab::Libraries;
                    }
                });
            });

        // 3. Central Canvas Panel
        egui::CentralPanel::default()
            .frame(
                Frame::new()
                    .fill(self.theme.bg_app)
                    .inner_margin(Margin::symmetric(20, 18)),
            )
            .show(root_ui, |ui| {
                match self.active_tab {
                    NavTab::Apps => {
                        apps_view::render(
                            ui,
                            &self.apps,
                            &mut self.running_processes,
                            &self.theme,
                            &mut self.apps_state,
                            &self.search_query,
                            &mut status_msg_pass,
                            &mut switch_to_recents,
                        );
                    }
                    NavTab::Recents => {
                        recents_view::render(
                            ui,
                            &self.apps,
                            &self.theme,
                            &mut self.recents_state,
                            &self.search_query,
                            &mut status_msg_pass,
                        );
                    }
                    NavTab::Libraries => {
                        libraries_view::render(
                            ui,
                            &self.theme,
                            &mut self.libraries_state,
                            &mut status_msg_pass,
                        );
                    }
                    NavTab::Tools => {
                        tools_view::render(ui, &self.theme, &mut self.tools_runner);
                    }
                    NavTab::Activity => {
                        activity_view::render(
                            ui,
                            &self.apps,
                            &mut self.running_processes,
                            &self.theme,
                            &mut status_msg_pass,
                        );
                    }
                }

                // Toast Notification
                if let Some((ref msg, is_err, _)) = self.status_message {
                    ui.add_space(8.0);
                    let (bg, stroke_col) = if is_err {
                        (self.theme.danger, self.theme.danger)
                    } else {
                        (self.theme.bg_card, self.theme.accent)
                    };

                    Frame::new()
                        .fill(bg)
                        .stroke(Stroke::new(1.0, stroke_col))
                        .corner_radius(CornerRadius::same(6))
                        .inner_margin(Margin::symmetric(14, 8))
                        .show(ui, |ui| {
                            let text_col = if is_err { Color32::WHITE } else { self.theme.text_primary };
                            ui.label(RichText::new(msg).size(12.5).color(text_col).strong());
                        });
                }
            });

        // Handle internal message callbacks
        if let Some((msg, is_err)) = status_msg_pass {
            self.status_message = Some((msg, is_err, Instant::now()));
        }

        if let Some(app_id) = switch_to_recents {
            self.active_tab = NavTab::Recents;
            self.recents_state.app_filter = Some(app_id);
        }
    }
}
