local Home = require("common/plugin_home")

describe("plugin home", function()
    it("opens the selected plugin menu and falls back when unavailable", function()
        local plugin = { config = { navbar = {
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
        assert.is_true(Home.open(plugin))
        assert.are.equal(1, opened)
        ZenSpec.replace("modules/menu/app_launcher/plugin_scan", { resolve = function() end })
        assert.is_false(Home.open(plugin))
        assert.is_false(Home.open(nil))
    end)

    it("runs a selected action and prevents recursive home actions", function()
        local plugin = { config = { navbar = { home_destination = "action", home_action = { open = true } } } }
        local opened = 0
        ZenSpec.replace("dispatcher", { execute = function(_, action)
            assert.is_true(action.open)
            assert.is_false(Home.open(plugin))
            opened = opened + 1
        end })
        assert.is_true(Home.open(plugin))
        assert.are.equal(1, opened)
        plugin.config.navbar.home_action = {}
        assert.is_false(Home.open(plugin))
    end)

    it("uses a plugin's registered open action instead of its lifecycle callback", function()
        local settingsList = { example_open_dashboard = { general = true, category = "none" } }
        local executed
        ZenSpec.replace("dispatcher", {
            registerAction = function() return settingsList end,
            execute = function(_, action) executed = action.example_open_dashboard end,
        })
        ZenSpec.replace("modules/menu/app_launcher/plugin_scan", {
            resolve = function() error("lifecycle callback must not run") end,
        })
        local plugin = { config = { navbar = {
            home_destination = "plugin", home_plugin_key = "example", home_plugin_method = "onShow",
        } } }
        assert.is_true(Home.open(plugin))
        assert.is_true(executed)
    end)

    it("delivers actions to the file manager under a library view", function()
        local reached, missed = 0, 0
        local ui = { sendEvent = function() missed = missed + 1 end }
        local original = ui.sendEvent
        local fm = { handleEvent = function(_, event)
            if event == "open" then reached = reached + 1; return true end
        end }
        ZenSpec.replace("ui/uimanager", ui)
        ZenSpec.replace("dispatcher", { execute = function()
            ui:sendEvent("open")
            ui:sendEvent("other")
        end })
        local plugin = { config = { navbar = { home_destination = "action", home_action = { open = true } } } }
        assert.is_true(Home.open(plugin, fm))
        assert.are.equal(1, reached)
        assert.are.equal(1, missed)
        assert.are.equal(original, ui.sendEvent)
    end)

    it("restores event delivery if an action fails", function()
        local ui = { sendEvent = function() end }
        local original = ui.sendEvent
        ZenSpec.replace("ui/uimanager", ui)
        ZenSpec.replace("dispatcher", { execute = function() error("failed") end })
        local plugin = { config = { navbar = { home_destination = "action", home_action = { open = true } } } }
        assert.is_false(Home.open(plugin, { handleEvent = function() end }))
        assert.are.equal(original, ui.sendEvent)
    end)
end)
