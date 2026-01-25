local M = {}

-- Constants
local TRIGGER = "${"
local CLOSE_BRACKET = "}"
local BACKTICK = "`"
local TARGET_QUOTES = { ['"'] = true, ["'"] = true }

-- Valid nodes
local VALID_NODES = {
	string = true,
	template_string = true,
	string_fragment = true,
	string_literal = true, -- Python/Go
}

-- Re-entrancy guard
local is_transforming = false

-- Fast checks
local function quick_check()
	-- Guard
	if is_transforming then
		return false
	end

	-- Modifiable buffer
	if not vim.api.nvim_get_option_value("modifiable", { buf = 0 }) then
		return false
	end

	-- Insert mode
	if vim.api.nvim_get_mode().mode ~= "i" then
		return false
	end

	return true
end

-- Find string node
local function get_valid_string_node()
	local ok, node = pcall(vim.treesitter.get_node)
	if not ok or not node then
		return nil
	end

	-- Walk up a few levels
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

-- Main
function M.check_and_transform()
	if not quick_check() then
		return
	end

	-- Fast path
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	if col < 2 then
		return
	end

	-- Check trigger
	local line = vim.api.nvim_get_current_line()
	local trigger_candidate = line:sub(col - 1, col)

	if trigger_candidate ~= TRIGGER then
		return
	end

	-- Treesitter check
	local node = get_valid_string_node()
	if not node then
		return
	end

	local s_row, s_col, e_row, e_col = node:range()

	-- Inside node
	if row < s_row or row > e_row then
		return
	end

	-- Lock
	is_transforming = true

	-- Scheduled edit
	vim.schedule(function()
		-- Always unlock
		local function unlock()
			is_transforming = false
		end

		-- Re-check buffer/mode
		if not vim.api.nvim_buf_is_valid(0) or vim.api.nvim_get_mode().mode ~= "i" then
			unlock()
			return
		end

		-- Guarded edit
		local status, err = pcall(function()
			local start_quote_text = vim.api.nvim_buf_get_text(0, s_row, s_col, s_row, s_col + 1, {})[1]
			local end_quote_text = vim.api.nvim_buf_get_text(0, e_row, e_col - 1, e_row, e_col, {})[1]

			local is_backtick = (start_quote_text == BACKTICK)

			if not is_backtick and start_quote_text == end_quote_text and TARGET_QUOTES[start_quote_text] then
				vim.api.nvim_buf_set_text(0, e_row, e_col - 1, e_row, e_col, { BACKTICK })
				vim.api.nvim_buf_set_text(0, s_row, s_col, s_row, s_col + 1, { BACKTICK })
			end

			-- Check for closing brace
			local current_line_content = vim.api.nvim_get_current_line()
			local char_after = current_line_content:sub(col + 1, col + 1)

			if char_after ~= CLOSE_BRACKET then
				vim.api.nvim_buf_set_text(0, row, col, row, col, { CLOSE_BRACKET })
			end
		end)

		if not status then
			-- vim.notify("AutoTemplate Error: " .. tostring(err), vim.log.levels.DEBUG)
		end

		unlock()
	end)
end

return M
