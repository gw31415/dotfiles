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

vim.api.nvim_create_autocmd('CursorHold', {
	once = true,
	command = 'source $HOME/.config/home-manager/nvim/lazy.vim'
})
vim.go.updatetime = 1
vim.api.nvim_create_autocmd('CursorHold', {
	once = true,
	callback = function() vim.go.updatetime = 4000 end,
})

----------------------------
-- Personal settings
----------------------------

vim.go.encoding = 'utf-8'
vim.opt_global.fencs = { 'utf-8', 'iso-2022-jp', 'euc-jp', 'sjis' }
vim.wo.number = true
vim.go.winblend = 20
vim.go.pumblend = 20
vim.go.guifont = 'HackGen_Console_NF:h14'
vim.go.tabstop = 4
vim.go.shiftwidth = 4
vim.go.cmdheight = 0
vim.wo.foldcolumn = '1'
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.cmd [[try | colo onedark | catch | endtry]]

-- Ignore startup treesitter errors
vim.treesitter.start = (function(wrapped)
	return function(bufnr, lang)
		lang = lang or vim.fn.getbufvar(bufnr or '', '&filetype')
		pcall(wrapped, bufnr, lang)
	end
end)(vim.treesitter.start)

vim.cmd 'filetype plugin indent on'
