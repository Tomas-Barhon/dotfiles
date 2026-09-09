-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Monitors (migrated from the old monitors.conf).
hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "-1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@60", position = "1920x0", scale = 1 })

-- Workspaces 1-5 on DP-3, 6-10 on eDP-1 (migrated from the old monitors.conf).
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3" })
hl.workspace_rule({ workspace = "3", monitor = "DP-3" })
hl.workspace_rule({ workspace = "4", monitor = "DP-3" })
hl.workspace_rule({ workspace = "5", monitor = "DP-3" })
hl.workspace_rule({ workspace = "6", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "7", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "8", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })
