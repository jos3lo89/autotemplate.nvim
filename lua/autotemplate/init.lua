local M = {}
local config = require("autotemplate.config")

-- Autocommand group name to prevent duplication during reloads
local AU_GROUP_NAME = "AutoTemplateSetup"

M.enabled = true

---Dynamically toggles the plugin state
function M.toggle()
	M.enabled = not M.enabled
	local status = M.enabled and "Enabled" or "Disabled"
	vim.notify("AutoTemplate: " .. status, vim.log.levels.INFO)
end

---Cleans up all plugin traces (Autocommands and internal state)
function M.teardown()
	if vim.fn.exists("#" .. AU_GROUP_NAME) == 1 then
		vim.api.nvim_del_augroup_by_name(AU_GROUP_NAME)
	end
	M.enabled = false
end

---Checks if the plugin should attach to the current buffer
local function should_attach(bufnr)
	if not M.enabled then
		return false
	end
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	for _, ignore in ipairs(config.options.ignored_filetypes) do
		if ft == ignore then
			return false
		end
	end
	for _, supported in ipairs(config.options.filetypes) do
		if ft == supported then
			return true
		end
	end
	return false
end

---Retrieves the existing mapping for a key to use as fallback
---@param key string The key to look up (e.g. "{")
---@return table|nil The mapping definition or nil
local function get_original_map(key)
	-- Look for buffer-local or global mappings for this key in Insert mode
	local map = vim.fn.maparg(key, "i", false, true)

	-- Safety check: verify map exists and is not empty
	if not map or vim.tbl_isempty(map) then
		return nil
	end

	-- CRITICAL: Avoid capturing our own mapping if the plugin is reloaded
	if map.desc == "Auto Template String Interpolation" then
		return nil
	end

	return map
end

function M.setup(opts)
	M.teardown()
	M.enabled = true
	config.setup(opts)

	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {})
	local au_group = vim.api.nvim_create_augroup(AU_GROUP_NAME, { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = au_group,
		pattern = config.options.filetypes,
		callback = function(args)
			if not should_attach(args.buf) then
				return
			end

			local trigger = config.options.trigger_key

			-- 1. CAPTURE EXISTING MAPPING (e.g. nvim-autopairs)
			-- We do this *before* setting our own map
			local fallback_map = get_original_map(trigger)

			-- 2. SET OUR MAPPING
			vim.keymap.set("i", trigger, function()
				-- Fallback Logic: What to do if we don't handle the key
				local function fallback()
					if fallback_map then
						-- If there was a previous mapping, execute it directly
						if fallback_map.callback then
							fallback_map.callback()
						elseif fallback_map.rhs then
							local keys = vim.api.nvim_replace_termcodes(fallback_map.rhs, true, false, true)
							-- Respect the original noremap setting
							local mode = fallback_map.noremap == 1 and "n" or "m"
							vim.api.nvim_feedkeys(keys, mode, false)
						end
					else
						-- If no previous mapping, just insert the character cleanly (No recursion)
						local key = vim.api.nvim_replace_termcodes(trigger, true, false, true)
						vim.api.nvim_feedkeys(key, "n", false)
					end
				end

				-- A. Guard clauses
				if not M.enabled then
					return fallback()
				end
				if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
					return fallback()
				end

				-- B. Core Logic
				local core = require("autotemplate.core")
				local handled = core.handle_trigger({
					auto_close = config.options.auto_close_brackets,
				})

				-- C. If not handled, execute fallback (autopairs or normal key)
				if not handled then
					fallback()
				end
			end, {
				buffer = args.buf,
				expr = false,
				remap = false,
				desc = "Auto Template String Interpolation",
			})
		end,
	})
end

return M
