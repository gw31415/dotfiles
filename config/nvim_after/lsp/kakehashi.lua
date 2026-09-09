-- kakehashi (https://github.com/atusy/kakehashi)
-- 設定 (languageServers 等) は ~/.config/kakehashi/kakehashi.toml に一元管理されており、
-- Neovim 側はサーバの起動のみを行う。

---@type vim.lsp.Config
return {
	cmd = { 'kakehashi' },
	on_init = function (client)
		-- semanticTokens/full/delta を使う (upstream の scripts/minimal_init.lua と同じ)
		client.server_capabilities.semanticTokensProvider.range = false
		-- pull 診断を無効化し push のみに一本化する。
		-- kakehashi は pull 応答と push 通知の両方に同じ診断を載せるが、
		-- Neovim 0.11+ は両者を別名前空間
		-- (nvim.lsp.<name>.<id> と nvim.lsp.<name>.<id>.<pull_id>) に格納するため
		-- そのままだと全診断が2重表示になる。kakehashi の push は下流の
		-- pull 非対応サーバ (taplo 等) の分もマージ済みのため、push 残しが安全。
		client.server_capabilities.diagnosticProvider = nil
	end,
	on_attach = function (_, bufnr)
		-- kakehashi (Tree-sitter) がハイライトを担うため、最初のトークン受信で
		-- 組み込みのハイライトを停止して二重ハイライトを避ける。
		-- kakehashi がパーサを持たない言語ではトークンが来ないため、
		-- 従来どおり treesitter / syntax のハイライトが使われる。
		vim.api.nvim_create_autocmd('LspTokenUpdate', {
			buffer = bufnr,
			once = true,
			callback = function ()
				vim.opt_local.syntax = 'OFF'
				vim.treesitter.stop(bufnr)
			end
		})
	end
}
