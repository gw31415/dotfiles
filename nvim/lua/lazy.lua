local function executable(cmd)
	return vim.fn.executable(cmd) == 1
end

vim.opt_global.helplang = 'ja,en'

--------------------------------------------------------------------------------
-- Global Functions used in Statusline
--------------------------------------------------------------------------------

function _G.get_warn_count()
	local warns = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.WARN })
	return #warns
end

function _G.get_error_count()
	local errors = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
	return #errors
end

function _G.get_macro_state()
	local key = vim.fn.reg_recording()
	if key == '' then return '' end
	return '[MACRO:' .. key .. ']'
end

function _G.search_count()
	if vim.v.hlsearch == 0 then
		return ''
	end
	local count = vim.fn.searchcount { recompute = 1, maxcount = 999 }
	local current = count.current
	local total = count.total
	if current == 0 then
		return ''
	end
	return string.format('[%d/%d]', current, total)
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

if executable 'fish-lsp' then
	vim.lsp.enable 'fish_lsp'
end

if executable 'sourcekit-lsp' then
	vim.lsp.enable 'sourcekit'
end


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
vim.keymap.set('n', '<F5>', function() require 'dap'.continue() end, {})
vim.keymap.set('n', '<F10>', function() require 'dap'.step_over() end, {})
vim.keymap.set('n', '<F11>', function() require 'dap'.step_into() end, {})
vim.keymap.set('n', '<F12>', function() require 'dap'.step_out() end, {})
vim.keymap.set('n', 'bb', function() require 'dap'.toggle_breakpoint() end, {})


--------------------------------------------------------------------------------
-- fzyselect.vim - Custom tweaks
--------------------------------------------------------------------------------

vim.defer_fn(function()
	vim.ui.select = require 'fzyselect'.start
end, 500)

-- fuzzy search
vim.keymap.set('n', 'g/', function() require 'fzyselect-lines'.open() end)
-- git ls-files
vim.keymap.set('n', '<c-p>', function()
	local res = vim.system({ 'git', 'ls-files' }, { text = true }):wait()
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

--------------------------------------------------------------------------------
-- dpp.vim - Message when make_state is done
--------------------------------------------------------------------------------

vim.api.nvim_create_autocmd('User', {
	pattern = 'Dpp:makeStatePost',
	callback = function()
		vim.notify 'dpp make_state() is done'
	end,
})

--------------------------------------------------------------------------------
-- dpp.vim - Custom Commands
--------------------------------------------------------------------------------

local dpp = require 'dpp'

-- Install
vim.api.nvim_create_user_command('DppInstall', function()
	dpp.sync_ext_action('installer', 'install')
end, {})
-- Update
vim.api.nvim_create_user_command(
	'DppUpdate',
	function(opts)
		dpp.sync_ext_action('installer', 'update', { names = opts.fargs })
	end,
	{ nargs = '*' }
)
-- Clean
local dpp_cache_cwd = vim.uv.fs_realpath(vim.fn.expand '~/.cache/dpp/repos/github.com/') .. '/'
local function check_clean()
	local res = {}
	for _, dir in ipairs(dpp.check_clean()) do
		local realdir = vim.uv.fs_realpath(dir)
		if not realdir then
			goto continue
		end
		if vim.startswith(realdir, dpp_cache_cwd) then
			table.insert(res, realdir:sub(#dpp_cache_cwd + 1))
		else
			table.insert(res, dir)
		end
		::continue::
	end
	return res
end
vim.api.nvim_create_user_command('DppClean', function(opts)
	local all_dirs = check_clean()
	local dirs = #opts.fargs > 0 and opts.fargs or all_dirs

	for i = #dirs, 1, -1 do
		if not vim.tbl_contains(all_dirs, dirs[i]) then
			vim.cmd('echoerr "Unknown-Item found: ' .. dirs[i] .. '"')
			return
		end
	end
	---@type string[]
	---@diagnostic disable-next-line: assign-type-mismatch
	dirs = vim.fn.uniq(vim.fn.sort(dirs))

	if #dirs == 0 then
		vim.notify 'Nothing to clean'
		return
	end
	local choice = opts.bang and 1 or
		vim.fn.confirm('Remove ' .. #dirs .. ' directories?', #opts.fargs > 0 and '&Yes\n&No' or '&Yes\n&No\n&List', 2)
	if choice == 1 then
		vim.system({ 'trash', unpack(dirs) }, {
			cwd = dpp_cache_cwd,
		}, function()
			vim.schedule(function()
				for _, dir in ipairs(dirs) do
					vim.notify('Removed ' .. dir)
				end
			end)
		end)
	elseif choice == 3 then
		print(table.concat(dirs, '\n'))
	end
end, {
	bang = true,
	nargs = '*',
	complete = function(_, CmdLine, CursorPos)
		local prior_char = CmdLine:sub(CursorPos, CursorPos)
		if prior_char:match '%s' then
			return vim.tbl_map(vim.fn.fnameescape, check_clean())
		else
			return {}
		end
	end,
})

vim.api.nvim_create_user_command('DppMkstate', function()
	dpp.make_state('~/.cache/dpp', '~/.config/home-manager/nvim/dpp.ts')
end, {})

vim.keymap.set('n', '<c-g>p', function() require 'commitgen'.paste {} end)
vim.keymap.set('n', '<c-g>P', function() require 'commitgen'.paste { after = false } end)
vim.keymap.set('n', '<c-g>c', '<cmd>Gin commit<cr>', { silent = true })
vim.keymap.set('n', '<c-g>C', '<cmd>Gin commit --amend<cr>', { silent = true })

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
