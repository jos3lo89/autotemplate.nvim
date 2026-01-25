local M = {}

-- CONSTANTES
local TRIGGER = "${"
local CLOSE_BRACKET = "}"
local BACKTICK = "`"
local TARGET_QUOTES = { ['"'] = true, ["'"] = true }

-- Cache de nodos válidos para evitar recrear la tabla en cada llamada
local VALID_NODES = {
	string = true,
	template_string = true,
	string_fragment = true,
	string_literal = true, -- Python/Go
}

-- Flag interno para evitar re-entrancia (Performance)
local is_transforming = false

---Verificaciones ultra-rápidas antes de cargar lógica pesada
local function quick_check()
	-- 1. Si estamos transformando, salir inmediatamente (evita loop)
	if is_transforming then
		return false
	end

	-- 2. Buffer modificable?
	if not vim.api.nvim_get_option_value("modifiable", { buf = 0 }) then
		return false
	end

	-- 3. Modo Insert? (Redundante si usamos TextChangedI pero seguro)
	if vim.api.nvim_get_mode().mode ~= "i" then
		return false
	end

	return true
end

---Busca nodo Treesitter válido
local function get_valid_string_node()
	local ok, node = pcall(vim.treesitter.get_node)
	if not ok or not node then
		return nil
	end

	-- Recorrer hacia arriba (limitado a 3 niveles para performance)
	local depth = 0
	while node and depth < 3 do
		if VALID_NODES[node:type()] then
			return node
		end
		node = node:parent()
		depth = depth + 1
	end
	return nil
end

---Lógica Principal
function M.check_and_transform()
	if not quick_check() then
		return
	end

	-- 1. FAST PATH: Lectura de caracteres (muy barato)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	if col < 2 then
		return
	end

	-- Leer solo los 2 caracteres relevantes
	local line = vim.api.nvim_get_current_line()
	local trigger_candidate = line:sub(col - 1, col)

	-- Si no es "${", salir INMEDIATAMENTE. Ahorra 99% CPU.
	if trigger_candidate ~= TRIGGER then
		return
	end

	-- 2. HEAVY PATH: Treesitter (solo si pasó el fast path)
	local node = get_valid_string_node()
	if not node then
		return
	end

	local s_row, s_col, e_row, e_col = node:range()

	-- Asegurar que el cambio es dentro del nodo y en la misma línea
	if row < s_row or row > e_row then
		return
	end

	-- Bloquear re-entrancia
	is_transforming = true

	-- 3. SCHEDULE: Ejecución diferida segura
	vim.schedule(function()
		-- Siempre liberar el lock, pase lo que pase
		local function unlock()
			is_transforming = false
		end

		-- Re-verificar validez del buffer y modo (el usuario pudo cambiar rápido)
		if not vim.api.nvim_buf_is_valid(0) or vim.api.nvim_get_mode().mode ~= "i" then
			unlock()
			return
		end

		-- Usar pcall para seguridad absoluta
		local status, err = pcall(function()
			-- A. Verificar comillas actuales
			local start_quote_text = vim.api.nvim_buf_get_text(0, s_row, s_col, s_row, s_col + 1, {})[1]
			local end_quote_text = vim.api.nvim_buf_get_text(0, e_row, e_col - 1, e_row, e_col, {})[1]

			local is_backtick = (start_quote_text == BACKTICK)

			-- B. Transformar comillas si es necesario
			if not is_backtick and start_quote_text == end_quote_text and TARGET_QUOTES[start_quote_text] then
				-- Reemplazo atómico
				vim.api.nvim_buf_set_text(0, e_row, e_col - 1, e_row, e_col, { BACKTICK })
				vim.api.nvim_buf_set_text(0, s_row, s_col, s_row, s_col + 1, { BACKTICK })
			end

			-- C. Compatibilidad mini.pairs / Autoclose
			-- Verificamos qué hay DELANTE del cursor (col apunta al siguiente char)
			-- Necesitamos obtener la linea actualizada tras el cambio de comillas?
			-- No, porque nvim_buf_set_text mantiene los indices relativos internos,
			-- pero es mejor releer el char específico.

			local current_line_content = vim.api.nvim_get_current_line()
			local char_after = current_line_content:sub(col + 1, col + 1)

			-- Si no hay '}', lo ponemos. Si mini.pairs ya lo puso, no hacemos nada.
			if char_after ~= CLOSE_BRACKET then
				vim.api.nvim_buf_set_text(0, row, col, row, col, { CLOSE_BRACKET })
			end
		end)

		if not status then
			-- Log de error silencioso o notificación debug
			-- vim.notify("AutoTemplate Error: " .. tostring(err), vim.log.levels.DEBUG)
		end

		unlock()
	end)
end

return M
