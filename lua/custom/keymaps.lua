-- Central keymaps. Loaded from init.lua and plugin configs via the functions below.
-- See `:help vim.keymap.set()`

local M = {}

-- =============================================================================
-- General (search UI, diagnostics, terminal, splits)
-- =============================================================================

function M.general()
  -- Clear highlights on search when pressing <Esc> in normal mode
  -- See `:help hlsearch`
  vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

  -- Diagnostics → quickfix
  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

  -- Exit terminal mode (discoverable alternative to <C-\><C-n>)
  vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

  -- Split / window navigation — see `:help wincmd`
  vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
  vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
  vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
  vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

  -- Format buffer (conform.nvim loads on first use)
  vim.keymap.set({ 'n', 'x' }, '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, { desc = '[F]ormat buffer' })

  vim.keymap.set('n', '<leader>tc', function() require('custom.smart_cd').toggle() end, { desc = '[T]oggle smart [C]wd (see :SmartCdToggle)' })
end

-- =============================================================================
-- Telescope – pickers & LSP (Telescope must be loaded before calling)
-- =============================================================================

---@param builtin telescope.builtin
function M.telescope(builtin)
  -- --- Formatting helpers (buffer) ---
  vim.keymap.set('n', '<leader>fj', '<cmd>%!jq .<CR>', { desc = '[F]ormat [J]SON' })
  vim.keymap.set('n', '<leader>fw', '<cmd>%s/\\s*$//e<CR>', { desc = '[F]ormat Trailing [W]hitespace' })

  -- --- Search / pickers (<leader>s…) ---
  vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
  vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
  vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
  vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
  vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
  vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
  vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
  vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
  vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
  vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
  vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

  -- --- .NET ---
  vim.keymap.set('n', '<leader>bc', function()
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'
    builtin.find_files {
      prompt_title = 'dotnet build (csproj/sln)',
      find_command = { 'fd', '-e', 'csproj', '-e', 'sln', '-t', 'f' },
      attach_mappings = function(prompt_bufnr, map)
        local function build_close()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry and entry.path then
            vim.cmd('split | term dotnet build ' .. vim.fn.shellescape(entry.path, true))
          end
        end
        map('i', '<CR>', build_close)
        map('n', '<CR>', build_close)
        return true
      end,
    }
  end, { desc = '[B]uild [C]# projects' })

  -- --- Current buffer / config ---
  vim.keymap.set('n', '<leader>/', function()
    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end, { desc = '[/] Fuzzily search in current buffer' })

  vim.keymap.set('n', '<leader>s/', function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end, { desc = '[S]earch [/] in Open Files' })

  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

  -- LSP actions that use Telescope (per buffer when LSP attaches)
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event) M.telescope_lsp_attach(builtin, event) end,
  })
end

--- Buffer-local Telescope LSP maps. C# uses omnisharp_extended when available.
---@param builtin telescope.builtin
function M.telescope_lsp_attach(builtin, event)
  local buf = event.buf

  local function csharp_telescope_or(extended_fn, builtin_fn)
    return function()
      local ft = vim.bo.filetype
      if ft == 'cs' then
        local ok, ox = pcall(require, 'omnisharp_extended')
        if ok then
          extended_fn(ox)
          return
        end
      end
      builtin_fn { bufnr = buf }
    end
  end

  vim.keymap.set(
    'n',
    'grr',
    csharp_telescope_or(function(ox) ox.telescope_lsp_references() end, builtin.lsp_references),
    { buffer = buf, desc = '[G]oto [R]eferences' }
  )
  vim.keymap.set(
    'n',
    'gri',
    csharp_telescope_or(function(ox) ox.telescope_lsp_implementation() end, builtin.lsp_implementations),
    { buffer = buf, desc = '[G]oto [I]mplementation' }
  )
  vim.keymap.set(
    'n',
    'grd',
    csharp_telescope_or(function(ox) ox.telescope_lsp_definition() end, builtin.lsp_definitions),
    { buffer = buf, desc = '[G]oto [D]efinition' }
  )

  vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
  vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

  vim.keymap.set(
    'n',
    'grt',
    csharp_telescope_or(function(ox) ox.telescope_lsp_type_definition() end, builtin.lsp_type_definitions),
    { buffer = buf, desc = '[G]oto [T]ype Definition' }
  )
end

-- =============================================================================
-- LSP (non-Telescope): rename, code actions, declaration, highlights, inlay
-- =============================================================================

function M.lsp_attach(event)
  local map = function(keys, func, desc, mode)
    mode = mode or 'n'
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
  end

  map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
  map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
  map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if client and client:supports_method('textDocument/documentHighlight', event.buf) then
    local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      buffer = event.buf,
      group = highlight_augroup,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = event.buf,
      group = highlight_augroup,
      callback = vim.lsp.buf.clear_references,
    })
    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
      callback = function(event2)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
      end,
    })
  end

  if client and client:supports_method('textDocument/inlayHint', event.buf) then
    map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
  end
end

return M
