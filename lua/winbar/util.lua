---@diagnostic disable: undefined-field

---@module 'winbar.util'
---@class winbar.utils
local M = {}

-- get the relative path of a buffer name, falling back to filename only for home directory paths.
---@param bufname string
---@return string
function M.get_relative_path(bufname)
  local relative_path = vim.fn.fnamemodify(bufname, ':~:.')
  if relative_path:sub(1, 1) == '~' then
    relative_path = vim.fn.fnamemodify(bufname, ':t')
  end

  return relative_path
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
  return vim.api.nvim_create_augroup('me_' .. name, { clear = true })
end

-- check if current buffer is a special buffer type or filetype that should be excluded.
---@param buftypes table<string>
---@param filetypes table<string>
function M.is_special_buffer(buftypes, filetypes)
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype

  -- skip special buffer types
  for _, bt in ipairs(buftypes) do
    if buftype == bt then
      return true
    end
  end

  -- skip special filetypes
  for _, ft in ipairs(filetypes) do
    if filetype == ft then
      return true
    end
  end

  return false
end

return M
