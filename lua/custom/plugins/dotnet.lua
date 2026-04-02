-- C# / .NET LSP via OmniSharp (omnisharp-roslyn).
-- Requires: .NET SDK on your PATH (https://dotnet.microsoft.com/download).
-- Mason installs package `omnisharp` (or the name from mason-lspconfig mappings).
--
-- OmniSharp often returns nothing for stock LSP textDocument/implementation (and
-- similar for definition). Hoffs/omnisharp-extended-lsp.nvim uses OmniSharp's
-- native navigation so Telescope gr* maps work reliably.

---@type LazySpec
return {
  {
    'neovim/nvim-lspconfig',
    config = function()
      vim.lsp.config('omnisharp', {
        settings = {
          MsBuild = {
            -- true can hide symbols in projects you never opened; hurts find-implementation across csprojs.
            LoadProjectsOnDemand = false,
          },
        },
      })
      vim.lsp.enable('omnisharp')

      vim.defer_fn(function()
        local ok, mr = pcall(require, 'mason-registry')
        if not ok then
          return
        end
        local pkg_name = 'omnisharp'
        local mlsp_ok, mlsp = pcall(require, 'mason-lspconfig')
        if mlsp_ok then
          local map = mlsp.get_mappings().lspconfig_to_package['omnisharp']
          if map then
            pkg_name = map
          end
        end
        mr.refresh(vim.schedule_wrap(function()
          local pkg = mr.get_package(pkg_name)
          if pkg and not pkg:is_installed() then
            pkg:install()
          end
        end))
      end, 1000)
    end,
  },

  {
    'Hoffs/omnisharp-extended-lsp.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'neovim/nvim-lspconfig',
    },
    config = function()
      -- Upstream uses get_clients({ buffer = 0 }); Neovim expects bufnr. Also allow client name variants.
      local u = require 'omnisharp_extended.utils'
      u.get_omnisharp_client = function()
        local bufnr = vim.api.nvim_get_current_buf()
        for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
          local n = (client.name or ''):lower()
          if n == 'omnisharp' or n == 'omnisharp_mono' or n:find('omnisharp', 1, true) then
            return client
          end
        end
      end
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-treesitter').install { 'c_sharp' }
    end,
  },
}
