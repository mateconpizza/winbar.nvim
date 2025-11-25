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

---@return integer buf The buffer number
---@return integer win The window ID
function M.create_floating_window(opts)
  opts = opts or {}
  local width = opts.width or math.floor(vim.o.columns * 0.7)
  local height = opts.height or math.floor(vim.o.lines * 0.7)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  local defaults = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  }

  opts.buf = nil
  opts = vim.tbl_extend('force', opts, defaults)
  local win = vim.api.nvim_open_win(buf, true, opts)

  return buf, win
end

---@param s string
---@param n integer
---@return string
function M.truncate_str(s, n)
  if #s > n then return s:sub(1, n) .. '...' end
  return s
end

-- create a prettified string array representation of the store
---@param cache table
---@return string[]
function M.prettify_store(cache)
  local lines = {}

  -- add header
  local title = 'Cache Store Contents'
  table.insert(lines, title)
  table.insert(lines, '=' .. string.rep('=', #title - 1))
  table.insert(lines, '')

  -- iterate through each domain (namespace)
  for domain, domain_data in pairs(cache) do
    local domain_title = string.format('Domain: %s', domain)
    table.insert(lines, domain_title)
    table.insert(lines, string.rep('-', #domain_title))

    -- check if domain has any keys
    local domain_empty = true
    for _ in pairs(domain_data) do
      domain_empty = false
      break
    end

    if domain_empty then
      table.insert(lines, '  (no entries)')
    else
      -- iterate through each key in the domain
      for key, entry in pairs(domain_data) do
        table.insert(lines, string.format('  Key: %s', key))

        if type(entry) == 'table' then
          -- pretty print the entry fields
          if entry.value ~= nil then
            local value_str = type(entry.value) == 'string' and string.format('"%s"', entry.value)
              or tostring(entry.value)
            table.insert(lines, string.format('    value: %s', value_str))
          end

          if entry.expires_at then table.insert(lines, string.format('    expires_at: %s', entry.expires_at)) end
          if entry.time then table.insert(lines, string.format('    time: %s', entry.time)) end
          if entry.bufnr then table.insert(lines, string.format('    bufnr: %s', entry.bufnr)) end

          -- show any other fields
          for field, val in pairs(entry) do
            if field ~= 'value' and field ~= 'expires_at' and field ~= 'time' and field ~= 'bufnr' then
              table.insert(lines, string.format('    %s: %s', field, tostring(val)))
            end
          end
        else
          table.insert(lines, string.format('    %s', tostring(entry)))
        end

        table.insert(lines, '')
      end
    end

    table.insert(lines, '')
  end

  return lines
end

return M
