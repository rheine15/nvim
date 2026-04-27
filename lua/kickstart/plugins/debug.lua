-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

---@module 'lazy'
---@type LazySpec
return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- DAP UI: nvim-dap-view (nvim-dap-ui replaced; see commented block in config)
    { 'igorlfs/nvim-dap-view', version = '1.*' },

    -- Previous UI: nvim-dap-ui
    -- 'rcarriga/nvim-dap-ui',
    -- 'nvim-neotest/nvim-nio', -- required by nvim-dap-ui

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<F11>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<F10>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F3>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    { '<leader>b', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
    { '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Set Breakpoint' },
    -- Toggle dap UI (see session output, scopes, etc.)
    { '<F7>', function() require('dap-view').toggle() end, desc = 'Debug: Toggle DAP view' },
    -- { '<F7>', function() require('dapui').toggle() end, desc = 'Debug: See last session result.' },
  },
  config = function()
    local dap = require 'dap'
    require('dap-view').setup { auto_toggle = true }

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'netcoredbg',
      },
    }

    -- (previous) nvim-dap-ui; replaced by nvim-dap-view
    -- local dapui = require 'dapui'
    -- dapui.setup {
    --   icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
    --   controls = {
    --     icons = {
    --       pause = '⏸',
    --       play = '▶',
    --       step_into = '⏎',
    --       step_over = '⏭',
    --       step_out = '⏮',
    --       step_back = 'b',
    --       run_last = '▶▶',
    --       terminate = '⏹',
    --       disconnect = '⏏',
    --     },
    --   },
    -- }
    -- dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    -- dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    -- dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Change breakpoint icons
    -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    -- local breakpoint_icons = vim.g.have_nerd_font
    --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
    --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    -- for type, icon in pairs(breakpoint_icons) do
    --   local tp = 'Dap' .. type
    --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
    --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    -- end

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- .NET / C# via netcoredbg (install with :Mason or `brew install netcoredbg` on macOS)
    local mason_netcoredbg = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason', 'packages', 'netcoredbg', vim.fn.has 'win32' == 1 and 'netcoredbg.exe' or 'netcoredbg')
    local netcoredbg_cmd = vim.uv.fs_stat(mason_netcoredbg) and mason_netcoredbg or vim.fn.exepath 'netcoredbg'
    if netcoredbg_cmd == '' then
      netcoredbg_cmd = mason_netcoredbg
    end

    dap.adapters.coreclr = {
      type = 'executable',
      command = netcoredbg_cmd,
      args = { '--interpreter=vscode' },
    }

    -- Set by find_debug_dll so cwd matches the app output folder (hostpolicy/runtime layout).
    local launch_working_dir = nil

    --- Prefer DLLs that sit next to a .runtimeconfig.json (real entry assemblies). Plain dependency
    --- DLLs (e.g. Autofac.*) lack it and break the host with libhostpolicy / self-contained errors.
    local function find_debug_dll()
      launch_working_dir = nil
      local cwd = vim.fn.getcwd()
      local raw = vim.fn.globpath(cwd, '**/bin/Debug/**/*.dll', false, true)
      local paths = type(raw) == 'table' and raw or vim.split(raw or '', '\n')

      local function has_runtimeconfig(dll_path)
        local rc = vim.fn.fnamemodify(dll_path, ':r') .. '.runtimeconfig.json'
        return vim.fn.filereadable(rc) == 1
      end

      local entrypoints = {}
      for _, path in ipairs(paths) do
        if path ~= '' and not path:find('/ref/', 1, true) and not path:find('\\ref\\', 1, true) then
          if has_runtimeconfig(path) then
            table.insert(entrypoints, path)
          end
        end
      end

      if #entrypoints == 0 then
        return vim.fn.input('Path to entry DLL (.runtimeconfig.json beside it): ', cwd .. '/bin/Debug/', 'file')
      end

      local csproj_roots = {}
      local raw_cs = vim.fn.globpath(cwd, '**/*.csproj', false, true)
      local csps = type(raw_cs) == 'table' and raw_cs or vim.split(raw_cs or '', '\n')
      for _, p in ipairs(csps) do
        if p ~= '' and not vim.fn.fnamemodify(p, ':t'):match('Tests%.csproj$') then
          csproj_roots[vim.fn.fnamemodify(p, ':t:r')] = true
        end
      end

      local function score(path)
        local base = vim.fn.fnamemodify(path, ':t:r')
        local s = 0
        if csproj_roots[base] then
          s = s + 1000
        end
        if path:find('/src/', 1, true) or path:find('\\src\\', 1, true) then
          s = s + 100
        end
        if path:find('/tests/', 1, true) or path:find('\\tests\\', 1, true) or base:find('Tests', 1, true) then
          s = s - 200
        end
        return s
      end

      table.sort(entrypoints, function(a, b)
        return score(a) > score(b)
      end)

      local chosen = entrypoints[1]
      launch_working_dir = vim.fn.fnamemodify(chosen, ':h')
      return chosen
    end

    dap.configurations.cs = {
      {
        type = 'coreclr',
        name = 'Launch .NET (netcoredbg)',
        request = 'launch',
        program = find_debug_dll,
        cwd = function()
          return launch_working_dir or vim.fn.getcwd()
        end,
      },
      {
        type = 'coreclr',
        name = 'Attach .NET (netcoredbg)',
        request = 'attach',
        processId = function()
          return tonumber(vim.fn.input('Process ID: '), 10)
        end,
      },
    }
  end,
}
