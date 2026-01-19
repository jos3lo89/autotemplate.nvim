local M = {}
local config = require("autotemplate.config")
local core = require("autotemplate.core")

-- Estado interno
M.enabled = true

-- Función para activar/desactivar manualmente
function M.toggle()
	M.enabled = not M.enabled
	local status = M.enabled and "Activado" or "Desactivado"
	vim.notify("AutoTemplate: " .. status, vim.log.levels.INFO)
end

-- Función auxiliar para verificar si debemos adjuntar el plugin al buffer actual
local function should_attach(bufnr)
	if not M.enabled then
		return false
	end

	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	-- 1. Chequeo de Lista Negra (Prioridad Alta)
	for _, ignore in ipairs(config.options.ignored_filetypes) do
		if ft == ignore then
			return false
		end
	end

	-- 2. Chequeo de Lista Blanca
	local is_supported = false
	for _, supported in ipairs(config.options.filetypes) do
		if ft == supported then
			is_supported = true
			break
		end
	end

	return is_supported
end

function M.setup(opts)
	config.setup(opts)

	-- Comando de usuario :AutoTemplateToggle
	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {})

	-- Autocomando principal
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("AutoTemplateSetup", { clear = true }),
		pattern = config.options.filetypes, -- Solo se dispara en los filetypes permitidos
		callback = function(args)
			-- Doble verificación (incluyendo blacklist) antes de mapear
			if not should_attach(args.buf) then
				return
			end

			-- Mapeo seguro de la tecla '{'
			vim.keymap.set("i", "{", function()
				-- Verificaciones en tiempo real
				if not M.enabled then
					return "{"
				end
				if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
					return "{"
				end

				-- Llamada al núcleo (core.lua)
				return core.handle_trigger()
			end, { buffer = args.buf, expr = true, remap = false, desc = "Auto Template String Interpolation" })
		end,
	})
end

return M
