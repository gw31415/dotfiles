vim.api.nvim_create_autocmd('User', {
    pattern = 'Dpp:makeStatePost',
    callback = function()
        vim.notify 'dpp make_state() is done'
    end,
})

-- install
vim.api.nvim_create_user_command('DppInstall', "call dpp#async_ext_action('installer', 'install')", {})
-- update
vim.api.nvim_create_user_command(
    'DppUpdate',
    function(opts)
        local args = opts.fargs
        vim.fn['dpp#async_ext_action']('installer', 'update', { names = args })
    end,
    { nargs = '*' }
)

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
    if key == '' then return ' ' end
    return '[MACRO:' .. key .. ']'
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
            if not winid then vim.lsp.buf.hover() end
        end, bufopts)
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
    end,
})
