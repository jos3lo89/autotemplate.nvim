local M = {}

local defaults = {
	-- O(1) lookup
	filetypes = {
		["javascript"] = true,
		["typescript"] = true,
		["javascriptreact"] = true,
		["typescriptreact"] = true,
		["vue"] = true,
		["svelte"] = true,
		["go"] = true,
		["python"] = true,
	},
	disable_in_macro = true,
}

M.options = vim.deepcopy(defaults)

function M.setup(opts)
	opts = opts or {}

	-- Accept list and convert to map
	if opts.filetypes and vim.tbl_islist(opts.filetypes) then
		local new_ft_map = {}
		for _, ft in ipairs(opts.filetypes) do
			new_ft_map[ft] = true
		end
		opts.filetypes = new_ft_map
	end

	M.options = vim.tbl_deep_extend("force", defaults, opts)
end

return M
