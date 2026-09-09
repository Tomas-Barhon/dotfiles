-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<C-s>v", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<C-s>h", "<C-w>s", { desc = "Split window horizontally" })

vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scrroll up and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-f>", "<C-f>zz", { desc = "Page down and center" })
vim.keymap.set("n", "<C-b>", "<C-b>zz", { desc = "Page up and center" })
--- focus neotree when open
vim.keymap.set("n", "<leader>e", ":Neotree focus<CR>", { desc = "Toggle Neotree" })
