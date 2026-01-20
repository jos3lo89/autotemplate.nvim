-- Prevent the plugin from loading multiple times
if vim.g.loaded_autotemplate then
	return
end
vim.g.loaded_autotemplate = 1

-- Verify that the running Neovim version meets the minimum requirements
if vim.fn.has("nvim-0.9.0") == 0 then
	vim.notify("autotemplate.nvim: Requires Neovim >= 0.9.0", vim.log.levels.ERROR)
	return
end
