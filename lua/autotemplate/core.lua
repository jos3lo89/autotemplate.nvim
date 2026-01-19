local M = {}

-- Función interna para buscar el nodo string
local function get_string_node()
	local ok, node = pcall(vim.treesitter.get_node)
	if not ok or not node then
		return nil
	end

	-- Subimos por el árbol hasta encontrar un string o template_string
	while node do
		local type = node:type()
		if type == "string" or type == "template_string" then
			return node
		end
		node = node:parent()
	end
	return nil
end

function M.handle_trigger()
	-- 1. Verificaciones rápidas (Fail fast)
	if vim.fn.mode() ~= "i" then
		return "{"
	end

	-- Obtener posición
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	if col == 0 then
		return "{"
	end

	-- Leer carácter anterior
	local line = vim.api.nvim_get_current_line()
	local char_before = line:sub(col, col)

	-- Si no escribiste un $, no hacemos nada
	if char_before ~= "$" then
		return "{"
	end

	-- 2. Análisis Treesitter
	local node = get_string_node()
	if not node then
		return "{"
	end

	local s_row, s_col, e_row, e_col = node:range()

	-- Seguridad: Obtener las comillas actuales
	local start_txt = vim.api.nvim_buf_get_text(0, s_row, s_col, s_row, s_col + 1, {})[1]
	local end_txt = vim.api.nvim_buf_get_text(0, e_row, e_col - 1, e_row, e_col, {})[1]

	-- CASO 1: Ya son backticks -> Solo cerramos llaves y centramos
	if start_txt == "`" then
		return "{}<Left>"
	end

	-- CASO 2: Son comillas simples o dobles -> Transformamos y centramos
	if (start_txt == "'" or start_txt == '"') and (start_txt == end_txt) then
		-- Edición atómica: cambiamos fin e inicio
		vim.api.nvim_buf_set_text(0, e_row, e_col - 1, e_row, e_col, { "`" })
		vim.api.nvim_buf_set_text(0, s_row, s_col, s_row, s_col + 1, { "`" })

		return "{}<Left>"
	end

	return "{"
end

return M
