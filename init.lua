--[[
-- 依存: NVim nightly, Git, Deno
-- siliconコマンドがあれば対応。
-- ]]

-- Emacs Keybindings
vim.keymap.set('i', '<c-f>', '<c-g>U<right>', {})
vim.keymap.set('i', '<c-b>', '<c-g>U<left>', {})
vim.keymap.set('i', '<c-p>', '<c-g>U<up>', {})
vim.keymap.set('i', '<c-n>', '<c-g>U<down>', {})
vim.keymap.set('i', '<c-d>', '<c-g>U<del>', {})
vim.cmd [[ inoremap <expr> <c-a> col('.') == match(getline('.'), '\S') + 1 ?
         \ repeat('<C-G>U<Left>', col('.') - 1) :
		 \ (col('.') < match(getline('.'), '\S') ?
         \     repeat('<C-G>U<Right>', match(getline('.'), '\S') + 0) :
         \     repeat('<C-G>U<Left>', col('.') - 1 - match(getline('.'), '\S')))]]
vim.cmd [[ inoremap <expr> <c-e> repeat('<C-G>U<Right>', col('$') - col('.')) ]]
vim.keymap.set('c', '<c-f>', '<right>', {})
vim.keymap.set('c', '<c-b>', '<left>', {})
vim.keymap.set('c', '<c-p>', '<up>', {})
vim.keymap.set('c', '<c-n>', '<down>', {})
vim.keymap.set('c', '<c-d>', '<del>', {})
vim.keymap.set('c', '<c-a>', '<home>', {})
vim.keymap.set('c', '<c-e>', '<end>', {})

function _G.lsp_onattach_func(_, bufnr)
	vim.api.nvim_create_user_command('Implementation', function() vim.lsp.buf.implementation() end, { force = true })
	local bufopts = { silent = true, buffer = bufnr }
	vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
	vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
	vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
	vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
	vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, bufopts)
	vim.keymap.set('n', '<leader>n', vim.lsp.buf.rename, bufopts)
	vim.keymap.set('n', '<leader>r', function() vim.lsp.buf.references({}, nil) end, bufopts)
end

-- Configure
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.wo.number = true
vim.o.imdisable = true
vim.wo.winblend = 20
vim.o.pumblend = vim.wo.winblend
vim.wo.cursorline = true
vim.wo.cursorcolumn = true
vim.o.shellslash = true
vim.o.splitbelow = true
vim.o.hidden = true
vim.o.laststatus = 3
vim.api.nvim_set_var('tex_conceal', '')
vim.api.nvim_set_var('netrw_banner', 0)
vim.api.nvim_set_var('netrw_liststyle', 3)
vim.diagnostic.config { virtual_text = false }

-- Neovide
vim.opt.guifont = { 'HackGenNerd Console', 'h13' }
if vim.g.neovide then
	vim.api.nvim_set_var('neovide_remember_window_size', false)
end

-- Mac Keybindings
vim.keymap.set('i', '<D-v>', '<esc>"+pa', {})
vim.keymap.set('n', '<D-v>', '"+p', {})
vim.keymap.set('v', '<D-c>', '"+y', {})
vim.keymap.set('n', '<D-t>', '<cmd>tabe<cr>', {})
vim.keymap.set('n', '<D-w>', '<cmd>q<cr>', {})
for i = 1, 10, 1 do
	local from = '<D-' .. i .. '>'
	local to = '<cmd>tabn ' .. i .. '<cr>'
	vim.keymap.set('n', from, to, {})
end

-- ripgrep
if vim.fn.executable('rg') then
	vim.api.nvim_set_option_value('grepprg', 'rg --vimgrep --hidden', {})
	vim.api.nvim_set_option_value('grepformat', '%f:%l:%c:%m', {})
end

local load_event = 'ColorScheme'

-- default plugins
local function lazy_default_plugs(name)
	vim.api.nvim_set_var('loaded_' .. name, true)
	vim.api.nvim_create_autocmd(load_event, {
		once = true,
		callback = function()
			vim.api.nvim_set_var('loaded_' .. name, false)
			vim.cmd('packadd ' .. name)
		end
	})
end

lazy_default_plugs 'matchit'
lazy_default_plugs 'matchparen'
vim.api.nvim_set_var('loaded_remote_plugins', true)
vim.api.nvim_set_var('skip_loading_mswin', true)
vim.api.nvim_set_var('loaded_tutor_mode_plugin', true)
vim.api.nvim_set_var('loaded_2html_plugin', true)

-- Jetpack
local fn = vim.fn
local jetpackfile = fn.stdpath('data') .. '/site/pack/jetpack/opt/vim-jetpack/plugin/jetpack.vim'
local jetpackurl = 'https://raw.githubusercontent.com/uga-rosa/vim-jetpack/refactor/plugin/jetpack.vim'
if fn.filereadable(jetpackfile) == 0 then
	fn.system('curl -fsSLo ' .. jetpackfile .. ' --create-dirs ' .. jetpackurl)
end
vim.cmd 'packadd vim-jetpack'
require 'jetpack.packer'.startup(function(use)
	use { 'tani/vim-jetpack', opt = 1 }
	use 'vim-denops/denops.vim'
	use 'nvim-lua/plenary.nvim'
	use { 'eandrju/cellular-automaton.nvim', cmd = { 'CellularAutomaton' } }

	-- 言語別プラグイン
	use {
		'akinsho/flutter-tools.nvim',
		ft = { 'dart' },
		config = function()
			require 'flutter-tools'.setup {
				lsp = {
					on_attach = _G.lsp_onattach_func,
				}
			}
		end,
	}

	vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
		pattern = { '*.saty', '*.satyh', '*satyh-*', '*.satyg' },
		command = 'setlocal filetype=satysfi'
	})
	use {
		'qnighy/satysfi.vim',
		ft = { 'satysfi' },
	}

	use {
		'tranvansang/octave.vim',
		ft = { 'matlab', 'octave' },
	}

	-- LSP
	use { 'folke/neodev.nvim', opt = 1 }
	use { 'williamboman/mason-lspconfig.nvim', opt = 1 }
	use { 'hrsh7th/cmp-nvim-lsp', opt = 1 }
	use { 'neovim/nvim-lspconfig', opt = 1 }
	use {
		'williamboman/mason.nvim', -- LSP Installer
		event = { load_event },
		config = function()
			require 'mason'.setup {}
			vim.fn['jetpack#load']('mason-lspconfig.nvim')
			local mason_lspconfig = require('mason-lspconfig')
			vim.fn['jetpack#load']('lspkind.nvim')
			vim.fn['jetpack#load']('nvim-cmp')
			vim.fn['jetpack#load']('cmp-nvim-lsp')
			local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
			mason_lspconfig.setup_handlers { function(server_name)
				local opts = {
					capabilities = capabilities,
					on_attach = _G.lsp_onattach_func,
					settings = {
						Lua = {}
					}
				}
				if server_name == 'sumneko_lua' then
					vim.fn['jetpack#load']('nvim-lspconfig')
					vim.fn['jetpack#load']('neodev.nvim')
					opts.settings.Lua = {
						workspace = {
							checkThirdParty = false,
						},
					}
					require 'neodev'.setup {
						override = function(_, library)
							library.enabled = true
							library.plugins = true
						end,
					}
				end
				vim.cmd 'packadd nvim-lspconfig'
				require 'lspconfig'[server_name].setup(opts)
			end }
			vim.cmd 'LspStart'
		end,
	}
	use {
		'jose-elias-alvarez/null-ls.nvim',
		event = { load_event },
		config = function()
			vim.fn['jetpack#load']('mason.nvim')
			local mason = require 'mason'
			local mason_package = require 'mason-core.package'
			local mason_registry = require 'mason-registry'
			local null_ls = require 'null-ls'
			mason.setup {}
			local null_sources = {}
			for _, package in ipairs(mason_registry.get_installed_packages()) do
				local package_categories = package.spec.categories[1]
				if package_categories == mason_package.Cat.Formatter then
					table.insert(null_sources, null_ls.builtins.formatting[package.name])
				elseif package_categories == mason_package.Cat.Linter then
					table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
				end
			end
			null_ls.setup {
				sources = null_sources,
				on_attach = _G.lsp_onattach_func,
			}
		end
	}
	use {
		'onsails/diaglist.nvim', -- Diagnosticの自動更新Quickfixリスト
		event = { 'LspAttach' },
		config = function()
			vim.api.nvim_create_user_command('Diaglist', function() require 'diaglist.quickfix'.populate_qflist() end,
				{ force = true })
			require 'diaglist'.init()
			require 'diaglist.quickfix'.populate_qflist()
		end
	}
	use {
		'j-hui/fidget.nvim', -- LSPのステータスを右下に表示
		event = { 'LspAttach' },
		config = function()
			vim.api.nvim_create_autocmd('VimLeavePre', { command = 'silent! FidgetClose' })
			require 'fidget'.setup()
		end
	}
	use {
		'ray-x/lsp_signature.nvim', -- 関数の引数の入力時のシグネチャヘルプ
		event = { 'LspAttach' },
		config = function()
			require 'lsp_signature'.setup {}
		end,
	}
	use {
		'numToStr/Comment.nvim', -- コメントのトグル
		event = { 'LspAttach' },
		config = function()
			require 'Comment'.setup {}
		end
	}

	-- Debug Adapter Protocol
	local function load_dap_plugins()
		vim.fn['jetpack#load']('lspkind.nvim')
		vim.fn['jetpack#load']('nvim-cmp')
		vim.fn['jetpack#load']('nvim-dap-ui')
	end

	use { 'mfussenegger/nvim-dap', opt = 1 }
	use {
		'theHamsta/nvim-dap-virtual-text',
		opt = 1,
		config = function()
			require 'nvim-dap-virtual-text'.setup {
				enabled_commands = false,
			}
		end
	}
	use {
		'rcarriga/cmp-dap',
		opt = 1,
		config = function()
			require 'cmp'.setup {
				enabled = function()
					return vim.api.nvim_buf_get_option(0, 'buftype') ~= 'prompt'
						or require 'cmp_dap'.is_dap_buffer()
				end
			}
			require 'cmp'.setup.filetype({ 'dap-repl', 'dapui_watches' }, {
				sources = {
					{ name = 'dap' },
				},
			})
		end
	}
	use {
		'rcarriga/nvim-dap-ui',
		opt = 1,
		config = function()
			vim.fn['jetpack#load']('nvim-dap')
			vim.fn['jetpack#load']('nvim-dap-virtual-text')
			vim.fn['jetpack#load']('cmp-dap')
			require 'dapui'.setup()

			-- codelldbの設定
			vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
				pattern = { '*.rs', '*.c', '*.cpp' },
				callback = function()
					local mason_dap_package = 'codelldb'

					if not require 'mason-registry'.is_installed(mason_dap_package) then
						vim.cmd('MasonInstall ' .. mason_dap_package)
					end
				end
			})
			require 'dap'.adapters.lldb = {
				type = 'server',
				port = '13000',
				executable = {
					command = vim.fn.stdpath 'data' .. '/mason/packages/codelldb/extension/adapter/codelldb',
					args = { '--port', '13000' },
					detached = false,
				}
			}

			-- dap-uiの自動起動・終了
			require 'dap'.listeners.before['event_initialized']['custom'] = function() require 'dapui'.open {} end
			require 'dap'.listeners.before['event_terminated']['custom'] = function() require 'dapui'.close {} end

			vim.keymap.set('n', '<F5>', function() require 'dap'.continue() end, {})
			vim.keymap.set('n', '<F10>', function() require 'dap'.step_over() end, {})
			vim.keymap.set('n', '<F11>', function() require 'dap'.step_into() end, {})
			vim.keymap.set('n', '<F12>', function() require 'dap'.step_out() end, {})
			vim.keymap.set('n', 'bb', function() require 'dap'.toggle_breakpoint() end, {})
		end
	}
	use {
		'leoluz/nvim-dap-go',
		ft = { 'go' },
		config = function()
			load_dap_plugins()
			vim.fn['jetpack#load']('mason.nvim')
			local mason_dap_package = 'delve'
			local init_func = require 'dap-go'.setup
			if not require 'mason-registry'.is_installed(mason_dap_package) then
				vim.cmd('MasonInstall ' .. mason_dap_package)
			end
			-- delveがインストール済み、又はインストールに成功した場合にdap-goを設定する
			if require 'mason-registry'.is_installed(mason_dap_package) then
				init_func()
			end
		end,
	}
	use {
		'gw31415/nvim-dap-rust',
		ft = { 'rust' },
		config = function()
			load_dap_plugins()
			vim.fn['jetpack#load']('mason.nvim')
			local mason_dap_package = 'codelldb'
			local init_func = require 'dap-rust'.setup
			if not require 'mason-registry'.is_installed(mason_dap_package) then
				vim.cmd('MasonInstall ' .. mason_dap_package)
			end
			-- delveがインストール済み、又はインストールに成功した場合にdap-goを設定する
			if require 'mason-registry'.is_installed(mason_dap_package) then
				init_func()
			end
		end,
	}
	use {
		'mfussenegger/nvim-dap-python',
		ft = { 'python' },
		config = function()
			vim.fn['jetpack#load']('mason.nvim')
			local mason_dap_package = 'delve'
			local init_func = function()
				require 'dap-python'.setup(vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python')
			end
			if not require 'mason-registry'.is_installed(mason_dap_package) then
				vim.cmd('MasonInstall ' .. mason_dap_package)
			end
			if require 'mason-registry'.is_installed(mason_dap_package) then
				init_func()
			end
		end
	}

	-- 補完
	use { 'hrsh7th/vim-vsnip', event = { 'InsertCharPre' } }
	vim.api.nvim_create_autocmd('InsertCharPre', {
		once = true,
		callback = function()
			vim.fn['jetpack#load']('lspkind.nvim')
			vim.fn['jetpack#load']('nvim-cmp')
			vim.fn['jetpack#load']('cmp-nvim-lsp-signature-help')
			vim.fn['jetpack#load']('cmp-path')
			vim.fn['jetpack#load']('cmp-omni')
			vim.fn['jetpack#load']('cmp-buffer')
			vim.fn['jetpack#load']('cmp-skkeleton')
		end,
	})
	vim.api.nvim_create_autocmd('CmdlineEnter', {
		once = true,
		callback = function()
			vim.fn['jetpack#load']('lspkind.nvim')
			vim.fn['jetpack#load']('nvim-cmp')
			vim.fn['jetpack#load']('cmp-cmdline')
			vim.fn['jetpack#load']('cmp-buffer')
		end,
	})
	use { 'hrsh7th/cmp-vsnip', opt = 1 }
	use { 'hrsh7th/cmp-nvim-lsp-signature-help', opt = 1 }
	use { 'hrsh7th/cmp-cmdline', opt = 1 }
	use { 'hrsh7th/cmp-path', opt = 1 }
	use { 'hrsh7th/cmp-omni', opt = 1 }
	use { 'hrsh7th/cmp-buffer', opt = 1 }
	use { 'uga-rosa/cmp-skkeleton', opt = 1 }
	use { 'onsails/lspkind.nvim', opt = 1 }
	use {
		'hrsh7th/nvim-cmp',
		opt = 1,
		config = function()
			local cmp = require 'cmp'
			local function feedkeys(keys)
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes(keys, true, true, true) or '',
					'',
					true
				)
			end

			cmp.setup {
				snippet = {
					expand = function(args)
						vim.fn['vsnip#anonymous'](args.body)
					end,
				},
				sources = cmp.config.sources {
					{ name = 'nvim_lsp' },
					{ name = 'vsnip' },
					{ name = 'buffer' },
					{ name = 'nvim_lsp_signature_help' },
					{ name = 'skkeleton' },
					{ name = 'path' },
				},
				formatting = {
					format = require 'lspkind'.cmp_format {
						mode = 'symbol_text',
					}
				},
				mapping = {
					['<c-n>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<c-p>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-e>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.abort()
						else
							fallback()
						end
					end),
					['<tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							local entry = cmp.get_selected_entry()
							if not entry then
								cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
							else
								cmp.confirm()
							end
						elseif vim.fn['vsnip#jumpable'](1) == 1 then
							feedkeys '<Plug>(vsnip-jump-next)'
						else
							fallback()
						end
					end, { 'i', 's', 'c', }),
					['<s-tab>'] = cmp.mapping(function(fallback)
						if vim.fn['vsnip#jumpable'](-1) == 1 then
							feedkeys '<Plug>(vsnip-jump-prev)'
						else
							fallback()
						end
					end, { 'i', 's', 'c', }),
				}
			}
			cmp.setup.filetype('octave', {
				sources = cmp.config.sources {
					{ name = 'omni' },
				}
			})
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources {
					{ name = 'cmdline' },
				}
			})
			for _, c in pairs { '/', '?' } do
				cmp.setup.cmdline(c, {
					mapping = cmp.mapping.preset.cmdline(),
					sources = cmp.config.sources {
						{ name = 'buffer' },
					}
				})
			end
		end
	}

	-- UI
	use {
		'kevinhwang91/nvim-bqf', -- quickfixのハイジャック
		event = { load_event },
	}
	use {
		'rcarriga/nvim-notify', -- vim.notifyのハイジャック
		event = { load_event },
		config = function() vim.notify = require 'notify' end
	}
	use {
		'gw31415/fzyselect.vim', -- vim.ui.select
		event = { load_event },
		config = function()
			vim.api.nvim_create_autocmd('FileType', {
				pattern = 'fzyselect',
				callback = function()
					vim.keymap.set('n', 'i', '<Plug>(fzyselect-fzy)', { buffer = true })
					vim.keymap.set('n', '<cr>', '<Plug>(fzyselect-retu)', { buffer = true })
					vim.keymap.set('n', '<esc>', '<cmd>clo<cr>', { buffer = true })
				end
			})
			-- Line Selector
			vim.cmd "nn gl <cmd>cal fzyselect#start(getline(1, '$'), #{prompt:'Fuzzy search'}, {_,i->i==v:null?v:null:cursor(i, 0)})<cr>"
			-- git ls-files
			vim.cmd [[
					fu! s:edit(path) abort
						if a:path != v:null
							exe 'e ' .. a:path
						en
					endfu
					nn <c-p> <cmd>cal fzyselect#start(split(system(['git', 'ls-files']), '\n'), #{prompt:'git ls-files'}, {p-><SID>edit(p)})<cr>
				]]

			-- Buffer Selector
			vim.cmd [[
				fu! s:buffer(i) abort
					if a:i != v:null
						exe 'b ' .. a:i
					en
				endfu
				nn B <cmd>cal fzyselect#start(
							\ filter(range(1, bufnr('$')), 'buflisted(v:val)'),
							\ #{prompt:'Select buffer',format_item:{i->split(execute('ls!'), "\n")[i-1]}},
							\ {li-><SID>buffer(li)})<cr>
			]]
			vim.ui.select = require 'fzyselect'.start
		end
	}
	use {
		'nvim-treesitter/nvim-treesitter', -- Treesitter
		event = { load_event },
		config = function()
			local parser_install_dir = vim.fn.stdpath 'data' .. '/treesitter'
			vim.opt.runtimepath:append(vim.fn.stdpath 'data' .. '/treesitter')
			require 'nvim-treesitter.configs'.setup {
				highlight = {
					parser_install_dir = parser_install_dir,
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				auto_install = true,
			}
			vim.fn['jetpack#load']('treesitter-unit')
			vim.wo.foldmethod = 'expr'
			vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
			vim.wo.foldenable = false
			vim.wo.foldlevel = 999
		end
	}
	use {
		'David-Kunz/treesitter-unit',
		opt = true,
		config = function()
			local opts = { noremap = true, silent = true }
			vim.api.nvim_set_keymap('x', 'iu', ':lua require"treesitter-unit".select(false)<CR>', opts)
			vim.api.nvim_set_keymap('x', 'au', ':lua require"treesitter-unit".select(true)<CR>', opts)
			vim.api.nvim_set_keymap('o', 'iu', ':<c-u>lua require"treesitter-unit".select(false)<CR>', opts)
			vim.api.nvim_set_keymap('o', 'au', ':<c-u>lua require"treesitter-unit".select(true)<CR>', opts)
		end
	}
	use {
		'lukas-reineke/indent-blankline.nvim', -- インデントの可視化
		event = { load_event },
		config = function()
			vim.opt.list = true
			require 'indent_blankline'.setup {
				space_char_blankline = ' ',
				show_current_context = true,
				show_current_context_start = true,
			}
		end,
	}
	use {
		'bronson/vim-trailing-whitespace', -- 余計な空白を赤くする
		event = { load_event },
	}
	use {
		'uga-rosa/ccc.nvim',
		cmd = {
			'CccPick',
			'CccConvert',
			'CccHighlighterEnable',
			'CccHighlighterDisable',
			'CccHighlighterToggle',
		},
		config = function()
			require 'ccc'.setup {
				bar_char = '-',
				point_char = '+',
				highlighter = {
					auto_enable = true,
					filetypes = { 'css', 'sass', 'scss', 'js', 'html', 'json' },
					events = { 'WinScrolled', 'TextChanged', 'TextChangedI', 'BufEnter' },
					lsp = true,
				},
			}
		end
	}

	-- 小機能追加
	use {
		'rbtnn/vim-ambiwidth', -- 曖昧幅な文字の文字幅設定
		event = { load_event },
	}
	use { 'cohama/lexima.vim', event = { load_event } } -- 自動括弧閉じ
	use {
		'kylechui/nvim-surround', -- operator 囲い文字
		tag = 'v1.0.0',
		event = { load_event },
		config = function()
			require 'nvim-surround'.setup {}
		end
	}
	use { 'kana/vim-textobj-user', opts = 1 } -- カスタムtextobj 依存プラグイン
	use {
		'glts/vim-textobj-comment', -- コメントに対する textobj
		event = { load_event },
		config = function()
			vim.fn['jetpack#load']('vim-textobj-user')
		end
	}
	use {
		'kana/vim-textobj-entire', -- バッファ全体に対する textobj
		event = { load_event },
		config = function()
			vim.fn['jetpack#load']('vim-textobj-user')
		end
	}
	use {
		'gbprod/substitute.nvim', -- vim-operator-replace
		event = { load_event },
		config = function()
			require 'substitute'.setup {}
			vim.keymap.set("n", "_", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })
			vim.keymap.set("n", "__", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
			vim.keymap.set("x", "_", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })
		end
	}
	if vim.fn.executable 'silicon' then
		use {
			'segeljakt/vim-silicon', -- ソースコードを画像化するsiliconコマンドのラッパー
			cmd = 'Silicon',
			config = function()
				vim.api.nvim_set_var('silicon', {
					font = 'HackGenNerd Console',
				})
			end
		}
	end
	use {
		'lambdalisue/gin.vim', -- Git連携
		config = function()
			if vim.fn.executable 'delta' then
				vim.api.nvim_set_var('gin_diff_default_args', { '++processor=delta' })
			end
		end
	}
	use {
		'lewis6991/gitsigns.nvim', -- Gitの行毎ステータス
		event = { load_event },
		config = function() require 'gitsigns'.setup() end
	}
	use {
		'phaazon/hop.nvim', -- 画面内ジャンプ
		event = { load_event },
		config = function()
			require 'hop'.setup {}
			vim.keymap.set('n', '<space>', function() require 'hop'.hint_words { multi_windows = true } end, {})
		end,
	}
	use {
		'mbbill/undotree',
		cmd = {
			'UndotreeShow',
			'UndotreeHide',
			'UndotreeFocus',
			'UndotreeToggle',
		}
	}
	vim.api.nvim_set_var('winresizer_start_key', '<C-W>c')
	use {
		'simeji/winresizer', -- ウィンドウサイズ変更
		event = { load_event },
	}
	use {
		'navarasu/onedark.nvim', -- テーマ
		event = { 'VimEnter' },
		config = function()
			require 'onedark'.setup {
				style = 'darker',
				code_style = {
					comments = 'none',
					functions = 'bold',
					keywords = 'none',
				},
				highlights = { MatchParen = { fg = '$red', bg = '$bg_yellow' } },
			}
			require 'onedark'.load()
		end,
	}
	use { 'gw31415/deepl.vim', opt = 1 }
	use {
		'gw31415/deepl-commands.nvim', -- deeplとの連携
		event = { 'CmdlineEnter' },
		config = function()
			vim.cmd 'packadd deepl.vim'
			require 'deepl-commands'.setup {
				selector_func = require 'fzyselect'.start
			}
		end
	}
	use 'vim-jp/vimdoc-ja' -- 日本語のヘルプ
	use 'gw31415/skkeletal.vim'
	use {
		'vim-skk/skkeleton', -- 日本語入力
		config = function()
			-- StatusLine
			function _G.get_warn_count()
				local warns = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
				return #warns
			end

			function _G.get_error_count()
				local errors = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
				return #errors
			end

			function _G.get_skkeleton_modestring()
				local mode = vim.fn['skkeleton#mode']()
				if mode == 'hira' then
					return 'ひら'
				elseif mode == 'kata' then
					return 'カタ'
				elseif mode == 'hankata' then
					return '半ｶﾀ'
				elseif mode == 'zenkaku' then
					return '全英'
				elseif mode == 'abbrev' then
					return 'Abbr'
				else -- if mode == ''
					return '英数'
				end
			end

			vim.cmd [[set statusline=[%{v:lua.get_skkeleton_modestring()}]%f%r%m%h%w%=E%{v:lua.get_error_count()}W%{v:lua.get_warn_count()}\ %l/%L]]

			vim.keymap.set('i', '<C-j>', '<Plug>(skkeleton-enable)', {})
			vim.keymap.set('c', '<C-j>', '<Plug>(skkeleton-enable)', {})
			vim.fn['skkeletal#config'] {
				eggLikeNewline = true,
				globalJisyo = '~/.skk/SKK-JISYO.L',
				markerHenkan = '▹',
				markerHenkanSelect = '▸',
				dvorak = true,
			}

			for _, map in pairs {
				{ 'input', '<c-e>', '' },
				{ 'henkan', '<c-e>', '' },
				{ 'input', '<c-n>', 'henkanFirst' },
				{ 'henkan', '<c-n>', 'henkanForward' },
				{ 'henkan', '<c-p>', 'henkanBackward' },
				{ 'henkan', '<bs>', 'henkanBackward' },
				{ 'henkan', '<c-h>', '' },
				{ 'henkan', '<c-h>', 'henkanBackward' },
			} do
				vim.fn['skkeleton#register_keymap'](map[1], map[2], map[3])
			end
		end,
	}
end)

-- インストールされていないプラグインがあった時の自動Sync
pcall(function()
	for _, name in ipairs(fn['jetpack#names']()) do
		if not fn['jetpack#tap'](name) then
			pcall(vim.fn['jetpack#sync'])
			break
		end
	end
end)
