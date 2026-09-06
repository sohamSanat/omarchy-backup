# Omarchy Signature Theme



<img width="1938" height="812" alt="deer" src="https://github.com/user-attachments/assets/b3e1b568-033f-498e-a4c5-10e3da10bb69" />
<img width="1672" height="941" alt="castle" src="https://github.com/user-attachments/assets/65667950-3a06-444f-bb47-0e39dfb4aa93" />

<img width="1672" height="941" alt="road" src="https://github.com/user-attachments/assets/17089eec-8f15-48f0-a1fd-186686eaa5ad" />

<img width="1672" height="941" alt="ChatGPT Image Sep 4, 2026, 10_00_57 PM" src="https://github.com/user-attachments/assets/d53a13f3-d6dd-4e17-8c39-0e4d2ef6676f" />


A sleek, modern dark theme for [Omarchy](https://omarchy.org/) featuring deep Tokyo Night canvases paired with vibrant Omarchy Signature green accents.

![Theme Preview](preview.png)

---

## 🎨 Features

- **Palette**: Deep Tokyo Night canvas (`#1A1B26`) paired with Omarchy Signature Green (`#9ECE6A`).
- **Neovim & VS Code**: Out-of-the-box configuration matching Tokyo Night schemes.
- **Custom Lockscreen**: Styled lockscreen with included `unlock.png` and `preview-unlock.png`.
- **GTK Icons**: Configured for `Yaru-olive` icon theme.
- **RGB Keyboard**: Synced accent lighting `#9ECE6A`.
- **Wallpapers**: Curated collection of high-resolution backgrounds included in `backgrounds/`.

---

## 🚀 Installation

### Option 1: Via Omarchy Menu (Recommended)
1. Press `Super + Alt + Space` (or `Super + Space`) to open the Omarchy menu.
2. Navigate to **Install > Style > Theme**.
3. Paste the repository URL:
   ```text
   https://github.com/mshareef-git/Omarchy_Signature.git
   ```

### Option 2: Via Terminal
Run the Omarchy theme install command:
```bash
omarchy theme install https://github.com/mshareef-git/Omarchy_Signature.git
```

*Or manually clone to your themes directory:*
```bash
git clone https://github.com/mshareef-git/Omarchy_Signature.git ~/.config/omarchy/themes/Omarchy_Signature
```

---

## 🖼️ Lock Screen Preview

![Lock Screen Preview](preview-unlock.png)

---

## 📂 Repository Structure

```text
├── backgrounds/         # Curated wallpapers
├── colors.toml          # 22-color palette definition for Omarchy
├── icons.theme          # GTK icon set configuration
├── keyboard.rgb         # Keyboard backlight hex color
├── neovim.lua           # Neovim colorscheme configuration
├── preview.png          # Theme switcher preview
├── preview-unlock.png   # Lock screen selector preview
├── shell.lock.toml      # Omarchy lockscreen styling
├── unlock.png           # Lockscreen visual asset
├── vscode.json          # VS Code theme reference
└── README.md            # Documentation & install guide
```

---

## 📄 License

Distributed under the MIT License.
