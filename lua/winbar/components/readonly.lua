-- comp/readonly.lua

local function highlight()
  return require('winbar.highlight').highlights
end

---@class winbar.components.readonly: winbar.component
local M = {}

M.name = 'readonly'
M.side = 'right'
M.icon = '[RO]'
function M.enabled()
  return vim.bo.readonly
end

function M.render()
  return '%#' .. highlight().readonly.group .. '#' .. M.icon .. '%*'
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon
  return M
end

return M
