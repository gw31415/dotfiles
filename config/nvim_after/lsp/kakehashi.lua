-- kakehashi (https://github.com/atusy/kakehashi)
-- 設定 (languageServers 等) は ~/.config/kakehashi/kakehashi.toml に一元管理されており、
-- Neovim 側はサーバの起動のみを行う。

---@type vim.lsp.Config
return {
	cmd = { 'kakehashi' },
	on_init = function(client)
		-- semanticTokens/full/delta を使う (upstream の scripts/minimal_init.lua と同じ)
		client.server_capabilities.semanticTokensProvider.range = false
	end,
	on_attach = function(_, bufnr)
		-- kakehashi (Tree-sitter) がハイライトを担うため、最初のトークン受信で
		-- 組み込みのハイライトを停止して二重ハイライトを避ける。
		-- kakehashi がパーサを持たない言語ではトークンが来ないため、
		-- 従来どおり treesitter / syntax のハイライトが使われる。
		vim.api.nvim_create_autocmd('LspTokenUpdate', {
			buffer = bufnr,
			once = true,
			callback = function()
				vim.opt_local.syntax = 'OFF'
				vim.treesitter.stop(bufnr)
			end,
		})
	end,
}
