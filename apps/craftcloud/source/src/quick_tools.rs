use std::path::PathBuf;
use std::process::Command;
use std::sync::mpsc::{channel, Receiver, Sender};
use std::time::Instant;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum QuickToolKind {
    ImageConvert,
    PdfCombine,
    PdfExtract,
    PhotoRender,
    VectorConvert,
}

impl QuickToolKind {
    pub fn title(&self) -> &'static str {
        match self {
            QuickToolKind::ImageConvert => "Image Format Transcoder",
            QuickToolKind::PdfCombine => "Combine & Merge PDFs",
            QuickToolKind::PdfExtract => "Extract PDF Pages",
            QuickToolKind::PhotoRender => "Develop & Export RAW Photo",
            QuickToolKind::VectorConvert => "Vector to Raster / SVG Converter",
        }
    }

    pub fn engine(&self) -> &'static str {
        match self {
            QuickToolKind::ImageConvert => "photocraft-cli convert",
            QuickToolKind::PdfCombine => "pdfcraft-cli combine",
            QuickToolKind::PdfExtract => "pdfcraft-cli extract",
            QuickToolKind::PhotoRender => "lightcraft-cli render",
            QuickToolKind::VectorConvert => "vectorcraft-cli convert",
        }
    }

    pub fn description(&self) -> &'static str {
        match self {
            QuickToolKind::ImageConvert => "Convert between raster formats (.pcraft, .psd, .png, .jpg, .webp, .exr) without opening the full editor.",
            QuickToolKind::PdfCombine => "Combine multiple PDF documents or page ranges into a single optimized output PDF.",
            QuickToolKind::PdfExtract => "Extract specific pages or page intervals from an existing PDF document.",
            QuickToolKind::PhotoRender => "Develop a RAW file (.dng, .arw, .cr3, .nef) with the LightCraft pipeline directly to JPEG/AVIF.",
            QuickToolKind::VectorConvert => "Render vector artboards (.vectorcraft, .svg, .ai) into high-res raster or clean SVG/PDF.",
        }
    }
}

pub struct ExecutionResult {
    pub success: bool,
    pub output: String,
    pub duration_ms: u128,
}

pub struct QuickToolsRunner {
    pub active_tool: QuickToolKind,
    pub input_path_1: String,
    pub input_path_2: String,
    pub output_path: String,
    pub format_choice: String,
    pub quality: u32,
    pub is_running: bool,
    pub log_console: Vec<String>,
    pub rx: Option<Receiver<ExecutionResult>>,
    pub tx: Sender<ExecutionResult>,
}

impl Default for QuickToolsRunner {
    fn default() -> Self {
        let (tx, rx) = channel();
        Self {
            active_tool: QuickToolKind::ImageConvert,
            input_path_1: String::new(),
            input_path_2: String::new(),
            output_path: String::new(),
            format_choice: "png".to_string(),
            quality: 90,
            is_running: false,
            log_console: vec!["Ready. Select a tool and specify files to run headless operations.".to_string()],
            rx: Some(rx),
            tx,
        }
    }
}

impl QuickToolsRunner {
    pub fn update(&mut self) {
        if let Some(ref rx) = self.rx {
            if let Ok(result) = rx.try_recv() {
                self.is_running = false;
                if result.success {
                    self.log_console.push(format!(
                        "✓ Completed successfully in {} ms",
                        result.duration_ms
                    ));
                } else {
                    self.log_console.push(format!(
                        "✗ Execution failed in {} ms",
                        result.duration_ms
                    ));
                }
                for line in result.output.lines() {
                    self.log_console.push(line.to_string());
                }
            }
        }
    }

    pub fn execute(&mut self) {
        if self.is_running {
            return;
        }

        let tool = self.active_tool;
        let in1 = self.input_path_1.trim().to_string();
        let in2 = self.input_path_2.trim().to_string();
        let out = self.output_path.trim().to_string();
        let quality = self.quality;
        let format_choice = self.format_choice.clone();
        let tx = self.tx.clone();

        self.is_running = true;
        self.log_console.push(format!("▶ Executing {}...", tool.engine()));

        std::thread::spawn(move || {
            let start = Instant::now();
            let (cmd_name, args) = match tool {
                QuickToolKind::ImageConvert => {
                    let mut a = vec!["convert".to_string(), in1, out];
                    a.push("--format".to_string());
                    a.push(format_choice);
                    a.push("--quality".to_string());
                    a.push(quality.to_string());
                    ("photocraft-cli", a)
                }
                QuickToolKind::PdfCombine => {
                    let mut a = vec!["combine".to_string()];
                    if !in1.is_empty() { a.push(in1); }
                    if !in2.is_empty() { a.push(in2); }
                    a.push("-o".to_string());
                    a.push(out);
                    ("pdfcraft-cli", a)
                }
                QuickToolKind::PdfExtract => {
                    let a = vec!["extract".to_string(), in1, "-o".to_string(), out];
                    ("pdfcraft-cli", a)
                }
                QuickToolKind::PhotoRender => {
                    let a = vec![
                        "render".to_string(),
                        in1,
                        "-o".to_string(),
                        out,
                        "--quality".to_string(),
                        quality.to_string(),
                    ];
                    ("lightcraft-cli", a)
                }
                QuickToolKind::VectorConvert => {
                    let a = vec!["convert".to_string(), in1, out];
                    ("vectorcraft-cli", a)
                }
            };

            let home = std::env::var("HOME").unwrap_or_else(|_| "/home/soham".to_string());
            let full_bin = PathBuf::from(home).join(".local/bin").join(cmd_name);

            let res = Command::new(&full_bin).args(&args).output();
            let duration_ms = start.elapsed().as_millis();

            match res {
                Ok(output) => {
                    let mut text = String::new();
                    if !output.stdout.is_empty() {
                        text.push_str(&String::from_utf8_lossy(&output.stdout));
                    }
                    if !output.stderr.is_empty() {
                        if !text.is_empty() {
                            text.push('\n');
                        }
                        text.push_str(&String::from_utf8_lossy(&output.stderr));
                    }
                    let _ = tx.send(ExecutionResult {
                        success: output.status.success(),
                        output: text,
                        duration_ms,
                    });
                }
                Err(e) => {
                    let _ = tx.send(ExecutionResult {
                        success: false,
                        output: format!("Failed to spawn {}: {}", full_bin.display(), e),
                        duration_ms,
                    });
                }
            }
        });
    }
}
