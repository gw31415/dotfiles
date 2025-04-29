---@type vim.lsp.Config
return {
	settings = {
		Lua = {
			diagnostics = {
				unusedLocalExclude = { '_*' }
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
