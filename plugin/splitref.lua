if vim.g.loaded_splitref then
  return
end
vim.g.loaded_splitref = true

require("splitref").setup()
