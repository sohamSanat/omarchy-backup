-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false
vim.g.autoformat = false

-- Dynamically synchronize Neovim background with Omarchy theme mode
local theme_mode_env = os.getenv("OMARCHY_THEME_MODE")
if theme_mode_env == "light" or vim.fn.filereadable(vim.fn.expand("~/.local/state/omarchy/current/theme/light.mode")) == 1 then
  vim.opt.background = "light"
else
  vim.opt.background = "dark"
end
