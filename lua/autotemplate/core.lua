local M = {}

--- Debug logger
---@param msg string
local function log_debug(msg)
	local config = require("autotemplate.config")
	if config.options.debug then
		vim.notify("[AutoTemplate] " .. msg, vim.log.levels.DEBUG)
	end
end

--- Safely get current treesitter node
---@return TSNode|nil
local function get_current_node()
	local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
	if not ok then
		log_debug("Treesitter utils not available")
		return nil
	end

	local ok_node, node = pcall(ts_utils.get_node_at_cursor)
	if not ok_node then
		log_debug("Failed to get node at cursor")
		return nil
	end

	return node
end

--- Find parent string node from current position
---@return TSNode|nil
local function get_string_node()
	local node = get_current_node()
	if not node then
		return nil
	end

	-- Navega hasta encontrar un nodo de string
	local max_depth = 10 -- Evita bucles infinitos
	local depth = 0

	while node and depth < max_depth do
		local node_type = node:type()

		-- Soporte para múltiples tipos de strings
		if node_type == "string"
			or node_type == "template_string"
			or node_type == "string_fragment"
			or node_type == "jsx_text" then
			log_debug("Found string node: " .. node_type)
			return node
		end

		node = node:parent()
		depth = depth + 1
	end

	log_debug("No string node found")
	return nil
end

--- Check if buffer is modifiable
---@param bufnr number
---@return boolean
local function is_buffer_modifiable(bufnr)
	return vim.api.nvim_get_option_value("modifiable", { buf = bufnr })
		and not vim.api.nvim_get_option_value("readonly", { buf = bufnr })
end

--- Get quote characters at string boundaries
---@param node TSNode
---@return string|nil, string|nil start_quote, end_quote
local function get_string_quotes(node)
	local s_row, s_col, e_row, e_col = node:range()

	-- Validar que las posiciones sean válidas
	if s_row < 0 or e_row < 0 or s_col < 0 or e_col < 0 then
		log_debug("Invalid node range")
		return nil, nil
	end

	local ok_start, start_txt = pcall(
		vim.api.nvim_buf_get_text,
		0, s_row, s_col, s_row, s_col + 1, {}
	)

	local ok_end, end_txt = pcall(
		vim.api.nvim_buf_get_text,
		0, e_row, e_col - 1, e_row, e_col, {}
	)

	if not ok_start or not ok_end then
		log_debug("Failed to get string boundaries")
		return nil, nil
	end

	return start_txt[1], end_txt[1]
end

--- Convert quotes to template string and insert braces
---@param node TSNode
---@return boolean success
local function convert_to_template_string(node)
	local s_row, s_col, e_row, e_col = node:range()

	-- Cambiar comillas a backticks de forma atómica
	local ok = pcall(function()
		vim.api.nvim_buf_set_text(0, e_row, e_col - 1, e_row, e_col, { "`" })
		vim.api.nvim_buf_set_text(0, s_row, s_col, s_row, s_col + 1, { "`" })
	end)

	if not ok then
		log_debug("Failed to convert quotes")
		return false
	end

	log_debug("Converted to template string")
	return true
end

--- Main trigger handler
---@return boolean handled
function M.handle_trigger()
	-- Validaciones de contexto
	if vim.fn.mode() ~= "i" then
		log_debug("Not in insert mode")
		return false
	end

	local bufnr = vim.api.nvim_get_current_buf()
	if not is_buffer_modifiable(bufnr) then
		log_debug("Buffer not modifiable")
		return false
	end

	-- Obtener posición del cursor
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	if col == 0 then
		log_debug("At line start")
		return false
	end

	-- Verificar carácter anterior
	local line = vim.api.nvim_get_current_line()
	local char_before = line:sub(col, col)

	if char_before ~= "$" then
		log_debug("Previous char is not $")
		return false
	end

	-- Buscar nodo de string
	local node = get_string_node()
	if not node then
		return false
	end

	local start_quote, end_quote = get_string_quotes(node)
	if not start_quote or not end_quote then
		return false
	end

	-- Insertar llaves
	local keys = vim.api.nvim_replace_termcodes("{}<Left>", true, false, true)

	-- Si ya es template string, solo insertar llaves
	if start_quote == "`" then
		vim.api.nvim_feedkeys(keys, "n", false)
		log_debug("Already template string")
		return true
	end

	-- Convertir a template string
	if (start_quote == "'" or start_quote == '"') and start_quote == end_quote then
		if convert_to_template_string(node) then
			vim.api.nvim_feedkeys(keys, "n", false)
			return true
		end
	end

	return false
end

return M
