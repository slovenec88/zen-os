local M = {}

function M.enabled(plugin)
    local navbar = plugin and plugin.config and plugin.config.navbar
    return type(navbar) == "table" and navbar.home_destination == "bookorbit"
end

function M.consumeFilesRequest(fm)
    local bookorbit = fm and fm.bookorbit
    if not bookorbit or bookorbit.skip_return_home_once ~= true then return false end
    bookorbit.skip_return_home_once = nil
    return true
end

function M.open(plugin, fm)
    if not M.enabled(plugin) then return false end
    local bookorbit = fm and fm.bookorbit
    if type(bookorbit) ~= "table" or type(bookorbit.browseCatalog) ~= "function" then
        return false
    end
    if bookorbit.catalog_browser and bookorbit.catalog_browser.catalog_closed then
        bookorbit.catalog_browser = nil
    end
    if bookorbit.catalog_browser then
        local catalog = bookorbit.catalog_browser
        local stack = require("ui/uimanager")._window_stack or {}
        for _, window in ipairs(stack) do
            if window.widget == catalog then
                require("common/utils").closeWidgetsAbove(catalog)
                if type(catalog.goDashboard) == "function" then catalog:goDashboard() end
                return true
            end
        end
        bookorbit.catalog_browser = nil
    end
    local ok = pcall(bookorbit.browseCatalog, bookorbit, true)
    return ok
end

return M
