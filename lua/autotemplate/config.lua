local M = {}

---@class AutoTemplateConfig
---@field filetypes string[] List of filetypes where the plugin is active
---@field ignored_filetypes string[] List of filetypes to explicitly ignore
---@field disable_in_macro boolean If true, disables the plugin while recording macros
---@field debug boolean If true, shows debug notifications
---@field trigger_key string Key that triggers interpolation (Default '{')
---@field auto_close_brackets boolean If true, automatically inserts "}"
local defaults = {
	filetypes = {
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
	},
	ignored_filetypes = {
		"markdown",
		"text",
	},
	disable_in_macro = true,
	debug = false,
	trigger_key = "{",
	auto_close_brackets = true,
}

---Active configuration (populated when calling setup)
---@type AutoTemplateConfig
M.options = vim.deepcopy(defaults)

---Validates that the user-provided configuration is correct
---@param opts table
local function validate_config(opts)
	-- vim.validate expects a table where:
	-- key = { current_value, expected_type, is_optional }
	local ok, err = pcall(vim.validate, {
		filetypes = { opts.filetypes, "table", true },
		ignored_filetypes = { opts.ignored_filetypes, "table", true },
		disable_in_macro = { opts.disable_in_macro, "boolean", true },
		debug = { opts.debug, "boolean", true },
		trigger_key = { opts.trigger_key, "string", true },
		auto_close_brackets = { opts.auto_close_brackets, "boolean", true },
	})

	if not ok then
		vim.notify("AutoTemplate Config Error: " .. (err or "Unknown error"), vim.log.levels.ERROR)
		return false
	end
	return true
end

---Initializes the plugin configuration
---@param opts? AutoTemplateConfig Optional configuration table
function M.setup(opts)
	opts = opts or {}

	-- 1. Validate types before merging (Prevents merging invalid data)
	if not validate_config(opts) then
		return
	end

	-- 2. Merge with defaults
	-- Use 'force' so user config overrides the default
	M.options = vim.tbl_deep_extend("force", defaults, opts)
end

return M
