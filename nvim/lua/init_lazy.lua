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

local path_sep = package.config:sub(1, 1) == '\\' and ';' or ':'

-- Use mise cmds
vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims" .. path_sep .. vim.env.PATH

local function prepend_node_modules_bin(path)
	if not path or path == '' then return end

	local node_modules_dir = vim.fs.find('node_modules', {
		path = path,
		upward = true,
		type = 'directory',
	})[1]
	if not node_modules_dir then return end

	local bin_dir = vim.fs.joinpath(node_modules_dir, '.bin')
	if vim.fn.isdirectory(bin_dir) == 0 then return end

	local path_entries = vim.split(vim.env.PATH or '', path_sep, { plain = true, trimempty = true })
	if vim.tbl_contains(path_entries, bin_dir) then return end

	vim.env.PATH = bin_dir .. path_sep .. (vim.env.PATH or '')
end

prepend_node_modules_bin(vim.fn.getcwd())
vim.api.nvim_create_autocmd({ 'VimEnter', 'DirChanged', 'BufEnter' }, {
	callback = function(args)
		prepend_node_modules_bin(vim.fn.getcwd())

		local bufname = args.buf and vim.api.nvim_buf_get_name(args.buf) or ''
		if bufname ~= '' then
			prepend_node_modules_bin(vim.fs.dirname(bufname))
		end
	end,
})

vim.api.nvim_create_user_command('Restart', function()
	local cache = vim.fn.stdpath 'cache' .. '/nvim-restart-session.vim'
	vim.cmd('mksession! ' .. vim.fn.fnameescape(cache))
	vim.cmd('restart source ' .. vim.fn.fnameescape(cache))
end, {})
vim.keymap.set('n', 'zr', '<cmd>Restart<cr>')

vim.api.nvim_create_user_command('TSReinstall', function()
	local ts_installed_list = require 'nvim-treesitter'.get_installed()
	require 'nvim-treesitter'.uninstall(ts_installed_list):wait(180000)
	require 'nvim-treesitter'.install(ts_installed_list, { summary = true })
end, {})

-- 空行での編集開始時に自動でインデント
for _, key in ipairs { 'a', 'A', 'i', 'I' } do
	vim.keymap.set('n', key, function()
		return vim.fn.empty(vim.fn.getline('.')) == 1 and '"_cc' or key
	end, { expr = true })
end

-- 残りのウィンドウが特殊ウィンドウのみである場合、終了する
-- https://zenn.dev/vim_jp/articles/ff6cd224fab0c7
vim.api.nvim_create_autocmd('QuitPre', {
	callback = function()
		-- 現在のウィンドウ番号を取得
		local current_win = vim.api.nvim_get_current_win()
		-- すべてのウィンドウをループして調べる
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			-- カレント以外を調査
			if win ~= current_win then
				local buf = vim.api.nvim_win_get_buf(win)
				-- buftypeが空文字（通常のバッファ）があればループ終了
				if vim.bo[buf].buftype == '' then
					return
				end
			end
		end
		-- ここまで来たらカレント以外がすべて特殊ウィンドウということなので
		-- カレント以外をすべて閉じる
		vim.cmd.only({ bang = true })
		-- この後、ウィンドウ1つの状態でquitが実行されるので、Vimが終了する
	end,
	desc = 'Close all special buffers and quit Neovim',
})

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
		vim.lsp.document_color.enable(true, { bufnr = args.buf }, { style = "virtual" })

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
		vim.keymap.set('n', 'gqal', function()
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
	vim.ui.select = function(...) return require 'fzyselect'.start(...) end
end, 1000)
