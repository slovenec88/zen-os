local M = {}
local opening = false
local open_count = 0

local function pluginOpenAction(key)
    if type(key) ~= "string" then return end
    local ok, dispatcher = pcall(require, "dispatcher")
    if not ok or type(dispatcher) ~= "table" or type(dispatcher.registerAction) ~= "function" then return end
    if type(dispatcher.init) == "function" then pcall(dispatcher.init, dispatcher) end
    local index = 1
    while true do
        local name, actions = debug.getupvalue(dispatcher.registerAction, index)
        if not name then return end
        if name == "settingsList" and type(actions) == "table" then
            local prefix = key .. "_open"
            local selected, ambiguous
            for id, action in pairs(actions) do
                if type(id) == "string" and (id == prefix or id:sub(1, #prefix + 1) == prefix .. "_")
                        and type(action) == "table" and action.general == true and action.category == "none"
                        and (type(dispatcher.isActionEnabled) ~= "function" or dispatcher:isActionEnabled(action)) then
                    if id == prefix then return dispatcher, id end
                    if selected then ambiguous = true else selected = id end
                end
            end
            if selected and not ambiguous then return dispatcher, selected end
            return
        end
        index = index + 1
    end
end

function M.openCount()
    return open_count
end

local function executeAction(dispatcher, actions, fm)
    local ui = fm and type(fm.handleEvent) == "function" and require("ui/uimanager")
    local send_event = ui and ui.sendEvent
    local forwarding = false
    if fm and type(fm.handleEvent) == "function" and type(send_event) == "function" then
        -- The hidden file manager does not receive dispatcher events from standalone views.
        ui.sendEvent = function(manager, event, ...)
            if not forwarding then
                forwarding = true
                local ok, handled = pcall(fm.handleEvent, fm, event)
                forwarding = false
                if ok and handled then return handled end
            end
            return send_event(manager, event, ...)
        end
    end
    local ok, result = pcall(dispatcher.execute, dispatcher, actions)
    if ui then ui.sendEvent = send_event end
    return ok and result ~= false
end

function M.enabled(plugin)
    local navbar = plugin and plugin.config and plugin.config.navbar
    return type(navbar) == "table"
        and (navbar.home_destination == "plugin" or navbar.home_destination == "action")
end

function M.open(plugin, fm)
    if opening or not M.enabled(plugin) then return false end
    local config = plugin.config.navbar
    if config.home_destination == "action" then
        if type(config.home_action) ~= "table" or not next(config.home_action) then return false end
        local ok, dispatcher = pcall(require, "dispatcher")
        if not ok or not dispatcher then return false end
        if type(dispatcher.init) == "function" then pcall(dispatcher.init, dispatcher) end
        if type(dispatcher.getDisplayList) == "function" then
            local available, items = pcall(dispatcher.getDisplayList, config.home_action)
            if not available or type(items) ~= "table" or #items == 0 then return false end
        end
        opening = true
        local success = executeAction(dispatcher, config.home_action, fm)
        opening = false
        if success then open_count = open_count + 1; return true end
        return false
    end
    local dispatcher, action = pluginOpenAction(config.home_plugin_key)
    if dispatcher then
        opening = true
        local ok = executeAction(dispatcher, { [action] = true }, fm)
        opening = false
        if ok then open_count = open_count + 1; return true end
    end
    local launch = require("modules/menu/app_launcher/plugin_scan").resolve(
        config.home_plugin_key, config.home_plugin_method)
    if not launch then return false end
    opening = true
    local ok, result = pcall(launch)
    opening = false
    if ok and result ~= false then open_count = open_count + 1; return true end
    return false
end

return M
