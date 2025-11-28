vim.opt_global.helplang = 'ja,en'

vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.splitbelow = true
vim.opt.laststatus = 3
vim.opt.scrolloff = 3
vim.opt.smoothscroll = true
vim.opt.diffopt:append { 'algorithm:histogram' }

-- Use ripgrep for :grep
vim.opt.grepprg = 'rg --vimgrep --no-heading --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'

-- Emacs-like keybindings in insert and command mode
vim.cmd [[
	ino <c-f> <c-g>U<right>
	ino <c-b> <c-g>U<left>
	ino <c-p> <c-g>U<up>
	ino <c-n> <c-g>U<down>
	ino <c-d> <c-g>U<del>
	ino <expr> <c-a> col('.') == match(getline('.'), '\S') + 1 ?
		\ repeat('<C-G>U<Left>', col('.') - 1) :
		\ (col('.') < match(getline('.'), '\S') ?
		\     repeat('<C-G>U<Right>', match(getline('.'), '\S') + 0) :
		\     repeat('<C-G>U<Left>', col('.') - 1 - match(getline('.'), '\S')))
	ino <expr> <c-e> repeat('<C-G>U<Right>', col('$') - col('.'))

	cno <c-f> <right>
	cno <c-b> <left>
	cno <c-p> <up>
	cno <c-n> <down>
	cno <c-d> <del>
	cno <c-a> <home>
	cno <c-e> <end>
]]

-- Use mise cmds
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH

if vim.g.neovide then
	vim.g.neovide_position_animation_length = 0
	vim.g.neovide_cursor_animation_length = 0.00
	vim.g.neovide_cursor_trail_size = 0
	vim.g.neovide_cursor_animate_in_insert_mode = false
	vim.g.neovide_cursor_animate_command_line = false
	vim.g.neovide_scroll_animation_far_lines = 0
	vim.g.neovide_scroll_animation_length = 0.00
end

-- 空行での編集開始時に自動でインデント
for _, key in ipairs { 'a', 'A' } do
	vim.keymap.set('n', key, function()
		return vim.fn.empty(vim.fn.getline('.')) == 1 and '"_cc' or key
	end, { expr = true })
end

--------------------------------------------------------------------------------
-- Global Mappings/Configs used in LSP
--------------------------------------------------------------------------------

vim.lsp.config('*', {
	capabilities = {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = true,
			},
		},
	},
})

vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(args)
		vim.lsp.document_color.enable(true, args.buf, { style = "virtual" })

		vim.opt_local.formatexpr = 'v:lua.require"conform".formatexpr()'

		vim.diagnostic.config { signs = false, virtual_text = false }
		local bufopts = { silent = true, buffer = true }
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
		vim.keymap.set('n', 'K', function()
			local winid = require 'ufo'.peekFoldedLinesUnderCursor()
			if not winid then vim.lsp.buf.hover() end
		end, bufopts)
		vim.keymap.set('n', 'gra', function()
			require 'actions-preview'.code_actions()
		end, bufopts)
		vim.keymap.set('n', 'gqae', function()
				require 'conform'.format { async = true, lsp_format = 'fallback' }
			end,
			{ buffer = true }
		)
	end,
})

--------------------------------------------------------------------------------
-- fzyselect.vim - Custom tweaks
--------------------------------------------------------------------------------

vim.defer_fn(function()
	---@diagnostic disable-next-line: duplicate-set-field
	vim.ui.select = function(...) require 'fzyselect'.start(...) end
end, 1000)

-- git ls-files
vim.keymap.set('n', '<c-p>', function()
	local res = vim.system({ 'sh', '-c', [[
		(
			git ls-files
			git ls-files --others --exclude-standard
		) | sort -u
	]] }, { text = true }):wait()
	if res.code ~= 0 then
		vim.notify(vim.fn.trim(res.stderr), vim.log.levels.ERROR, { title = 'fzyselect: git ls-files' })
	else
		require 'fzyselect'.start(vim.fn.split(res.stdout, '\n'),
			{ prompt = 'git ls-files: <Enter> to edit' },
			function(path)
				if path then vim.cmd.edit(path) end
			end)
	end
end)

-- Update
vim.api.nvim_create_user_command('PackUpdate', function() vim.pack.update() end, {})

vim.api.nvim_create_user_command('TSReinstall', function()
	local ts_installed_list = require 'nvim-treesitter'.get_installed()
	require 'nvim-treesitter'.uninstall(ts_installed_list):wait(180000)
	require 'nvim-treesitter'.install(ts_installed_list, { summary = true })
end, {})

vim.g.gin_proxy_editor_opener = 'bo sp'
vim.keymap.set('n', '<c-g>p', function() require 'commitgen'.paste {} end)
vim.keymap.set('n', '<c-g>P', function() require 'commitgen'.paste { after = false } end)
vim.keymap.set('n', '<c-g>c', '<cmd>Gin commit<cr>', { silent = true })
vim.keymap.set('n', '<c-g>C', '<cmd>Gin commit --amend<cr>', { silent = true })

vim.api.nvim_create_user_command('Restart', function()
	local cache = vim.fn.stdpath 'cache' .. '/nvim-restart-session.vim'
	vim.cmd('mksession! ' .. vim.fn.fnameescape(cache))
	vim.cmd('restart source ' .. vim.fn.fnameescape(cache))
end, {})
vim.keymap.set('n', '<c-n>', function() require 'fyler'.toggle { kind = "float" } end, { desc = "Toggle Fyler View" })

-- local ok, extui = pcall(require, 'vim._extui')
-- if ok then
-- 	extui.enable({
-- 		enable = true,
-- 		msg = {
-- 			pos = 'cmd',
-- 			box = {
-- 				timeout = 5000,
-- 			},
-- 		},
-- 	})
-- end
