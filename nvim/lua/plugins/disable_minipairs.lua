return {
  {
    "nvim-mini/mini.pairs",
    opts = {
      mappings = {
        -- Disable the <CR> mapping
        ["\r"] = { action = "closeopen", pair = "\r\r", neigh_pattern = "[^\\].", register = { cr = false } },
      },
    },
  },
}
