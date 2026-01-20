local M = {}

M.defaults = {
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
	-- Nuevas opciones útiles
	auto_close_brackets = true,
	trigger_chars = { "{" }, -- Permite extender triggers
}

M.options = {}

--- Validates configuration options
---@param opts table User configuration
---@return boolean, string|nil success, error message
local function validate_config(opts)
	if opts.filetypes and type(opts.filetypes) ~= "table" then
		return false, "filetypes must be a table"
	end

	if opts.ignored_filetypes and type(opts.ignored_filetypes) ~= "table" then
		return false, "ignored_filetypes must be a table"
	end

	if opts.disable_in_macro and type(opts.disable_in_macro) ~= "boolean" then
		return false, "disable_in_macro must be a boolean"
	end

	if opts.debug and type(opts.debug) ~= "boolean" then
		return false, "debug must be a boolean"
	end

	return true, nil
end

--- Setup configuration with validation
---@param opts table|nil User configuration
function M.setup(opts)
	opts = opts or {}

	local valid, err = validate_config(opts)
	if not valid then
		vim.notify(
			string.format("AutoTemplate config error: %s", err),
			vim.log.levels.ERROR
		)
		return
	end

	M.options = vim.tbl_deep_extend("force", M.defaults, opts)

	if M.options.debug then
		vim.notify("AutoTemplate config loaded", vim.log.levels.INFO)
	end
end

return M
