local M = {}
local config = require("autotemplate.config")
local core = require("autotemplate.core")

-- Estado interno para el Toggle
M.enabled = true

function M.toggle()
	M.enabled = not M.enabled
	local status = M.enabled and "Enabled" or "Disabled"
	vim.notify("AutoTemplate: " .. status, vim.log.levels.INFO)
end

function M.setup(opts)
	config.setup(opts)

	-- Crear comando de usuario :AutoTemplateToggle
	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {})

	-- Autocomando para activar el keymap solo en buffers correctos
	vim.api.nvim_create_autocmd("FileType", {
		pattern = config.options.filetypes,
		callback = function()
			-- Mapeamos '{' en modo inserción
			vim.keymap.set("i", "{", function()
				if not M.enabled then
					return "{"
				end

				-- Verificar si estamos en una macro (opcional)
				if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
					return "{"
				end

				return core.handle_trigger()
			end, { buffer = true, expr = true, remap = false, desc = "Auto Template String" })
		end,
	})
end

return M
