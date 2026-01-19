local M = {}

M.defaults = {
	filetypes = {
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
	},

	ignored_filetypes = {
		"markdown",
		"text",
	},

	disable_in_macro = true,
	debug = false,
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
