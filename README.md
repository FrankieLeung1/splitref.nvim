# splitref.nvim

A lightweight Neovim plugin to open reference code snippets side-by-side in split windows with custom highlights.

## Features

- **Side-by-side reference splits**: Instantly split out lines from a buffer into dedicated reference windows.
- **Grouped reference panes**: The first invocation creates a vertical split (`vsplit`), while subsequent calls stack in the reference column.
- **Visual line highlighting**: Highlights the exact line range being referenced in the split window.
- **Auto-centering**: Automatically centers the target reference line (`zz`) in the newly opened window.
- **Dynamic auto-sizing**: Automatically calculates the split column width to fit the longest line (plus padding, capped at half the screen width) and recalculates on `VimResized`.
- **Read-only scratch buffers**: Opens copies in non-modifiable scratch buffers (`buftype = "nofile"`) with gutter elements disabled for a clean reference view.
- **Easy clearing**: Clear all reference highlights and reset state with a single command.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "splitref.nvim", -- or "your-username/splitref.nvim"
  config = function()
    require("splitref").setup({
      bg = "#1b454c", -- Optional custom background highlight color
      padding = 2,    -- Optional padding for split width calculation
    })
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "splitref.nvim",
  config = function()
    require("splitref").setup()
  end
}
```

## Usage

### Commands

- `:SplitRef`  
  Opens a reference split window. Works with ranges in Normal or Visual mode.
  - In **Visual mode**: Select a range of lines and run `:SplitRef`.
  - In **Normal mode**: Run `:SplitRef` to split out the current line, or specify a range like `:10,20SplitRef`.

- `:SplitRefClear`  
  Clears all `splitref.nvim` extmarks/highlights across buffers and resets window tracking state.

### Lua API

- `require("splitref").split_ref(line1, line2)` — Opens a reference split for the specified line range (or visual selection / cursor line if omitted).
- `require("splitref").clear()` — Clears all reference highlights and resets tracked windows.

### Keymaps Example

You can set up convenient keymaps in your configuration:

```lua
vim.keymap.set({ "n", "v" }, "<leader>sr", ":SplitRef<CR>", { desc = "Split reference" })
vim.keymap.set("n", "<leader>sc", ":SplitRefClear<CR>", { desc = "Clear split references" })
```

## Configuration

By default, the plugin creates a `SplitRefLine` highlight group with `{ bg = "#1b454c" }`. You can customize it directly via your colorscheme / `vim.api.nvim_set_hl`:

```lua
vim.api.nvim_set_hl(0, "SplitRefLine", { bg = "#1b454c" })
```

Or pass configuration options to the `setup` function:

```lua
require("splitref").setup({
  highlight_group = "SplitRefLine", -- Custom highlight group name (default: "SplitRefLine")
  bg = "#1b454c",                  -- Or directly override the background color
  padding = 2,                      -- Padding added to each side of auto-calculated width (default: 2)
})
```

## License

MIT
