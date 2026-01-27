---@type vim.lsp.Config
return {
	on_attach = function(client, bufnr)
		local root_dir = client.config.root_dir
		local biome_configured = root_dir and vim.uv.fs_stat(root_dir .. '/biome.json') ~= nil
		local biome_running = #(vim.lsp.get_clients { name = 'biome', bufnr = bufnr }) > 0
		if biome_configured or biome_running then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end
	end,
}
