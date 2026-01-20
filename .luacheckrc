std = "lua51+luajit"
globals = {"vim"}
read_globals = {
	"describe",
	"it",
	"before_each",
	"after_each",
}
ignore = {
	"212", -- Unused argument
	"631", -- Line too long
}