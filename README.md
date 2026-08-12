# splitref.nvim

A lightweight Neovim plugin to open reference code snippets side-by-side in split windows with custom highlights.

## Features

- **Side-by-side reference splits**: Instantly split out lines from a buffer into dedicated reference windows.
- **Grouped reference panes**: The first invocation creates a vertical split (`vsplit`), while subsequent calls stack horizontally/vertically in the reference column.
- **Visual line highlighting**: Highlights the exact line range being referenced in the split window.
- **Auto-centering**: Automatically centers the target reference line (`zz`) in the newly opened window.
- **Easy clearing**: Clear all reference highlights and reset state with a single command.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "splitref.nvim", -- or "your-username/splitref.nvim"
  config = function()
    require("splitref").setup({
      bg = "#1b454c", -- Optional custom background highlight color
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

### Keymaps Example

You can set up convenient keymaps in your configuration:

```lua
vim.keymap.set({ "n", "v" }, "<leader>sr", ":SplitRef<CR>", { desc = "Split reference" })
vim.keymap.set("n", "<leader>sc", ":SplitRefClear<CR>", { desc = "Clear split references" })
```

## Configuration

Pass configuration options to the `setup` function:

```lua
require("splitref").setup({
  bg = "#1b454c", -- Custom hex color for highlighted reference lines
})
```

## License

MIT
