local util = require 'lspconfig.util'

return {
	default_config = {
		cmd = { 'erg', 'server' },
		filetypes = { 'erg' },
		root_dir = util.find_git_ancestor,
		single_file_support = true,
	},
	docs = {
		description = [[
	  https://github.com/erg-lang/erg
      Language server for Erg.
      ]],
		default_config = {
			root_dir = [[root_pattern(".git")]],
		},
	},
}
