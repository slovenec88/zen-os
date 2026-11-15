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
end)
