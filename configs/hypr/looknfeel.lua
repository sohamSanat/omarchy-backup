-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    rounding = 10,

    -- Window blur for transparent windows / terminals
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      new_optimizations = true,
      ignore_opacity = true,
      xray = false,
      noise = 0.05,
      contrast = 1.05,
      brightness = 1.02,
      vibrancy = 0.2,
      vibrancy_darkness = 0.0,
      popups = true,
    },

    shadow = {
      enabled = true,
      range = 15,
      render_power = 3,
      color = "rgba(00000044)",
    },
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- >>> omaland managed block >>>
-- Written by Omaland. Safe to hand-edit: Omaland re-reads this block
-- every time it opens, and only ever rewrites what's between the fences.
hl.config({
  animations = {
    enabled = false,
  },

  decoration = {
    rounding = 7,
    rounding_power = 10,

    glow = {
      enabled = false,
    },

    shadow = {
      range = 24,
      render_power = 4,
      scale = 0.56,
      sharp = false,
    },
  },

  general = {
    border_size = 0,
    float_gaps = 0,
    gaps_in = 3,
    gaps_out = 6,
    gaps_workspaces = 7,

    snap = {
      enabled = false,
    },
  },
})
-- <<< omaland managed block <<<
