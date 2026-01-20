-- 1. Evitar carga doble
if vim.g.loaded_autotemplate then
	return
end
vim.g.loaded_autotemplate = 1

-- 2. Verificación de Versión (Usando vim.notify)
if vim.fn.has("nvim-0.9.0") == 0 then
	vim.notify("autotemplate.nvim: Requires Neovim >= 0.9.0", vim.log.levels.ERROR)
	return
end
