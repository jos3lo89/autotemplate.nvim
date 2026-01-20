local M = {}

local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error

function M.check()
    start("AutoTemplate Health Check")

    -- Check Neovim version
    if vim.fn.has("nvim-0.9") == 1 then
        ok("Neovim >= 0.9.0")
    else
        error("Neovim >= 0.9.0 required")
    end

    -- Check treesitter
    local ts_ok, _ = pcall(require, "nvim-treesitter")
    if ts_ok then
        ok("nvim-treesitter is installed")

        -- Check parsers
        local parsers = require("nvim-treesitter.parsers")
        local config = require("autotemplate.config")

        for _, ft in ipairs(config.options.filetypes) do
            if parsers.has_parser(ft) then
                ok(string.format("Parser for '%s' is installed", ft))
            else
                warn(string.format("Parser for '%s' is not installed. Run :TSInstall %s", ft, ft))
            end
        end
    else
        error("nvim-treesitter is not installed")
    end

    -- Check configuration
    local cfg = require("autotemplate.config")
    if cfg.options then
        ok("Configuration loaded successfully")
    else
        warn("Configuration not loaded")
    end
end

return M
