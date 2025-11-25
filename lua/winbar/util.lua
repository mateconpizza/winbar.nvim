---@diagnostic disable: undefined-field
local uv = vim.uv or vim.loop
local last_redraw = 0

---@module 'winbar.util'
---@class winbar.utils
local M = {}

-- get the relative path of a buffer name, falling back to filename only for home directory paths.
---@param bufname string
---@return string
function M.get_relative_path(bufname)
  local relative_path = vim.fn.fnamemodify(bufname, ':~:.')
  if relative_path:sub(1, 1) == '~' then relative_path = vim.fn.fnamemodify(bufname, ':t') end

  return relative_path
end

-- skip special or unlisted buffers
function M.is_normal_buffer(bufnr)
  return vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == '' and vim.bo[bufnr].buflisted
end

-- check if a buffer is visible in any non-floating window.
---@param bufnr integer Buffer handle
---@return boolean true if visible in at least one normal window, false otherwise
function M.is_visible_in_normal_win(bufnr)
  return vim.iter(vim.fn.win_findbuf(bufnr)):any(function(win)
    return not M.is_float(win)
  end)
end

-- check if the window is float
---@param winid integer
---@return boolean
function M.is_float(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ''
end

-- create a autocommand group
---@param name string
function M.augroup(name)
  return vim.api.nvim_create_augroup('winbar_' .. name, { clear = true })
end

-- check if current buffer is a special buffer type or filetype that should be excluded.
---@param buftypes table<string>
---@param filetypes table<string>
---@return boolean
function M.is_special_buffer(buftypes, filetypes)
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype

  -- skip special buffer types
  for _, bt in ipairs(buftypes) do
    if buftype == bt then return true end
  end

  -- skip special filetypes
  for _, ft in ipairs(filetypes) do
    if filetype == ft then return true end
  end

  return false
end

-- redraws the statusline/winbar with a throttle interval.
function M.throttled_redraw(interval_ms)
  local now = uv.hrtime()
  if (now - last_redraw) / 1e6 > interval_ms then
    last_redraw = now
    vim.cmd('redrawstatus')
  end
end

---@return string|nil
function M.git_branch()
  -- check if git is available
  if vim.fn.executable('git') ~= 1 then return nil end

  -- check if inside a git repository
  local is_git_repo = vim.fn.system({ 'git', 'rev-parse', '--is-inside-work-tree' })
  if vim.v.shell_error ~= 0 or not is_git_repo:match('true') then return nil end

  -- get current branch name
  local branch = vim.fn.system({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }):gsub('\n', '')
  if vim.v.shell_error ~= 0 or branch == '' then return nil end

  return branch
end

return M
