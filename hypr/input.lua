-- Personal input overrides (migrated from the old input.conf).

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
  input = {
    kb_layout = "us",
    kb_options = "caps:ctrl_modifier",
    repeat_rate = 40,
    repeat_delay = 600,
    numlock_by_default = true,
    sensitivity = 0.25,

    touchpad = {
      scroll_factor = 0.4,
    },
  },

  cursor = {
    hide_on_key_press = false,
  },
})

-- Ghostty-specific touchpad scroll speed.
-- The old scroll_touchpad rule for (Alacritty|kitty|foot) was dropped:
-- ghostty is the only terminal on this system.
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })