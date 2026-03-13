-- comp/fileicon.lua

local function cache()
  return require('winbar.cache')
end

local function utils()
  return require('winbar.util')
end

local function highlight()
  return require('winbar.highlight')
end

---@class winbar.components.fileicon: winbar.component
local M = {}

-- Helper to resolve icon and highlight group name from external plugins
---@param bufnr number
---@return string? icon
---@return string? hl_group
local function resolve_icon_data(bufnr)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
  local filetype = vim.bo[bufnr].filetype
  local ext = vim.fn.fnamemodify(filename, ':e')

  -- try mini.icons
  if _G.MiniIcons then
    local mini_icons = require('mini.icons')
    local icon, hl, is_default

    -- try specific resolvers first for accuracy
    icon, hl, is_default = mini_icons.get('filetype', filetype)
    if not is_default then return icon, hl end

    if ext ~= '' then
      icon, hl, is_default = mini_icons.get('extension', ext)
      if not is_default then return icon, hl end
    end

    -- fallback to generic file resolver
    icon, hl = mini_icons.get('file', filename)
    return icon, hl
  end

  -- fallback to nvim-web-devicons
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if ok then
    if ext == '' then ext = filetype end
    local icon, hl = devicons.get_icon(filename, ext, { default = true })
    return icon, hl
  end

  return nil, nil
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

  -- retrieve icon data
  -- result object: { icon = "", hl = "MiniIconsLua" }
  local data = cache().ensure(M.name, bufnr, function()
    local icon, hl = resolve_icon_data(bufnr)
    if not icon or not hl then return nil end
    return { icon = icon, hl = hl }
  end)

  if not data then return '' end

  local hl_group = data.hl
  if not utils().is_active_win() then hl_group = highlight().inactive end

  return highlight().string(hl_group, data.icon)
end

---@param opts boolean
---@return winbar.component
function M.setup(opts)
  M.opts = opts or false
  return M
end

return M
