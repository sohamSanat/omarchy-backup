pub mod apps_view;
pub mod recents_view;
pub mod libraries_view;
pub mod tools_view;
pub mod activity_view;

use egui::{Color32, CornerRadius, Margin, RichText, Ui};

pub fn badge(ui: &mut Ui, text: &str, bg: Color32, fg: Color32) {
    egui::Frame::new()
        .fill(bg)
        .corner_radius(CornerRadius::same(4))
        .inner_margin(Margin::symmetric(6, 2))
        .show(ui, |ui| {
            ui.label(RichText::new(text).size(11.0).color(fg).strong());
        });
}

#[allow(dead_code)]
pub fn section_header(ui: &mut Ui, title: &str, subtitle: &str, text_color: Color32, muted_color: Color32) {
    ui.horizontal(|ui| {
        ui.heading(RichText::new(title).size(20.0).color(text_color).strong());
        if !subtitle.is_empty() {
            ui.label(RichText::new(format!("— {}", subtitle)).size(13.0).color(muted_color));
        }
    });
    ui.add_space(8.0);
}
