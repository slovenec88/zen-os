local M = {}
local opening = false

function M.enabled(plugin)
    local navbar = plugin and plugin.config and plugin.config.navbar
    return type(navbar) == "table"
        and (navbar.home_destination == "plugin" or navbar.home_destination == "action")
end

function M.open(plugin)
    if opening or not M.enabled(plugin) then return false end
    local config = plugin.config.navbar
    if config.home_destination == "action" then
        if type(config.home_action) ~= "table" or not next(config.home_action) then return false end
        local ok, dispatcher = pcall(require, "dispatcher")
        if not ok or not dispatcher then return false end
        opening = true
        local success, result = pcall(dispatcher.execute, dispatcher, config.home_action)
        opening = false
        return success and result ~= false
    end
    local launch = require("modules/menu/app_launcher/plugin_scan").resolve(
        config.home_plugin_key, config.home_plugin_method)
    if not launch then return false end
    opening = true
    local ok, result = pcall(launch)
    opening = false
    return ok and result ~= false
end

return M
