return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#0b0d11",
        dark_bg = "#080a0d",
        darker_bg = "#060709",
        lighter_bg = "#19171c",

        fg = "#f0b7ca",
        dark_fg = "#4a5d46",
        light_fg = "#f0b7ca",
        bright_fg = "#fff1f6",
        muted = "#678270",

        red = "#f23888",
        yellow = "#d7be96",
        orange = "#d7be96",
        green = "#5aa15d",
        cyan = "#6f9485",
        blue = "#67dd82",
        magenta = "#f0b7ca",
        brown = "#6c5f4b",

        bright_red = "#ff6aa7",
        bright_yellow = "#e6d3b4",
        bright_green = "#86bf86",
        bright_cyan = "#8bb0a4",
        bright_blue = "#8bf0a1",
        bright_magenta = "#ffd0dc",

        accent = "#f23888",
        cursor = "#fff1f6",
        foreground = "#f0b7ca",
        background = "#0b0d11",
        selection = "#f23888",
        selection_foreground = "#0b0d11",
        selection_background = "#f23888",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
