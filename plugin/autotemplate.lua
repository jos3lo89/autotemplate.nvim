if vim.fn.has('nvim-0.9') == 0 then
	vim.api.nvim_err_writeln('autotemplate.nvim requires Neovim >= 0.9.0')
	return
end

if vim.g.loaded_autotemplate then
	return
end

vim.g.loaded_autotemplate = 1
