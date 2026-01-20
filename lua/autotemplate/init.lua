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
	local map = vim.fn.maparg(key, "i", false, true)
	if not map or vim.tbl_isempty(map) then
		return nil
	end

	-- Critical: Don't capture our own mapping
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

			-- 1. CAPTURE EXISTING MAPPING (autopairs, etc.)
			local fallback_map = get_original_map(trigger)

			-- 2. SET OUR MAPPING
			vim.keymap.set("i", trigger, function()
				-- Fallback Logic: Execute previous map correctly
				local function fallback()
					if fallback_map then
						local keys_to_feed = nil

						-- Case A: Lua Callback
						if fallback_map.callback then
							if fallback_map.expr == 1 then
								-- Map is an expression: Call it and Capture result
								keys_to_feed = fallback_map.callback()
							else
								-- Map is side-effect: Just call it
								fallback_map.callback()
								return
							end

						-- Case B: Vimscript RHS
						elseif fallback_map.rhs then
							if fallback_map.expr == 1 then
								-- Evaluate Vimscript expression
								keys_to_feed = vim.api.nvim_eval(fallback_map.rhs)
							else
								keys_to_feed = fallback_map.rhs
							end
						end

						-- Feed the result if any (using 'n' to prevent loops)
						if keys_to_feed then
							local term_keys = vim.api.nvim_replace_termcodes(keys_to_feed, true, false, true)
							vim.api.nvim_feedkeys(term_keys, "n", false)
						end
					else
						-- Case C: No previous map, just type the key
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

				-- B. Core Logic (Lazy Load)
				local core = require("autotemplate.core")
				local handled = core.handle_trigger({
					auto_close = config.options.auto_close_brackets,
				})

				-- C. If not handled, execute fallback
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
