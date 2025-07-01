---@type vim.lsp.Config
return {
	on_attach = function(client, bufnr)
		local biomeRunning = #(vim.lsp.get_clients { name = 'biome', bufnr = bufnr }) > 0
		client.server_capabilities.documentFormattingProvider = not biomeRunning
		client.server_capabilities.documentRangeFormattingProvider = not biomeRunning
	end,
}
