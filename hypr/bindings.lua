-- Personal keybinding overrides (migrated from the old bindings.conf API).
-- Most bindings from bindings.conf are now Omarchy defaults, so only the
-- differences from the defaults are kept here.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Keyboard remaps.
hl.unbind("CAPS")
o.bind("CAPS", nil, "omarchy-shell shell toggle omarchy.capslock")
hl.unbind("CTRL")
o.bind("CTRL", nil, "omarchy-shell shell toggle omarchy.ctrl")

-- SUPER+SHIFT+W: Typora instead of the default Omawrite.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Typora", "uwsm-app -- typora --enable-wayland-ime")

-- Keep disabled the shortcuts that were commented out in the old bindings.conf.
hl.unbind("SUPER + SHIFT + G")        -- Signal (was disabled)
hl.unbind("SUPER + SHIFT + O")        -- Obsidian (was disabled)
hl.unbind("SUPER + SHIFT + CTRL + G") -- Google Messages (was disabled)
hl.unbind("SUPER + SHIFT + P")        -- Google Photos (was disabled)
hl.unbind("SUPER + SHIFT + X")        -- X (was disabled)
hl.unbind("SUPER + SHIFT + ALT + X")  -- X Post (was disabled)