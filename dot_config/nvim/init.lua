--[[
-- 依存: NVim nightly, Git, cURL, Deno
-- siliconコマンドがあれば対応。
-- ]]
-- Emacs Keybindings

vim.keymap.set("i", "<c-f>", "<c-g>U<right>", {})
vim.keymap.set("i", "<c-b>", "<c-g>U<left>", {})
vim.keymap.set("i", "<c-p>", "<c-g>U<up>", {})
vim.keymap.set("i", "<c-n>", "<c-g>U<down>", {})
vim.keymap.set("i", "<c-d>", "<c-g>U<del>", {})
vim.cmd([[ inoremap <expr> <c-a> col('.') == match(getline('.'), '\S') + 1 ?
         \ repeat('<C-G>U<Left>', col('.') - 1) :
		 \ (col('.') < match(getline('.'), '\S') ?
         \     repeat('<C-G>U<Right>', match(getline('.'), '\S') + 0) :
         \     repeat('<C-G>U<Left>', col('.') - 1 - match(getline('.'), '\S')))]])
vim.cmd([[ inoremap <expr> <c-e> repeat('<C-G>U<Right>', col('$') - col('.')) ]])
vim.keymap.set("c", "<c-f>", "<right>", {})
vim.keymap.set("c", "<c-b>", "<left>", {})
vim.keymap.set("c", "<c-p>", "<up>", {})
vim.keymap.set("c", "<c-n>", "<down>", {})
vim.keymap.set("c", "<c-d>", "<del>", {})
vim.keymap.set("c", "<c-a>", "<home>", {})
vim.keymap.set("c", "<c-e>", "<end>", {})

vim.api.nvim_create_autocmd("BufRead", {
	pattern = "*.mdx",
	callback = function() vim.bo.filetype = "markdown" end,
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

vim.keymap.set("n", "<C-n>", "<cmd>Fern . -drawer -toggle -reveal=% <cr>")

function _G.lsp_onattach_func(_, bufnr)
	vim.api.nvim_create_user_command("Implementation", function()
		vim.lsp.buf.implementation()
	end, { force = true })
	local bufopts = { silent = true, buffer = bufnr }
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
	vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
	vim.keymap.set("n", "<C-j>", vim.diagnostic.goto_next, bufopts)
	vim.keymap.set("n", "<C-k>", vim.diagnostic.goto_prev, bufopts)
	vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, bufopts)
	vim.keymap.set("n", "cI", vim.lsp.buf.rename, bufopts)
	vim.keymap.set("n", "z*", vim.lsp.buf.references, bufopts)
	vim.keymap.set("n", "gqae", function() vim.lsp.buf.format({ async = true }) end, { buffer = bufnr, nowait = true })
	-- vim.api.nvim_create_autocmd('BufWritePre', {
	-- 	callback = function() vim.lsp.buf.format { async = false } end,
	-- 	buffer = bufnr,
	-- })
end

-- Configure
vim.o.tabstop = 4
vim.o.shiftwidth = 4
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
vim.opt.guifont = { "HackGenNerd Console", "h13" }
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
vim.api.nvim_set_var("loaded_matchit", true)
vim.api.nvim_set_var("loaded_netrwPlugin", true)
vim.api.nvim_set_var("loaded_remote_plugins", true)
vim.api.nvim_set_var("skip_loading_mswin", true)
vim.api.nvim_set_var("loaded_tutor_mode_plugin", true)
vim.api.nvim_set_var("loaded_2html_plugin", true)

--LaTeXの自動コンパイル設定
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*.tex",
	once = true,
	callback = function()
		if not vim.fn.executable("latexmk") then
			return
		end
		vim.api.nvim_create_augroup("LaTeXAutomk", {})
		vim.api.nvim_create_user_command("LaTeXAutomkToggle", function()
			if vim.b["latex_automk_enabled"] == nil then
				vim.api.nvim_buf_set_var(0, "latex_automk_enabled", false)
			end
			local enabled = not vim.api.nvim_buf_get_var(0, "latex_automk_enabled")
			vim.api.nvim_buf_set_var(0, "latex_automk_enabled", enabled)
			if enabled then
				vim.notify("latex automk enabled.")
			else
				vim.notify("latex automk disabled.")
			end
			if enabled then
				vim.api.nvim_create_autocmd("BufWritePost", {
					group = "LaTeXAutomk",
					callback = function()
						vim.fn.jobstart({ "latexmk", vim.fn.bufname() })
					end,
				})
			else
				vim.api.nvim_clear_autocmds({ group = "LaTeXAutomk" })
			end
		end, {})
	end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
	vim.fn.system({ "git", "-C", lazypath, "checkout", "tags/stable" }) -- last stable release
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
	"nvim-lua/plenary.nvim",
	"vim-denops/denops.vim",

	-- Games
	{ "eandrju/cellular-automaton.nvim", cmd = "CellularAutomaton" },
	{ "gw31415/nvim-tetris",                cmd = "Tetris" },
	{ "seandewar/nvimesweeper",          cmd = "Nvimesweeper" },

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
		},
		ft = "org",
		config = function()
			vim.keymap.set('n', '<Leader>o', '<Nop>', {})
			require("orgmode").setup_ts_grammar()
			require("orgmode").setup({
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
			vim.api.nvim_create_autocmd("BufRead", {
				pattern = "*.org",
				callback = function()
					vim.opt_local.formatoptions:append('mM')
					vim.wo.foldlevel = 0
					vim.bo.expandtab = true
					vim.bo.tabstop = 1
					vim.bo.shiftwidth = 1
				end
			})
		end,
	},
	{
		"akinsho/flutter-tools.nvim",
		ft = { "dart" },
		config = true,
		opts = {
			lsp = {
				on_attach = _G.lsp_onattach_func,
			},
		},
	},
	{
		"tranvansang/octave.vim",
		ft = { "matlab", "octave" },
	},

	-- LSP
	{
		"williamboman/mason.nvim", -- LSP Installer
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
			"neovim/nvim-lspconfig",
			{
				"folke/neodev.nvim",
				ft = "lua",
				config = true,
				opts = {
					override = function(_, library)
						library.enabled = true
						library.plugins = true
					end,
				},
			},
		},
		event = "VeryLazy",
		config = function()
			require("mason").setup({})
			local mason_lspconfig = require("mason-lspconfig")
			local capabilities =
				require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
			mason_lspconfig.setup_handlers({
				function(server_name)
					local opts = {
						capabilities = capabilities,
						on_attach = function(i, bufnr)
							---@diagnostic disable-next-line: redundant-parameter
							vim.api.nvim_buf_set_option(bufnr, "formatexpr",
								---@diagnostic disable-next-line: redundant-parameter
								"v:lua.vim.lsp.formatexpr(#{timeout_ms:250})")
							_G.lsp_onattach_func(i, bufnr)
						end,
						settings = {
							Lua = {
								workspace = { checkThirdParty = false },
								completion = { callSnippet = "Replace" },
							},
							["rust-analyzer"] = {
								checkOnSave = {
									command = "clippy",
								},
							},
						},
					}
					require("lspconfig")[server_name].setup(opts)
				end,
			})
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
		"jose-elias-alvarez/null-ls.nvim",
		event = "VeryLazy",
		dependencies = { "williamboman/mason.nvim", "nvim-lua/plenary.nvim" },
		config = function()
			local mason = require("mason")
			local mason_package = require("mason-core.package")
			local mason_registry = require("mason-registry")
			local null_ls = require("null-ls")
			mason.setup({})
			local null_sources = {}
			for _, package in ipairs(mason_registry.get_installed_packages()) do
				local package_categories = package.spec.categories[1]
				if package_categories == mason_package.Cat.Formatter then
					table.insert(null_sources, null_ls.builtins.formatting[package.name])
				elseif package_categories == mason_package.Cat.Linter then
					table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
				end
			end
			null_ls.setup({
				sources = null_sources,
				on_attach = _G.lsp_onattach_func,
			})
		end,
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
		event = { "LspAttach" },
		config = function()
			vim.api.nvim_create_autocmd("VimLeavePre", { command = "silent! FidgetClose" })
			require("fidget").setup()
		end,
	},
	{
		"ray-x/lsp_signature.nvim", -- 関数の引数の入力時のシグネチャヘルプ
		event = { "LspAttach" },
		config = true,
	},
	{
		"numToStr/Comment.nvim", -- コメントのトグル
		event = { "LspAttach" },
		config = true,
	},

	-- Debug Adapter Protocol
	{
		"mfussenegger/nvim-dap",
		dependencies = { "rcarriga/nvim-dap-ui" },
		keys = { "<F5>", "<F10>", "<F11>", "<F12>", "bb", },
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

			vim.keymap.set("n", "<F5>", function()
				require("dap").continue()
			end, {})
			vim.keymap.set("n", "<F10>", function()
				require("dap").step_over()
			end, {})
			vim.keymap.set("n", "<F11>", function()
				require("dap").step_into()
			end, {})
			vim.keymap.set("n", "<F12>", function()
				require("dap").step_out()
			end, {})
			vim.keymap.set("n", "bb", function()
				require("dap").toggle_breakpoint()
			end, {})
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
		"rcarriga/cmp-dap",
		dependencies = { "hrsh7th/nvim-cmp", "mfussenegger/nvim-dap" },
		config = function()
			require("cmp").setup({
				enabled = function()
					---@diagnostic disable-next-line: redundant-parameter
					return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt" or require("cmp_dap").is_dap_buffer()
				end,
			})
			require("cmp").setup.filetype({ "dap-repl", "dapui_watches" }, {
				sources = {
					{ name = "dap" },
				},
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
	{ "hrsh7th/vim-vsnip",                   event = "InsertEnter" },
	{
		"hrsh7th/nvim-cmp",
		dependencies = { "onsails/lspkind.nvim" },
		config = function()
			local cmp = require("cmp")
			local function feedkeys(keys)
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true) or "", "", true)
			end

			cmp.setup({
				snippet = {
					expand = function(args)
						vim.fn["vsnip#anonymous"](args.body)
					end,
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "vsnip" },
					{ name = "buffer" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "skkeleton" },
					{ name = "path" },
				}),
				formatting = {
					format = require("lspkind").cmp_format({
						mode = "symbol_text",
					}),
				},
				mapping = {
					["<c-n>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<c-p>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-e>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.abort()
						else
							fallback()
						end
					end),
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
					end, { "i", "s", "c" }),
					["<s-tab>"] = cmp.mapping(function(fallback)
						if vim.fn["vsnip#jumpable"](-1) == 1 then
							feedkeys("<Plug>(vsnip-jump-prev)")
						else
							fallback()
						end
					end, { "i", "s", "c" }),
				},
			})
			cmp.setup.filetype("octave", {
				sources = cmp.config.sources({
					{ name = "omni" },
				}),
			})
			cmp.setup.filetype("org", {
				sources = cmp.config.sources({
					{ name = "orgmode" },
					{ name = "path" },
					{ name = "skkeleton" },
					{ name = "vsnip" },
					{ name = "buffer" },
				}),
			})
			cmp.setup.filetype({ "org", "markdown" }, {
				sources = cmp.config.sources({
					{ name = "emoji" },
				}),
			})
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "cmdline" },
				}),
			})
			for _, c in pairs({ "/", "?" }) do
				cmp.setup.cmdline(c, {
					mapping = cmp.mapping.preset.cmdline(),
					sources = cmp.config.sources({
						{ name = "buffer" },
					}),
				})
			end
		end,
	},
	{ "hrsh7th/cmp-vsnip",                   dependencies = "hrsh7th/nvim-cmp", event = "InsertCharPre" },
	{ "hrsh7th/cmp-nvim-lsp-signature-help", dependencies = "hrsh7th/nvim-cmp", event = "InsertCharPre" },
	{ "hrsh7th/cmp-cmdline",                 dependencies = "hrsh7th/nvim-cmp", event = "CmdlineEnter" },
	{ "hrsh7th/cmp-path",                    dependencies = "hrsh7th/nvim-cmp", event = "InsertCharPre" },
	{ "hrsh7th/cmp-omni",                    dependencies = "hrsh7th/nvim-cmp", event = "InsertCharPre" },
	{
		"hrsh7th/cmp-buffer",
		dependencies = "hrsh7th/nvim-cmp",
		event = { "InsertCharPre", "CmdlineEnter" }
	},
	{ "uga-rosa/cmp-skkeleton", dependencies = "hrsh7th/nvim-cmp", event = "InsertCharPre" },
	{ "hrsh7th/cmp-emoji",      dependencies = "hrsh7th/nvim-cmp", event = "InsertCharPre" },

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
	"lambdalisue/readablefold.vim", -- より良い foldtext
	{
		"monaqa/dial.nvim",      -- 拡張版<C-a><C-x>
		keys = {
			{ "<C-a>" },
			{ "<C-x>" },
			{ "<C-a>",  mode = "v" },
			{ "<C-x>",  mode = "v" },
			{ "g<C-a>", mode = "v" },
			{ "g<C-x>", mode = "v" },
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
			vim.keymap.set("n", "<C-a>", require("dial.map").inc_normal(), { noremap = true })
			vim.keymap.set("n", "<C-x>", require("dial.map").dec_normal(), { noremap = true })
			vim.keymap.set("v", "<C-a>", require("dial.map").inc_visual(), { noremap = true })
			vim.keymap.set("v", "<C-x>", require("dial.map").dec_visual(), { noremap = true })
			vim.keymap.set("v", "g<C-a>", require("dial.map").inc_gvisual(), { noremap = true })
			vim.keymap.set("v", "g<C-x>", require("dial.map").dec_gvisual(), { noremap = true })
		end,
	},
	-- 'andymass/vim-matchup',

	-- ファイラ
	{
		"gw31415/onlybrowsex.vim",
		keys = { "gx" },
		config = function()
			vim.keymap.set("n", "gx", function()
				vim.fn["onlybrowsex#BrowseX"](vim.fn.expand("<cfile>"))
			end, { noremap = true, silent = true })
		end,
	},
	"lambdalisue/nerdfont.vim",
	{
		"lambdalisue/fern.vim",
		cmd = "Fern",
		dependencies = {
			"lambdalisue/fern-renderer-nerdfont.vim",
			"lambdalisue/nerdfont.vim",
			"lambdalisue/fern-git-status.vim",
		},
		config = function()
			vim.api.nvim_set_var("fern#renderer", "nerdfont")
			vim.api.nvim_set_var("fern#renderer#nerdfont#indent_markers", 1)
		end,
	},
	{ "lambdalisue/fern-hijack.vim", lazy = false },
	{
		"gw31415/fzyselect.vim", -- vim.ui.select
		config = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "fzyselect",
				callback = function()
					vim.keymap.set("n", "i", "<Plug>(fzyselect-fzy)", { buffer = true })
					vim.keymap.set("n", "<cr>", "<Plug>(fzyselect-retu)", { buffer = true })
					vim.keymap.set("n", "<esc>", "<cmd>clo<cr>", { buffer = true })
				end,
			})
			-- Line Selector
			vim.cmd(
				"nn gl <cmd>cal fzyselect#start(getline(1, '$'), #{prompt:'Fuzzy search'}, {_,i->i==v:null?v:null:cursor(i, 0)})<cr>"
			)
			-- git ls-files
			vim.cmd([[
				fu! s:fzyselect_lsfiles() abort
					let out = system(['git', 'ls-files'])
					if v:shell_error
						echo out
					el
						cal fzyselect#start(split(out, '\n'), #{prompt:'git ls-files'}, {p-><SID>edit(p)})
					en
				endfu
				fu! s:edit(path) abort
					if a:path != v:null
						exe 'e ' .. a:path
					en
				endfu
				nn <c-p> <cmd>cal <SID>fzyselect_lsfiles()<cr>
			]])

			-- Buffer Selector
			vim.cmd([[
				fu! s:buffer(i) abort
					if a:i != v:null
						exe 'b ' .. a:i
					en
				endfu
				nn B <cmd>cal fzyselect#start(
							\ filter(range(1, bufnr('$')), 'buflisted(v:val)'),
							\ #{prompt:'Select buffer',format_item:{i->split(execute('ls!'), "\n")[i-1]}},
							\ {li-><SID>buffer(li)})<cr>
			]])
			vim.ui.select = require("fzyselect").start
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter", -- Treesitter
		config = function()
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
				ensure_installed = { 'org' },
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
		"David-Kunz/treesitter-unit",
		dependencies = "nvim-treesitter/nvim-treesitter",
		keys = {
			{ "iu", mode = "x" },
			{ "au", mode = "x" },
			{ "iu", mode = "o" },
			{ "au", mode = "o" },
		},
		config = function()
			local opts = { noremap = true, silent = true }
			vim.keymap.set("x", "iu", '<cmd>lua require"treesitter-unit".select(false)<CR>', opts)
			vim.keymap.set("x", "au", '<cmd>lua require"treesitter-unit".select(true)<CR>', opts)
			vim.keymap.set("o", "iu", ':<c-u>lua require"treesitter-unit".select(false)<CR>', opts)
			vim.keymap.set("o", "au", ':<c-u>lua require"treesitter-unit".select(true)<CR>', opts)
		end,
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
		dependencies = "nvim-treesitter/nvim-treesitter",
		event = "VeryLazy",
		init = function()
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
		config = function()
			vim.api.nvim_set_var("indent_blankline_indent_level", 4)
			vim.api.nvim_set_var("indent_blankline_use_treesitter", true)
			vim.opt.list = true
			vim.opt.listchars:append("tab:│ ")
			require("indent_blankline").setup({
				space_char_blankline = " ",
				show_current_context = true,
				show_current_context_start = true,
			})
		end,
	},
	{
		"nmac427/guess-indent.nvim",
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

	-- 小機能追加
	"rbtnn/vim-ambiwidth", -- 曖昧幅な文字の文字幅設定

	{
		"cohama/lexima.vim", -- 自動括弧閉じ
		event = "InsertEnter",
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
			{ "c", mode = "o" },
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
		"osyo-manga/vim-operator-stay-cursor", -- カーソルを固定したOperatorをつくる
		keys = "gq",
		dependencies = "kana/vim-operator-user",
		config = function()
			vim.cmd('nmap <expr> gq operator#stay_cursor#wrapper("gq")')
		end,
	},
	{
		"gbprod/substitute.nvim", -- vim-operator-replace
		keys = {
			{ "_", mode = "n" },
			{ "_", mode = "x" },
		},
		config = function()
			require("substitute").setup({})
			vim.keymap.set("n", "_", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })
			vim.keymap.set("n", "__", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
			vim.keymap.set("x", "_", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })
		end,
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
		"lambdalisue/gin.vim", -- Git連携
		event = "VeryLazy",
		config = function()
			vim.api.nvim_set_var("gin_patch_default_args", { "++no-head", "%" })
		end,
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
		"phaazon/hop.nvim", -- 画面内ジャンプ
		keys = { {
			"<Space>",
			function()
				require("hop").hint_words({ multi_windows = true })
			end,
		} },
		config = true,
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
			vim.api.nvim_set_var("winresizer_start_key", "<C-W>c")
		end,
	},
	{ "thinca/vim-partedit", event = "CmdlineEnter" }, -- 分割編集
	{
		"navarasu/onedark.nvim",                    -- テーマ
		lazy = false,
		config = function()
			require("onedark").setup({
				style = "darker",
				code_style = {
					comments = "none",
					functions = "bold",
					keywords = "none",
				},
				highlights = { ParenMatch = { fg = "$red", bg = "$bg_yellow" } },
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
			{ "<C-g>", mode = "n" },
			{ "<C-g>", mode = "x" },
			{ "<C-g>", mode = "i" },
		},
		config = function()
			local function setup_authkey(path)
				---@diagnostic disable: param-type-mismatch
				path = vim.fn.expand(path, nil, nil)
				local key
				if vim.fn.filereadable(path) == 1 then
					key = vim.fn.trim(vim.fn.readfile(path, nil, 1)[1])
				else
					key = vim.fn.input('OPENAI_API_KEY = ')
					if key == '' then
						return nil
					end
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

			require 'gpt'.setup {
				api_key = function() return setup_authkey('~/.ssh/openai_api_key.txt') end,
			}

			vim.keymap.set({ 'n', 'x' }, '<C-g>r', '<Plug>(gpt-replace)')
			vim.keymap.set({ 'n', 'i' }, '<C-g>p', require 'gpt'.prompt)
			vim.keymap.set('n', '<C-g>c', require 'gpt'.cancel)
			vim.keymap.set('n', '<C-g>o', function()
				require 'gpt'.order {
					opener = "10split",
					setup_window = function()
						---@diagnostic disable-next-line: redundant-parameter
						vim.api.nvim_win_set_option(0, "stl", "order-result")
					end
				}
			end)
		end
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
	{ "vim-jp/vimdoc-ja",    lazy = false }, -- 日本語のヘルプ
	{
		"vim-skk/skkeleton",              -- 日本語入力
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = { "gw31415/skkeletal.vim", "vim-denops/denops.vim" },
		config = function()
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

			vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-enable)", {})
			vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-enable)", {})
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
