vim.opt.packpath:prepend '~/.cache/rsplug'

require 'onedark'.setup { transparent = true, dark = true }
vim.cmd.colorscheme 'onedark'

----------------------------
-- Disable built-in plugins
----------------------------

vim.g.loaded_netrwPlugin = true
vim.g.loaded_remote_plugins = true
vim.g.skip_loading_mswin = true
vim.g.loaded_tutor_mode_plugin = true
vim.g.loaded_2html_plugin = true

----------------------------
-- Lazy loading
----------------------------

vim.schedule(function()
	require 'init_lazy'
	vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy', modeline = false })
end)

----------------------------
-- Personal settings
----------------------------

vim.go.encoding = 'utf-8'
vim.opt_global.fencs = { 'utf-8', 'iso-2022-jp', 'euc-jp', 'sjis' }
vim.wo.number = true
vim.go.winblend = 20
vim.go.pumblend = 20
vim.go.guifont = 'HackGen_Console_NF:h14'
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.go.cmdheight = 0
vim.o.fillchars = [[eob: ,fold: ,foldopen:󱨉,foldsep: ,foldclose:]]

vim.cmd 'filetype plugin indent on'

vim.filetype.add {
	filename = {
		Appfile = 'ruby',
	}
}
