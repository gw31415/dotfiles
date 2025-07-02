---@type vim.lsp.Config
return {
	root_markers = { 'biome.json' },
	workspace_required = true,
	cmd = function(dispatchers, config)
		local root_dir = config.root_dir
		local local_cmd = root_dir and (root_dir .. '/node_modules/.bin/biome') or ''
		local command = vim.fn.executable(local_cmd) == 1 and local_cmd or 'biome'
		return vim.lsp.rpc.start({ command, 'lsp-proxy' }, dispatchers)
	end,
}
