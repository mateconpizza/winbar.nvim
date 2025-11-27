-- comp/fileicon.lua

local function cache()
  return require('winbar.cache')
end

---@class winbar.components.fileicon: winbar.component
local M = {}

-- get icon from external plugin
local function get_icon(bufnr)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
  local filetype = vim.bo[bufnr].filetype
  local icon, hl

  -- try mini.icons
  local ok_mini, mini = pcall(require, 'mini.icons')
  if ok_mini then
    icon, hl = mini.get('filetype', filetype)
  end

  -- fallback to devicons
  if not icon then
    local ok_dev, devicons = pcall(require, 'nvim-web-devicons')
    if ok_dev then
      local ext = vim.fn.fnamemodify(filename, ':e')
      if ext == '' then ext = filetype end
      icon, hl = devicons.get_icon(filename, ext or filetype, { default = true })
    end
  end

  return (icon and hl) and ('%#' .. hl .. '#' .. icon .. '%*') or ''
end

M.name = 'fileicon'
M.side = 'right'
M.enabled = function()
  return M.opts
end

M.opts = false

---@return string
function M.render()
  local bufnr = vim.api.nvim_get_current_buf()
  return cache().ensure('fileicon', bufnr, function()
    return get_icon(bufnr)
  end)
end

---@param opts boolean
---@return winbar.component
function M.setup(opts)
  M.opts = opts or false
  return M
end

return M
