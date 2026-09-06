return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg = "#0d0506",
        dark_bg = "#070203",
        darker_bg = "#020001",
        lighter_bg = "#1b1011",

        fg = "#ffc8c6",
        dark_fg = "#9d6b6b",
        light_fg = "#ffe4e3",
        bright_fg = "#fff6f6",
        muted = "#715555",

        red = "#c64b5c",
        yellow = "#c44d5d",
        orange = "#c8495b",
        green = "#c84a5c",
        cyan = "#c54d5d",
        blue = "#c9475a",
        magenta = "#c34f5e",
        brown = "#a2595f",

        bright_red = "#ee5f72",
        bright_yellow = "#f05d71",
        bright_green = "#ec6173",
        bright_cyan = "#f05e72",
        bright_blue = "#ed6173",
        bright_magenta = "#f15b70",

        accent = "#de555d",
        cursor = "#fff6f6",
        foreground = "#ffc8c6",
        background = "#0d0506",
        selection = "#45111b",
        selection_foreground = "#fff6f6",
        selection_background = "#45111b",
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
