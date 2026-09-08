---@type vim.lsp.Config
return {
	settings = {
		pylsp = {
			plugins = {
				-- Disable all pylsp plugins
				mccabe = { enabled = false },
				pycodestyle = { enabled = false },
				pyflakes = { enabled = false },
				autopep8 = { enabled = false },
				yapf = { enabled = false },
			},
		},
	},
	on_attach = function(client, _)
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
}
