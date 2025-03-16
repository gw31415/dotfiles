local util = require 'lspconfig.util'

return {
	default_config = {
		single_file_support = true,
		cmd = { 'fish-lsp', 'start' },
		filetypes = { 'fish' },
		root_dir = nil,
	},
	docs = {
		description = [[
	  https://www.fish-lsp.dev
	  fish-lsp is a language server protocol (LSP) implementation for the fish shell. It aims to provide a rich set of features including: auto-completion, hover, go-to references, and many others.
      ]],
		default_config = {
		},
	},
}
