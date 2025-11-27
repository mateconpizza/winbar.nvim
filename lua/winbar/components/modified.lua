-- cmp/readonly.lua

local function highlight()
  return require('winbar.highlight').highlights
end

---@class winbar.components.modified: winbar.component
local M = {}

M.name = 'modified'
M.side = 'right'
M.icon = '[+]'
function M.enabled()
  return vim.bo.modified
end

function M.render()
  return '%#' .. highlight().modified.group .. '#' .. M.icon .. '%*'
end

---@param icon string
---@return winbar.component
function M.setup(icon)
  M.icon = icon
  return M
end

return M
