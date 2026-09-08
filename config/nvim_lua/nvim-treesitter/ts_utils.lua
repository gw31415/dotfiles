-- mattn/emmet-vim
-- Compatibility shim for plugins still requiring nvim-treesitter.ts_utils.
-- Newer nvim-treesitter versions removed this module in favor of vim.treesitter APIs.
local M = {}

local function get_parser(bufnr)
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if ok then
		return parser
	end
	return nil
end

local function get_node_at_pos(bufnr, row, col)
	if vim.treesitter.get_node then
		local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr, pos = { row, col } })
		if ok then
			return node
		end
	end

	local parser = get_parser(bufnr)
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	if not tree then
		return nil
	end

	local root = tree:root()
	return root:named_descendant_for_range(row, col, row, col)
end

function M.get_node_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	return get_node_at_pos(bufnr, row - 1, col)
end

function M.get_root_for_position(line, col, root_lang_tree)
	if root_lang_tree and root_lang_tree.tree_for_range then
		local ok, tree = pcall(root_lang_tree.tree_for_range, root_lang_tree, { line, col, line, col })
		if ok and tree then
			return tree:root()
		end
	end

	if root_lang_tree and root_lang_tree.root then
		local ok, root = pcall(root_lang_tree.root, root_lang_tree)
		if ok then
			return root
		end
	end

	local parser = get_parser(0)
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	return tree and tree:root() or nil
end

function M.is_in_node_range(node, line, col, include_end)
	if not node then
		return false
	end
	local srow, scol, erow, ecol = node:range()
	if line < srow or line > erow then
		return false
	end
	if line == srow and col < scol then
		return false
	end
	if include_end then
		if line == erow and col > ecol then
			return false
		end
	else
		if line == erow and col >= ecol then
			return false
		end
	end
	return true
end

function M.get_vim_range(range)
	return { range[1] + 1, range[2], range[3] + 1, range[4] }
end

function M.highlight_node(node, bufnr, ns, hl_group)
	if not node then
		return
	end
	bufnr = bufnr or 0
	local srow, scol, erow, ecol = node:range()
	if srow == erow then
		vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, srow, scol, ecol)
		return
	end
	vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, srow, scol, -1)
	for line = srow + 1, erow - 1 do
		vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, line, 0, -1)
	end
	vim.api.nvim_buf_add_highlight(bufnr, ns, hl_group, erow, 0, ecol)
end

function M.goto_node(node, opts)
	if not node then
		return
	end
	local srow, scol = node:range()
	if opts and opts.winid then
		vim.api.nvim_win_set_cursor(opts.winid, { srow + 1, scol })
	else
		vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
	end
end

return M
