require("hyprland/lib")

-- Shared list of user-overridable custom config modules, in load order.
-- Used here to create any missing files, and by `hyprland.lua` to require them.
local customConfigs = {
   "env",
   "execs",
   "general",
   "rules",
   "keybinds",
   "variables"
}

hl.on("hyprland.start", function()
   local homeDir = os.getenv("HOME")
   if string.len(homeDir) == 0 then
      return
   end
   local baseCustomDir = homeDir .. "/.config/hypr/custom"
   local createdFiles = 0
   for _, name in ipairs(customConfigs) do
      local file = baseCustomDir .. "/" .. name .. ".lua"
      if not is_file_exists(file) then
         create_if_not_exists(file)
         createdFiles = createdFiles + 1
      end
   end

   if createdFiles > 0 then
      -- hl.exec_cmd("notify-send 'Hyprland config' 'Created " .. createdFiles .. " custom Hyprland config files in " .. baseCustomDir .. "' -a 'Hyprland'")
      -- hl.exec_cmd("hyprctl reload")
   end
end)

return customConfigs
