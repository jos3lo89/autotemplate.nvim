local M = {}

M.defaults = {
	-- Archivos donde funciona la interpolación tipo JS/TS `${}`
	-- Puedes agregar más lenguajes que usen backticks para templates
	filetypes = {
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
	},
	disable_in_macro = true, -- No activar si se está grabando una macro
	debug = false, -- Para ver mensajes si algo falla
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
