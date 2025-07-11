---@type vim.lsp.Config
return {
	workspace_required = true,
	root_markers = {
		'deno.json',
		'deno.jsonc',
		'deno.lock',
		'deps.ts',
		'denops',
	},
	root_dir = function(bufnr, cb)
		local found_dirs = vim.fs.find({
			'deno.json',
			'deno.jsonc',
			'deno.lock',
			'deps.ts',
			'denops',
		}, {
			upward = true,
			path = vim.fs.dirname(vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))),
		})
		if #found_dirs > 0 then
			return cb(vim.fs.dirname(found_dirs[1]))
		end
	end,
	init_options = {
		lint = true,
		unstable = true,
		suggest = {
			imports = {
				hosts = {
					['https://deno.land'] = true,
					['https://cdn.nest.land'] = true,
					['https://crux.land'] = true,
				},
			},
		},
	},
	on_attach = function(client, bufnr)
		local biomeRunning = #(vim.lsp.get_clients { name = 'biome', bufnr = bufnr }) > 0
		if not biomeRunning then
			local found_dirs = vim.fs.find('biome.json',
				{
					upward = true,
					path = vim.fs.dirname(vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))),
				})
			if #found_dirs > 0 then
				biomeRunning = true
			end
		end
		client.server_capabilities.documentFormattingProvider = not biomeRunning
		client.server_capabilities.documentRangeFormattingProvider = not biomeRunning
	end,
}
