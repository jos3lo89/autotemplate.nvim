local M = {}

local config = require("autotemplate.config")
local core = require("autotemplate.core")

M.enabled = true
M._augroup = nil

--- Toggle plugin state
function M.toggle()
	M.enabled = not M.enabled
	local status = M.enabled and "Enabled" or "Disabled"
	vim.notify("AutoTemplate: " .. status, vim.log.levels.INFO)
end

--- Enable plugin
function M.enable()
	if not M.enabled then
		M.toggle()
	end
end

--- Disable plugin
function M.disable()
	if M.enabled then
		M.toggle()
	end
end

--- Check if plugin should attach to buffer
---@param bufnr number
---@return boolean
local function should_attach(bufnr)
	if not M.enabled then
		return false
	end

	-- Validar que el buffer sea válido
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end

	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	-- Verificar ignored filetypes
	for _, ignore in ipairs(config.options.ignored_filetypes or {}) do
		if ft == ignore then
			return false
		end
	end

	-- Verificar supported filetypes
	for _, supported in ipairs(config.options.filetypes) do
		if ft == supported then
			return true
		end
	end

	return false
end

--- Setup trigger keymap for buffer
---@param bufnr number
local function setup_keymap(bufnr)
	vim.keymap.set("i", "{", function()
		if not M.enabled then
			return "{"
		end

		-- Respetar disable_in_macro
		if config.options.disable_in_macro and vim.fn.reg_recording() ~= "" then
			return "{"
		end

		local handled = core.handle_trigger()
		if not handled then
			return "{"
		end
	end, {
		buffer = bufnr,
		expr = true, -- IMPORTANTE: expr=true para retornar el string
		noremap = true,
		silent = true,
		desc = "AutoTemplate: Convert to template string"
	})
end

--- Cleanup all autocommands and keymaps
function M.cleanup()
	if M._augroup then
		vim.api.nvim_del_augroup_by_id(M._augroup)
		M._augroup = nil
	end
end

--- Setup plugin
---@param opts table|nil User configuration
function M.setup(opts)
	-- Cleanup previous setup
	M.cleanup()

	-- Setup configuration
	config.setup(opts)

	-- Create augroup
	M._augroup = vim.api.nvim_create_augroup("AutoTemplate", { clear = true })

	-- Register user command
	vim.api.nvim_create_user_command("AutoTemplateToggle", M.toggle, {
		desc = "Toggle AutoTemplate plugin"
	})

	vim.api.nvim_create_user_command("AutoTemplateEnable", M.enable, {
		desc = "Enable AutoTemplate plugin"
	})

	vim.api.nvim_create_user_command("AutoTemplateDisable", M.disable, {
		desc = "Disable AutoTemplate plugin"
	})

	-- Setup FileType autocmd
	vim.api.nvim_create_autocmd("FileType", {
		group = M._augroup,
		pattern = config.options.filetypes,
		callback = function(args)
			if not should_attach(args.buf) then
				return
			end

			setup_keymap(args.buf)

			if config.options.debug then
				vim.notify(
					string.format("AutoTemplate attached to buffer %d", args.buf),
					vim.log.levels.INFO
				)
			end
		end,
	})

	-- Attach to already opened buffers
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and should_attach(bufnr) then
			setup_keymap(bufnr)
		end
	end
end

return M
