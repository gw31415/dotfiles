vim.opt.runtimepath:prepend '$HOME/.cache/dpp/repos/github.com/Shougo/dpp.vim'
local dpp = require 'dpp'

local dpp_base = '~/.cache/dpp/'

vim.opt.runtimepath:append '$HOME/.cache/dpp/repos/github.com/Shougo/dpp-ext-toml'
vim.opt.runtimepath:append '$HOME/.cache/dpp/repos/github.com/Shougo/dpp-protocol-git'
vim.opt.runtimepath:append '$HOME/.cache/dpp/repos/github.com/Shougo/dpp-ext-lazy'
vim.opt.runtimepath:append '$HOME/.cache/dpp/repos/github.com/Shougo/dpp-ext-installer'

if dpp.load_state(dpp_base) then
    vim.opt.runtimepath:prepend '$HOME/.cache/dpp/repos/github.com/vim-denops/denops.vim'

    vim.api.nvim_create_autocmd('User', {
        pattern = 'DenopsReady',
        callback = function()
            vim.notify 'Recreating state'
            dpp.make_state(dpp_base, '~/.config/nvim/dpp.ts')
        end
    })
end

------------------------
-- Personal settings
------------------------
vim.api.nvim_create_autocmd('CursorHold', {
    once = true,
    command = 'source $HOME/.config/nvim/lazy.vim'
})

vim.opt_global.encoding = 'utf-8'
vim.opt_global.fencs = { 'utf-8', 'iso-2022-jp', 'euc-jp', 'sjis' }
vim.g.loaded_netrwPlugin = true
vim.g.loaded_remote_plugins = true
vim.g.skip_loading_mswin = true
vim.g.loaded_tutor_mode_plugin = true
vim.g.loaded_2html_plugin = true
vim.o.winblend = 20
vim.o.pumblend = 20
vim.wo.number = true
vim.go.guifont = 'HackGen_Console_NF:h14'

vim.cmd [[
se ut=1
au CursorHold * ++once se ut=4000
autocmd BufRead *.typ setfiletype typst
autocmd BufRead *.tf setfiletype terraform
try | colorscheme onedark | catch | endtry
]]

function _G.get_warn_count()
    local warns = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.WARN })
    return #warns
end

function _G.get_error_count()
    local errors = vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
    return #errors
end

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function()
        vim.opt_local.formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms:250})'

        vim.diagnostic.config { signs = false }
        vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
            vim.lsp.handlers.hover,
            { border = 'single', title = 'hover' }
        )
        vim.api.nvim_create_user_command('Implementation', function()
            vim.lsp.buf.implementation()
        end, { force = true })
        local bufopts = { silent = true, buffer = true }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', 'K', function()
            local winid = require 'ufo'.peekFoldedLinesUnderCursor()
            if not winid then
                vim.lsp.buf.hover()
            end
        end, bufopts)
        -- vim.keymap.set("n", "<C-j>", vim.diagnostic.goto_next, bufopts) -- Now default mapping is `]d`
        -- vim.keymap.set("n", "<C-k>", vim.diagnostic.goto_prev, bufopts) -- Now default mapping is `[d`
        vim.keymap.set('n', 'glr', vim.lsp.buf.code_action, bufopts)
        vim.keymap.set('n', 'gln', vim.lsp.buf.rename, bufopts)
        vim.keymap.set('n', 'z*', vim.lsp.buf.references, bufopts)
        vim.keymap.set('i', '<C-S>', vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set('n', 'gqae', function()
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
    end,
})

-- Ignore startup treesitter errors
vim.treesitter.start = (function(wrapped)
    return function(bufnr, lang)
        lang = lang or vim.fn.getbufvar(bufnr or '', '&filetype')
        pcall(wrapped, bufnr, lang)
    end
end)(vim.treesitter.start)
