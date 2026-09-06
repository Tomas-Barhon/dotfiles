-- Personal autostart and start-window rules (migrated from the old autostart.conf).

-- Start-window rules.
o.window("^(firefox)$", { workspace = "2", no_initial_focus = true })
o.window("^(org.zealdocs.zeal)$", { workspace = "3" })
o.window("^(chrome-notion.so__-Profile_1)$", { workspace = "4" })
o.window("^(spotify)$", { workspace = "6" })

hl.on("hyprland.start", function()
  -- Working apps on their own workspaces.
  hl.exec_cmd("ghostty -e sh -lc 'tmux new-session -A -s dev'", { workspace = "1", silent = true })
  hl.exec_cmd("firefox", { workspace = "2", silent = true })
  hl.exec_cmd("zeal", { workspace = "3", silent = true })
  hl.exec_cmd("ghostty -e yazi", { workspace = "5", silent = true })
  hl.exec_cmd("spotify", { workspace = "6", silent = true })
  hl.exec_cmd("ghostty -e btop", { workspace = "7", silent = true })

  -- Problematic apps - launch then move in background.
  hl.exec_cmd("omarchy-launch-webapp " .. o.shell_quote("https://notion.so"))
  hl.exec_cmd('(sleep 5 && hyprctl dispatch movetoworkspacesilent "4,class:^(chrome-notion.so__-Profile_1)$" && hyprctl dispatch workspace 1) &')
end)