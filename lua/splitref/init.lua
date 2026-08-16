local M = {}

local ns = vim.api.nvim_create_namespace("splitref")
local hl_ns = vim.api.nvim_create_namespace("splitref_hl")
local marked_wins = {}
local hl_bg = "#1b454c"

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
  vim.cmd(split_cmd .. " " .. vim.fn.fnameescape(src_file))

  local new_win = vim.api.nvim_get_current_win()
  local new_buf = vim.api.nvim_get_current_buf()

  -- Track the new window
  table.insert(marked_wins, { win = new_win, line = line1 })
  vim.w[new_win].splitref_marked = true

  -- Define the highlight only in the window-local namespace
  vim.api.nvim_set_hl(hl_ns, "SplitRefLine", { bg = hl_bg })
  vim.api.nvim_win_set_hl_ns(new_win, hl_ns)

  -- Highlight the referenced lines with extmarks
  for lnum = line1, line2 do
    vim.api.nvim_buf_set_extmark(new_buf, ns, lnum - 1, 0, {
      line_hl_group = "SplitRefLine",
      priority = 200,
    })
  end

  -- Recenter all tracked reference windows
  for _, entry in ipairs(marked_wins) do
    if vim.api.nvim_win_is_valid(entry.win) then
      vim.api.nvim_win_set_cursor(entry.win, { entry.line, 0 })
      vim.api.nvim_win_call(entry.win, function() vim.cmd("normal! zz") end)
    end
  end

  -- Return focus to the original window
  vim.api.nvim_set_current_win(orig_win)
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
---@param opts? { bg?: string }
function M.setup(opts)
  opts = opts or {}

  hl_bg = opts.bg or hl_bg

  vim.api.nvim_create_user_command("SplitRef", function(cmd)
    M.split_ref(cmd.line1, cmd.line2)
  end, { range = true, desc = "Open a reference split with highlighted lines" })

  vim.api.nvim_create_user_command("SplitRefClear", function()
    M.clear()
  end, { desc = "Clear all SplitRef highlights and reset marked window" })
end

return M
