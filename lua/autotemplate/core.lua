local M = {}

-- CONSTANTS & CONFIGURATION
local TRIGGER_CHAR = "$"
local MODE_INSERT = "i"
local REPLACEMENT_QUOTE = "`"

-- Keys to inject based on the 'auto_close' configuration
-- 1. When auto_close_brackets = true
local KEYS_WITH_CLOSE = "{}<Left>"
-- 2. When auto_close_brackets = false
local KEYS_WITHOUT_CLOSE = "{"

-- Valid Treesitter node types to detect string context
local STRING_NODES = {
	string = true,
	template_string = true,
}

-- Target quote characters that should be replaced
local TARGET_QUOTES = {
	['"'] = true,
	["'"] = true,
}

-- UTILITY FUNCTIONS

---Checks if the current buffer is modifiable
---@return boolean
local function is_buffer_modifiable()
	return vim.api.nvim_get_option_value("modifiable", { buf = 0 })
end

---Safely retrieves the parent string node using Treesitter
---@return TSNode|nil
local function get_string_node_safe()
	local ok, node = pcall(vim.treesitter.get_node)
	if not ok or not node then
		return nil
	end

	-- Traverse up the tree to find a valid string node
	while node do
		if STRING_NODES[node:type()] then
			return node
		end
		node = node:parent()
	end

	return nil
end

---Gets the character immediately before the cursor
---@param col number Current column (0-indexed)
---@return string|nil
local function get_char_before_cursor(col)
	if col == 0 then
		return nil
	end
	local line = vim.api.nvim_get_current_line()
	return line:sub(col, col)
end

---Executes the atomic replacement of start and end quotes
---@param start_row number
---@param start_col number
---@param end_row number
---@param end_col number
---@return boolean success
local function apply_quote_transformation(start_row, start_col, end_row, end_col)
	local ok = pcall(function()
		-- Replace end quote first to maintain index integrity
		vim.api.nvim_buf_set_text(0, end_row, end_col - 1, end_row, end_col, { REPLACEMENT_QUOTE })
		vim.api.nvim_buf_set_text(0, start_row, start_col, start_row, start_col + 1, { REPLACEMENT_QUOTE })
	end)
	return ok
end

-- MAIN LOGIC

---Main handler function
---@param opts table Options passed from init.lua (e.g., { auto_close = true })
---@return boolean handled Returns true if an action was performed
function M.handle_trigger(opts)
	-- Retrieve options, defaulting to true if missing
	opts = opts or {}
	local auto_close = opts.auto_close ~= false -- default true

	-- 1. State Validations
	if vim.fn.mode() ~= MODE_INSERT then
		return false
	end
	if not is_buffer_modifiable() then
		return false
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local _, col = cursor[1] - 1, cursor[2]

	-- 2. Trigger Character Validation
	local char_before = get_char_before_cursor(col)
	if char_before ~= TRIGGER_CHAR then
		return false
	end

	-- 3. Treesitter Context Analysis
	local node = get_string_node_safe()
	if not node then
		return false
	end

	local s_row, s_col, e_row, e_col = node:range()

	-- 4. Safe Text Retrieval
	-- Use pcall to avoid errors if buffer state changes rapidly
	local ok_start, start_text_list = pcall(vim.api.nvim_buf_get_text, 0, s_row, s_col, s_row, s_col + 1, {})
	local ok_end, end_text_list = pcall(vim.api.nvim_buf_get_text, 0, e_row, e_col - 1, e_row, e_col, {})

	if not ok_start or not ok_end then
		return false
	end

	-- Extract the actual string character from the list
	local start_quote = start_text_list[1]
	local end_quote = end_text_list[1]

	-- 5. Determine Keys to Inject
	-- If auto_close is true: inject {} and move cursor left
	-- If auto_close is false: inject only {
	local keys_to_inject = auto_close and KEYS_WITH_CLOSE or KEYS_WITHOUT_CLOSE
	local keys = vim.api.nvim_replace_termcodes(keys_to_inject, true, false, true)

	-- CASE A: Already backticks (Standard interpolation)
	if start_quote == REPLACEMENT_QUOTE then
		vim.api.nvim_feedkeys(keys, "n", false)
		return true
	end

	-- CASE B: Transform quotes (' or ")
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
