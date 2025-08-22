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

vim.defer_fn(function()
	vim.cmd [[
		source $HOME/.config/home-manager/nvim/lazy.vim
		doautocmd CursorHold
	]]
end, 1)

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

-- Ignore startup treesitter errors
vim.treesitter.start = (function(wrapped)
	return function(bufnr, lang)
		lang = lang or vim.fn.getbufvar(bufnr, '&filetype')
		-- Vimdocの場合無効化
		if lang == 'help' then return end

		pcall(wrapped, bufnr, lang)
	end
end)(vim.treesitter.start)
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
	callback = function(ctx) vim.treesitter.start(0, ctx.match) end,
})

vim.cmd 'filetype plugin indent on'

vim.filetype.add {
	filename = {
		Appfile = 'ruby',
	}
}
