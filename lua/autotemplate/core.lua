local M = {}

-- Constantes
local TRIGGER_CHAR = "$"
local KEYS_TO_INJECT = "{}<Left>"
local MODE_INSERT = "i"

-- Tipos de nodos válidos
local STRING_NODES = {
	string = true,
	template_string = true,
}

-- Comillas a reemplazar
local TARGET_QUOTES = {
	['"'] = true,
	["'"] = true,
}

local REPLACEMENT_QUOTE = "`"

---Verifica si el buffer actual se puede modificar
---@return boolean
local function is_buffer_modifiable()
	return vim.api.nvim_get_option_value("modifiable", { buf = 0 })
end

---Obtiene el nodo de string padre de forma segura
---@return TSNode|nil
local function get_string_node_safe()
	local ok, node = pcall(vim.treesitter.get_node)
	if not ok or not node then
		return nil
	end

	while node do
		if STRING_NODES[node:type()] then
			return node
		end
		node = node:parent()
	end

	return nil
end

---Obtiene el carácter anterior al cursor
---@param col number Columna actual (0-indexed)
---@return string|nil
local function get_char_before_cursor(col)
	if col == 0 then
		return nil
	end
	local line = vim.api.nvim_get_current_line()
	return line:sub(col, col)
end

---Ejecuta el cambio de comillas
local function apply_quote_transformation(start_row, start_col, end_row, end_col)
	local ok = pcall(function()
		vim.api.nvim_buf_set_text(0, end_row, end_col - 1, end_row, end_col, { REPLACEMENT_QUOTE })
		vim.api.nvim_buf_set_text(0, start_row, start_col, start_row, start_col + 1, { REPLACEMENT_QUOTE })
	end)
	return ok
end

---Función principal
---@return boolean
function M.handle_trigger()
	if vim.fn.mode() ~= MODE_INSERT then
		return false
	end
	if not is_buffer_modifiable() then
		return false
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local _, col = cursor[1] - 1, cursor[2]

	local char_before = get_char_before_cursor(col)
	if char_before ~= TRIGGER_CHAR then
		return false
	end

	local node = get_string_node_safe()
	if not node then
		return false
	end

	local s_row, s_col, e_row, e_col = node:range()

	-- CORRECCIÓN 2: Usamos nombres distintos para la lista (resultado API) y el string final
	local ok_start, start_text_list = pcall(vim.api.nvim_buf_get_text, 0, s_row, s_col, s_row, s_col + 1, {})
	local ok_end, end_text_list = pcall(vim.api.nvim_buf_get_text, 0, e_row, e_col - 1, e_row, e_col, {})

	if not ok_start or not ok_end then
		return false
	end

	-- Extraemos el string de la lista de forma segura
	local start_quote = start_text_list[1]
	local end_quote = end_text_list[1]

	local keys = vim.api.nvim_replace_termcodes(KEYS_TO_INJECT, true, false, true)

	-- CASO A: Ya son backticks
	if start_quote == REPLACEMENT_QUOTE then
		vim.api.nvim_feedkeys(keys, "n", false)
		return true
	end

	-- CASO B: Transformar comillas
	if TARGET_QUOTES[start_quote] and start_quote == end_quote then
		local success = apply_quote_transformation(s_row, s_col, e_row, e_col)
		if success then
			vim.api.nvim_feedkeys(keys, "n", false)
			return true
		end
	end

	return false
end

return M
