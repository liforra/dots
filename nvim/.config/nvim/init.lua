-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.api.nvim_set_keymap(
  "t", -- mode: terminal
  "<Esc>", -- lhs
  [[<C-\><C-n>]], -- rhs (enter Normal mode)
  { noremap = true, silent = true }
)
