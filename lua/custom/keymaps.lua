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

  -- Back and forward file navigation
  --vim.keymap.set('n', '<leader>gh', bprev, { desc = 'Previous buffer' })
  --vim.keymap.set('n', '<leader>gl', bprev, { desc = 'Next buffer' })
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
          if entry and entry.path then vim.cmd('split | term dotnet build ' .. vim.fn.shellescape(entry.path, true)) end
        end
        map('i', '<CR>', build_close)
        map('n', '<CR>', build_close)
        return true
      end,
    }
  end, { desc = '[B]uild [C]# projects' })

  vim.keymap.set('n', '<leader>br', function()
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'
    builtin.find_files {
      prompt_title = 'dotnet run (.sln / .csproj)',
      find_command = { 'fd', '-e', 'sln', '-e', 'csproj', '-t', 'f' },
      attach_mappings = function(prompt_bufnr, map)
        local function run_close()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry and entry.path then
            local path = vim.fn.fnamemodify(entry.path, ':p')
            local ext = vim.fn.fnamemodify(path, ':e'):lower()
            if ext == 'csproj' then
              vim.cmd('split | term sh -lc ' .. vim.fn.shellescape('dotnet run --project ' .. path, true))
            else
              local dir = vim.fn.fnamemodify(path, ':h')
              vim.cmd('split | term sh -lc ' .. vim.fn.shellescape('cd ' .. dir .. ' && dotnet run', true))
            end
          end
        end
        map('i', '<CR>', run_close)
        map('n', '<CR>', run_close)
        return true
      end,
    }
  end, { desc = 'dotnet [R]un (sln → cwd run, csproj → --project)' })

  vim.keymap.set('n', '<leader>bt', function()
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'

    local test_project_fd = { 'fd', '-i', 'test', '-e', 'csproj', '-e', 'sln', '-t', 'f' }

    local function run_dotnet_test(path)
      path = vim.fn.fnamemodify(path, ':p')
      vim.cmd('split | term dotnet test ' .. vim.fn.shellescape(path, true))
    end

    local paths = vim.fn.systemlist(test_project_fd)
    if vim.v.shell_error ~= 0 then
      vim.notify('fd failed (is fd installed?)', vim.log.levels.ERROR)
      return
    end
    if #paths == 0 then
      vim.notify('No .csproj/.sln with "test" in the path (under cwd)', vim.log.levels.WARN)
      return
    end
    if #paths == 1 then
      run_dotnet_test(paths[1])
      return
    end

    builtin.find_files {
      prompt_title = 'dotnet test (path contains "test")',
      find_command = test_project_fd,
      attach_mappings = function(prompt_bufnr, map)
        local function test_close()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry and entry.path then
            run_dotnet_test(entry.path)
          end
        end
        map('i', '<CR>', test_close)
        map('n', '<CR>', test_close)
        return true
      end,
    }
  end, { desc = '[B]uild [T]est projects' })

  -- --- Current buffer / config ---
  vim.keymap.set(
    'n',
    '<leader>/',
    function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end,
    { desc = '[/] Fuzzily search in current buffer' }
  )

  vim.keymap.set(
    'n',
    '<leader>s/',
    function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end,
    { desc = '[S]earch [/] in Open Files' }
  )

  vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

  -- LSP actions that use Telescope (per buffer when LSP attaches)
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
    callback = function(event) M.telescope_lsp_attach(builtin, event) end,
  })
end

--- Buffer-local Telescope LSP maps.
---@param builtin telescope.builtin
function M.telescope_lsp_attach(builtin, event)
  local buf = event.buf

  vim.keymap.set('n', 'grr', function() builtin.lsp_references { bufnr = buf } end, { buffer = buf, desc = '[G]oto [R]eferences' })
  vim.keymap.set('n', 'gri', function() builtin.lsp_implementations { bufnr = buf } end, { buffer = buf, desc = '[G]oto [I]mplementation' })
  vim.keymap.set('n', 'grd', function() builtin.lsp_definitions { bufnr = buf } end, { buffer = buf, desc = '[G]oto [D]efinition' })

  vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
  vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

  vim.keymap.set('n', 'grt', function() builtin.lsp_type_definitions { bufnr = buf } end, { buffer = buf, desc = '[G]oto [T]ype Definition' })
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
