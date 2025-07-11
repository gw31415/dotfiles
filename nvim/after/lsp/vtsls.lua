local ft = {
	node_files = {
		'node_modules',
		'bun.lockb',     -- bun
		'package-lock.json', -- npm or bun
		'npm-shrinkwrap.json', -- npm
		'yarn.lock',     -- yarn
		'pnpm-lock.yaml', -- pnpm
	},
	node_specific_files = {
		'package.json',
		'node_modules',
		'bun.lockb',     -- bun
		'package-lock.json', -- npm or bun
		'npm-shrinkwrap.json', -- npm
		'yarn.lock',     -- yarn
		'pnpm-lock.yaml', -- pnpm
	},
}

---@type vim.lsp.Config
return {
	workspace_required = true,
	root_markers = { 'package.json' },
	root_dir = function(path, cb)
		local project_root = vim.fs.root(path, vim.iter { '.git', ft.node_files }:flatten(math.huge):totable())

		if project_root == nil then
			return
		end

		local is_node_files_found = vim.iter(ft.node_specific_files):any(function(file)
			return vim.uv.fs_stat(vim.fs.joinpath(project_root, file)) ~= nil
		end)

		if is_node_files_found then
			return cb(project_root)
		end
	end,
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
	settings = {
		typescript = {
			suggest = {
				completionFunctionCalls = true,
			},
			inlayHints = {
				parameterNames = {
					enabled = 'literals', -- 'none' | 'literals' | 'all'
					suppressWhenArgumentMatchesName = true,
				},
				parameterTypes = { enabled = false },
				variableTypes = { enabled = false },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = false },
				enumMemberValues = { enabled = true },
			},
		},
		javascript = {
			inlayHints = {
				parameterNames = {
					enabled = 'literals', -- 'none' | 'literals' | 'all'
					suppressWhenArgumentMatchesName = true,
				},
				parameterTypes = { enabled = false },
				variableTypes = { enabled = false },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = false },
				enumMemberValues = { enabled = true },
			}

		},
	}
}
