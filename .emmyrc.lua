-- emmylua_ls 用プロジェクト設定 (Neovim からは kakehashi 経由で起動)。
-- Lua スクリプトとして評価され、os / table / string 等の標準ライブラリのみ利用可 (io なし)。
local vimruntime = os.getenv 'VIMRUNTIME'
local home = os.getenv 'HOME'
local cache_home = os.getenv 'XDG_CACHE_HOME'
if cache_home == nil or cache_home == '' then
	cache_home = home ~= nil and home ~= '' and home .. '/.cache' or nil
end
-- rsplug が ~/.cache/rsplug/pack/_gen/opt/<hash>/lua/ 以下に展開した
-- プラグイン群を library に追加し、require 'plugin-name' を解決する。
local rsplug_opt = cache_home ~= nil and cache_home ~= '' and cache_home .. '/rsplug/pack/_gen/opt' or nil

local library = {}
-- vim.api 等の型は $VIMRUNTIME を実行時に解決して読み込む
-- (未設定環境では空リストで動くようガード)。
if vimruntime ~= nil and vimruntime ~= '' then library[#library + 1] = vimruntime end
if rsplug_opt ~= nil and rsplug_opt ~= '' then
	library[#library + 1] = {
		path = rsplug_opt,
		-- cellwidths の templates/*.lua は UTF-8 でないデータファイルのため除外。
		ignoreGlobs = { '**/cellwidths/templates/*' }
	}
end

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
		library = library
	}
}
