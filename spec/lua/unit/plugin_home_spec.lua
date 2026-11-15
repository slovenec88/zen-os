local Home = require("common/plugin_home")

describe("plugin home", function()
    local plugin = { config = { navbar = { home_destination = "bookorbit" } } }

    it("opens the live file manager plugin with its cached dashboard", function()
        local called
        local bookorbit = { browseCatalog = function(self, cached)
            called = self
            assert.is_true(cached)
        end }
        assert.is_true(Home.open(plugin, { bookorbit = bookorbit }))
        assert.are.equal(bookorbit, called)
    end)

    it("falls back when disabled, missing, or broken", function()
        assert.is_false(Home.open(nil, {}))
        assert.is_false(Home.open(plugin, {}))
        assert.is_false(Home.open(plugin, { bookorbit = { browseCatalog = function() error("failed") end } }))
    end)

    it("opens a selected plugin and falls back if it is unavailable", function()
        local destination = { config = { navbar = {
            home_destination = "plugin", home_plugin_key = "example", home_plugin_method = "open",
        } } }
        local opened = 0
        ZenSpec.replace("modules/menu/app_launcher/plugin_scan", {
            resolve = function(key, method)
                assert.are.equal("example", key)
                assert.are.equal("open", method)
                return function() opened = opened + 1 end
            end,
        })
        assert.is_true(Home.open(destination, {}))
        assert.are.equal(1, opened)
        ZenSpec.replace("modules/menu/app_launcher/plugin_scan", { resolve = function() end })
        assert.is_false(Home.open(destination, {}))
    end)

    it("honors the Files request only once", function()
        local fm = { bookorbit = { skip_return_home_once = true } }
        assert.is_true(Home.consumeFilesRequest(fm))
        assert.is_false(Home.consumeFilesRequest(fm))
        assert.is_false(Home.consumeFilesRequest(nil))
    end)

    it("does not open a second dashboard", function()
        ZenSpec.replace("common/utils", { closeWidgetsAbove = function() end })
        local returned = false
        local catalog = { goDashboard = function() returned = true end }
        ZenSpec.replace("ui/uimanager", { _window_stack = { { widget = catalog } } })
        assert.is_true(Home.open(plugin, { bookorbit = {
            catalog_browser = catalog, browseCatalog = function() error("opened twice") end,
        } }))
        assert.is_true(returned)
    end)

    it("shows files after the BookOrbit catalog closes", function()
        local queue, files = {}, 0
        local catalog = { onCloseAllMenus = function(self) self.catalog_closed = true end }
        local fm = { bookorbit = { browseCatalog = function(self) self.catalog_browser = catalog end } }
        ZenSpec.replace("ui/uimanager", { nextTick = function(_, fn) queue[#queue + 1] = fn end })
        _G.__ZEN_UI_NAVBAR_SHOW_FILES = function() files = files + 1 end
        assert.is_true(Home.open(plugin, fm))
        catalog:onCloseAllMenus()
        assert.are.equal(0, files)
        queue[1]()
        assert.are.equal(1, files)
        _G.__ZEN_UI_NAVBAR_SHOW_FILES = nil
    end)
end)
