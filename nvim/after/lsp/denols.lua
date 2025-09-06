---@type vim.lsp.Config
return {
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
}
