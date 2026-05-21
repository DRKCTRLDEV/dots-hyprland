-- You can put custom rules here.
-- Window/layer rules: https://wiki.hyprland.org/Configuring/Window-Rules/
-- Workspace rules: https://wiki.hyprland.org/Configuring/Workspace-Rules/

-- ##### Preset WindowRules #####
-- Blur/Transparency Global:
hl.window_rule({ match = { class = ".*" }, opacity = "0.89 override 0.89 override" })
hl.window_rule({ match = { class = ".*" }, no_blur = false })

-- Blur/Transparency Whitelist:
-- hl.window_rule({ match = { class = "(?i).*(dolphin|code|kitty|spotify).*" }, opacity = "0.89 override 0.89 override" })
-- hl.window_rule({ match = { class = "(?i).*(dolphin|code|kitty|spotify).*" }, no_blur = false })

-- Blur/Transparency Blacklist:
-- hl.window_rule({ match = { class = "(?i).*(dolphin|code|kitty|spotify).*" }, opacity = "1 override 1 override" })
-- hl.window_rule({ match = { class = "(?i).*(dolphin|code|kitty|spotify).*" }, no_blur = true })

-- Disable blur for XWayland (compatibility):
-- hl.window_rule({ match = { xwayland = 1 }, no_blur = true })

-- ##### Custom WindowRules #####
hl.window_rule({ match = { class = "steam", title = "Steam Settings" }, float = true })
