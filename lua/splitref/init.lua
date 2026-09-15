local M = {}

local ns = vim.api.nvim_create_namespace("splitref")
local marked_wins = {}
local hl_group = "SplitRefLine"
local padding = 2

vim.api.nvim_set_hl(0, "SplitRefLine", { default = true, bg = "#1b454c" })

--- Recalculate and apply the width of the reference split column.
local function recalc_width()
	marked_wins = vim.tbl_filter(function(entry)
		return vim.api.nvim_win_is_valid(entry.win)
	end, marked_wins)
	if #marked_wins == 0 then
		return
	end

	local max_len = 0
	for _, entry in ipairs(marked_wins) do
		if vim.api.nvim_win_is_valid(entry.win) then
			local buf = vim.api.nvim_win_get_buf(entry.win)
			local top = vim.fn.line("w0", entry.win)
			local bot = vim.fn.line("w$", entry.win)
			local lines = vim.api.nvim_buf_get_lines(buf, top - 1, bot, false)
			for _, line in ipairs(lines) do
				local w = vim.fn.strdisplaywidth(line)
				if w > max_len then
					max_len = w
				end
			end
		end
	end
	local width = math.min(max_len + padding * 2, math.floor(vim.o.columns / 2))
	vim.api.nvim_win_set_width(marked_wins[1].win, width)
end

--- Open a vertical split showing the selected lines highlighted as a reference.
--- On first call, vsplits the current window and marks the new split.
--- On subsequent calls, finds the marked window and splits from there,
--- keeping all reference panes grouped together.
---@param line1? integer start line (1-indexed)
---@param line2? integer end line (1-indexed)
function M.split_ref(line1, line2)
	-- If no lines provided, check current mode: if in visual mode use selection, else use current cursor line
	if not line1 or not line2 then
		local mode = vim.fn.mode()
		if mode == "v" or mode == "V" or mode == "\22" then
			-- Exit visual mode so the '< and '> marks are set
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
			local vstart = vim.fn.getpos("'<")
			local vend = vim.fn.getpos("'>")
			if vstart[2] > 0 and vend[2] > 0 and vstart[2] <= vend[2] then
				line1 = vstart[2]
				line2 = vend[2]
			end
		end

		if not line1 or not line2 then
			local cur = vim.api.nvim_win_get_cursor(0)
			line1 = cur[1]
			line2 = cur[1]
		end
	end

	local orig_win = vim.api.nvim_get_current_win()
	local src_buf = vim.api.nvim_get_current_buf()
	local src_file = vim.api.nvim_buf_get_name(src_buf)

	if src_file == "" then
		vim.notify("SplitRef: buffer has no file", vim.log.levels.WARN)
		return
	end

	-- Prune dead windows
	marked_wins = vim.tbl_filter(function(entry)
		return vim.api.nvim_win_is_valid(entry.win)
	end, marked_wins)

	-- If tracked windows exist, jump to the last one so the new split
	-- is created adjacent to the other reference panes.
	local has_marked = #marked_wins > 0
	if has_marked then
		vim.api.nvim_set_current_win(marked_wins[#marked_wins].win)
	else
		-- Starting fresh — clear stale highlights from any previous session
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
			end
		end
	end

	-- First invocation: vsplit; subsequent (from marked window): hsplit
	local split_cmd = has_marked and "belowright split" or "vsplit"
	vim.cmd(split_cmd)

	local new_win = vim.api.nvim_get_current_win()

	-- Create a read-only scratch buffer with the source file contents
	local new_buf = vim.api.nvim_create_buf(false, true)
	local src_lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)
	vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, src_lines)
	vim.api.nvim_win_set_buf(new_win, new_buf)
	vim.bo[new_buf].filetype = vim.bo[src_buf].filetype
	vim.bo[new_buf].buftype = "nofile"
	vim.bo[new_buf].bufhidden = "wipe"
	vim.bo[new_buf].modifiable = false
	vim.b[new_buf].snacks_animate_indent = false

	-- Position cursor on the middle point of the highlighted lines and center
	local mid_line = math.floor((line1 + line2) / 2)
	vim.api.nvim_win_set_cursor(new_win, { mid_line, 0 })
	vim.cmd("normal! $zz")
	local cur = vim.api.nvim_win_get_cursor(new_win)

	-- Track the new window
	table.insert(marked_wins, { win = new_win, line = mid_line, col = cur[2] })

	-- Disable gutter elements
	vim.wo[new_win].number = false
	vim.wo[new_win].relativenumber = false
	-- vim.wo[new_win].signcolumn = "no"
	vim.wo[new_win].foldcolumn = "0"

	-- Auto-size width to fit the longest line across all splits
	recalc_width()

	-- Highlight the referenced lines with extmarks
	for lnum = line1, line2 do
		vim.api.nvim_buf_set_extmark(new_buf, ns, lnum - 1, 0, {
			line_hl_group = hl_group,
			priority = 200,
		})
	end

	-- Recenter all tracked reference windows
	for _, entry in ipairs(marked_wins) do
		if vim.api.nvim_win_is_valid(entry.win) then
			vim.api.nvim_win_set_cursor(entry.win, { entry.line, entry.col or 0 })
			vim.api.nvim_win_call(entry.win, function()
				vim.cmd("normal! zz")
			end)
		end
	end

	-- Return focus to the original window allowing time 
	-- for snacks_animate_indent to set the indent color
	vim.schedule(function()
		if vim.api.nvim_win_is_valid(orig_win) then
			vim.api.nvim_set_current_win(orig_win)
		end
	end)
end

--- Clear all SplitRef highlights and forget the marked window.
function M.clear()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
		end
	end
	marked_wins = {}
end

--- Setup commands and highlight group.
---@param opts? { highlight_group?: string, bg?: string, padding?: integer }
function M.setup(opts)
	opts = opts or {}

	if opts.highlight_group then
		hl_group = opts.highlight_group
	end
	if opts.bg then
		vim.api.nvim_set_hl(0, hl_group, { bg = opts.bg })
	end
	padding = opts.padding or padding

	vim.api.nvim_create_user_command("SplitRef", function(cmd)
		M.split_ref(cmd.line1, cmd.line2)
	end, { range = true, desc = "Open a reference split with highlighted lines" })

	vim.api.nvim_create_user_command("SplitRefClear", function()
		M.clear()
	end, { desc = "Clear all SplitRef highlights and reset marked window" })

	local augroup = vim.api.nvim_create_augroup("SplitRef", { clear = true })
	vim.api.nvim_create_autocmd("VimResized", {
		group = augroup,
		callback = recalc_width,
	})
end

return M
