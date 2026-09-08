vim.filetype.add {
	-- フルパスに対してマッチング
	pattern = {
		-- 拡張子がないので、任意のファイルパスにマッチさせる
		['.*'] = {
			---@param _ string ファイルパス
			---@param bufnr number バッファ番号
			---@return string | nil ファイルタイプ
			function(_, bufnr)
				-- 1行目を取得し、shebangか判定
				local shebang = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
				if not shebang or shebang:sub(1, 2) ~= '#!' then
					return
				end

				-- 後で使いやすいように整形
				shebang = shebang:gsub('%s+', ' ')

				-- 実行ファイルが`/usr/bin/env`の場合は、続く引数を確認
				local idx_space = shebang:find ' '
				local path = string.sub(shebang, 3, idx_space and idx_space - 1 or nil)
				if path == '/usr/bin/env' then
					if
						vim.startswith(shebang, '#!/usr/bin/env deno')
						or vim.startswith(shebang, '#!/usr/bin/env -S deno')
					then
						return 'typescript'
					end
				end

				-- コマンドがdenoならtypescript
				local cmd = vim.fs.basename(path)
				if cmd == 'deno' then
					return 'typescript'
				end
			end,
			-- どうしてもファイルタイプを判定できなかった時に使うので、
			-- priorityを下げておく
			{ priority = -math.huge },
		},
	},
}
