---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local cmd = 'biome'
    local root_dir = nil
    if (config or {}).root_dir then
      if type(config.root_dir) == "function" then
        config.root_dir(0, function(dir) root_dir = dir end)
      elseif type(config.root_dir) == "string" then
        root_dir = config.root_dir
      end
    end
    local local_cmd = root_dir and root_dir .. '/node_modules/.bin/biome'
    if local_cmd and vim.fn.executable(local_cmd) == 1 then
      cmd = local_cmd
    end
    return vim.lsp.rpc.start({ cmd, 'lsp-proxy' }, dispatchers)
  end,
  filetypes = {
    'astro',
    'css',
    'graphql',
    'html',
    'javascript',
    'javascriptreact',
    'json',
    'jsonc',
    'svelte',
    'typescript',
    'typescript.tsx',
    'typescriptreact',
    'vue',
  },
}
