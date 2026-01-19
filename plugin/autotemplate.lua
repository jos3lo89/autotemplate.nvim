-- Evitar carga doble
if vim.g.loaded_autotemplate then
	return
end
vim.g.loaded_autotemplate = 1

-- Opcional: Si quieres que el plugin arranque con configuración por defecto sin llamar a .setup()
-- require("autotemplate").setup()
