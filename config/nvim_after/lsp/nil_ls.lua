---@type vim.lsp.Config
return {
	settings = {
		formatting = {
			command = { 'nixfmt' },
		},
		['nil'] = {
			flake = {
				autoArchive = true,
			}
		}
	}
}
