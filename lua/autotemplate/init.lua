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
	-- Delete the autocommand group to stop listening to new FileTypes
	if vim.fn.exists("#" .. AU_GROUP_NAME) == 1 then
		vim.api.nvim_del_augroup_by_name(AU_GROUP_NAME)
	end

	-- Reset global enabled flag
	M.enabled = false
end

---Checks if the plugin should attach to the current buffer
local function should_attach(bufnr)
	if not M.enabled then
		return false
	end

	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	-- Priority: Blacklist check
	for _, ignore in ipairs(config.options.ignored_filetypes) do
		if ft == ignore then
			return false
		end
	end

	-- Whitelist check
	for _, supported in ipairs(config.options.filetypes) do
		if ft == supported then
			return true
		end
	end
	return false
end

function M.setup(opts)
	-- Clean previous state if reloading the plugin
	M.teardown()
	M.enabled = true

	-- Initialize configuration
	config.setup(opts)

	-- Create user commands
	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {})

	-- Create Autogroup (clear=true removes old definitions)
	local au_group = vim.api.nvim_create_augroup(AU_GROUP_NAME, { clear = true })

	-- Main autocommand to handle filetype detection
	vim.api.nvim_create_autocmd("FileType", {
		group = au_group,
		pattern = config.options.filetypes,
		callback = function(args)
			if not should_attach(args.buf) then
				return
			end

			-- Dynamic mapping using the configured trigger key
			vim.keymap.set("i", config.options.trigger_key, function()
				-- If disabled, fallback to native behavior
				if not M.enabled then
					return config.options.trigger_key
				end

				-- Check if a macro is being recorded to avoid interruptions
				if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
					return config.options.trigger_key
				end

				-- Lazy Loading: Require 'core' only when the user presses the key
				-- This ensures instant startup time for Neovim
				local core = require("autotemplate.core")

				-- Execute core logic
				local handled = core.handle_trigger({
					auto_close = config.options.auto_close_brackets,
				})

				-- If core did not handle the input, return the original key
				if not handled then
					-- Use feedkeys to simulate natural input if logic failed or was skipped
					-- Note: expr=false is used for buffer safety, so we use feedkeys instead of returning the string
					vim.api.nvim_feedkeys(config.options.trigger_key, "n", false)
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
