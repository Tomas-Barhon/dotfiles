-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<C-s>v", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<C-s>h", "<C-w>s", { desc = "Split window horizontally" })

vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
  expr = true,
  replace_keycodes = false,
})
vim.g.copilot_no_tab_map = true

vim.keymap.set("i", "<C-k>", "<Plug>(copilot-dismiss)")
vim.keymap.set("i", "<C-l>", "<Plug>(copilot-next)")
vim.keymap.set("i", "<C-h>", "<Plug>(copilot-previous)")
vim.keymap.set("i", "<C-;>", "<Plug>(copilot-accept-word)")
vim.keymap.set("i", "<C-'>", "<Plug>(copilot-accept-line)")

vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scrroll up and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-f>", "<C-f>zz", { desc = "Page down and center" })
vim.keymap.set("n", "<C-b>", "<C-b>zz", { desc = "Page up and center" })
--- focus neotree when open
vim.keymap.set("n", "<leader>e", ":Neotree focus<CR>", { desc = "Toggle Neotree" })
