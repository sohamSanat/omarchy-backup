use crate::quick_tools::{QuickToolKind, QuickToolsRunner};
use crate::theme::CraftTheme;
use egui::{CornerRadius, Frame, Margin, RichText, Stroke, Ui};

pub fn render(
    ui: &mut Ui,
    theme: &CraftTheme,
    runner: &mut QuickToolsRunner,
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
                        RichText::new("Quick Express Tools")
                            .size(22.0)
                            .color(theme.text_primary)
                            .strong(),
                    );
                    ui.label(
                        RichText::new("Headless command runners. Execute instant conversions, PDF operations, and photo merges without opening full editors.")
                            .size(13.0)
                            .color(theme.text_secondary),
                    );
                });
            });
        });

    ui.add_space(14.0);

    // 2. Tool Selector Chips
    ui.horizontal(|ui| {
        let tools = [
            QuickToolKind::ImageConvert,
            QuickToolKind::PdfCombine,
            QuickToolKind::PdfExtract,
            QuickToolKind::PhotoRender,
            QuickToolKind::VectorConvert,
        ];

        for tool in tools {
            let is_sel = runner.active_tool == tool;
            let (bg, fg) = if is_sel {
                (theme.accent, theme.text_on_accent)
            } else {
                (theme.bg_card, theme.text_secondary)
            };

            let btn = egui::Button::new(RichText::new(tool.title()).size(12.0).color(fg).strong())
                .fill(bg)
                .corner_radius(CornerRadius::same(14))
                .stroke(Stroke::new(1.0, if is_sel { theme.accent } else { theme.border_subtle }));

            if ui.add(btn).clicked() {
                runner.active_tool = tool;
            }
        }
    });

    ui.add_space(12.0);

    // 3. Tool Config Card
    Frame::new()
        .fill(theme.bg_card)
        .stroke(Stroke::new(1.0, theme.border_card))
        .corner_radius(CornerRadius::same(8))
        .inner_margin(Margin::same(16))
        .show(ui, |ui| {
            ui.vertical(|ui| {
                ui.horizontal(|ui| {
                    ui.label(RichText::new(runner.active_tool.title()).size(16.0).color(theme.text_primary).strong());
                    crate::ui::badge(ui, runner.active_tool.engine(), theme.bg_badge, theme.accent);
                });

                ui.label(RichText::new(runner.active_tool.description()).size(12.5).color(theme.text_secondary));
                ui.add_space(10.0);

                // Inputs
                ui.label(RichText::new("Input File 1:").size(12.0).color(theme.text_muted));
                ui.add(egui::TextEdit::singleline(&mut runner.input_path_1).hint_text("Absolute file path (e.g. /home/soham/Pictures/sample.psd)"));
                ui.add_space(6.0);

                if runner.active_tool == QuickToolKind::PdfCombine {
                    ui.label(RichText::new("Input File 2 (optional second PDF):").size(12.0).color(theme.text_muted));
                    ui.add(egui::TextEdit::singleline(&mut runner.input_path_2).hint_text("Second PDF to merge (e.g. /home/soham/Documents/page2.pdf)"));
                    ui.add_space(6.0);
                }

                ui.label(RichText::new("Output File:").size(12.0).color(theme.text_muted));
                ui.add(egui::TextEdit::singleline(&mut runner.output_path).hint_text("Target output path (e.g. /tmp/converted_output.png)"));
                ui.add_space(8.0);

                if runner.active_tool == QuickToolKind::ImageConvert || runner.active_tool == QuickToolKind::PhotoRender {
                    ui.horizontal(|ui| {
                        ui.label(RichText::new("Quality:").size(12.0).color(theme.text_muted));
                        ui.add(egui::Slider::new(&mut runner.quality, 1..=100));

                        ui.add_space(16.0);

                        ui.label(RichText::new("Format:").size(12.0).color(theme.text_muted));
                        let formats = ["png", "jpg", "webp", "tif", "exr"];
                        for f in formats {
                            if ui.selectable_label(runner.format_choice == f, f).clicked() {
                                runner.format_choice = f.to_string();
                            }
                        }
                    });
                    ui.add_space(8.0);
                }

                // Action execution button
                ui.horizontal(|ui| {
                    let btn_text = if runner.is_running { "Running..." } else { "▶ Run Headless Action" };
                    let exec_btn = egui::Button::new(
                        RichText::new(btn_text)
                            .size(13.5)
                            .color(theme.text_on_accent)
                            .strong(),
                    )
                    .fill(if runner.is_running { theme.text_muted } else { theme.accent })
                    .corner_radius(CornerRadius::same(6));

                    if ui.add_enabled(!runner.is_running, exec_btn).clicked() {
                        runner.execute();
                    }

                    if runner.is_running {
                        ui.spinner();
                    }
                });
            });
        });

    ui.add_space(12.0);

    // 4. Execution Console Terminal
    ui.label(RichText::new("Headless Execution Log:").size(13.0).color(theme.text_muted));
    ui.add_space(4.0);

    Frame::new()
        .fill(theme.bg_input)
        .stroke(Stroke::new(1.0, theme.border_card))
        .corner_radius(CornerRadius::same(6))
        .inner_margin(Margin::same(12))
        .show(ui, |ui| {
            egui::ScrollArea::vertical()
                .max_height(180.0)
                .stick_to_bottom(true)
                .show(ui, |ui| {
                    ui.set_min_width(ui.available_width());
                    for line in &runner.log_console {
                        let color = if line.starts_with('✓') {
                            theme.success
                        } else if line.starts_with('✗') {
                            theme.danger
                        } else if line.starts_with('▶') {
                            theme.accent
                        } else {
                            theme.text_secondary
                        };
                        ui.label(RichText::new(line).monospace().size(11.5).color(color));
                    }
                });
        });
}
