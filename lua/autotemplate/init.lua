local M = {}
local config = require("autotemplate.config")
local core = require("autotemplate.core")

local AU_GROUP = "AutoTemplateGroup"
M.enabled = true

function M.toggle()
	M.enabled = not M.enabled
	vim.notify("AutoTemplate: " .. (M.enabled and "Enabled" or "Disabled"), vim.log.levels.INFO)
end

function M.setup(opts)
	config.setup(opts)

	vim.api.nvim_create_augroup(AU_GROUP, { clear = true })
	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {})

	-- Evento: TextChangedI
	vim.api.nvim_create_autocmd("TextChangedI", {
		group = AU_GROUP,
		pattern = "*",
		callback = function(evt)
			if not M.enabled then
				return
			end

			-- 1. Check de Buffer Type (Evitar consolas, prompts, etc)
			-- 'buftype' vacío es un archivo normal. 'nofile', 'prompt', etc se ignoran.
			if vim.bo[evt.buf].buftype ~= "" then
				return
			end

			-- 2. Check de Filetype (O(1) gracias al mapa en config)
			local ft = vim.bo[evt.buf].filetype
			if not config.options.filetypes[ft] then
				return
			end

			-- 3. Check de Macros
			if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
				return
			end

			-- Solo si pasa todo esto, llamamos al core
			core.check_and_transform()
		end,
	})
end

return M
