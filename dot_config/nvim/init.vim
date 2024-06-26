se encoding=utf-8
se fencs=utf-8,iso-2022-jp,euc-jp,sjis
se fdc=1
se vop=folds
se ts=4
se sw=4
se nu
se winbl=20
se pb=20
se cul
se cuc
se sb
se hid
se ls=3
se sms
se so=3
se ch=0
se guifont=HackGen_Console_NF:h14
let g:neovide_window_blurred = v:true
let g:neovide_transparency = 0.7
se diffopt+=algorithm:histogram
lua << EOF
	function _G.get_warn_count()
		local warns = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.WARN })
		return #warns
	end

	function _G.get_error_count()
		local errors = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
		return #errors
	end

	if vim.g.neovide then
		local opts = { noremap = true, silent = true }
		vim.keymap.set({ 'i', 'n' }, '<D-a>', '<ESC>ggVG')    -- Select all

		vim.keymap.set('n', '<D-s>', '<cmd>w<CR>', opts)      -- Save
		vim.keymap.set('v', '<D-c>', '"+y', opts)             -- Copy
		vim.keymap.set('n', '<D-v>', 'i<C-r><C-o>+<ESC>l', opts) -- Paste
		vim.keymap.set('i', '<D-v>', '<C-r><C-o>+', opts)     -- Paste insert mode
		vim.keymap.set('x', '<D-v>', '"+P', opts)             -- Paste
		vim.keymap.set({ 'c', 't' }, '<D-v>', '<C-r>+', opts) -- Paste command mode
		vim.keymap.set('v', '<D-x>', '"+x', opts)             -- Cut

		-- Tab navigation
		vim.keymap.set('n', '<D-t>', '<cmd>tabnew<CR>', opts)                        -- New tab
		vim.keymap.set('i', '<D-t>', '<C-o><cmd>tabnew<CR><ESC>')
		vim.keymap.set('n', '<D-w>', '<cmd>q<CR>', opts)                             -- Close tab
		vim.keymap.set({ 'i', 'n' }, '<D-]>', '<cmd>tabn<cr>', opts) -- next tab
		vim.keymap.set({ 'i', 'n' }, '<D-[>', '<cmd>tabp<cr>', opts) -- previous tab

		for i = 1, 9 do
			vim.keymap.set('n', '<D-' .. i .. '>', i .. 'gt', opts)                  -- Go to tab i
		end

		-- toggle blur
		vim.keymap.set('n', '<D-b>', function() vim.g.neovide_window_blurred = not vim.g.neovide_window_blurred end, opts)
	end

	function LspAttach()
		vim.diagnostic.config { signs = false }
		vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
			vim.lsp.handlers.hover,
			{ border = "single", title = "hover" }
		)
		vim.api.nvim_create_user_command("Implementation", function()
			vim.lsp.buf.implementation()
		end, { force = true })
		local bufopts = { silent = true, buffer = true }
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
		vim.keymap.set("n", "K", function()
			local winid = require 'ufo'.peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, bufopts)
		-- vim.keymap.set("n", "<C-j>", vim.diagnostic.goto_next, bufopts) -- Now default mapping is `]d`
		-- vim.keymap.set("n", "<C-k>", vim.diagnostic.goto_prev, bufopts) -- Now default mapping is `[d`
		vim.keymap.set("n", "glr", vim.lsp.buf.code_action, bufopts)
		vim.keymap.set("n", "gln", vim.lsp.buf.rename, bufopts)
		vim.keymap.set("n", "z*", vim.lsp.buf.references, bufopts)
		vim.keymap.set("i", "<C-S>", vim.lsp.buf.signature_help, bufopts)
		vim.keymap.set("n", "gqae", function()
				local view = vim.fn.winsaveview()
				vim.lsp.buf.format { async = false }
				if view then vim.fn.winrestview(view) end
			end,
			{ buffer = true }
		)
		-- refresh codelens on TextChanged and InsertLeave as well
		-- vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave', 'CursorHold', 'LspAttach' }, {
		-- 	buffer = 0,
		-- 	callback = vim.lsp.codelens.refresh,
		-- })

		-- trigger codelens refresh
		-- vim.api.nvim_exec_autocmds('User', { pattern = 'LspAttached' })
		-- vim.api.nvim_create_autocmd('BufWritePre', {
		-- 	callback = function() vim.lsp.buf.format { async = false } end,
		-- 	buffer = bufnr,
		-- })
	end

	vim.api.nvim_create_autocmd("LspAttach", { callback = LspAttach })

	-- Ignore startup treesitter errors
	vim.treesitter.start = (function(wrapped)
		return function(bufnr, lang)
			lang = lang or vim.fn.getbufvar(bufnr or '', '&filetype')
			pcall(wrapped, bufnr, lang)
		end
	end)(vim.treesitter.start)

	function SetupAuthkey(path, opts)
		opts = opts or {}
		path = vim.fn.expand(path, nil, nil)
		local key
		if vim.fn.filereadable(path) == 1 then
			key = vim.fn.trim(vim.fn.readfile(path, nil, 1)[1])
		else
			key = vim.fn.input(opts.prompt or 'Input api key: ')
			if key == '' then return nil end
			vim.fn.writefile({ key }, path)
			vim.fn.system({ 'chmod', '600', path })
			vim.notify(string.format(
					'Successfully saved the API key at `%s`.', path),
				vim.log.levels.INFO, {
					title = 'gpt.nvim'
				})
		end
		return key
	end
EOF
se stl=%f%r%m%h%w%=%{&et?'(et)':''}sw=%{&sw}\ E%{v:lua.get_error_count()}W%{v:lua.get_warn_count()}\ %l/%L

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

se ut=1
au CursorHold * ++once se ut=4000

let g:loaded_netrwPlugin = v:true
let g:loaded_remote_plugins = v:true
let g:skip_loading_mswin = v:true
let g:loaded_tutor_mode_plugin = v:true
let g:loaded_2html_plugin = v:true

let s:dein = $"{stdpath('cache')}/dein"
let s:dein_plugin = $"{s:dein}/repos/github.com/Shougo/dein.vim"
if !(s:dein_plugin->isdirectory())
	exe '!git clone https://github.com/Shougo/dein.vim' s:dein_plugin
endi
exe $"se rtp^={s:dein_plugin}"

if dein#min#load_state(s:dein)
	cal dein#begin(s:dein)
	let s:toml = $"{stdpath('config')}/dein"
	cal dein#load_toml($'{s:toml}/plugin.toml', #{lazy:0})
	" cal dein#load_toml($'{s:toml}/dap.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/common.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/game.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/treesitter.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/lsp-core.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/lsp.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/cmp.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/tweaks.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/ft.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/fern.toml', #{lazy:1})
	cal dein#load_toml($'{s:toml}/ui.toml', #{lazy:1})
	cal dein#end()
	let g:dein#auto_recache = v:true
	cal dein#save_state()
endi

if dein#check_install()
	cal dein#install()
	cal dein#deno_cache()
endi

au BufEnter *.er setl ft=erg
colo onedark

com Dap cal dein#source([
				\ "nvim-dap",
				\ "nvim-dap-ui",
				\ "nvim-dap-virtual-text",
				\ "cmp-dap",
				\ "nvim-dap-python",
				\ "nvim-dap-go",
				\])

if executable('rg')
	set grepprg=rg\ --vimgrep
	set grepformat=%f:%l:%c:%m
endif

if executable('mise')
	lua vim.env.PATH = vim.env.HOME .. "/.local/share/mise/shims:" .. vim.env.PATH
endif

autocmd BufRead *.typ setfiletype typst
