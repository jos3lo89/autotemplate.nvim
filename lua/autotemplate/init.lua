local M = {}
local config = require("autotemplate.config")
local core = require("autotemplate.core")

M.enabled = true

function M.toggle()
	M.enabled = not M.enabled
	local status = M.enabled and "Activado" or "Desactivado"
	vim.notify("AutoTemplate: " .. status, vim.log.levels.INFO)
end

-- Función auxiliar para verificar si debemos adjuntar el plugin
local function should_attach(bufnr)
	if not M.enabled then
		return false
	end
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	-- 1. Chequeo de Lista Negra
	for _, ignore in ipairs(config.options.ignored_filetypes or {}) do
		if ft == ignore then
			return false
		end
	end

	-- 2. Chequeo de Lista Blanca
	for _, supported in ipairs(config.options.filetypes) do
		if ft == supported then
			return true
		end
	end
	return false
end

function M.setup(opts)
	config.setup(opts)

	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {})

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("AutoTemplateSetup", { clear = true }),
		pattern = config.options.filetypes,
		callback = function(args)
			if not should_attach(args.buf) then
				return
			end

			-- CAMBIO IMPORTANTE: expr = false
			-- Ahora controlamos la escritura manualmente
			vim.keymap.set("i", "{", function()
				-- 1. Si está desactivado, escribir '{' normal
				if not M.enabled then
					vim.api.nvim_feedkeys("{", "n", false)
					return
				end

				-- 2. Chequeo de macro
				if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
					vim.api.nvim_feedkeys("{", "n", false)
					return
				end

				-- 3. Intentar activar la lógica
				local handled = core.handle_trigger()

				-- 4. Si no se activó la lógica, escribir '{' normal
				if not handled then
					vim.api.nvim_feedkeys("{", "n", false)
				end
			end, { buffer = args.buf, expr = false, remap = false, desc = "Auto Template String" })
		end,
	})
end

return M
