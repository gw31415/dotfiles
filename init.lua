--[[
-- 依存: NVim nightly, Git, Deno
-- siliconコマンドがあれば対応。
-- ]]
pcall(function() require 'impatient' end)

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
	vim.keymap.set('n', 'gqq', function() vim.lsp.buf.format { async = true } end, bufopts)
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

-- Packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'
local packer_bootstrap = '' -- Packerのインストールがない場合は空文字列
if vim.fn.empty(vim.fn.glob(install_path, false, vim.NIL, false)) > 0 then
	packer_bootstrap = vim.fn.system { 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim',
		install_path }
	vim.cmd 'packadd packer.nvim'
end
require 'packer'.startup {
	function(use)
		-- プラグイン管理
		use 'wbthomason/packer.nvim'
		use 'lewis6991/impatient.nvim'

		-- 言語別プラグイン
		use {
			'akinsho/flutter-tools.nvim',
			requires = 'nvim-lua/plenary.nvim',
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
		use {
			'williamboman/mason.nvim', { -- LSP Installer
				'neovim/nvim-lspconfig',
				requires = {
					'folke/neodev.nvim',
					'williamboman/mason-lspconfig.nvim',
					'hrsh7th/cmp-nvim-lsp',
				},
				config = function()
					require 'mason'.setup {}
					local mason_lspconfig = require('mason-lspconfig')
					local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
					mason_lspconfig.setup_handlers { function(server_name)
						local opts = {
							capabilities = capabilities,
							on_attach = _G.lsp_onattach_func,
						}
						if server_name == 'sumneko_lua' then
							require 'neodev'.setup {
								override = function(_, library)
									library.enabled = true
									library.plugins = true
								end,
							}
							local lspconfig = require 'lspconfig'
							lspconfig[server_name].setup(opts)
						else
							local lspconfig = require 'lspconfig'
							lspconfig[server_name].setup(opts)
						end
					end }
				end,
			}
		}
		use {
			'jose-elias-alvarez/null-ls.nvim',
			requires = { 'williamboman/mason.nvim' },
			config = function()
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
					end
					if package_categories == mason_package.Cat.Linter then
						table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
					end
				end
				null_ls.setup { sources = null_sources }
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
		use {
			'rcarriga/nvim-dap-ui',
			requires = { 'mfussenegger/nvim-dap' },
			config = function()
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
				vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
					pattern = { '*.rs' },
					callback = function()
						local metadata = vim.fn.json_decode(
							vim.fn.system({ 'cargo', 'metadata', '--format-version=1', '--no-deps' })
						) or {}
						local workspace = metadata.workspace_root
						local target_dir = metadata.target_directory
						local root_pkg = metadata.packages[1]

						local dap_config = {}
						---配列に値が含まれるかどうかを調べます。
						---@param arr table
						---@param val any
						---@return boolean
						local function has(arr, val)
							for _, value in pairs(arr) do
								if value == val then
									return true
								end
							end
							return false
						end

						for _, crate in pairs(root_pkg.targets) do
							if has(crate.kind, 'bin') then
								table.insert(dap_config,
									{
										type = 'lldb',
										request = 'launch',
										name = "Debug executable '" .. crate.name .. "'",
										cargo = {
											args = {
												'build',
												'--package=' .. root_pkg.name,
												'--bin=' .. crate.name,
											},
											filter = {
												name = crate.name,
												kind = 'bin'
											}
										},
										program = target_dir .. '/debug/' .. crate.name,
										args = {},
										cwd = workspace
									})
								table.insert(dap_config,
									{
										type = 'lldb',
										request = 'launch',
										name = "Debug unit tests in executable '" .. crate.name .. "'",
										program = function()
											---指定したreasonの出力をtableの配列で取りだす
											---@param arr string[]
											---@param reason_name string
											---@return table[]
											local function expand_reason(arr, reason_name)
												local out = {}
												for _, js_txt in pairs(arr) do
													local js = vim.fn.json_decode(js_txt) or {}
													if js.reason == reason_name then
														table.insert(out, js)
													end
												end
												return out
											end

											local output_lines = vim.fn.split(vim.fn.system {
												'cargo',
												'test',
												'-q',
												'--package=' .. root_pkg.name,
												'--bin=' .. crate.name,
												'--no-run',
												'--message-format=json'
											}, '\n')
											local exe_datas = expand_reason(output_lines, 'compiler-artifact') or {}
											exe_datas = vim.fn.filter(exe_datas, function(_, val)
												return val.executable ~= vim.NIL
											end)
											if #exe_datas == 1 then
												return exe_datas[1].executable
											else
												return coroutine.create(function(dap_run_co)
													vim.ui.select(exe_datas, {
														prompt = 'Select executables:',
														format_item = function(exe_data)
															return exe_data.executable
														end
													}, function(exe_data)
														coroutine.resume(dap_run_co, exe_data.executable)
													end)
												end)
											end
										end,
										args = function()
											local tests = vim.fn.split(vim.fn.system {
												'cargo',
												'test',
												'-q',
												'--package=' .. root_pkg.name,
												'--bin=' .. crate.name,
												'--',
												'--list',
												'--format=terse'
											}, '\n')
											local run_all = 'Run All tests'
											table.insert(tests, run_all)
											return coroutine.create(function(dap_run_co)
												vim.ui.select(tests, {
													prompt = 'Select test:',
												}, function(terse)
													local test = vim.fn.split(terse)[1]
													if terse == run_all then
														coroutine.resume(dap_run_co, {})
													else
														coroutine.resume(dap_run_co, { test:sub(1, -2) })
													end
												end)
											end)
										end,
										cwd = workspace
									})
							end
							if has(crate.kind, 'lib') then
								table.insert(dap_config,
									{
										type = 'lldb',
										request = 'launch',
										name = "Debug unit tests in library '" .. crate.name .. "'",
										program = function()
											---指定したreasonの出力をtableの配列で取りだす
											---@param arr string[]
											---@param reason_name string
											---@return table[]
											local function expand_reason(arr, reason_name)
												local out = {}
												for _, js_txt in pairs(arr) do
													local js = vim.fn.json_decode(js_txt) or {}
													if js.reason == reason_name then
														table.insert(out, js)
													end
												end
												return out
											end

											local output_lines = vim.fn.split(vim.fn.system {
												'cargo',
												'test',
												'-q',
												'--package=' .. root_pkg.name,
												'--lib',
												'--no-run',
												'--message-format=json'
											}, '\n')
											local exe_datas = expand_reason(output_lines, 'compiler-artifact') or {}
											exe_datas = vim.fn.filter(exe_datas, function(_, val)
												return val.executable ~= vim.NIL
											end)
											if #exe_datas == 1 then
												return exe_datas[1].executable
											else
												return coroutine.create(function(dap_run_co)
													vim.ui.select(exe_datas, {
														prompt = 'Select executables:',
														format_item = function(exe_data)
															return exe_data.executable
														end
													}, function(exe_data)
														coroutine.resume(dap_run_co, exe_data.executable)
													end)
												end)
											end
										end,
										args = function()
											local tests = vim.fn.split(vim.fn.system {
												'cargo',
												'test',
												'-q',
												'--package=' .. root_pkg.name,
												'--lib',
												'--',
												'--list',
												'--format=terse'
											}, '\n')
											local run_all = 'Run All tests'
											table.insert(tests, run_all)
											return coroutine.create(function(dap_run_co)
												vim.ui.select(tests, {
													prompt = 'Select test:',
												}, function(terse)
													local test = vim.fn.split(terse)[1]
													if terse == run_all then
														coroutine.resume(dap_run_co, {})
													else
														coroutine.resume(dap_run_co, { test:sub(1, -2) })
													end
												end)
											end)
										end,
										cwd = workspace
									})
							end
						end
						require 'dap'.configurations.rust = dap_config
					end
				})

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
			'theHamsta/nvim-dap-virtual-text',
			event = { 'LspAttach' },
			requires = { 'rcarriga/nvim-dap-ui' },
			config = function()
				require 'nvim-dap-virtual-text'.setup {
					enabled_commands = false,
				}
			end
		}
		use {
			'rcarriga/cmp-dap',
			event = { 'LspAttach' },
			requires = { 'rcarriga/nvim-dap-ui' },
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
			'leoluz/nvim-dap-go',
			requires = { 'mfussenegger/nvim-dap', 'williamboman/mason.nvim' },
			ft = { 'go' },
			config = function()
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
			'mfussenegger/nvim-dap-python',
			ft = { 'python' },
			config = function()
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
		use { 'hrsh7th/cmp-vsnip', event = { 'InsertEnter' } }
		use { 'hrsh7th/cmp-nvim-lsp-signature-help', event = { 'InsertEnter' } }
		use { 'hrsh7th/vim-vsnip', event = { 'InsertEnter' } }
		use { 'hrsh7th/cmp-cmdline', event = { 'CmdlineEnter' } }
		use { 'hrsh7th/cmp-path', event = { 'InsertEnter' } }
		use { 'hrsh7th/cmp-omni', event = { 'InsertEnter' } }
		use { 'hrsh7th/cmp-buffer', event = { 'InsertEnter', 'CmdlineEnter' } }
		use { 'uga-rosa/cmp-skkeleton', event = { 'InsertEnter' } }
		use {
			'hrsh7th/nvim-cmp',
			requires = { 'onsails/lspkind.nvim' },
			event = { 'InsertEnter', 'CmdlineEnter' },
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
		use 'kevinhwang91/nvim-bqf' -- quickfixのハイジャック
		use { 'rcarriga/nvim-notify', config = function() vim.notify = require 'notify' end } -- vim.notifyのハイジャック
		use {
			'gw31415/fzyselect.vim', -- vim.ui.select
			config = function()
				vim.api.nvim_create_autocmd('FileType', {
					pattern = 'fzyselect',
					callback = function()
						vim.keymap.set('n', 'i', '<Plug>(fzyselect-fzy)', { buffer = true })
						vim.keymap.set('n', '<cr>', '<Plug>(fzyselect-retu)', { buffer = true })
						vim.keymap.set('n', '<esc>', '<cmd>clo<cr>', { buffer = true })
					end
				})
				vim.ui.select = require 'fzyselect'.start
			end
		}
		use {
			'nvim-treesitter/nvim-treesitter', -- Treesitter
			config = function()
				require 'nvim-treesitter.configs'.setup {
					highlight = {
						enable = true,
						additional_vim_regex_highlighting = false,
					},
				}
			end
		}
		use {
			'lukas-reineke/indent-blankline.nvim', -- インデントの可視化
			config = function()
				vim.opt.list = true
				require 'indent_blankline'.setup {
					space_char_blankline = ' ',
					show_current_context = true,
					show_current_context_start = true,
				}
			end,
		}
		use 'bronson/vim-trailing-whitespace' -- 余計な空白を赤くする
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
		use 'rbtnn/vim-ambiwidth' -- 曖昧幅な文字の文字幅設定
		use {
			'kylechui/nvim-surround', -- 囲い文字向けの操作拡張
			tag = '*',
			config = function()
				require 'nvim-surround'.setup {}
			end
		}
		use { 'cohama/lexima.vim', event = { 'InsertEnter' } } -- 自動括弧閉じ
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
			'lambdalisue/gin.vim',
			requires = { 'vim-denops/denops.vim' },
			config = function()
				if vim.fn.executable 'delta' then
					vim.api.nvim_set_var('gin_diff_default_args', { '++processor=delta' })
				end
			end
		} -- Git連携
		use { 'lewis6991/gitsigns.nvim', config = function() require 'gitsigns'.setup() end } -- Gitの行毎ステータス
		use {
			'phaazon/hop.nvim', -- 画面内ジャンプ
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
		use {
			'simeji/winresizer', -- ウィンドウサイズ変更
			config = function()
				vim.api.nvim_set_var('winresizer_start_key', '<C-W>c')
			end
		}
		use {
			'navarasu/onedark.nvim', -- テーマ
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
		use {
			'gw31415/deepl-commands.nvim', -- deeplとの連携
			event = { 'CmdlineEnter' },
			requires = {
				'gw31415/deepl.vim',
				'gw31415/fzyselect.vim', -- Optional
			},
			config = function()
				require 'deepl-commands'.setup {
					selector_func = require 'fzyselect'.start
				}
			end
		}
		use 'vim-jp/vimdoc-ja' -- 日本語のヘルプ
		use {
			'vim-skk/skkeleton', -- 日本語入力
			requires = { 'vim-denops/denops.vim', 'gw31415/skkeletal.vim' },
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

		if packer_bootstrap ~= '' then
			require 'packer'.sync()
		end
	end,
	config = {
		display = { open_fn = require 'packer.util'.float, },
	},
}
