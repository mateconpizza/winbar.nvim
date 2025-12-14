-- comp/fileicon.lua

local function cache()
  return require('winbar.cache')
end

local function highlighter()
  return require('winbar.highlight')
end

---@class winbar.components.fileicon: winbar.component
local M = {}

-- get icon from external plugin
local function get_icon(bufnr)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
  local filetype = vim.bo[bufnr].filetype
  local ext = vim.fn.fnamemodify(filename, ':e')
  local icon, hl

  -- try mini.icons
  local _, mini_icons = pcall(require, 'mini.icons')
  if _G.MiniIcons then
    local is_default

    -- by filetype
    icon, hl, is_default = mini_icons.get('filetype', filetype)
    if not is_default then return highlighter().string(hl, icon) end

    -- by extension
    if ext ~= '' then
      icon, hl, is_default = mini_icons.get('extension', ext)
      if not is_default then return highlighter().string(hl, icon) end
    end

    -- by file (lets `mini.icons` do its full internal resolution)
    icon, hl = mini_icons.get('file', filename)
    return highlighter().string(hl, icon)
  end

  -- fallback to devicons
  if not icon then
    local ok_dev, devicons = pcall(require, 'nvim-web-devicons')
    if ok_dev then
      if ext == '' then ext = filetype end
      icon, hl = devicons.get_icon(filename, ext or filetype, { default = true })
    end
  end

  return (icon and hl) and (highlighter().string(hl, icon)) or ''
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
  return cache().ensure(M.name, bufnr, function()
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
