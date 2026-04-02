-- Smart cwd: under ~/repos use git repo root (e.g. perkspot-unified); elsewhere use the file’s directory.
-- Toggle with :SmartCdToggle (or require('custom.smart_cd').toggle()).

local M = {}

local git_root_memo = {}

---@return string|nil absolute path with trailing slash removed
local function abspath(p)
  if not p or p == '' then
    return nil
  end
  return (vim.fn.fnamemodify(p, ':p'):gsub('/$', ''))
end

---@param path string
---@return boolean
local function under_repos(path_abs)
  local repos = abspath(vim.fn.expand('~/repos'))
  if not repos or not path_abs then
    return false
  end
  return path_abs == repos or path_abs:find(repos .. '/', 1, true) == 1
end

---@param file_dir string absolute directory of the buffer file
---@return string|nil
local function git_toplevel(file_dir)
  if git_root_memo[file_dir] ~= nil then
    local c = git_root_memo[file_dir]
    return c and c or nil
  end
  if vim.fn.executable 'git' ~= 1 then
    git_root_memo[file_dir] = false
    return nil
  end
  local out = vim.trim(vim.fn.system { 'git', '-C', file_dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 or out == '' then
    git_root_memo[file_dir] = false
    return nil
  end
  local root = abspath(out)
  git_root_memo[file_dir] = root or false
  return root
end

---@param path_abs string
---@return string|nil first path segment inside ~/repos, e.g. .../repos/perkspot-unified/foo -> .../repos/perkspot-unified
local function repos_first_segment(path_abs)
  local repos = abspath(vim.fn.expand('~/repos'))
  if not repos or not under_repos(path_abs) then
    return nil
  end
  local rest = path_abs:sub(#repos + 1)
  if rest:sub(1, 1) == '/' then
    rest = rest:sub(2)
  end
  local name = rest:match '^([^/]+)'
  if not name or name == '' then
    return nil
  end
  return repos .. '/' .. name
end

---@param bufnr integer
---@return string|nil
function M.desired_cwd(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' or vim.bo[bufnr].buftype ~= '' then
    return nil
  end
  local path_abs = abspath(path)
  if not path_abs then
    return nil
  end
  local dir = vim.fs.dirname(path_abs)
  if not dir or dir == '' then
    return nil
  end
  dir = abspath(dir) or dir

  if under_repos(path_abs) then
    local root = git_toplevel(dir)
    if root and under_repos(root) then
      return root
    end
    return repos_first_segment(path_abs) or dir
  end

  return dir
end

function M.is_enabled()
  return vim.g.custom_smart_cd_enabled ~= false
end

function M.enable()
  vim.g.custom_smart_cd_enabled = true
end

function M.disable()
  vim.g.custom_smart_cd_enabled = false
end

function M.toggle()
  if M.is_enabled() then
    M.disable()
    vim.notify('Smart cd: off', vim.log.levels.INFO)
  else
    M.enable()
    vim.notify('Smart cd: on', vim.log.levels.INFO)
    M.apply_now()
  end
end

function M.apply_now()
  local want = M.desired_cwd()
  if want then
    local cur = abspath(vim.fn.getcwd())
    if cur ~= want then
      vim.cmd.cd(vim.fn.fnameescape(want))
    end
  end
end

function M.setup()
  vim.g.custom_smart_cd_enabled = true

  vim.api.nvim_create_user_command('SmartCdToggle', function() M.toggle() end, { desc = 'Toggle smart cwd (repos root / file dir)' })
  vim.api.nvim_create_user_command('SmartCdOn', function()
    M.enable()
    vim.notify('Smart cd: on', vim.log.levels.INFO)
    M.apply_now()
  end, { desc = 'Enable smart cwd' })
  vim.api.nvim_create_user_command('SmartCdOff', function()
    M.disable()
    vim.notify('Smart cd: off', vim.log.levels.INFO)
  end, { desc = 'Disable smart cwd' })

  vim.api.nvim_create_autocmd('BufEnter', {
    group = vim.api.nvim_create_augroup('custom-smart-cd', { clear = true }),
    callback = function(args)
      if not M.is_enabled() then
        return
      end
      local want = M.desired_cwd(args.buf)
      if not want then
        return
      end
      local cur = abspath(vim.fn.getcwd())
      if cur ~= want then
        vim.cmd.cd(vim.fn.fnameescape(want))
      end
    end,
  })
end

return M
