local Home = require("common/bookorbit_home")

describe("BookOrbit home", function()
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
end)
