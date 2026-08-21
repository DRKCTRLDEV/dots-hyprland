-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- Internal stuff --
require("hyprland.lib")
require("hyprland.services")

-- Shared list of user-overridable custom config modules (see create_custom_config.lua)
local customConfigs = require("hyprland/services/create_custom_config")

local function requireCustom(name)
    if is_file_exists(HOME .. "/.config/hypr/custom/" .. name .. ".lua") then
        require("custom." .. name)
    end
end

-- Environment variables --
require("hyprland.env")
requireCustom("env")

-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")

-- Custom configurations (env is loaded above; variables is loaded by keybinds.lua)
for _, name in ipairs(customConfigs) do
    if name ~= "env" and name ~= "variables" then
        requireCustom(name)
    end
end

-- nwg-displays support --
if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
    require("workspaces")
end
if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
    require("monitors")
end

-- Shell overrides --
require("hyprland.shellOverrides.main")
