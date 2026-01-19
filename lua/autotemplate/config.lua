local M = {}

M.defaults = {
	-- LISTA BLANCA: Lenguajes donde queremos que funcione la interpolación `${}`
	filetypes = {
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
		"python", -- Python usa f"{}" pero la lógica de backticks no aplica igual, el usuario puede quitarlo si quiere
	},

	-- LISTA NEGRA: Tipos de archivo donde NUNCA debe activarse, incluso si están en la lista blanca
	ignored_filetypes = {
		"markdown",
		"text",
	},

	disable_in_macro = true, -- No activar si se está grabando una macro
	debug = false, -- Para ver notificaciones de depuración
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
