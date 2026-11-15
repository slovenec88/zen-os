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

local function watchClose(plugin, fm, catalog)
    if type(catalog) ~= "table" or catalog._zen_home_close_wrapped
            or type(catalog.onCloseAllMenus) ~= "function" then return end
    local close = catalog.onCloseAllMenus
    catalog._zen_home_close_wrapped = true
    function catalog:onCloseAllMenus(...)
        local result = close(self, ...)
        require("ui/uimanager"):nextTick(function()
            local reader = package.loaded["apps/reader/readerui"]
            local show_files = rawget(_G, "__ZEN_UI_NAVBAR_SHOW_FILES")
            local current = fm.bookorbit and fm.bookorbit.catalog_browser
            if M.enabled(plugin) and type(show_files) == "function"
                    and not (reader and reader.instance and reader.instance.document)
                    and (not current or (current == self and self.catalog_closed)) then
                show_files()
            end
        end)
        return result
    end
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
                watchClose(plugin, fm, catalog)
                require("common/utils").closeWidgetsAbove(catalog)
                if type(catalog.goDashboard) == "function" then catalog:goDashboard() end
                return true
            end
        end
        bookorbit.catalog_browser = nil
    end
    local ok = pcall(bookorbit.browseCatalog, bookorbit, true)
    if ok then watchClose(plugin, fm, bookorbit.catalog_browser) end
    return ok
end

return M
