return {
	default_config = {
		cmd = { 'npm', 'run', 'watch' },
		filetypes = { 'markdown' },
		get_root_dir = function ()
			return nil
		end,
		single_file_support = true,
	},
}
