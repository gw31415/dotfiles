---@type vim.lsp.Config
return {
	on_attach = function(client, bufnr)
		local biomeRunning = #(vim.lsp.get_clients { name = 'biome', bufnr = bufnr }) > 0
		local hasFormatterConfigFile = vim.fs.find({
				'biome.json',
				'.biome.json',
				'.oxfmtrc.json',
			},
			{ path = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)), upward = true })[1] ~= nil
		client.server_capabilities.documentFormattingProvider = not (biomeRunning or hasFormatterConfigFile)
		client.server_capabilities.documentRangeFormattingProvider = not (biomeRunning or hasFormatterConfigFile)
	end,
}
