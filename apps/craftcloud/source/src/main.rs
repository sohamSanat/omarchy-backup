mod app;
mod app_registry;
mod libraries;
mod process_supervisor;
mod quick_tools;
mod recents;
mod theme;
mod ui;

use app::CraftCloudApp;
use eframe::NativeOptions;

fn main() -> eframe::Result<()> {
    let native_options = NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("CraftCloud — Creative Suite Hub")
            .with_inner_size([1100.0, 720.0])
            .with_min_inner_size([850.0, 560.0])
            .with_app_id("ai.storyteller.craftcloud"),
        ..Default::default()
    };

    eframe::run_native(
        "CraftCloud",
        native_options,
        Box::new(|cc| Ok(Box::new(CraftCloudApp::new(cc)))),
    )
}
