-----------------------------------------------------------
-- Automatically Making-State for dpp.vim
-----------------------------------------------------------

local CONFIG_REALPATH = vim.uv.fs_realpath(vim.fn.stdpath 'config')

local function is_nvimconfig(file)
	local function resolve(path)
		local resolved_path = vim.uv.fs_realpath(path)
		return resolved_path or path
	end

	local resolved_file = resolve(file)

	return resolved_file and resolved_file:sub(1, #CONFIG_REALPATH) == CONFIG_REALPATH
end

vim.api.nvim_create_autocmd('BufWritePost', {
	callback = function()
		if is_nvimconfig(vim.fn.expand '%:p') then
			-- Locking for Dpp:makeStatePost event
			local waiting = true
			local leave_lock = vim.api.nvim_create_autocmd('VimLeave', {
				callback = function()
					vim.cmd 'echo "dpp make_state() is running...."'

					-- Polling for Dpp:makeStatePost event
					while waiting do
						vim.wait(100)
					end
				end
			})

			require 'dpp'.make_state('~/.cache/dpp/', '~/.config/nvim/dpp.ts')

			vim.api.nvim_create_autocmd('User', {
				pattern = 'Dpp:makeStatePost',
				once = true,
				callback = function()
					waiting = false       -- Release the lock
					vim.api.nvim_del_autocmd(leave_lock) -- Remove the lock
				end,
			})
		end
	end
})
