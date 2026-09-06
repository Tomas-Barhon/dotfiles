return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          before_init = function(_, config)
            local util = require("lspconfig.util")

            -- Find project root (pyproject.toml or .git usually marks uv workspace)
            local root = util.root_pattern("pyproject.toml", ".git")(vim.api.nvim_buf_get_name(0))

            local function find_venv(start)
              local path = util.search_ancestors(start, function(dir)
                local python = dir .. "/.venv/bin/python"
                if vim.fn.executable(python) == 1 then
                  return dir
                end
              end)
              return path
            end

            local venv_root = find_venv(root or vim.fn.getcwd())

            if venv_root then
              config.settings.python.pythonPath = venv_root .. "/.venv/bin/python"
            else
              local python = vim.fn.exepath("python3") or vim.fn.exepath("python")
              if python ~= "" then
                config.settings.python.pythonPath = python
              end
            end
          end,

          settings = {
            pyright = {
              disableOrganizeImports = true,
            },
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
      },
    },
  },
}
