-- emmylua_ls 用プロジェクト設定 (Neovim からは kakehashi 経由で起動)。
-- Lua スクリプトとして評価され、os / table / string 等の標準ライブラリのみ利用可。
local vimruntime = os.getenv 'VIMRUNTIME'

return {
	['$schema'] = 'https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json',
	-- Neovim 添付の Lua は LuaJIT。
	runtime = {
		version = 'LuaJIT'
	},
	diagnostics = {
		globals = { 'vim' }
	},
	workspace = {
		-- vim.api 等の型は $VIMRUNTIME を実行時に解決して読み込む
		-- (未設定環境では空リストで動くようガード)。
		library = vimruntime ~= nil and vimruntime ~= '' and { vimruntime } or {}
	}
}
