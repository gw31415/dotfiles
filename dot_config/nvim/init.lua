if vim.loader then vim.loader.enable() end

--[[
-- 依存: NVim nightly, Git, cURL, Deno
-- silicon, ra-multiplexがあれば対応。
-- ]]
-- Emacs Keybindings

vim.keymap.set("i", "<c-f>", "<c-g>U<right>")
vim.keymap.set("i", "<c-b>", "<c-g>U<left>")
vim.keymap.set("i", "<c-p>", "<c-g>U<up>")
vim.keymap.set("i", "<c-n>", "<c-g>U<down>")
vim.keymap.set("i", "<c-d>", "<c-g>U<del>")
vim.cmd [[
	inoremap <expr> <c-a> col('.') == match(getline('.'), '\S') + 1 ?
		\ repeat('<C-G>U<Left>', col('.') - 1) :
		\ (col('.') < match(getline('.'), '\S') ?
		\     repeat('<C-G>U<Right>', match(getline('.'), '\S') + 0) :
		\     repeat('<C-G>U<Left>', col('.') - 1 - match(getline('.'), '\S')))
]]
vim.cmd([[ inoremap <expr> <c-e> repeat('<C-G>U<Right>', col('$') - col('.')) ]])
vim.keymap.set("c", "<c-f>", "<right>")
vim.keymap.set("c", "<c-b>", "<left>")
vim.keymap.set("c", "<c-p>", "<up>")
vim.keymap.set("c", "<c-n>", "<down>")
vim.keymap.set("c", "<c-d>", "<del>")
vim.keymap.set("c", "<c-a>", "<home>")
vim.keymap.set("c", "<c-e>", "<end>")

vim.api.nvim_create_autocmd("BufRead", {
	pattern = "*.mdx",
	callback = function() vim.opt_local.filetype = "markdown" end,
})
vim.api.nvim_create_autocmd("BufRead", {
	pattern = "*.saty",
	callback = function()
		vim.opt_local.filetype = "satysfi"
		require("indent_blankline.commands").disable()
	end,
})
vim.api.nvim_create_autocmd('BufReadPost', {
	pattern = "COMMIT_EDITMSG",
	callback = function()
		vim.keymap.set('n', '<C-g><tab>', function()
			local diff = vim.fn.system({ 'git', '--git-dir', vim.fn.expand('%:p:h'), 'diff', 'HEAD' })
			require 'gpt'.stream(
				'Write a commit message describing the changes and the reasoning:\n\n========\n' .. diff)
		end, { buffer = true })
	end
})
vim.api.nvim_create_autocmd('BufReadPost', {
	pattern = { "*.json", "*.ts", "*.js", "*.jsx", "*.tsx" },
	callback = function()
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
		vim.opt_local.tabstop = 2
	end
})
vim.api.nvim_create_autocmd("BufRead", {
	pattern = "*.njk",
	callback = function()
		vim.opt_local.filetype = "html"
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.md",
	once = true,
	callback = function()
		local lspconfig = require('lspconfig')
		local configs = require('lspconfig.configs')
		if not configs.obsidian then
			configs.obsidian = {
				default_config = {
					didChangeWatchedFiles = {
						dynamicRegistration = true,
						relativePatternSupport = true
					},
					cmd = { "npx", "obsidian-lsp", "--", "--stdio" },
					-- cmd = { "npm", "--prefix", "/Users/ama/obsidian-lsp", "run", "dev", "--", "--stdio" },
					single_file_support = false,
					root_dir = lspconfig.util.root_pattern ".obsidian",
					filetypes = { 'markdown' },
				},
			}
		end
		lspconfig.obsidian.setup {}
		vim.cmd 'LspStart'
	end
})
vim.keymap.set("n", "<Leader>ob", function()
	local path = "/Users/ama/Library/Mobile Documents/iCloud~md~obsidian/Documents/Zettelkasten/"
	local filename = vim.fn.strftime("%Y%m%d%H%M%S") .. ".md"
	vim.cmd(string.format("sp %s%s", path, filename))
end)

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
		for _, value in pairs(vim.lsp.get_clients()) do
			---@diagnostic disable-next-line: undefined-field
			if value.name == "obsidian" then
				---@diagnostic disable-next-line: undefined-field
				local root_dir = value.config.root_dir
				vim.keymap.set("n", "zz", function()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("ZZ<Leader>ob", true, true, true) or "", "",
						true)
				end, { buffer = true })
				vim.keymap.set("n", "<c-p>", function()
					local query = vim.fn.input("検索: ")
					if query == "" then return end
					---@diagnostic disable-next-line: undefined-field
					local res = vim.system({ "rg", "--json", "-g", "**/*.md", query }, {
						text = true,
						cwd = root_dir,
						---@diagnostic disable-next-line: undefined-field
					}):wait()
					local json = {}
					for _, jsonstr in pairs(vim.fn.split(res.stdout, '\n') or {}) do
						local j = vim.fn.json_decode(jsonstr)
						if j and j.type == "match" then
							table.insert(json, j)
						end
					end
					require 'fzyselect'.start(json,
						{
							prompt = 'Obsidian note files: <Enter> to edit',
							format_item = function(j)
								return string.format("%s | %s", j.data.path.text, vim.fn.trim(j.data.lines.text))
							end,
						},
						function(j)
							if j then vim.cmd.edit(root_dir .. '/' .. j.data.path.text) end
						end)
				end, { buffer = true })
				vim.keymap.set({ "n", "i" }, "<M-v>", function()
					local filename = vim.fn.strftime("%Y%m%d%H%M%S") .. ".png"
					local res = vim.system({ "pngpaste", filename }, {
						text = true,
						cwd = root_dir,
						---@diagnostic disable-next-line: undefined-field
					}):wait()
					if res.signal ~= 0 then
						vim.notify(res.stderr, vim.log.levels.ERROR)
					else
						vim.notify("pngpaste: " .. filename, vim.log.levels.INFO)
						vim.api.nvim_feedkeys(
							vim.api.nvim_replace_termcodes(
								"<Esc>a![](" .. filename .. ")<Esc>%hi",
								true,
								true,
								true
							) or "",
							"",
							true
						)
					end
				end, { buffer = true })
				break
			end
		end
	end
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*.org",
	callback = function()
		vim.opt_local.formatoptions:append('mM')
		vim.opt_local.foldlevel = 0
		vim.opt_local.expandtab = true
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.keymap.set({ "n", "i" }, "<M-v>", function()
			local filename = vim.fn.strftime("%Y%m%d%H%M%S") .. ".png"
			local res = vim.system({ "pngpaste", filename }, {
				text = true,
				cwd = vim.fn.expand('%:p:h'),
				---@diagnostic disable-next-line: undefined-field
			}):wait()
			if res.signal ~= 0 then
				vim.notify(res.stderr, vim.log.levels.ERROR)
			else
				vim.notify("pngpaste: " .. filename, vim.log.levels.INFO)
				vim.api.nvim_feedkeys(
					vim.api.nvim_replace_termcodes(
						"<Esc>a[[file:" .. filename .. "]]<Esc>%O#+CAPTION:<Space>",
						true,
						true,
						true
					) or "",
					"",
					true
				)
			end
		end, { buffer = true })
	end
})

if vim.g.goneovim then
	vim.keymap.set("n", "<C-w>O", function()
		local width = vim.api.nvim_win_get_width(0)
		local height = vim.api.nvim_win_get_height(0)
		vim.api.nvim_win_set_config(0, { external = true, width = width, height = height })
	end)
end

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
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
			local winid = require('ufo').peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, bufopts)
		vim.keymap.set("n", "<C-j>", vim.diagnostic.goto_next, bufopts)
		vim.keymap.set("n", "<C-k>", vim.diagnostic.goto_prev, bufopts)
		vim.keymap.set("n", "<Leader>a", vim.lsp.buf.code_action, bufopts)
		vim.keymap.set("n", "cI", vim.lsp.buf.rename, bufopts)
		vim.keymap.set("n", "z*", vim.lsp.buf.references, bufopts)
		vim.keymap.set("n", "gqae", function() vim.lsp.buf.format({ async = true }) end,
			{ buffer = true, nowait = true })
		-- vim.api.nvim_create_autocmd('BufWritePre', {
		-- 	callback = function() vim.lsp.buf.format { async = false } end,
		-- 	buffer = bufnr,
		-- })
	end
})

-- Configure
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.winblend = 20
vim.opt.pumblend = vim.wo.winblend
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.splitbelow = true
vim.opt.hidden = true
vim.opt.laststatus = 3
vim.opt.smoothscroll = true
vim.api.nvim_set_var("tex_conceal", "")
vim.diagnostic.config({ signs = false })

-- Terminal
vim.api.nvim_create_autocmd('TermOpen', {
	callback = function()
		vim.cmd.setl("nonumber")
		vim.cmd.setl("norelativenumber")
	end
})

-- Neovide
vim.opt.guifont = "Hack Nerd Font:h13,HackGen Console NF:h13"
if vim.g.neovide then
	vim.api.nvim_set_var("neovide_remember_window_size", false)
end

-- Mac Keybindings
vim.keymap.set("i", "<D-v>", '<esc>"+pa', {})
vim.keymap.set("n", "<D-v>", '"+p', {})
vim.keymap.set("v", "<D-c>", '"+y', {})
vim.keymap.set("n", "<D-t>", "<cmd>tabe<cr>", {})
vim.keymap.set("n", "<D-w>", "<cmd>q<cr>", {})
for i = 1, 10, 1 do
	local from = "<D-" .. i .. ">"
	local to = "<cmd>tabn " .. i .. "<cr>"
	vim.keymap.set("n", from, to, {})
end

-- ripgrep
if vim.fn.executable("rg") then
	vim.api.nvim_set_option_value("grepprg", "rg --vimgrep --hidden", {})
	vim.api.nvim_set_option_value("grepformat", "%f:%l:%c:%m", {})
end

-- StatusLine
function _G.get_warn_count()
	local warns = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
	return #warns
end

function _G.get_error_count()
	local errors = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	return #errors
end

_G.get_skkeleton_modestring = function() return "英数" end

vim.cmd(
	[[set statusline=[%{v:lua.get_skkeleton_modestring()}]%f%r%m%h%w%=E%{v:lua.get_error_count()}W%{v:lua.get_warn_count()}\ %l/%L]]
)

-- default plugins
vim.api.nvim_set_var("loaded_netrwPlugin", true)
vim.api.nvim_set_var("loaded_remote_plugins", true)
vim.api.nvim_set_var("skip_loading_mswin", true)
vim.api.nvim_set_var("loaded_tutor_mode_plugin", true)
vim.api.nvim_set_var("loaded_2html_plugin", true)

-- APIキーの読みこみ関数
local function setup_authkey(path, opts)
	---@diagnostic disable: param-type-mismatch
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
				'Successfully saved OPENAI_API_KEY at `%s`.', path),
			vim.log.levels.INFO, {
				title = 'gpt.nvim'
			})
	end
	return key
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
	vim.fn.system({ "git", "-C", lazypath, "checkout", "tags/stable" }) -- last stable release
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
	"nvim-lua/plenary.nvim",
	{ "vim-denops/denops.vim",           lazy = false },

	-- Games
	{ "eandrju/cellular-automaton.nvim", cmd = "CellularAutomaton" },
	{ "gw31415/nvim-tetris",             cmd = "Tetris" },
	{ "seandewar/nvimesweeper",          cmd = "Nvimesweeper" },
	{
		"m4xshen/hardtime.nvim",
		dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
		opts = {},
		cmd = "Hardtime",
	},
	{
		"gw31415/pets.nvim",
		dependencies = { "MunifTanjim/nui.nvim", "giusgad/hologram.nvim" },
		event = "VeryLazy",
		opts = {
			row = 6,
		},
		enabled = function()
			return vim.fn.environ()["TERM"] == "xterm-kitty"
		end,
	},

	-- 言語別プラグイン
	{
		"nvim-orgmode/orgmode",
		dependencies = {
			{
				"akinsho/org-bullets.nvim",
				config = true,
				opts = {
					symbols = {
						headlines = {
							"◉", "◊", "▹",
							"◉", "◊", "▹",
							"◉", "◊", "▹",
							"◉", "◊", "▹",
						}
					},
				},
			},
			'tpope/vim-repeat',
			"danilshvalov/org-modern.nvim",
		},
		ft = "org",
		keys = "<Leader>o",
		config = function()
			local Menu = require("org-modern.menu")
			vim.keymap.set('n', '<Leader>o', '<Nop>', {})
			require("orgmode").setup_ts_grammar()
			require("orgmode").setup({
				ui = {
					menu = {
						handler = function(data)
							Menu:new({
								window = {
									margin = { 1, 0, 1, 0 },
									padding = { 0, 1, 0, 1 },
									title_pos = "center",
									border = "single",
									zindex = 1000,
								},
								icons = {
									separator = "➜",
								},
							}):open(data)
						end,
					},
				},
				org_agenda_files = { "~/iCloud_Drive/org/*" },
				org_agenda_skip_deadline_if_done = true,
				org_default_notes_file = "~/iCloud_Drive/org/refile.org",
				org_capture_templates = {
					n = {
						description = "Default Note",
						template = "* %?\n %U",
					},
					t = {
						description = "Task",
						template = "* TODO %?\n  %u",
						target = "~/iCloud_Drive/org/tasks.org",
					},
				},
			})
		end,
	},
	{
		"akinsho/flutter-tools.nvim",
		ft = { "dart" },
		config = true,
		-- opts = {
		-- 	lsp = {
		-- 		on_attach = _G.lsp_onattach_func,
		-- 	},
		-- },
	},
	{
		"tranvansang/octave.vim",
		ft = { "matlab", "octave" },
	},
	{
		"mattn/emmet-vim",
		ft = { "html", "jsx", "tsx" }
	},
	{
		"gw31415/zk-obsidian.nvim",
		event = "VeryLazy",
	},

	-- LSP
	{
		"folke/neodev.nvim",
		ft = "lua",
		dependencies = "neovim/nvim-lspconfig",
		config = function()
			-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
			require 'neodev'.setup {}
			require 'lspconfig'.lua_ls.setup {
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace"
						}
					}
				}
			}
		end,
	},
	{
		"williamboman/mason.nvim", -- LSP Installer
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"neovim/nvim-lspconfig",
			"jose-elias-alvarez/null-ls.nvim",
			"nvim-lua/plenary.nvim",
			"jay-babu/mason-null-ls.nvim",
		},
		event = "VeryLazy",
		config = function()
			require "mason".setup {}
			local mason_lspconfig = require("mason-lspconfig")
			local on_attach = function(_, bufnr)
				vim.api.nvim_buf_set_option(bufnr, "formatexpr",
					"v:lua.vim.lsp.formatexpr(#{timeout_ms:250})")
				-- _G.lsp_onattach_func(i, bufnr)
			end
			mason_lspconfig.setup_handlers({
				function(server_name)
					local opts = {
						on_attach = on_attach,
						settings = {
							["rust-analyzer"] = {
								checkOnSave = {
									command = "clippy",
								},
							},
							["pylsp"] = {
								plugins = {
									autopep8 = {
										enabled = false,
									},
									yapf = {
										enabled = false,
									},
								},
							},
							["omniSharp"] = {
								useGlobalMono = "always"
							}
						},
					}

					local node_root_dir = require 'lspconfig'.util.root_pattern("package.json")
					local is_node_repo = node_root_dir(vim.api.nvim_buf_get_name(0)) ~= nil

					if server_name == "tsserver" then
						if not is_node_repo then return end
						opts["root_dir"] = node_root_dir
						opts["single_file_support"] = false
					elseif server_name == "denols" then
						if is_node_repo then return end
					end

					require("lspconfig")[server_name].setup(opts)
				end,
			})
			require('mason-null-ls').setup({
				automatic_setup = true,
				handlers = {},
			})
			require "null-ls".setup({
				-- on_attach = _G.lsp_onattach_func,
			})
			if vim.fn.executable "satysfi-language-server" == 1 then
				require('lspconfig')['satysfi-ls'].setup { autostart = true }
			end
			vim.cmd("LspStart") -- 初回起動時はBufEnterが発火しない
		end,
	},
	{
		"tamago324/nlsp-settings.nvim",
		config = true,
		opts = {
			config_home = vim.fn.stdpath("config") .. "/nlsp-settings",
			local_settings_dir = ".vscode",
			local_settings_root_markers_fallback = { ".git" },
			append_default_schemas = true,
			loader = "json",
		},
	},
	{
		"onsails/diaglist.nvim", -- Diagnosticの自動更新Quickfixリスト
		event = { "LspAttach" },
		config = function()
			vim.api.nvim_create_user_command("Diaglist", function()
				require("diaglist.quickfix").populate_qflist()
			end, { force = true })
			require("diaglist").init()
			require("diaglist.quickfix").populate_qflist()
		end,
	},
	{
		"j-hui/fidget.nvim", -- LSPのステータスを右下に表示
		tag = "legacy",
		event = { "LspAttach" },
		config = function()
			vim.api.nvim_create_autocmd("VimLeavePre", { command = "silent! FidgetClose" })
			require("fidget").setup()
		end,
	},
	{
		"numToStr/Comment.nvim", -- コメントのトグル
		keys = { { "gc", mode = { "n", "x" } } },
		config = true,
		opts = {
			toggler = {
				block = 'gCC',
			},
			opleader = {
				block = 'gC',
			},
		},
	},
	{
		'stevearc/overseer.nvim', -- タスクランナーを起動する
		event = "VeryLazy",
		config = true,
	},

	-- Debug Adapter Protocol
	{
		"mfussenegger/nvim-dap",
		dependencies = { "rcarriga/nvim-dap-ui" },
		keys = {
			{ "<F5>",  function() require "dap".continue() end },
			{ "<F10>", function() require "dap".step_over() end },
			{ "<F11>", function() require "dap".step_into() end },
			{ "<F12>", function() require "dap".step_out() end },
			{ "bb",    function() require "dap".toggle_breakpoint() end },
		},
		config = function()
			require("dapui").setup()

			-- codelldbの設定
			vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
				pattern = { "*.rs", "*.c", "*.cpp" },
				callback = function()
					local mason_dap_package = "codelldb"

					if not require("mason-registry").is_installed(mason_dap_package) then
						vim.cmd("MasonInstall " .. mason_dap_package)
					end
				end,
			})
			require("dap").adapters.lldb = {
				type = "server",
				port = "13000",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb",
					args = { "--port", "13000" },
					detached = false,
				},
			}

			-- dap-uiの自動起動・終了
			require("dap").listeners.before["event_initialized"]["custom"] = function()
				require("dapui").open({})
			end
			require("dap").listeners.before["event_terminated"]["custom"] = function()
				require("dapui").close({})
			end
		end,
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		dependencies = "mfussenegger/nvim-dap",
		config = function()
			require("nvim-dap-virtual-text").setup({
				enabled_commands = false,
			})
		end,
	},
	{
		"leoluz/nvim-dap-go",
		ft = { "go" },
		dependencies = { "mfussenegger/nvim-dap", "williamboman/mason.nvim" },
		config = function()
			local mason_dap_package = "delve"
			local init_func = require("dap-go").setup
			if not require("mason-registry").is_installed(mason_dap_package) then
				vim.cmd("MasonInstall " .. mason_dap_package)
			end
			-- delveがインストール済み、又はインストールに成功した場合にdap-goを設定する
			if require("mason-registry").is_installed(mason_dap_package) then
				init_func()
			end
		end,
	},
	{
		"gw31415/nvim-dap-rust",
		ft = { "rust" },
		dependencies = { "mfussenegger/nvim-dap", "williamboman/mason.nvim" },
		config = function()
			local mason_dap_package = "codelldb"
			local init_func = require("dap-rust").setup
			if not require("mason-registry").is_installed(mason_dap_package) then
				vim.cmd("MasonInstall " .. mason_dap_package)
			end
			-- delveがインストール済み、又はインストールに成功した場合にdap-goを設定する
			if require("mason-registry").is_installed(mason_dap_package) then
				init_func()
			end
		end,
	},
	{
		"mfussenegger/nvim-dap-python",
		ft = { "python" },
		dependencies = { "mfussenegger/nvim-dap", "williamboman/mason.nvim" },
		config = function()
			local mason_dap_package = "delve"
			local init_func = function()
				require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
			end
			if not require("mason-registry").is_installed(mason_dap_package) then
				vim.cmd("MasonInstall " .. mason_dap_package)
			end
			if require("mason-registry").is_installed(mason_dap_package) then
				init_func()
			end
		end,
	},

	{
		"CRAG666/code_runner.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		event = "VeryLazy",
		config = true,
		opts = {
			mode = "term",
			focus = true,
			startinsert = true,
			filetype = {
				java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
				python = "python3 -u",
				typescript = "deno run",
				rust = "cd $dir && rustc $fileName && $dir/$fileNameWithoutExt",
				go = "go run",
			},
			term = {
				position = "bot",
				size = 8,
			},
			-- filetype_path = vim.fn.expand('~/.config/nvim/code_runner.json'),
			-- project_path = vim.fn.expand('~/.config/nvim/project_manager.json')
		},
	},

	-- 補完
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/vim-vsnip",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			{
				'petertriho/cmp-git',
				dependencies = 'nvim-lua/plenary.nvim',
				config = true,
			}
		},
		event = { "InsertEnter", "CmdlineEnter" },
		config = function()
			local cmp = require 'cmp'
			local function feedkeys(key)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true) or "", "", true)
			end
			cmp.setup {
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end
				},
				window = {
					documentation = cmp.config.window.bordered()
				},
				sources = cmp.config.sources {
					{ name = 'nvim_lsp' },
					{ name = 'vsnip' },
					{ name = 'nvim_lsp_signature_help' },
				},
				mapping = cmp.mapping.preset.insert {
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							local entry = cmp.get_selected_entry()
							if not entry then
								cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
							else
								cmp.confirm()
							end
						elseif vim.fn["vsnip#jumpable"](1) == 1 then
							feedkeys("<Plug>(vsnip-jump-next)")
						else
							fallback()
						end
					end),
					["<s-tab>"] = cmp.mapping(function(fallback)
						if vim.fn["vsnip#jumpable"](-1) == 1 then
							feedkeys("<Plug>(vsnip-jump-prev)")
						else
							fallback()
						end
					end),
				}
			}
			cmp.setup.cmdline({ '/', '?' }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = 'buffer' }
				}
			})
			cmp.setup.cmdline(':', {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources {
					{ name = 'cmdline' }
				}
			})
			cmp.setup.filetype('gitcommit', {
				sources = cmp.config.sources({
					{ name = 'git' },
				})
			})
		end
	},

	-- UI
	{
		"kevinhwang91/nvim-bqf", -- quickfixのハイジャック
		event = "VeryLazy",
	},
	{
		"rcarriga/nvim-notify", -- vim.notifyのハイジャック
		event = "VeryLazy",
		config = function()
			vim.notify = require("notify")
		end,
	},
	{
		'kevinhwang91/nvim-ufo', -- 折りたたみの改良
		event = "VeryLazy",
		dependencies = "kevinhwang91/promise-async",
		config = function()
			require "ufo".setup {
				provider_selector = function()
					return { "treesitter", "indent" }
				end,
				fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
					local newVirtText = {}
					local suffix = ('   %d '):format(endLnum - lnum)
					local sufWidth = vim.fn.strdisplaywidth(suffix)
					local targetWidth = width - sufWidth
					local curWidth = 0
					for _, chunk in ipairs(virtText) do
						local chunkText = chunk[1]
						local chunkWidth = vim.fn.strdisplaywidth(chunkText)
						if targetWidth > curWidth + chunkWidth then
							table.insert(newVirtText, chunk)
						else
							chunkText = truncate(chunkText, targetWidth - curWidth)
							local hlGroup = chunk[2]
							table.insert(newVirtText, { chunkText, hlGroup })
							chunkWidth = vim.fn.strdisplaywidth(chunkText)
							-- str width returned from truncate() may less than 2nd argument, need padding
							if curWidth + chunkWidth < targetWidth then
								suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
							end
							break
						end
						curWidth = curWidth + chunkWidth
					end
					table.insert(newVirtText, { suffix, 'MoreMsg' })
					return newVirtText
				end
			}
		end
	},
	{
		"monaqa/dial.nvim", -- 拡張版<C-a><C-x>
		keys = {
			{ "<C-a>",  "<Plug>(dial-increment)",                                              mode = { "n", "x" } },
			{ "<C-x>",  "<Plug>(dial-decrement)",                                              mode = { "n", "x" } },
			{ "g<C-a>", function() require 'dial.map'.manipulate("increment", "gvisual") end,  mode = "x" },
			{ "g<C-x>", function() require 'dial.map'.manipulate("decrement", "gvisual") end,  mode = "x" },
			{ "g<C-a>", function() require("dial.map").manipulate("increment", "gnormal") end, mode = "n" },
			{ "g<C-x>", function() require("dial.map").manipulate("decrement", "gnormal") end, mode = "n" },
		},
		config = function()
			local augend = require("dial.augend")
			require("dial.config").augends:register_group({
				default = {
					augend.integer.alias.decimal,
					augend.semver.alias.semver,
					augend.integer.alias.hex,
					augend.constant.alias.bool,
					augend.date.alias["%Y/%m/%d"],
					augend.date.alias["%Y-%m-%d"],
				},
			})
		end,
	},

	-- ファイラ
	{
		"gw31415/onlybrowsex.vim",
		keys = { { "gx", function() vim.fn["onlybrowsex#BrowseX"](vim.fn.expand("<cfile>")) end } },
	},
	"lambdalisue/nerdfont.vim",
	{
		"lambdalisue/fern.vim",
		cmd = "Fern",
		keys = {
			{ "<C-n>", "<cmd>Fern . -drawer -toggle -reveal=% <cr>" }
		},
		dependencies = {
			"lambdalisue/fern-renderer-nerdfont.vim",
			"lambdalisue/nerdfont.vim",
			"lambdalisue/fern-git-status.vim",
			"lambdalisue/fern-mapping-git.vim",
		},
		init = function()
			vim.api.nvim_set_var("fern#renderer", "nerdfont")
			vim.api.nvim_set_var("fern#renderer#nerdfont#indent_markers", 1)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "fern",
				callback = function()
					local opts = { buffer = true }
					vim.keymap.set("n", "K", "<Plug>(fern-action-new-dir)", opts)
				end,
			})
		end,
		config = function()
			vim.fn["fern_git_status#init"]()
		end
	},
	{ "lambdalisue/fern-hijack.vim", lazy = false },
	{
		"gw31415/fzyselect.vim", -- vim.ui.select
		event = "VeryLazy",
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "fzyselect",
				callback = function()
					vim.keymap.set("n", "i", "<Plug>(fzyselect-fzy)", { buffer = true })
					vim.keymap.set("n", "<cr>", "<Plug>(fzyselect-retu)", { buffer = true })
					vim.keymap.set("n", "<esc>", "<cmd>clo<cr>", { buffer = true })
				end,
			})
			-- fuzzy search
			vim.keymap.set('n', "gl", function()
				local winid = vim.api.nvim_get_current_win()
				require 'fzyselect'.start(vim.api.nvim_buf_get_lines(0, 0, -1, true),
					{ prompt = "fuzzy search: <Enter> to jump" },
					function(_, i)
						if i then
							vim.api.nvim_win_set_cursor(winid, { i, 0 })
						end
					end)
			end)
			-- git ls-files
			vim.keymap.set("n", "<c-p>", function()
				---@diagnostic disable-next-line: undefined-field
				local res = vim.system({ 'git', 'ls-files' }, { text = true }):wait()
				if res.code ~= 0 then
					vim.notify(vim.fn.trim(res.stderr), vim.log.levels.ERROR, { title = "fzyselect: git ls-files" })
				else
					require 'fzyselect'.start(vim.fn.split(res.stdout, '\n'),
						{ prompt = 'git ls-files: <Enter> to edit' },
						function(path)
							if path then vim.cmd.edit(path) end
						end)
				end
			end)
			-- buffer manager
			local last_access = {}
			vim.api.nvim_create_autocmd('BufEnter', {
				callback = function() last_access[vim.api.nvim_get_current_buf()] = vim.fn.localtime() end,
			})
			vim.api.nvim_create_autocmd('BufDelete', {
				callback = function() last_access[vim.api.nvim_get_current_buf()] = nil end,
			})
			vim.keymap.set("n", "gb", function()
				local winid = vim.api.nvim_get_current_win()
				local bufs = {}
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(buf)
						and vim.fn.buflisted(buf)
						and vim.api.nvim_buf_get_name(buf) ~= ""
						and buf ~= vim.api.nvim_get_current_buf() then
						table.insert(bufs, buf)
					end
				end
				table.sort(bufs, function(a, b)
					return (last_access[a] or 0) > (last_access[b] or 0)
				end)
				vim.api.nvim_create_autocmd('FileType', {
					once = true,
					pattern = 'fzyselect',
					callback = function()
						vim.keymap.set('n', 'dd', function()
							local buf = bufs[vim.api.nvim_win_get_cursor(0)[1]]
							local bufname = vim.api.nvim_buf_get_name(buf)
							vim.cmd.close()
							vim.api.nvim_buf_delete(buf, {})
							vim.notify('deleted buffer: ' .. bufname, vim.log.levels.INFO, {
								title = "fzyselect: buffer manager"
							})
						end, { buffer = true })
					end
				})
				require 'fzyselect'.start(bufs, {
					format_item = vim.api.nvim_buf_get_name,
					prompt = 'buffer manager: <Enter> to switch or dd to delete'
				}, function(buf)
					if buf then vim.api.nvim_win_set_buf(winid, buf) end
				end)
			end)
			vim.ui.select = require("fzyselect").start
		end,
	},
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.1',
		cmd = "Telescope",
	},
	{
		"nvim-treesitter/nvim-treesitter", -- Treesitter
		dependencies = {
			{
				"nvim-treesitter/nvim-treesitter-context",
				config = function()
					require 'treesitter-context'.setup {
						line_numbers = true,
						mode = 'topline',
						separator = '~'
					}
				end
			},
		},
		config = function()
			-- markdown treesitter のPluginの有効化
			vim.fn.setenv("EXTENSION_WIKI_LINK", 1)

			-- satysfiサーバのセットアップ
			local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
			parser_config.satysfi = {
				install_info = {
					url = "https://github.com/monaqa/tree-sitter-satysfi",
					files = { "src/parser.c", "src/scanner.c" }
				},
				filetype = "satysfi",
			}

			local parser_install_dir = vim.fn.stdpath("data") .. "/treesitter"
			vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/treesitter")
			require("nvim-treesitter.configs").setup({
				parser_install_dir = parser_install_dir,
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = { "org", "markdown" },
				},
				indent = {
					enable = true,
				},
				auto_install = true,
				ensure_installed = { 'org', 'satysfi', 'markdown' },
			})
			vim.wo.foldmethod = "expr"
			vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
			vim.wo.foldenable = false
			vim.wo.foldlevel = 999
			vim.api.nvim_create_autocmd("BufEnter", {
				command = "TSEnable highlight",
			})
		end,
	},
	{
		"https://gitlab.com/HiPhish/rainbow-delimiters.nvim",
		lazy = false,
		dependencies = "nvim-treesitter/nvim-treesitter",
	},
	{
		"kiyoon/treesitter-indent-object.nvim",
		keys = {
			{
				"ai",
				function() require 'treesitter_indent_object.textobj'.select_indent_outer() end,
				mode = { "x", "o" },
				desc = "Select context-aware indent (outer)",
			},
			{
				"aI",
				function() require 'treesitter_indent_object.textobj'.select_indent_outer(true) end,
				mode = { "x", "o" },
				desc = "Select context-aware indent (outer, line-wise)",
			},
			{
				"ii",
				function() require 'treesitter_indent_object.textobj'.select_indent_inner() end,
				mode = { "x", "o" },
				desc = "Select context-aware indent (inner, partial range)",
			},
			{
				"iI",
				function() require 'treesitter_indent_object.textobj'.select_indent_inner(true) end,
				mode = { "x", "o" },
				desc = "Select context-aware indent (inner, entire range)",
			},
		},
	},
	{
		"ziontee113/syntax-tree-surfer",
		config = true,
		keys = {
			{ "<c-j>", '<cmd>STSSelectNextSiblingNode<cr>', mode = "x" },
			{ "<c-k>", '<cmd>STSSelectPrevSiblingNode<cr>', mode = "x" },
			{ "<c-h>", '<cmd>STSSelectParentNode<cr>',      mode = "x" },
			{ "<c-l>", '<cmd>STSSelectChildNode<cr>',       mode = "x" },
			{ "<A-j>", '<cmd>STSSwapNextVisual<cr>',        mode = "x" },
			{ "<A-k>", '<cmd>STSSwapPrevVisual<cr>',        mode = "x" },
		}
	},
	{
		"Wansmer/treesj",
		keys = {
			{ "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
		},
		opts = { use_default_keymaps = false, max_join_length = 150 },
	},
	{
		"lukas-reineke/indent-blankline.nvim", -- インデントの可視化
		event = "VeryLazy",
		opts = function()
			return require("indent-rainbowline").make_opts({
				show_current_context_start = true,
				show_current_context = true,
			}, {
				color_transparency = 0.07,
			})
		end,
		dependencies = {
			"TheGLander/indent-rainbowline.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		init = function()
			vim.api.nvim_set_var("indent_blankline_use_treesitter", true)
			vim.api.nvim_set_var("indent_blankline_filetype_exclude", {
				"lspinfo",
				"packer",
				"checkhealth",
				"help",
				"man",
				"",
				"org",
			})
		end,
	},
	{
		'stevearc/aerial.nvim',
		opts = {},
		event = "VeryLazy",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons"
		},
	},
	{
		"Darazaki/indent-o-matic",
		config = true,
	},
	{
		"uga-rosa/ccc.nvim",
		cmd = {
			"CccPick",
			"CccConvert",
			"CccHighlighterEnable",
			"CccHighlighterDisable",
			"CccHighlighterToggle",
		},
		config = true,
		opts = {
			bar_char = "-",
			point_char = "+",
			highlighter = {
				auto_enable = true,
				filetypes = { "css", "sass", "scss", "js", "html", "json" },
				events = { "WinScrolled", "TextChanged", "TextChangedI", "BufEnter" },
				lsp = true,
			},
		},
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = true,
		event = "VeryLazy",
	},

	-- 小機能追加
	-- "rbtnn/vim-ambiwidth",
	{
		"delphinus/cellwidths.nvim", -- 曖昧幅な文字の文字幅設定
		opts = {
			name = "cica",
		}
	},

	{
		"hrsh7th/nvim-insx", -- 自動括弧閉じ
		event = "InsertEnter",
		config = function()
			require('insx.preset.standard').setup()
		end
	},
	{
		"kylechui/nvim-surround", -- operator 囲い文字
		event = "VeryLazy",
		tag = "v1.0.0",
		config = true,
	},
	{
		"glts/vim-textobj-comment", -- コメントに対する textobj
		keys = {
			{ "ic", mode = { "o", "x" } },
			{ "ac", mode = { "o", "x" } },
		},
		dependencies = "kana/vim-textobj-user",
	},
	{
		"kana/vim-textobj-entire", -- バッファ全体に対する textobj
		keys = {
			{ "ae", mode = "o" },
		},
		dependencies = "kana/vim-textobj-user",
	},
	{
		"gbprod/substitute.nvim", -- vim-operator-replace
		keys = {
			{ "_",  function() require('substitute').operator() end },
			{ "_",  function() require('substitute').visual() end,  mode = "x" },
			{ "__", function() require('substitute').line() end },
		},
		config = true,
	},
	{
		"segeljakt/vim-silicon", -- ソースコードを画像化するsiliconコマンドのラッパー
		cmd = "Silicon",
		enabled = function()
			return vim.fn.executable("silicon") == 1
		end,
		config = function()
			vim.api.nvim_set_var("silicon", {
				font = "HackGenNerd Console",
			})
		end,
	},
	{
		"itchyny/calendar.vim",
		cmd = "Calendar",
		config = function()
			vim.g.calendar_google_api_key = setup_authkey("~/.ssh/google_calender_api_key.txt", {
				prompt = "GOOGLE_API_KEY = ",
			})
			vim.g.calendar_google_client_id = setup_authkey("~/.ssh/google_calender_client_id.txt", {
				prompt = "GOOGLE_CALENDER_CLIENT_ID = ",
			})
			vim.g.calendar_google_client_secret = setup_authkey("~/.ssh/google_calender_client_secret.txt", {
				prompt = "GOOGLE_CALENDER_CLIENT_SECRET = ",
			})
			vim.g.calendar_google_calendar = 1
		end
	},
	{
		"lambdalisue/gin.vim", -- Git連携
		dependencies = "vim-denops/denops.vim",
		lazy = false,
	},
	{
		"lewis6991/gitsigns.nvim", -- Gitの行毎ステータス
		event = "VeryLazy",
		config = true,
		opts = {
			numhl = true,
			signcolumn = false,
		},
	},
	{
		"yuki-yano/fuzzy-motion.vim", -- 画面内ジャンプ
		lazy         = false,
		dependencies = { "vim-denops/denops.vim", "lambdalisue/kensaku.vim" },
		keys         = { { "<Space>", "<cmd>FuzzyMotion<cr>" } },
		config       = function()
			vim.g.fuzzy_motion_labels = {
				'U', 'H', 'E', 'T', 'O', 'N', 'A', 'S', 'P', 'G', 'I', 'D', 'K', 'B', 'J', 'M',
			}
			vim.g.fuzzy_motion_matchers = { 'fzf', 'kensaku' }
		end
	},
	{
		"mbbill/undotree",
		cmd = {
			"UndotreeShow",
			"UndotreeHide",
			"UndotreeFocus",
			"UndotreeToggle",
		},
	},
	{
		"simeji/winresizer", -- ウィンドウサイズ変更
		keys = "<c-w>",
		init = function()
			vim.api.nvim_set_var("winresizer_start_key", "<C-W>e")
		end,
	},
	{
		"monaqa/nvim-treesitter-clipping",
		dependencies = {
			"thinca/vim-partedit",
			"nvim-treesitter/nvim-treesitter",
		},
		keys = {
			{ "cx", "<Plug>(ts-clipping-clip)" },
			{ "cx", "<Plug>(ts-clipping-select)", mode = { "x", "o" } },
		},
	},
	{
		"thinca/vim-ambicmd", -- コマンドの曖昧展開
		event = "CmdlineEnter",
		config = function()
			vim.keymap.set("c", "<Space>", function()
				return vim.fn["ambicmd#expand"]("<Space>")
			end, { expr = true })
		end
	},
	{
		"navarasu/onedark.nvim", -- テーマ
		lazy = false,
		config = function()
			require("onedark").setup({
				style = "darker",
				code_style = vim.g.goneovim ~= 1 and {
					comments = "none",
					functions = "bold",
					keywords = "none",
				} or nil,
			})
			require("onedark").load()
		end,
	},
	{
		"gw31415/deepl-commands.nvim", -- deeplとの連携
		event = { "CmdlineEnter" },
		dependencies = { "gw31415/deepl.vim", "gw31415/fzyselect.vim" },
		config = function()
			require("deepl-commands").setup({
				selector_func = require("fzyselect").start,
			})
		end,
	},
	{
		"gw31415/gpt.nvim",
		keys = {
			{ "<C-g>r", '<Plug>(gpt-replace)',                 mode = { "n", "x" } },
			{ "<C-g>p", function() require 'gpt'.prompt() end, mode = { "n", "i" } },
			{ "<C-g>c", function() require 'gpt'.cancel() end, },
			{ "<C-g>o", function()
				require 'gpt'.order {
					opener = "10split",
					-- opener = "call nvim_open_win(bufnr('%'), v:true, { 'external': v:true, 'width': 50, 'height': 20 })",
					setup_window = function()
						---@diagnostic disable-next-line: redundant-parameter
						vim.api.nvim_win_set_option(0, "stl", "order-result")
					end
				}
			end, },
		},
		opts = {
			api_key = function() return setup_authkey('~/.ssh/openai_api_key.txt', { prompt = 'OPENAI_API_KEY = ' }) end,
		},
		config = true,
	},
	{
		"gw31415/mastodon.nvim", -- Mastodon
		dependencies = {
			"nvim-lua/plenary.nvim",
			"rcarriga/nvim-notify",
			"kkharji/sqlite.lua",
		},
		event = "VeryLazy",
		config = function()
			require "mastodon".setup()
			vim.api.nvim_set_var("mastodon_toot_visibility", "public")
		end
	},
	{ "vim-jp/vimdoc-ja",            lazy = false }, -- 日本語のヘルプ
	{
		"vim-skk/skkeleton",                      -- 日本語入力
		keys = { { "<C-j>", "<Plug>(skkeleton-enable)", mode = { "i", "c" } } },
		lazy = false,
		dependencies = {
			"gw31415/skkeletal.vim",
			"vim-denops/denops.vim",
		},
		config = function()
			vim.api.nvim_create_autocmd("User", { pattern = "skkeleton-mode-changed", command = "redraws" })
			_G.get_skkeleton_modestring = function()
				local mode = vim.fn["skkeleton#mode"]()
				if mode == "hira" then
					return "ひら"
				elseif mode == "kata" then
					return "カタ"
				elseif mode == "hankata" then
					return "半ｶﾀ"
				elseif mode == "zenkaku" then
					return "全英"
				elseif mode == "abbrev" then
					return "Abbr"
				else -- if mode == ''
					return "英数"
				end
			end
			vim.fn["skkeletal#config"]({
				eggLikeNewline = true,
				globalJisyo = "~/.skk/SKK-JISYO.L",
				markerHenkan = "▹",
				markerHenkanSelect = "▸",
				dvorak = true,
			})

			for _, map in pairs({
				{ "input",  "<c-e>", "" },
				{ "henkan", "<c-e>", "" },
				{ "input",  "<c-n>", "henkanFirst" },
				{ "henkan", "<c-n>", "henkanForward" },
				{ "henkan", "<c-p>", "henkanBackward" },
				{ "henkan", "<bs>",  "henkanBackward" },
				{ "henkan", "<c-h>", "" },
				{ "henkan", "<c-h>", "henkanBackward" },
			}) do
				vim.fn["skkeleton#register_keymap"](map[1], map[2], map[3])
			end
		end,
	},
}, {
	defaults = {
		lazy = true,
	}
})
