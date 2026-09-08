---@type vim.lsp.Config
return {
	settings = {
		Lua = {
			diagnostics = {
				globals = { 'vim' },
				unusedLocalExclude = { '_*' },
			},
			workspace = {
				library = { vim.env.VIMRUNTIME },
				checkThirdParty = false,
			},
			format = {
				enable = true,
				defaultConfig = {
					quote_style = 'single',
					call_arg_parentheses = 'remove',
				},
			},
		}
	}
}
