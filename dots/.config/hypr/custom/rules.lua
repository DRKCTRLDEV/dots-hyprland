-- You can put custom rules here.
-- Window/layer rules: https://wiki.hyprland.org/Configuring/Window-Rules/
-- Workspace rules: https://wiki.hyprland.org/Configuring/Workspace-Rules/

-- ##### Preset WindowRules #####
-- Blur/Transparency Global:
hl.window_rule({ match = { class = ".*" }, no_blur = false, opacity = "0.89 override 0.89 override" })
hl.window_rule({ match = { fullscreen = "true" }, no_blur = true, opacity = "1.0 override 1.0 override" })

-- Blur/Transparency Whitelist:
-- hl.window_rule({ match = { class = "(?i).*(dolphin|code|kitty|spotify).*" }, no_blur = false, opacity = "0.89 override 0.89 override" })

-- Blur/Transparency Blacklist:
-- hl.window_rule({ match = { class = "(?i).*(dolphin|code|kitty|spotify).*" }, no_blur = true, opacity = "1 override 1 override" })

-- Disable blur for XWayland (compatibility):
-- hl.window_rule({ match = { xwayland = 1 }, no_blur = true })

-- ##### Custom WindowRules #####
-- Steam Settings: Float
hl.window_rule({ match = { class = "steam", title = "Steam Settings" }, float = true })

-- MCA Selector: No Blur/Transparency
hl.window_rule({ match = { class = "^net\\.querz\\.mcaselector\\.ui\\.Window$" }, no_blur = true, opacity = "1.0 override 1.0 override" })
