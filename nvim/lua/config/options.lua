require("config.remote_clipboard").setup()
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.snacks_animate = false
vim.opt.ignorecase = true
vim.opt.colorcolumn = "80"
vim.opt.termguicolors = true
vim.g.netrw_hide = 0

formatting = {
  format = function(entry, vim_item)
    vim_item.menu = "[" .. entry.source.name .. "]"
    return vim_item
  end,
}
