function ColorMyPencils(color)
  color = color or "rose-pine"
  vim.cmd.colorscheme(color)
  --  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  --vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end
return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      require("rose-pine").setup({
        disable_background = true,
        styles = {
          bold = true,
          italics = false,
          transparency = true,
        },
        highlight_groups = {
          Pmenu = { bg = "surface" },
          PmenuSel = { bg = "highlight", bold = true },
          Comment = { fg = "muted", italic = false },
        },
      })
      vim.cmd("colorscheme rose-pine")
      ColorMyPencils()
    end,
  },
}
