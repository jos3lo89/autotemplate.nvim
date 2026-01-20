local autotemplate = require("autotemplate")

describe("autotemplate", function()
    before_each(function()
        autotemplate.setup()
    end)

    it("can be required", function()
        assert.is_not_nil(autotemplate)
    end)

    it("has setup function", function()
        assert.is_function(autotemplate.setup)
    end)

    it("has toggle function", function()
        assert.is_function(autotemplate.toggle)
    end)

    describe("configuration", function()
        it("uses default config", function()
            local config = require("autotemplate.config")
            assert.is_table(config.options.filetypes)
        end)

        it("merges custom config", function()
            autotemplate.setup({
                debug = true
            })
            local config = require("autotemplate.config")
            assert.is_true(config.options.debug)
        end)
    end)
end)
