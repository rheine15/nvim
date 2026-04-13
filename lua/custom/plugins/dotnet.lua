-- C# / .NET LSP via csharp-ls (https://github.com/razzmatazz/csharp-language-server).
-- Generally lighter than OmniSharp; uses normal LSP (goto def/refs, etc. work with stock Telescope).
-- Requires: .NET SDK on PATH. Mason installs `csharp-language-server` (binary: `csharp-ls`).

---@type LazySpec
return {
  {
    'neovim/nvim-lspconfig',
    config = function()
      vim.lsp.config('csharp_ls', {})
      vim.lsp.enable('csharp_ls')

      vim.defer_fn(function()
        local ok, mr = pcall(require, 'mason-registry')
        if not ok then
          return
        end
        local pkg_name = 'csharp-language-server'
        local mlsp_ok, mlsp = pcall(require, 'mason-lspconfig')
        if mlsp_ok then
          local map = mlsp.get_mappings().lspconfig_to_package['csharp_ls']
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
    'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-treesitter').install { 'c_sharp' }
    end,
  },
}
