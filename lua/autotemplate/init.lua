local M = {}
local config = require("autotemplate.config")

-- Constante para el grupo de autocomandos (evita duplicados al recargar)
local AU_GROUP_NAME = "AutoTemplateSetup"

M.enabled = true

---Activa o desactiva el plugin dinámicamente
function M.toggle()
	M.enabled = not M.enabled
	local status = M.enabled and "Activado" or "Desactivado"
	vim.notify("AutoTemplate: " .. status, vim.log.levels.INFO)
end

---Limpia todo rastro del plugin (Autocommands y estado)
function M.teardown()
	-- 1. Borrar el grupo de autocomandos (deja de escuchar FileTypes nuevos)
	if vim.fn.exists("#" .. AU_GROUP_NAME) == 1 then
		vim.api.nvim_del_augroup_by_name(AU_GROUP_NAME)
	end

	-- 2. Desactivar flag global
	M.enabled = false
end

---Verifica si el buffer actual debe tener el plugin activo
local function should_attach(bufnr)
	if not M.enabled then
		return false
	end

	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	-- Prioridad: Lista Negra
	for _, ignore in ipairs(config.options.ignored_filetypes) do
		if ft == ignore then
			return false
		end
	end

	-- Lista Blanca
	for _, supported in ipairs(config.options.filetypes) do
		if ft == supported then
			return true
		end
	end
	return false
end

function M.setup(opts)
	-- 0. Limpiar estado previo si se está recargando el plugin
	M.teardown()
	M.enabled = true

	-- 1. Configurar opciones
	config.setup(opts)

	-- 2. Crear comandos de usuario
	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {})

	-- 3. Crear Autogroup (clear = true elimina duplicados viejos)
	local au_group = vim.api.nvim_create_augroup(AU_GROUP_NAME, { clear = true })

	-- 4. Autocomando principal
	vim.api.nvim_create_autocmd("FileType", {
		group = au_group,
		pattern = config.options.filetypes,
		callback = function(args)
			if not should_attach(args.buf) then
				return
			end

			-- MAPEO DINÁMICO (Usa trigger_key de la config)
			vim.keymap.set("i", config.options.trigger_key, function()
				-- A. Si está desactivado, comportamiento nativo
				if not M.enabled then
					return config.options.trigger_key -- Devuelve la tecla literal
				end

				-- B. Chequeo de macros
				if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
					return config.options.trigger_key
				end

				-- C. LAZY LOADING REAL:
				-- Solo requerimos 'core' cuando el usuario presiona la tecla.
				-- Esto hace que el inicio de Neovim sea instantáneo.
				local core = require("autotemplate.core")

				-- D. Ejecutar lógica
				local handled = core.handle_trigger({
					auto_close = config.options.auto_close_brackets,
				})

				-- E. Si core no hizo nada, devolver la tecla original
				if not handled then
					-- Usamos feedkeys para simular la pulsación natural si falló la lógica
					-- Nota: Retornar string en expr=true es mejor, pero ya cambiamos a expr=false
					-- por seguridad del buffer, así que usamos feedkeys.
					vim.api.nvim_feedkeys(config.options.trigger_key, "n", false)
				end
			end, {
				buffer = args.buf,
				expr = false, -- Mantenemos false por seguridad con nvim_buf_set_text
				remap = false,
				desc = "Auto Template String Interpolation",
			})
		end,
	})
end

return M
