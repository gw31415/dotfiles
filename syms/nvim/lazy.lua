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

--------------------------------------------------------------------------------
-- Global Mappings/Configs used in LSP
--------------------------------------------------------------------------------

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
    dpp.async_ext_action('installer', 'install')
end, {})
-- Update
vim.api.nvim_create_user_command(
    'DppUpdate',
    function(opts)
        dpp.async_ext_action('installer', 'update', { names = opts.fargs })
    end,
    { nargs = '*' }
)
-- Clean
vim.api.nvim_create_user_command('DppClean', function(opts)
    local dirs = dpp.check_clean()
    if #dirs == 0 then
        vim.notify 'Nothing to clean'
        return
    end
    local choice = opts.bang and 1 or vim.fn.confirm('Remove ' .. #dirs .. ' directories?', '&Yes\n&No\n&List', 2)
    if choice == 1 then
        vim.system({ 'trash', unpack(dirs) }, nil, function()
            vim.schedule(function()
                for _, dir in ipairs(dirs) do
                    vim.notify('Removed ' .. dir)
                end
            end)
        end)
    elseif choice == 3 then
        print(table.concat(dirs, '\n'))
    end
end, { bang = true })
