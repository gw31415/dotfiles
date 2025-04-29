---@type vim.lsp.Config
return {
	settings = {
		texlab = {
			build = {
				executable = 'tectonic',
				args = {
					'-X',
					'compile',
					'%f',
					'--synctex',
					'--keep-logs',
					'--keep-intermediates',
				},
			},
		},
	}
}
