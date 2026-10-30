vim.loader.enable()
dofile(vim.fn.expand '~/.cache/rsplug/init.lua')

-- rsplug --watch (LaunchAgent / systemd) が新しい世代を公開したら知らせる。
-- RSPLUG_GENERATION で世代を固定して起動したときは知らせない。
local ok, rsplug = pcall(require, 'rsplug')
if ok and not vim.env.RSPLUG_GENERATION then
	rsplug.watch(function(latest)
		local hint = vim.fn.exists(':restart') == 2 and ':restart で反映できます' or 'Neovim を再起動すると反映されます'
		vim.notify(('rsplug: 新しい世代 %s を公開しました。%s'):format(latest:sub(1, 8), hint))
	end)
end
