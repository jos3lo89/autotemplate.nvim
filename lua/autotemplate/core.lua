local M = {}

local function get_string_node()
	local ok, node = pcall(vim.treesitter.get_node)
	if not ok or not node then
		return nil
	end

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
	if vim.fn.mode() ~= "i" then
		return false
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	if col == 0 then
		return false
	end

	local line = vim.api.nvim_get_current_line()
	local char_before = line:sub(col, col)

	if char_before ~= "$" then
		return false
	end

	local node = get_string_node()
	if not node then
		return false
	end

	local s_row, s_col, e_row, e_col = node:range()
	local start_txt = vim.api.nvim_buf_get_text(0, s_row, s_col, s_row, s_col + 1, {})[1]
	local end_txt = vim.api.nvim_buf_get_text(0, e_row, e_col - 1, e_row, e_col, {})[1]

	local keys = vim.api.nvim_replace_termcodes("{}<Left>", true, false, true)

	if start_txt == "`" then
		vim.api.nvim_feedkeys(keys, "n", false)
		return true
	end

	if (start_txt == "'" or start_txt == '"') and (start_txt == end_txt) then
		-- Al no estar en expr=true, esto ya es legal
		vim.api.nvim_buf_set_text(0, e_row, e_col - 1, e_row, e_col, { "`" })
		vim.api.nvim_buf_set_text(0, s_row, s_col, s_row, s_col + 1, { "`" })

		-- Insertamos las llaves después de cambiar las comillas
		vim.api.nvim_feedkeys(keys, "n", false)
		return true
	end

	return false
end

return M
