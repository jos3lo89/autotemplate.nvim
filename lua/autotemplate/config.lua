local M = {}

---@class AutoTemplateConfig
---@field filetypes string[] Lista de filetypes donde el plugin estará activo
---@field ignored_filetypes string[] Lista de filetypes a ignorar explícitamente
---@field disable_in_macro boolean Si es true, desactiva el plugin al grabar macros
---@field debug boolean Si es true, muestra notificaciones de depuración
---@field trigger_key string Tecla que activa la interpolación (Por defecto '{')
---@field auto_close_brackets boolean Si es true, inserta "}" automáticamente
local defaults = {
	filetypes = {
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
	},
	ignored_filetypes = {
		"markdown",
		"text",
	},
	disable_in_macro = true,
	debug = false,
	trigger_key = "{",
	auto_close_brackets = true,
}

---Configuración activa (se llena al llamar a setup)
---@type AutoTemplateConfig
M.options = vim.deepcopy(defaults)

---Valida que la configuración ingresada por el usuario sea correcta
---@param opts table
local function validate_config(opts)
	-- vim.validate espera una tabla donde:
	-- clave = { valor_actual, tipo_esperado, es_opcional }
	local ok, err = pcall(vim.validate, {
		filetypes = { opts.filetypes, "table", true },
		ignored_filetypes = { opts.ignored_filetypes, "table", true },
		disable_in_macro = { opts.disable_in_macro, "boolean", true },
		debug = { opts.debug, "boolean", true },
		trigger_key = { opts.trigger_key, "string", true },
		auto_close_brackets = { opts.auto_close_brackets, "boolean", true },
	})

	if not ok then
		vim.notify("AutoTemplate Config Error: " .. (err or "Unknown error"), vim.log.levels.ERROR)
		return false
	end
	return true
end

---Inicializa la configuración del plugin
---@param opts? AutoTemplateConfig Tabla de configuración opcional
function M.setup(opts)
	opts = opts or {}

	-- 1. Validar tipos antes de mezclar (Evita mezclar basura)
	if not validate_config(opts) then
		return
	end

	-- 2. Mezclar con defaults
	-- Usamos 'force' para que la config del usuario sobrescriba la default
	M.options = vim.tbl_deep_extend("force", defaults, opts)
end

return M
